// Centralized content for the global info banner shown at the top of the docs
// site. The banner informs users that the screenshots/visuals in the
// documentation are pending an update to match the new platform UI, so any
// discrepancies between the live platform and the docs are expected.
//
// To update the copy later: edit `bannerText` for BOTH locales and bump the
// version suffix on `BANNER_STORAGE_KEY` so users who dismissed the previous
// message see the new one again.

// Descriptive + versioned key used by Nextra's <Banner> to persist dismissal in
// localStorage. Changing this re-shows the banner to everyone (see FR-006).
export const BANNER_STORAGE_KEY = 'docs-visuals-pending-platform-redesign-2026-06'

// Locale-keyed banner message. Must contain an entry for every supported locale
// (en-US, nl-NL) to satisfy bilingual parity.
export const bannerText = {
  'en-US':
    "Heads up: the screenshots and visuals in this documentation are being updated to match Alkemio's new platform design. Some images may not yet reflect the latest UI.",
  'nl-NL':
    'Let op: de schermafbeeldingen en visuals in deze documentatie worden bijgewerkt naar het nieuwe platformontwerp van Alkemio. Sommige afbeeldingen komen mogelijk nog niet overeen met de nieuwste UI.'
}

const DEFAULT_LOCALE = 'en-US'

// Returns the banner message for the given locale, falling back to the default
// locale so the banner is never blank for a supported page.
export function getBannerText(lang) {
  return bannerText[lang] ?? bannerText[DEFAULT_LOCALE]
}
