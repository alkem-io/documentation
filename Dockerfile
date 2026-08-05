###############################################################################
# workspace#036-distroless-wave-1 — `documentation`
#
# Two-stage build producing a distroless, non-root runtime image:
#   1. build   — glibc (Debian trixie), full deps, `next build` + pagefind
#   2. runtime — gcr.io/distroless/nodejs22-debian13:nonroot: no shell, no
#                package manager, no sources, no dev dependencies, no pnpm.
#
# Why distroless-node and NOT nginx (agreed point A2):
#   `next.config.mjs` has no `output: 'export'` and `proxy.js` performs
#   per-request cookie / Accept-Language negotiation via `next/server`. There
#   is no static export to serve, so a static file server cannot serve this
#   site. The workspace#033 client-web nginx pattern is categorically
#   inapplicable here.
#
# Why `output: 'standalone'` (ruling C2, gates DOC-4/DOC-5 — both PASSED):
#   Standalone emits `.next/standalone/server.js` plus a pruned `node_modules`
#   (4 top-level packages), which lets the runtime stage drop pnpm, the dev
#   dependencies and the entire source tree. The old runtime stage ran
#   `CMD ["pnpm","run","start"]`; distroless has no shell and no pnpm, so that
#   form could not have survived in any case.
#
#   Next does NOT copy `public/` or `.next/static/` into the standalone tree
#   (documented upstream behaviour requiring a manual copy), and pagefind
#   writes `public/_pagefind` *after* the build — doubly outside the traced
#   output. Hence the two explicit COPY lines below. This was verified, not
#   assumed: gate D1 showed pagefind indexing 76 pages / 2 languages /
#   3964 words, with `_pagefind` confirmed OUTSIDE `.next/standalone/`.
#
# Base images pinned by digest (resolved with
# `docker buildx imagetools inspect <image>:<tag>` on 2026-08-05). Both are
# top-level OCI index digests. Re-resolve tag *and* digest together on a bump.
#
#   node:22.21.1-trixie-slim   (matches the Volta pin 22.21.1; glibc/Debian 13)
#     digest: sha256:c3bf4cf764467f1bf9789fde549971a2cf8e720196df6cf3f95bafa590e5f4af
#   gcr.io/distroless/nodejs22-debian13:nonroot   (reports Node v22.23.2, ABI 127)
#     digest: sha256:939d6f1671529d230f50b563578e9b5d206af58f038b10ebd7e1233023d4e167
#
# Debian 13 (trixie), not Debian 12: Google's distroless project has frozen the
# Debian 12 variants — only Debian 13 receives fresh builds. Same rationale as
# workspace#026. The builder moves off Alpine/musl onto Debian/glibc so that
# builder and runtime share one libc family.
#
# NOTE ON `readOnlyRootFilesystem` (agreed point A12): it is deliberately NOT
# applied to this workload. A Next standalone server run `--read-only` returns
# HTTP 200 while logging EROFS prerender-cache failures — silent degradation
# that sails past health checks. See the matching comment in
# manifests/25-documentation-deployment-dev.yaml.
###############################################################################

###############################################################################
# Stage 1: build — full deps (incl. the pagefind dev dependency), `next build`,
# then the package.json `postbuild` hook generates the pagefind index into
# public/_pagefind.
#
# `.dockerignore` excludes node_modules, .next, public/_pagefind and .git, so
# `COPY . .` cannot smuggle in a host-built artifact and the pagefind index is
# always regenerated rather than inherited stale.
###############################################################################
FROM node:22.21.1-trixie-slim@sha256:c3bf4cf764467f1bf9789fde549971a2cf8e720196df6cf3f95bafa590e5f4af AS build

RUN npm i -g pnpm@10.17.1

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# `next build` honours `output: 'standalone'`; `postbuild` then runs
# `pagefind --site .next/server/app --output-path public/_pagefind`.
RUN pnpm run build

###############################################################################
# Stage 2: runtime — distroless, non-root (UID 65532).
#
# The base sets ENTRYPOINT ["/nodejs/bin/node"], so CMD is the script path.
#
# Unlike workspace#026's server image, `ENV PATH="/nodejs/bin:${PATH}"` is
# deliberately NOT set here: no consumer of this image overrides `command:` or
# `args:` with a bare `node ...` invocation. The single live apply path
# (manifests/25-documentation-deployment-dev.yaml, used by all five deploy
# workflows) sets no `command:` at all, so the image ENTRYPOINT always applies
# and the PATH workaround would be dead configuration. Re-evaluate if a
# consumer ever adds a bare-`node` command override.
###############################################################################
FROM gcr.io/distroless/nodejs22-debian13:nonroot@sha256:939d6f1671529d230f50b563578e9b5d206af58f038b10ebd7e1233023d4e167 AS runtime

WORKDIR /app

# PORT/HOSTNAME are how the standalone server picks its listen address — it
# does not read `next start -p`. HOSTNAME=0.0.0.0 is required for the kubelet
# to reach the container; the standalone server otherwise binds localhost only.
ENV NODE_ENV=production \
    PORT=3010 \
    HOSTNAME=0.0.0.0

# The traced standalone output: generated server.js + pruned node_modules.
COPY --from=build --chown=65532:65532 /app/.next/standalone ./
# NOT part of the traced output — must be copied explicitly.
COPY --from=build --chown=65532:65532 /app/.next/static ./.next/static
# Static assets, and critically the pagefind index written by `postbuild`.
COPY --from=build --chown=65532:65532 /app/public ./public

EXPOSE 3010

# Explicit non-root user (US7-AS4, ruling C1's mandatory mitigation). The
# kubelet evaluates `runAsNonRoot: true` against the IMAGE's declared user
# before the container starts; the previous Dockerfile had NO USER directive,
# so the image declared root and the hardened securityContext added in
# manifests/25-documentation-deployment-dev.yaml would have failed admission.
USER 65532

CMD ["server.js"]
