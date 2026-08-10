#!/usr/bin/env bash
set -euo pipefail
#
# Generate a kubeconfig for the Scaleway v3 PRODUCTION cluster on the runner.
#
# Mirrors .scripts/configure-acceptance-v3-kubeconfig.sh. Keep the two in step:
# they differ only in their pinned target UUIDs and profile filename.
#
# WHY auth-method=cli AND NOT legacy: the v3 clusters issue credentials through
# an `exec` plugin that shells out to the scw CLI. An earlier revision of this
# script asked for `auth-method=legacy` to get a self-contained static-token
# kubeconfig instead. That endpoint rejects the Project-scoped
# KubernetesReadOnly policy the deployer application carries:
#
#   scw k8s kubeconfig get … auth-method=legacy
#     -> insufficient permissions
#
# so the deploy failed before reaching the cluster. This script installs the
# CLI and a job-local mode-0600 profile instead, which makes the generated
# kubeconfig portable for the lifetime of the runner job without asking
# Scaleway for a privileged legacy kubeconfig.
#
# TARGET FENCE: the previous stored-secret approach (KUBECONFIG_SECRET_SCALEWAY_PROD)
# had no way to assert which cluster it pointed at. If that secret were ever
# rotated to the wrong cluster this repo would deploy there silently. Every
# pinned constant below is asserted before anything is applied, so a wrong
# cluster, Project, region, or application fails closed.
#
# Secrets are consumed from the environment and never echoed. Do not add
# `set -x` here, and do not print $HOME/.kube/config.

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${HOME:?HOME is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${SCW_PRODUCTION_V3_ACCESS_KEY:?SCW_PRODUCTION_V3_ACCESS_KEY is required}"
: "${SCW_PRODUCTION_V3_SECRET_KEY:?SCW_PRODUCTION_V3_SECRET_KEY is required}"
: "${SCW_PRODUCTION_V3_APPLICATION_ID:?SCW_PRODUCTION_V3_APPLICATION_ID is required}"
: "${SCW_PRODUCTION_V3_CLUSTER_ID:?SCW_PRODUCTION_V3_CLUSTER_ID is required}"
: "${SCW_PRODUCTION_V3_PROJECT_ID:?SCW_PRODUCTION_V3_PROJECT_ID is required}"
: "${SCW_PRODUCTION_V3_ORGANIZATION_ID:?SCW_PRODUCTION_V3_ORGANIZATION_ID is required}"
: "${SCW_PRODUCTION_V3_REGION:?SCW_PRODUCTION_V3_REGION is required}"

readonly target_cluster=62166d69-76c6-43a1-85af-d0040c1449d0
readonly target_project=069a6063-fb1d-427d-ab59-a69dc3971ccd
readonly target_region=nl-ams
readonly target_endpoint=https://62166d69-76c6-43a1-85af-d0040c1449d0.api.k8s.nl-ams.scw.cloud:6443
readonly target_application=e8a9d9c6-4681-4a54-8439-be646c48a9ad
readonly target_deployer_group=scaleway:group:2f7adaf1-305f-42f9-b9b4-8c8fe21eb03f
readonly target_admin_group=scaleway:group:49455e82-43ef-4604-8a1d-73015b72176c
readonly kubectl_request_timeout=30s
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
[[ $SCW_PRODUCTION_V3_APPLICATION_ID == "$target_application" ]] || {
  echo "FAIL: application id $SCW_PRODUCTION_V3_APPLICATION_ID is not $target_application" >&2
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
readonly scw_config="$RUNNER_TEMP/scw-documentation-production-v3.yaml"
printf 'access_key: %s\nsecret_key: %s\ndefault_organization_id: %s\ndefault_project_id: %s\ndefault_region: %s\ndefault_zone: %s\n' \
  "$SCW_PRODUCTION_V3_ACCESS_KEY" \
  "$SCW_PRODUCTION_V3_SECRET_KEY" \
  "$SCW_PRODUCTION_V3_ORGANIZATION_ID" \
  "$SCW_PRODUCTION_V3_PROJECT_ID" \
  "$SCW_PRODUCTION_V3_REGION" \
  nl-ams-1 >"$scw_config"
chmod 600 "$scw_config"
unset SCW_PRODUCTION_V3_ACCESS_KEY SCW_PRODUCTION_V3_SECRET_KEY

scw --config "$scw_config" k8s kubeconfig get "$SCW_PRODUCTION_V3_CLUSTER_ID" \
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

# Fence the credential as well as the target. The API key must belong to the
# documentation application, carry the deployer group, and carry no broad or
# admin path. ROLE is an IAM/RBAC property; an access-key name cannot downscope
# a more privileged application.
actual_username=$(kubectl auth whoami --request-timeout="$kubectl_request_timeout" -o jsonpath='{.status.userInfo.username}')
[[ $actual_username == "scaleway:bearer:$target_application" ]] || {
  echo "FAIL: credential bearer $actual_username is not the documentation deployer application" >&2
  exit 1
}
read -r -a actual_groups <<<"$(kubectl auth whoami --request-timeout="$kubectl_request_timeout" -o jsonpath='{.status.userInfo.groups[*]}')"
has_group() {
  local expected=$1
  local group
  for group in "${actual_groups[@]}"; do
    [[ $group == "$expected" ]] && return 0
  done
  return 1
}

has_group "$target_deployer_group" || {
  echo "FAIL: credential is not in the production-v3 deployer group" >&2
  exit 1
}
if has_group scaleway:cluster-write || has_group system:masters || has_group "$target_admin_group"; then
  echo "FAIL: credential has broad or administrator access" >&2
  exit 1
fi

can_i() {
  local result
  result=$(kubectl auth can-i --request-timeout="$kubectl_request_timeout" "$@" 2>/dev/null || true)
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
expect_can_i no list secrets -n default
expect_can_i no watch secrets -n default
expect_can_i no create secrets -n default
expect_can_i no patch secrets -n default
expect_can_i no update secrets -n default
expect_can_i no delete secrets -n default
expect_can_i no deletecollection secrets -n default
expect_can_i no delete deployments.apps -n default
expect_can_i no create pods/exec -n default
expect_can_i no patch deployments.apps -n kube-system
expect_can_i no create clusterrolebindings.rbac.authorization.k8s.io

# Bound the request: kubectl's default --request-timeout is 0 (no timeout), so
# an unresponsive control plane would hang the deploy job with no diagnostic.
kubectl get --raw=/readyz --request-timeout="$kubectl_request_timeout"
