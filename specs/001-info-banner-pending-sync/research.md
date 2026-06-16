# Phase 0 Research: Info banner for pending docs/platform design sync

**Feature**: 001-info-banner-pending-sync | **Date**: 2026-06-16

## Decisions

### D1 — Banner mechanism: Nextra native `Banner` via `Layout` `banner` prop

- **Decision**: Use the `Banner` component exported from `nextra/components`,
  passed to the `banner` prop of the `nextra-theme-docs` `Layout`.
- **Rationale**: It is the framework-native, supported way to render a top-of-site
  banner. Confirmed present in the installed packages:
  - `node_modules/nextra/dist/client/components/index.js` exports `Banner`.
  - `nextra-theme-docs` schema (`dist/schemas.js`) documents the `banner` prop as a
    "Rendered `<Banner>` component" and the layout types declare `banner?: React.ReactNode`.
  - `Banner` is dismissible by default (`dismissible = true`) and persists dismissal
    in `localStorage` under a `storageKey` (default `nextra-banner`).
- **Alternatives considered**:
  - *Custom React component + custom CSS in `styles.css`*: rejected — more code,
    duplicates dismissal/persistence logic the framework already provides, violates
    Constitution Principle V (minimal footprint).
  - *MDX `<Callout>` inside each page*: rejected — not global, would require editing
    every page in both locales, no top-of-site placement, no dismissal persistence.

### D2 — Placement: locale layout (`app/[lang]/layout.jsx`)

- **Decision**: Wire the banner in `app/[lang]/layout.jsx`, which already awaits
  `params` and has `lang` available.
- **Rationale**: This layout wraps all routes for a locale and already constructs
  `navbar`/`footer` for `<Layout>`. Adding the `banner` prop here makes the banner
  global and lets us pick the localized string from the resolved `lang`.
- **Alternatives considered**: Root `app/layout.jsx` — rejected, it is minimal and
  does not render the Nextra `Layout` nor have the locale.

### D3 — Localization of the banner string

- **Decision**: Store banner strings in a small co-located module
  `app/_components/banner-content.js`, keyed by locale (`en-US`, `nl-NL`), plus a
  single exported versioned `storageKey`.
- **Rationale**: The banner text is a layout-level UI string, not page (MDX)
  content. Crowdin governs MDX content translation; for a layout chrome string the
  established React i18n pattern is a code map. Centralizing satisfies bilingual
  parity (Constitution I) and couples text↔key for FR-006.
- **Alternatives considered**: Inline ternary in the layout — rejected, scatters
  copy and the key; harder to update and to keep both locales in sync.

### D4 — Storage key strategy (re-show on copy change)

- **Decision**: Use a descriptive, versioned key, e.g.
  `docs-visuals-pending-platform-redesign-2026-06`. Bump the suffix when the copy
  materially changes.
- **Rationale**: Satisfies FR-006 — users who dismissed an old message see a new
  one. Matches Nextra's documented best practice ("always use a descriptive key
  for the current text").

### D5 — Iframe height handling

- **Decision**: No change to `ClientProviders`.
- **Rationale**: `ClientProviders` observes `document.body` with a `ResizeObserver`
  and reports `document.documentElement.scrollHeight || document.body.scrollHeight`.
  The banner is part of the document flow at the top, so total height already
  includes it; dismissing the banner triggers a resize → a fresh `PAGE_HEIGHT`.
  No additional integration code is needed (FR-009). Verify in quickstart.

### D6 — Theme & accessibility

- **Decision**: Rely on native `Banner` styling under forced light theme; do not
  add dark-mode styles. Keep default dismiss `<button>` (keyboard-accessible).
- **Rationale**: Constitution IV (light-only) and FR-011 (a11y). The native close
  control is a real button with an icon; banner text contrast on the native dark
  banner background is sufficient. If contrast/visual needs tuning for the light
  brand, a minimal `className`/CSS override may be applied without adding dark mode.

## Open Questions

None. All clarifications resolved in spec.md (2 clarify iterations, 0 remaining).
