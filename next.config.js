const withNextra = require('nextra')({
    theme: 'nextra-theme-docs',
    themeConfig: './theme.config.jsx',
});
   
module.exports = withNextra({
    // output: 'export', not working with i18n
    i18n: {
        locales: ['en-US', 'nl-NL'],
        defaultLocale: 'en-US'
    },
    images: {
    unoptimized: true,
    },
    basePath: '/documentation',   
});