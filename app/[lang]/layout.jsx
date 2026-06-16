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
  title: 'Alkemio - Safe Spaces for Collaboration',
  description: 'Join Alkemio! Achieve your goals. Safe smart spaces for collective action.',
  openGraph: {
    type: 'website',
    title: 'Alkemio - Safe Spaces for Collaboration',
    description: 'Join Alkemio! Achieve your goals. Safe smart spaces for collective action.',
    images: '/alkemio-og.png',
    url: 'https://alkem.io/documentation'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Alkemio - Safe Spaces for Collaboration',
    description: 'Join Alkemio! Achieve your goals. Safe smart spaces for collective action.',
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
      MIT {new Date().getFullYear()} Alkemio Foundation
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
