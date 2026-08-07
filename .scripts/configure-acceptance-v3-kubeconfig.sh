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
# credentials through an `exec` plugin that shells out to the scw CLI. This
# script installs that CLI and a job-local mode-0600 profile, so the generated
# kubeconfig is portable for the lifetime of this runner job without asking
# Scaleway for a privileged legacy kubeconfig. The legacy endpoint rejects the
# Project-scoped KubernetesReadOnly policy used by the deployer application.
#
# Secrets are consumed from the environment and never echoed. Do not add
# `set -x` here, and do not print $HOME/.kube/config.

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${HOME:?HOME is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${SCW_ACCESS_KEY:?SCW_ACCESS_KEY is required}"
: "${SCW_SECRET_KEY:?SCW_SECRET_KEY is required}"
: "${SCW_APPLICATION_ID:?SCW_APPLICATION_ID is required}"
: "${SCW_CLUSTER_ID:?SCW_CLUSTER_ID is required}"
: "${SCW_PROJECT_ID:?SCW_PROJECT_ID is required}"
: "${SCW_ORGANIZATION_ID:?SCW_ORGANIZATION_ID is required}"
: "${SCW_REGION:?SCW_REGION is required}"

readonly target_cluster=63babd2d-2acc-4bcd-992a-46278088916c
readonly target_project=b038f044-d128-4011-8ffb-3eb8589ecc04
readonly target_application=17a221c4-613b-423d-b6c4-cb5245940fd4
readonly target_deployer_group=scaleway:group:393445d9-6d83-4c5d-9880-1a83b96d67cf
readonly target_admin_group=scaleway:group:54b80cea-7db9-4238-9cf3-406fd83592ba
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
[[ $SCW_APPLICATION_ID == "$target_application" ]] || {
  echo "FAIL: application id $SCW_APPLICATION_ID is not $target_application" >&2
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

# Keep the API key in a job-local profile. Unset the environment variables
# before generating the kubeconfig: otherwise scw copies the token into the
# kubeconfig instead of emitting the intended exec-credential reference.
readonly scw_config="$RUNNER_TEMP/scw-documentation-acceptance-v3.yaml"
printf 'access_key: %s\nsecret_key: %s\ndefault_organization_id: %s\ndefault_project_id: %s\ndefault_region: %s\ndefault_zone: %s\n' \
  "$SCW_ACCESS_KEY" \
  "$SCW_SECRET_KEY" \
  "$SCW_ORGANIZATION_ID" \
  "$SCW_PROJECT_ID" \
  "$SCW_REGION" \
  nl-ams-1 >"$scw_config"
chmod 600 "$scw_config"
unset SCW_ACCESS_KEY SCW_SECRET_KEY SCW_REGION

scw --config "$scw_config" k8s kubeconfig get "$SCW_CLUSTER_ID" \
  region="$target_region" auth-method=cli \
  > "$HOME/.kube/config"

# Fail if a future CLI change embeds a token or loses the job-local profile.
[[ -z $(kubectl config view --minify --raw -o jsonpath='{.users[0].user.token}') ]] || {
  echo "FAIL: generated kubeconfig embeds a bearer token" >&2
  exit 1
}
[[ $(kubectl config view --minify --raw -o jsonpath='{.users[0].user.exec.command}') == scw ]] || {
  echo "FAIL: generated kubeconfig has no scw exec credential" >&2
  exit 1
}
exec_args=$(kubectl config view --minify --raw -o jsonpath='{.users[0].user.exec.args}')
[[ $exec_args == *"$scw_config"* ]] || {
  echo "FAIL: generated kubeconfig does not use the job-local scw profile" >&2
  exit 1
}

generated_context="$(kubectl config current-context)"
target_context="acceptance-v3-$SCW_CLUSTER_ID"
if [[ $generated_context != "$target_context" ]]; then
  kubectl config rename-context "$generated_context" "$target_context" >/dev/null
fi

# shellcheck source=acceptance-v3-target-fence.sh
. "$(dirname "$0")/acceptance-v3-target-fence.sh"
acceptance_v3_assert_target_fence

# Fence the credential as well as the target. The API key must belong to the
# documentation application, carry the deployer group, and carry no broad or
# admin path. ROLE is an IAM/RBAC property; an access-key name cannot downscope
# a more privileged application.
actual_username=$(kubectl auth whoami -o jsonpath='{.status.userInfo.username}')
[[ $actual_username == "scaleway:bearer:$target_application" ]] || {
  echo "FAIL: credential bearer $actual_username is not the documentation deployer application" >&2
  exit 1
}
read -r -a actual_groups <<<"$(kubectl auth whoami -o jsonpath='{.status.userInfo.groups[*]}')"
has_group() {
  local expected=$1
  local group
  for group in "${actual_groups[@]}"; do
    [[ $group == "$expected" ]] && return 0
  done
  return 1
}

has_group "$target_deployer_group" || {
  echo "FAIL: credential is not in the acceptance-v3 deployer group" >&2
  exit 1
}
if has_group scaleway:cluster-write || has_group system:masters || has_group "$target_admin_group"; then
  echo "FAIL: credential has broad or administrator access" >&2
  exit 1
fi

can_i() {
  local result
  result=$(kubectl auth can-i "$@" 2>/dev/null || true)
  [[ $result == yes || $result == no ]] || {
    echo "FAIL: unexpected authorization result for kubectl auth can-i $*" >&2
    exit 1
  }
  printf '%s\n' "$result"
}

expect_can_i() {
  local expected=$1
  shift
  local actual
  actual=$(can_i "$@")
  [[ $actual == "$expected" ]] || {
    echo "FAIL: expected '$expected' for kubectl auth can-i $*, got '$actual'" >&2
    exit 1
  }
}

expect_can_i yes get pods -n default
expect_can_i yes patch deployments.apps -n default
expect_can_i yes create jobs.batch -n default
expect_can_i yes patch services -n default
expect_can_i no get secrets -n default
expect_can_i no delete deployments.apps -n default
expect_can_i no create pods/exec -n default
expect_can_i no patch deployments.apps -n kube-system
expect_can_i no create clusterrolebindings.rbac.authorization.k8s.io

# Bound the request: kubectl's default --request-timeout is 0 (no timeout), so
# an unresponsive control plane would hang the deploy job with no diagnostic.
kubectl get --raw=/readyz --request-timeout=30s
