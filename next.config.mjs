import nextra from 'nextra'

const withNextra = nextra({
  // Nextra options
})

export default withNextra({
  i18n: {
    locales: ['en-US', 'nl-NL'],
    defaultLocale: 'en-US'
  },
  images: {
    unoptimized: true,
  },
  // workspace#036-distroless-wave-1 (DOC-4/DOC-6, ruling C2).
  // Emits a self-contained `.next/standalone/` tree with a generated
  // `server.js` and a pruned `node_modules`, so the runtime image needs no
  // pnpm, no dev dependencies and no source tree — which is what makes a
  // distroless runtime possible at all (distroless has no shell, so the old
  // `CMD ["pnpm","run","start"]` could not survive).
  //
  // Next does NOT copy `public/` or `.next/static/` into the standalone tree,
  // and pagefind writes `public/_pagefind` *after* the build — so the
  // Dockerfile copies both explicitly. Verified empirically: gate D1 indexed
  // 76 pages / 2 languages / 3964 words with `_pagefind` outside
  // `.next/standalone/`; gate D2 then served it byte-identically to the
  // pre-change image. See specs/036-distroless-wave-1/evidence/documentation/.
  output: 'standalone',
  basePath: '/documentation',
  devIndicators: false,
  async redirects() {
    return [
      {
        source: '/:path*.:lang([a-z]{2}-[A-Z]{2})',
        destination: '/:path*',
        permanent: true,
      },
    ]
  },
})
