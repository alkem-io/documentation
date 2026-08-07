#!/usr/bin/env bash
# shellcheck shell=bash
#
# Target fence for the Scaleway v3 ACCEPTANCE cluster.
#
# Ported from infrastructure-operations/.scripts/stage-p-target-fence.sh so the
# two repos assert the same invariant with the same values. Keep them in step:
# if the acceptance cluster is ever re-provisioned, BOTH copies must change.
#
# The point of this file is that a credential mix-up must fail loudly instead of
# deploying somewhere unintended. It refuses to proceed unless the kubeconfig
# that was just generated resolves to exactly the acceptance-v3 cluster, and it
# explicitly rejects a production or decommissioned-acceptance context even if
# one somehow satisfied the cluster-id check.

acceptance_v3_target_cluster=63babd2d-2acc-4bcd-992a-46278088916c
acceptance_v3_target_project=b038f044-d128-4011-8ffb-3eb8589ecc04
acceptance_v3_target_endpoint=https://63babd2d-2acc-4bcd-992a-46278088916c.api.k8s.nl-ams.scw.cloud:6443

acceptance_v3_validate_target_fence() {
  local context=${1-} endpoint=${2-} project=${3-}
  [[ -n $context ]] || { echo "FAIL: ACC-V3 TARGET FENCE: absent context" >&2; return 1; }
  [[ $context != *"old-acceptance"* ]] || { echo "FAIL: ACC-V3 TARGET FENCE: old-acceptance context" >&2; return 1; }
  [[ $context != *"production"* && $context != *"prod"* ]] || { echo "FAIL: ACC-V3 TARGET FENCE: production context" >&2; return 1; }
  [[ $context == *"$acceptance_v3_target_cluster"* ]] || { echo "FAIL: ACC-V3 TARGET FENCE: unrecognised context" >&2; return 1; }
  [[ $endpoint == "$acceptance_v3_target_endpoint" ]] || { echo "FAIL: ACC-V3 TARGET FENCE: unrecognised endpoint" >&2; return 1; }
  [[ $project == "$acceptance_v3_target_project" ]] || { echo "FAIL: ACC-V3 TARGET FENCE: project mismatch" >&2; return 1; }
}

acceptance_v3_assert_target_fence() {
  local context endpoint
  context=$(kubectl config current-context 2>/dev/null) || {
    echo "FAIL: ACC-V3 TARGET FENCE: absent context" >&2; return 1;
  }
  endpoint=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null) || {
    echo "FAIL: ACC-V3 TARGET FENCE: absent context" >&2; return 1;
  }
  : "${SCW_PROJECT_ID:?FAIL: ACC-V3 TARGET FENCE: project is absent}"
  acceptance_v3_validate_target_fence "$context" "$endpoint" "$SCW_PROJECT_ID"
}
