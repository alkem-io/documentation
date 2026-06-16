# Phase 1 Data Model: Info banner for pending docs/platform design sync

**Feature**: 001-info-banner-pending-sync | **Date**: 2026-06-16

This feature has no persistent server-side data. The only "data" are static,
localized UI strings and a client-side dismissal flag managed by the framework.

## Entities

### BannerNotice (static configuration)

The informational message rendered globally at the top of the docs site.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `text` (per locale) | string | The user-facing banner message | Required for each supported locale (`en-US`, `nl-NL`); plain text |
| `storageKey` | string | Identifier used to persist dismissal and to invalidate on copy change | Required; descriptive + versioned (e.g. `docs-visuals-pending-platform-redesign-2026-06`); must change when `text` materially changes |
| `dismissible` | boolean | Whether a close control is shown | Fixed `true` |

**Source of truth**: `app/_components/banner-content.js` (locale-keyed map +
exported `storageKey`).

**Localized values** (canonical):

- `en-US`: "Heads up: the screenshots and visuals in this documentation are being updated to match Alkemio's new platform design. Some images may not yet reflect the latest UI."
- `nl-NL`: "Let op: de schermafbeeldingen en visuals in deze documentatie worden bijgewerkt naar het nieuwe platformontwerp van Alkemio. Sommige afbeeldingen komen mogelijk nog niet overeen met de nieuwste UI."

### BannerDismissalState (client-side, framework-managed)

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| key | string | Equals `BannerNotice.storageKey` | Set in `localStorage` by Nextra `Banner` on dismiss |
| value | truthy | Presence indicates dismissed | Managed entirely by the framework; not read/written by app code |

**Lifecycle**: Absent → banner shown. User clicks close → key written → banner
hidden on this and future loads. `storageKey` changes (new copy) → old key no
longer matches → banner shown again.

## Relationships

`app/[lang]/layout.jsx` selects `BannerNotice.text[lang]` (falling back to the
default locale) and the shared `storageKey`, and passes them to the native
`Banner`, which owns the `BannerDismissalState`.

## Validation Rules

- Every supported locale MUST have a non-empty `text` entry (bilingual parity).
- `storageKey` MUST be non-empty and MUST be revised when `text` changes (FR-006).
- A locale with no explicit entry MUST fall back to the default locale (`en-US`)
  so the banner is never blank.
