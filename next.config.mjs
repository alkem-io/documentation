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
