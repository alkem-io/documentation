#!/usr/bin/env bash
set -euo pipefail
#
# Generate a kubeconfig for the Scaleway v3 ACCEPTANCE cluster on the runner.
#
# Ported from infrastructure-operations/.scripts/configure-acceptance-v3-kubeconfig.sh.
#
# WHY THIS EXISTS: this repo previously authenticated with the stored
# KUBECONFIG_SECRET_SCALEWAY_ACC org secret, which still points at the
# DECOMMISSIONED pre-v3 acceptance cluster (51.158.216.139). Deploys therefore
# failed with `dial tcp 51.158.216.139:6443: i/o timeout` while the workflow's
# top-level status still read green, because only the deploy job failed.
#
# A kubeconfig cannot simply be re-stored as a secret: the v3 clusters issue
# short-lived credentials via an `exec` plugin that shells out to the scw CLI,
# which is not portable to a runner. `auth-method=legacy` below is what makes
# the generated config self-contained and therefore usable in CI.
#
# Secrets are consumed from the environment and never echoed. Do not add
# `set -x` here, and do not print $HOME/.kube/config.

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${HOME:?HOME is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${SCW_ACCESS_KEY:?SCW_ACCESS_KEY is required}"
: "${SCW_SECRET_KEY:?SCW_SECRET_KEY is required}"
: "${SCW_CLUSTER_ID:?SCW_CLUSTER_ID is required}"
: "${SCW_PROJECT_ID:?SCW_PROJECT_ID is required}"
: "${SCW_ORGANIZATION_ID:?SCW_ORGANIZATION_ID is required}"
: "${SCW_REGION:?SCW_REGION is required}"

readonly target_cluster=63babd2d-2acc-4bcd-992a-46278088916c
readonly target_project=b038f044-d128-4011-8ffb-3eb8589ecc04
readonly target_region=nl-ams
# scaleway-cli v2.59.0 linux/amd64 — same pin as infrastructure-operations.
readonly scw_cli_sha256=e9606386ddbf7885f06d5d585d04356559039c55252bf2abd99e55b69f3d94f6

# Fail before touching any cluster if the environment points somewhere else.
[[ $SCW_CLUSTER_ID == "$target_cluster" ]] || {
  echo "FAIL: cluster id $SCW_CLUSTER_ID is not $target_cluster" >&2
  exit 1
}
[[ $SCW_PROJECT_ID == "$target_project" ]] || {
  echo "FAIL: project id $SCW_PROJECT_ID is not $target_project" >&2
  exit 1
}
[[ $SCW_REGION == "$target_region" ]] || {
  echo "FAIL: region $SCW_REGION is not $target_region" >&2
  exit 1
}

umask 077
mkdir -p "$RUNNER_TEMP/bin" "$HOME/.kube"
curl --fail --location --silent --show-error \
  --connect-timeout 10 --max-time 120 \
  --retry 3 --retry-connrefused --retry-delay 2 \
  --output "$RUNNER_TEMP/bin/scw" \
  https://github.com/scaleway/scaleway-cli/releases/download/v2.59.0/scaleway-cli_2.59.0_linux_amd64
echo "$scw_cli_sha256  $RUNNER_TEMP/bin/scw" | sha256sum --check
chmod 700 "$RUNNER_TEMP/bin/scw"
echo "$RUNNER_TEMP/bin" >> "$GITHUB_PATH"
export PATH="$RUNNER_TEMP/bin:$PATH"

export SCW_DEFAULT_PROJECT_ID="$SCW_PROJECT_ID"
export SCW_DEFAULT_ORGANIZATION_ID="$SCW_ORGANIZATION_ID"
export SCW_DEFAULT_REGION="$SCW_REGION"

# auth-method=legacy emits a static-token kubeconfig (no exec plugin), which is
# what makes the result usable on a runner that has no scw profile.
scw k8s kubeconfig get "$SCW_CLUSTER_ID" \
  region="$SCW_REGION" auth-method=legacy \
  > "$HOME/.kube/config"

generated_context="$(kubectl config current-context)"
target_context="acceptance-v3-$SCW_CLUSTER_ID"
if [[ $generated_context != "$target_context" ]]; then
  kubectl config rename-context "$generated_context" "$target_context" >/dev/null
fi

# shellcheck source=acceptance-v3-target-fence.sh
. "$(dirname "$0")/acceptance-v3-target-fence.sh"
acceptance_v3_assert_target_fence
# Bound the request: kubectl's default --request-timeout is 0 (no timeout), so an
# unresponsive control plane would hang the deploy job with no diagnostic.
kubectl get --raw=/readyz --request-timeout=30s
