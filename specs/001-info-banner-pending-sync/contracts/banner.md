# Behavioural Contract: Global info banner

**Feature**: 001-info-banner-pending-sync | **Date**: 2026-06-16

This docs site has no HTTP API surface for this feature. The "contract" is the
observable UI/behavioural contract of the global banner and the public shape of
the banner-content module.

## Module contract — `app/_components/banner-content.js`

```js
// Exports:
export const BANNER_STORAGE_KEY: string          // descriptive + versioned key
export const bannerText: Record<string, string>  // locale -> message
export function getBannerText(lang: string): string  // localized text, falls back to en-US
```

- `BANNER_STORAGE_KEY` MUST be a non-empty string and MUST change when the message
  text materially changes.
- `bannerText` MUST contain entries for every supported locale (`en-US`, `nl-NL`).
- `getBannerText(lang)` MUST return `bannerText[lang]` when present, otherwise the
  `en-US` entry; it MUST never return empty/undefined for a supported locale.

## UI behavioural contract — rendered banner

| ID | Given | When | Then |
|----|-------|------|------|
| BC-1 | A fresh browser (no dismissal stored) on any docs page, `en-US` | Page renders | A banner appears at the top of the site with the `en-US` message |
| BC-2 | Banner visible | User navigates to another page | Banner still visible (global) |
| BC-3 | Banner visible | User clicks the close control | Banner is hidden |
| BC-4 | Banner dismissed | User reloads or navigates | Banner stays hidden |
| BC-5 | Page rendered in `nl-NL` | Page renders | Banner shows the Dutch message |
| BC-6 | A dismissal exists under an OLD storage key, copy/key updated | User visits | Banner shows the new message again |
| BC-7 | Docs embedded in platform iframe, banner present | Page renders / banner dismissed | Reported `PAGE_HEIGHT` reflects current total height; no content/banner clipped |
| BC-8 | Forced light theme | Page renders | Banner renders legibly; no dark-mode variant |
| BC-9 | Keyboard user | Tabs to the banner close control and presses Enter/Space | Banner is dismissed (close control is a focusable button) |

## Non-goals

- No backend endpoint, no analytics event, no admin toggle.
- No link/CTA inside the banner (plain informational text only).
- No dark-mode styling.
