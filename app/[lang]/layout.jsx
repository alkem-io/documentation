import { Footer, Layout, Navbar, LocaleSwitch } from 'nextra-theme-docs'
import { Head, Banner } from 'nextra/components'
import { getPageMap } from 'nextra/page-map'
import 'nextra-theme-docs/style.css'
import '../../styles.css'
import ClientProviders from '../_components/ClientProviders'
import LocaleSwitchWrapper from '../_components/LocaleSwitchWrapper'
import { BANNER_STORAGE_KEY, getBannerText } from '../_components/banner-content'

export const metadata = {
  metadataBase: new URL('https://alkem.io'),
  title: 'Alkemio - Collaboration in the spaces between organisations',
  description: 'Alkemio is a European digital platform for collaboration in the spaces between organisations.',
  openGraph: {
    type: 'website',
    title: 'Alkemio - Collaboration in the spaces between organisations',
    description: 'Alkemio is a European digital platform for collaboration in the spaces between organisations.',
    images: '/alkemio-og.png',
    url: 'https://alkem.io/documentation'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Alkemio - Collaboration in the spaces between organisations',
    description: 'Alkemio is a European digital platform for collaboration in the spaces between organisations.',
    images: '/alkemio-og.png'
  }
}

export default async function RootLayout({ children, params }) {
  const { lang } = await params
  const pageMap = await getPageMap(`/${lang}`)

  const navbar = (
    <Navbar logo={<span></span>}>
      <LocaleSwitch />
    </Navbar>
  )

  const footer = (
    <Footer>
      EUPL-1.2 {new Date().getFullYear()} Alkemio
      {' · '}
      <a href="https://www.linkedin.com/company/alkemio" target="_blank" rel="noopener noreferrer" aria-label="Alkemio on LinkedIn">LinkedIn</a>
      {' · '}
      <a href="https://github.com/alkem-io" target="_blank" rel="noopener noreferrer" aria-label="Alkemio on GitHub">GitHub</a>
    </Footer>
  )

  // Global, dismissible info banner: warns that the docs visuals are pending an
  // update to match the new platform UI. Locale-aware; the versioned storageKey
  // re-shows the banner whenever the copy/key changes.
  const banner = (
    <Banner storageKey={BANNER_STORAGE_KEY}>
      {getBannerText(lang)}
    </Banner>
  )

  return (
    <html lang={lang} dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <ClientProviders />
        <LocaleSwitchWrapper />
        <Layout
          banner={banner}
          navbar={navbar}
          footer={footer}
          pageMap={pageMap}
          i18n={[
            { locale: 'en-US', name: 'English' },
            { locale: 'nl-NL', name: 'Nederlands' }
          ]}
          darkMode={false}
          nextThemes={{
            defaultTheme: 'light',
            forcedTheme: 'light'
          }}
        >
          {children}
        </Layout>
      </body>
    </html>
  )
}
