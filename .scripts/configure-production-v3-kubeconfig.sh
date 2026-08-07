#!/usr/bin/env bash
set -euo pipefail
#
# Generate a kubeconfig for the Scaleway v3 PRODUCTION cluster on the runner.
#
# Ported from infrastructure-operations/.scripts/configure-production-v3-kubeconfig.sh.
#
# WHY THIS EXISTS: unlike the acceptance path, production is NOT broken — the
# stored KUBECONFIG_SECRET_SCALEWAY_PROD secret does point at v3 and deploys
# have been succeeding (verified: 2026-07-21 run 29831746087 configured the
# Deployment on the same namespace that infra-ops run 29563771867 had annotated,
# and that run was fenced to cluster 62166d69-…).
#
# What the stored-secret approach lacks is a TARGET FENCE. If that secret is
# ever rotated to the wrong cluster, this repo would deploy there silently,
# whereas infrastructure-operations fails closed. This change buys that same
# fail-closed property and removes a long-lived credential from the org secret
# store in favour of short-lived, generated ones.
#
# Secrets are consumed from the environment and never echoed. Do not add
# `set -x` here, and do not print $HOME/.kube/config.

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${HOME:?HOME is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${SCW_PRODUCTION_V3_ACCESS_KEY:?SCW_PRODUCTION_V3_ACCESS_KEY is required}"
: "${SCW_PRODUCTION_V3_SECRET_KEY:?SCW_PRODUCTION_V3_SECRET_KEY is required}"
: "${SCW_PRODUCTION_V3_CLUSTER_ID:?SCW_PRODUCTION_V3_CLUSTER_ID is required}"
: "${SCW_PRODUCTION_V3_PROJECT_ID:?SCW_PRODUCTION_V3_PROJECT_ID is required}"
: "${SCW_PRODUCTION_V3_ORGANIZATION_ID:?SCW_PRODUCTION_V3_ORGANIZATION_ID is required}"
: "${SCW_PRODUCTION_V3_REGION:?SCW_PRODUCTION_V3_REGION is required}"

readonly target_cluster=62166d69-76c6-43a1-85af-d0040c1449d0
readonly target_project=069a6063-fb1d-427d-ab59-a69dc3971ccd
readonly target_region=nl-ams
readonly target_endpoint=https://62166d69-76c6-43a1-85af-d0040c1449d0.api.k8s.nl-ams.scw.cloud:6443
# scaleway-cli v2.59.0 linux/amd64 — same pin as infrastructure-operations.
readonly scw_cli_sha256=e9606386ddbf7885f06d5d585d04356559039c55252bf2abd99e55b69f3d94f6

# Fail before touching any cluster if the environment points somewhere else.
[[ $SCW_PRODUCTION_V3_CLUSTER_ID == "$target_cluster" ]] || {
  echo "FAIL: cluster id $SCW_PRODUCTION_V3_CLUSTER_ID is not $target_cluster" >&2
  exit 1
}
[[ $SCW_PRODUCTION_V3_PROJECT_ID == "$target_project" ]] || {
  echo "FAIL: project id $SCW_PRODUCTION_V3_PROJECT_ID is not $target_project" >&2
  exit 1
}
[[ $SCW_PRODUCTION_V3_REGION == "$target_region" ]] || {
  echo "FAIL: region $SCW_PRODUCTION_V3_REGION is not $target_region" >&2
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

export SCW_ACCESS_KEY="$SCW_PRODUCTION_V3_ACCESS_KEY"
export SCW_SECRET_KEY="$SCW_PRODUCTION_V3_SECRET_KEY"
export SCW_DEFAULT_PROJECT_ID="$SCW_PRODUCTION_V3_PROJECT_ID"
export SCW_DEFAULT_ORGANIZATION_ID="$SCW_PRODUCTION_V3_ORGANIZATION_ID"
export SCW_DEFAULT_REGION="$SCW_PRODUCTION_V3_REGION"

# auth-method=legacy emits a static-token kubeconfig (no exec plugin), which is
# what makes the result usable on a runner that has no scw profile.
scw k8s kubeconfig get "$SCW_PRODUCTION_V3_CLUSTER_ID" \
  region="$SCW_PRODUCTION_V3_REGION" auth-method=legacy \
  > "$HOME/.kube/config"

generated_context="$(kubectl config current-context)"
target_context="production-v3-$SCW_PRODUCTION_V3_CLUSTER_ID"
if [[ $generated_context != "$target_context" ]]; then
  kubectl config rename-context "$generated_context" "$target_context" >/dev/null
fi

# Target fence: assert what was actually generated, not what we asked for.
current_context="$(kubectl config current-context)"
current_endpoint="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')"
[[ $current_context == "$target_context" ]] || {
  echo "FAIL: context $current_context is not $target_context" >&2
  exit 1
}
[[ $current_endpoint == "$target_endpoint" ]] || {
  echo "FAIL: endpoint $current_endpoint is not $target_endpoint" >&2
  exit 1
}
[[ $SCW_PRODUCTION_V3_PROJECT_ID == "$target_project" ]] || {
  echo "FAIL: project id $SCW_PRODUCTION_V3_PROJECT_ID drifted from $target_project" >&2
  exit 1
}
kubectl get --raw=/readyz
