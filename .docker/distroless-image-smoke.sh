#!/usr/bin/env bash
# workspace#036-distroless-wave-1 — persisted regression for `documentation`.
#
# This repo's CI runs only `pnpm install` + `pnpm run build` — there is no
# lint job and no test job. This harness is therefore the ONLY behavioural
# gate the repository has, and it is written accordingly: it asserts both the
# image-hardening contract AND the four site behaviours that gates DOC-4/DOC-5
# established, so a future change cannot silently regress either.
#
# Asserted (DOC-10):
#   1. US1-AS1  — image declares UID 65532, and the process really runs as it
#   2.           — CMD is ["server.js"] on the distroless node ENTRYPOINT
#   3. US1-AS2  — no shell, no package manager, no pnpm/npm reachable
#   4. US1-AS3  — no source tree, no pnpm/pagefind in the runtime node_modules
#   5. US2-AS1  — no floating FROM in the Dockerfile; both stages digest-pinned
#   6. US7-AS1/2/3 — live HTTP: 200 under the /documentation basePath, locale
#                    redirect, NEXT_LOCALE honoured, pagefind index served
#                    (the persisted D1/D2 regression)
#   7. NODE_ENV=dev injection (four of five environments inject it via the
#      alkemio-config ConfigMap and envFrom overrides Dockerfile ENV) does not
#      degrade the standalone server
#   8. Emits IMAGE_DIGEST= / IMAGE_SIZE_BYTES= for mechanical evidence (US5-AS3)
#
# Usage: .docker/distroless-image-smoke.sh <image[:tag]>
set -euo pipefail

IMAGE="${1:?usage: distroless-image-smoke.sh <image[:tag]>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKERFILE="$REPO_ROOT/Dockerfile"
CONTAINER="doc-smoke-$$"
HOST_PORT="${SMOKE_PORT:-31010}"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

run_node() { docker run --rm --entrypoint /nodejs/bin/node "$IMAGE" "$@"; }

echo "== distroless-image-smoke: $IMAGE =="

# --- 1. US1-AS1: declared user --------------------------------------------
USER_ID="$(docker inspect "$IMAGE" --format '{{.Config.User}}')"
[ "$USER_ID" = "65532" ] || [ "$USER_ID" = "nonroot" ] ||
  fail "expected image user 65532/nonroot, got '$USER_ID' (an empty value means ROOT, and the hardened securityContext's runAsNonRoot would fail admission before start)"
pass "image declares user '$USER_ID'"

# The kubelet checks the declared user, but only the running process proves it.
ACTUAL_UID="$(run_node -e "console.log(process.getuid()+':'+process.getgid())")"
[ "$ACTUAL_UID" = "65532:65532" ] ||
  fail "expected process uid:gid 65532:65532, got '$ACTUAL_UID'"
pass "process really runs as uid:gid $ACTUAL_UID"

# --- 2. entrypoint + CMD ---------------------------------------------------
ENTRYPOINT_JSON="$(docker inspect "$IMAGE" --format '{{json .Config.Entrypoint}}')"
echo "$ENTRYPOINT_JSON" | grep -q '/nodejs/bin/node' ||
  fail "expected the distroless node entrypoint, got $ENTRYPOINT_JSON"
pass "entrypoint is the distroless node binary"

CMD_JSON="$(docker inspect "$IMAGE" --format '{{json .Config.Cmd}}')"
[ "$CMD_JSON" = '["server.js"]' ] ||
  fail "expected CMD [\"server.js\"] (Next standalone), got $CMD_JSON — note CMD [\"pnpm\",\"run\",\"start\"] can never work: distroless has no shell and no pnpm"
pass "CMD is [\"server.js\"]"

# --- no shell / no package manager -----------------------------------------
# Sweep every PATH-shaped directory instead of probing a fixed denylist of
# binary names: distroless ships /bin, /sbin, /usr/bin, /usr/sbin (and has no
# /usr/local/bin or /busybox) EMPTY, so ANY entry appearing in one of them —
# a shell, a package manager, busybox, anything — is a regression. This
# closes the two holes the review proved in the earlier checks: (a) an
# exit-status probe read working binaries as absent (apk with no args exits
# non-zero), and (b) a fixed path list missed /busybox/sh, where Google's
# :debug variants actually put the shell. lstat/readdir needs no exec
# permission and sees dangling symlinks.
FORBIDDEN="$(run_node -e "
const fs = require('fs');
const dirs = ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin','/busybox'];
const hits = [];
for (const d of dirs) {
  let entries = [];
  try { entries = fs.readdirSync(d); } catch { continue; } // absent dir is fine
  for (const e of entries) hits.push(d + '/' + e);
}
console.log(hits.join(','));
")"
[ -z "$FORBIDDEN" ] || fail "unexpected executables in runtime image PATH dirs: $FORBIDDEN"
pass "PATH directories are empty (no shell / package manager / any binary)"

# --- 4. US1-AS3: no sources, no build tooling in the runtime ---------------
for path in app content components proxy.js mdx-components.js styles.css pnpm-lock.yaml; do
  EXISTS="$(run_node -e "console.log(require('fs').existsSync('/app/$path'))")"
  [ "$EXISTS" = "false" ] || fail "expected '/app/$path' to be absent from the runtime image"
done
pass "no source tree in the runtime image (Next standalone traced output only)"

for mod in pnpm pagefind; do
  EXISTS="$(run_node -e "const fs=require('fs');console.log(fs.existsSync('/app/node_modules/$mod')||fs.existsSync('/app/node_modules/.bin/$mod'))")"
  [ "$EXISTS" = "false" ] || fail "expected '$mod' to be absent from the runtime node_modules"
done
pass "no pnpm / pagefind in the runtime node_modules"

# next must be loadable — it is what server.js runs on.
NEXT_VERSION="$(run_node -e "console.log(require('/app/node_modules/next/package.json').version)")"
[ -n "$NEXT_VERSION" ] || fail "next is not loadable from the runtime image"
pass "next $NEXT_VERSION loads from the pruned standalone node_modules"

# --- 5. US2-AS1: no floating FROM -----------------------------------------
[ -f "$DOCKERFILE" ] || fail "Dockerfile not found at $DOCKERFILE"
while read -r line; do
  echo "$line" | grep -q '@sha256:[0-9a-f]\{64\}' ||
    fail "floating (non-digest-pinned) base image: $line"
done < <(grep -E '^[[:space:]]*FROM[[:space:]]' "$DOCKERFILE")
FROM_COUNT="$(grep -cE '^[[:space:]]*FROM[[:space:]]' "$DOCKERFILE")"
pass "all $FROM_COUNT FROM stage(s) are digest-pinned"

# --- 6. US7-AS1/2/3: live behaviour (the persisted D1/D2 regression) -------
# NODE_ENV=dev is injected by the alkemio-config ConfigMap in dev/test/sandbox/
# acceptance, and `envFrom` overrides the Dockerfile ENV — so the harness runs
# the container the way the cluster actually will.
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" -e NODE_ENV=dev -p "$HOST_PORT:3010" "$IMAGE" >/dev/null
B="http://localhost:$HOST_PORT"

READY=""
for _ in $(seq 1 60); do
  if [ "$(curl -s -o /dev/null -w '%{http_code}' "$B/documentation" 2>/dev/null)" != "000" ]; then
    READY=1; break
  fi
  sleep 1
done
[ -n "$READY" ] || { docker logs "$CONTAINER" >&2 || true; fail "container did not start listening on 3010"; }
pass "container starts and listens on 3010 (with NODE_ENV=dev injected)"

# 6a. basePath — 200 under /documentation, NOT merely on /.
FINAL_CODE="$(curl -sL -o /dev/null -w '%{http_code}' "$B/documentation")"
[ "$FINAL_CODE" = "200" ] || fail "expected HTTP 200 under the /documentation basePath, got $FINAL_CODE"
pass "HTTP 200 under the /documentation basePath (US7-AS1)"

# 6b. locale negotiation via proxy.js -> /documentation/en-US
REDIR="$(curl -s -o /dev/null -w '%{redirect_url}' "$B/documentation")"
case "$REDIR" in
  */documentation/en-US) pass "/documentation redirects to /documentation/en-US (US7-AS3)" ;;
  *) fail "expected a redirect to /documentation/en-US, got '$REDIR'" ;;
esac

# 6c. NEXT_LOCALE cookie honoured
REDIR_NL="$(curl -s -o /dev/null -w '%{redirect_url}' -H 'Cookie: NEXT_LOCALE=nl-NL' "$B/documentation")"
case "$REDIR_NL" in
  */documentation/nl-NL) pass "NEXT_LOCALE=nl-NL is honoured (US7-AS3)" ;;
  *) fail "expected the NEXT_LOCALE cookie to yield /documentation/nl-NL, got '$REDIR_NL'" ;;
esac

# 6d. pagefind index is present AND populated. Next does not copy public/ into
# .next/standalone/ and pagefind writes after the build, so this asserts the
# explicit `COPY public` survived.
PF_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$B/documentation/_pagefind/pagefind.js")"
[ "$PF_CODE" = "200" ] || fail "pagefind.js not served (got $PF_CODE) — the runtime stage is missing public/_pagefind"
PF_ENTRY="$(curl -s "$B/documentation/_pagefind/pagefind-entry.json")"
echo "$PF_ENTRY" | grep -q '"page_count":[1-9]' ||
  fail "pagefind index is present but EMPTY (page_count 0) — search would silently return nothing: $PF_ENTRY"
pass "pagefind index served and non-empty (US7-AS2)"

# 6e. .next/static is served — also outside the traced standalone output.
# NB: `... | head -1` would SIGPIPE the upstream grep and, under `pipefail`,
# abort the script with 141. Buffer first, then take the first match.
CHUNK_LIST="$(curl -s "$B/documentation/en-US" | grep -oE '/documentation/_next/static/chunks/[A-Za-z0-9._-]+\.js' || true)"
CHUNK="$(printf '%s\n' "$CHUNK_LIST" | sed -n '1p')"
[ -n "$CHUNK" ] || fail "no static chunk referenced in the rendered page"
CHUNK_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$B$CHUNK")"
[ "$CHUNK_CODE" = "200" ] || fail "static chunk $CHUNK not served (got $CHUNK_CODE) — the runtime stage is missing .next/static"
pass "static assets served from .next/static"

# 6f. a deep content route renders (not just the index)
DEEP_CODE="$(curl -sL -o /dev/null -w '%{http_code}' "$B/documentation/faq")"
[ "$DEEP_CODE" = "200" ] || fail "deep content route /documentation/faq returned $DEEP_CODE"
pass "deep content route renders"

# --- 7. evidence lines (US5-AS3) ------------------------------------------
IMAGE_DIGEST="$(docker inspect "$IMAGE" --format '{{.Id}}')"
IMAGE_SIZE_BYTES="$(docker save "$IMAGE" | wc -c)"
echo "IMAGE_DIGEST=$IMAGE_DIGEST"
echo "IMAGE_SIZE_BYTES=$IMAGE_SIZE_BYTES"

echo "== distroless-image-smoke: ALL CHECKS PASSED =="
