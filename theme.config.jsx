export default {
    logo: <span></span>,
    primaryHue: { dark: 215, light: 215 },
    primarySaturation: { dark: 50, light: 50 },
    darkMode: false,
    nextThemes: {
        defaultTheme: 'light',
        forcedTheme: 'light',
    },
    i18n: [
        { locale: 'en-US', text: 'English' },
        { locale: 'nl-NL', text: 'Nederlands' },
    ],
    head: (
        <>
          <title>Alkemio - Safe Spaces for Collaboration</title>
          <meta name="description" content="Join Alkemio! Achieve your goals. Safe smart spaces for collective action." />
        
          <meta property="og:type" content="website" />
          <meta property="og:title" content="Alkemio - Safe Spaces for Collaboration" />
          <meta property="og:description" content="Join Alkemio! Achieve your goals. Safe smart spaces for collective action." />
          <meta property="og:image" content="/alkemio-og.png" />
          <meta property="og:url" content="https://alkem.io/documentation" />
    
          <meta name="twitter:card" content="summary_large_image" />
          <meta name="twitter:title" content="Alkemio - Safe Spaces for Collaboration" />
          <meta name="twitter:description" content="Join Alkemio! Achieve your goals. Safe smart spaces for collective action." />
          <meta name="twitter:image" content="/alkemio-og.png" />
        </>
      )
    };