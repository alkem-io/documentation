# Feature Specification: Info banner for pending synchronisation of docs with latest platform design

**Feature Branch**: `story/125-info-banner-pending-sync-docs-platform-design`
**Created**: 2026-06-16
**Status**: Clarified
**Input**: User description: "Info banner for the pending synchronisation of the docs with the latest platform design. As a user I want to be prompted that the documentation is not up-to-date with the latest platform design, so the discrepancies between the platform and the docs site are expected. Acceptance criteria: An info banner on top of the docs site informing the users that the visuals in the docs site are pending update to match the new platform UI." (GitHub story alkem-io/documentation#125)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reader is informed the docs visuals are pending update (Priority: P1)

A user opens any page of the Alkemio documentation site (standalone or embedded
in the platform iframe). Before or while reading, they see a clearly-styled
informational banner at the top of the site stating that the visuals/screenshots
in the documentation are pending an update to match the new platform UI, so any
discrepancies between what they see in the platform and what is shown in the docs
are expected and temporary.

**Why this priority**: This is the entire purpose of the story. Without the
banner, users encountering visual mismatches between the live platform and the
docs may conclude the docs are wrong or that they are using the product
incorrectly, eroding trust. The banner sets expectations up front. It is the MVP.

**Independent Test**: Load any documentation page (e.g. the home page) in the
default `en-US` locale and confirm an info banner appears at the top of the site
with the expected message. This single slice delivers the full user value.

**Acceptance Scenarios**:

1. **Given** a user navigates to any documentation page in `en-US`, **When** the page renders, **Then** an info banner is displayed at the top of the site stating the docs visuals are pending update to match the new platform UI.
2. **Given** a user navigates between multiple documentation pages, **When** each page renders, **Then** the banner remains visible at the top on every page (it is global, not page-specific) until dismissed.
3. **Given** the documentation is embedded in the Alkemio platform iframe, **When** a page renders, **Then** the banner is displayed and the iframe height messaging (`PAGE_HEIGHT`) accounts for the banner so no content is clipped.

### User Story 2 - Reader can dismiss the banner (Priority: P2)

A returning or focused user who has already acknowledged the notice can dismiss
the banner so it no longer occupies vertical space on subsequent reading, and the
dismissal is remembered across navigation and visits.

**Why this priority**: Reduces friction for repeat readers and keeps the reading
surface clean once the message has been seen. Valuable but secondary to simply
showing the message; the native banner mechanism provides this for free.

**Independent Test**: Display the banner, click its dismiss control, confirm it
disappears, then navigate to another page / reload and confirm it stays hidden.

**Acceptance Scenarios**:

1. **Given** the banner is visible, **When** the user clicks the dismiss (close) control, **Then** the banner is hidden.
2. **Given** the user has dismissed the banner, **When** they navigate to another page or reload the site, **Then** the banner remains hidden.
3. **Given** the banner message text is later changed (new wording / new key), **When** a user who previously dismissed the old banner visits, **Then** the new banner is shown again (dismissal does not suppress a materially new notice).

### User Story 3 - Dutch-speaking reader sees the notice in their language (Priority: P3)

A user browsing the documentation in the Dutch (`nl-NL`) locale sees the same
informational banner with the message presented in Dutch.

**Why this priority**: The platform serves Dutch and English audiences and the
constitution mandates bilingual content parity. Important for completeness but
the core value (informing the user) is already delivered for the default locale.

**Independent Test**: Switch the locale to `nl-NL` (or load an `nl-NL` URL) and
confirm the banner appears with the Dutch translation of the message.

**Acceptance Scenarios**:

1. **Given** a user views the documentation in `nl-NL`, **When** any page renders, **Then** the banner is displayed with the message in Dutch.
2. **Given** a user switches locale from `en-US` to `nl-NL`, **When** the locale changes, **Then** the banner message reflects the active locale.

### Edge Cases

- **No clipping in iframe**: When embedded, the banner adds height; the page-height message sent to the parent must include the banner so the iframe is not too short and the banner is not cut off.
- **Dismissal persistence boundary**: Dismissal is per-browser (client storage). A user on a different browser/device sees the banner again — this is expected and acceptable.
- **Message update invalidation**: If the wording changes, previously-dismissed users must see the updated banner; this requires a versioned/descriptive storage key tied to the current message.
- **Light-theme only**: The banner must render correctly under the forced light theme; no dark-mode variant is needed.
- **Standalone vs iframe**: The banner must render identically whether the docs are viewed standalone (`not-in-iframe`) or embedded.
- **Long message / small viewport**: On narrow viewports the banner text must wrap and remain readable without breaking layout.
- **Link (optional)**: If the message includes a link, it must be keyboard-accessible and open appropriately; if no link is required, the banner is plain text.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The documentation site MUST display an informational banner at the top of the site on every documentation page.
- **FR-002**: The banner MUST inform users that the visuals/screenshots in the documentation are pending update to match the new platform UI, and that discrepancies between the platform and the docs are expected and temporary.
- **FR-003**: The banner MUST be global (rendered once at the layout level) and appear consistently across all pages and routes.
- **FR-004**: The banner MUST be dismissible by the user via a visible close control.
- **FR-005**: Once dismissed, the banner MUST remain hidden across page navigation and subsequent visits within the same browser (persisted via client-side storage).
- **FR-006**: The banner's persistence key MUST be tied to the current message so that a future change to the message re-shows the banner to users who dismissed the previous one.
- **FR-007**: The banner message MUST be available in both supported locales (`en-US` and `nl-NL`) and MUST render in the locale active for the current page.
- **FR-008**: The banner MUST render correctly under the site's forced light theme and MUST NOT introduce a dark-mode variant.
- **FR-009**: When the documentation is embedded in the Alkemio platform iframe, the banner MUST be accounted for in the `PAGE_HEIGHT` message so no content (including the banner) is clipped.
- **FR-010**: The banner MUST be implemented using the documentation framework's native banner mechanism (Nextra `Banner` via the theme `Layout` `banner` prop), avoiding a bespoke component where the native one suffices.
- **FR-011**: The banner MUST be accessible: dismiss control reachable by keyboard, message readable by assistive technology, and text legible (sufficient contrast) on the light theme.

### Key Entities *(include if feature involves data)*

- **Banner notice**: The informational message shown to users. Attributes: localized text (`en-US`, `nl-NL`), a descriptive/versioned storage key identifying the current message, dismissible flag (true). Relationship: rendered globally by the documentation layout.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a fresh browser session, 100% of documentation pages (any route, default locale) display the info banner at the top of the site on first render.
- **SC-002**: A user can dismiss the banner in a single action, and after dismissal the banner does not reappear on any page within the same browser session or on reload (0 reappearances).
- **SC-003**: The banner message is presented in the correct language for both supported locales (`en-US` and `nl-NL`) — verifiable by loading a page in each locale.
- **SC-004**: The production build (`pnpm build`) and Pagefind index generation complete successfully with the banner in place (0 build errors).
- **SC-005**: When embedded in the platform iframe, no documentation content or the banner itself is clipped — the iframe height reflects the banner (verifiable by inspecting that the reported page height includes the banner).

## Assumptions

- The documentation framework is Nextra 4 with `nextra-theme-docs`, whose `Layout` accepts a `banner` prop and exposes a dismissible `Banner` component from `nextra/components` (confirmed by inspecting installed packages). This native mechanism is the chosen implementation per FR-010.
- Per the constitution, Dutch translations normally flow through Crowdin; however, the banner text is a layout-level UI string rather than MDX content. To satisfy bilingual parity (FR-007) within this single repo PR, the localized banner strings are defined in code keyed by locale, alongside the existing localized layout strings, with the canonical English text authored here and the Dutch text provided as the working translation (subject to later Crowdin refinement). This is the optimal in-repo resolution and is recorded as a clarification.
- The banner is informational only (no destructive or required action) and contains plain text; an optional link is not required by the acceptance criteria and is therefore omitted to keep the footprint minimal (constitution principle V).
- The exact final marketing copy may be refined by content owners; the spec fixes the meaning and the implementation centralizes the text so copy can be updated in one place. Canonical wording chosen below.
- Forced light theme remains; no dark-mode styling is added.

## Clarifications

### Session 2026-06-16 (iteration 1)

Ambiguities surfaced across taxonomy categories (functional scope, data/state,
interaction, non-functional, integration, i18n, copy). Each resolved by decision
per YOLO rules, consistent with repo conventions and the constitution.

- **Q (Functional scope): Should the banner be dismissible or permanently shown until the docs are updated?**
  **A**: Dismissible. Rationale: the Nextra native `Banner` is dismissible by default and this is the established UX pattern; a permanent un-dismissable bar is more intrusive and not requested. Re-show on message change handles the "still relevant" concern. (→ FR-004, FR-006)

- **Q (Data/state): Where is the dismissal state stored and what is its scope?**
  **A**: Client-side `localStorage` (Nextra `Banner` default), scoped per browser, keyed by a descriptive/versioned `storageKey`. Rationale: no backend exists in this static docs site; matches framework default. (→ FR-005, FR-006)

- **Q (Copy): What is the canonical English banner text?**
  **A**: "Heads up: the screenshots and visuals in this documentation are being updated to match Alkemio's new platform design. Some images may not yet reflect the latest UI." Rationale: states the discrepancy is expected and temporary per the story's user need; centralized in code for easy copy edits. (→ FR-002)

- **Q (i18n): How is the Dutch text provided given Crowdin normally owns translations?**
  **A**: The banner is a layout-level UI string, not MDX content, so it is defined in code keyed by locale (alongside existing localized layout strings). Canonical Dutch working text: "Let op: de schermafbeeldingen en visuals in deze documentatie worden bijgewerkt naar het nieuwe platformontwerp van Alkemio. Sommige afbeeldingen komen mogelijk nog niet overeen met de nieuwste UI." Subject to later Crowdin refinement. Rationale: satisfies bilingual parity (Constitution I) within one PR. (→ FR-007)

- **Q (Integration / non-functional): Does the banner break iframe height messaging?**
  **A**: No new handling required. The existing `ResizeObserver` on `document.body` in `ClientProviders` already measures total document height (which includes the banner) and the banner is sticky at the top within the document flow, so `PAGE_HEIGHT` already accounts for it. We verify rather than add code. (→ FR-009, SC-005)

- **Q (Interaction / placement): Where exactly does the banner render — per page or globally?**
  **A**: Globally, via the `banner` prop on the `nextra-theme-docs` `Layout` in `app/[lang]/layout.jsx`, so it appears once above the navbar on all routes and locales. (→ FR-003, FR-010)

- **Q (Non-functional / theme + a11y): Any theme or accessibility constraints?**
  **A**: Must work under forced light theme (no dark variant) and the dismiss control must be keyboard-accessible with legible contrast. The native `Banner` close button is a real `<button>` (keyboard-accessible); text uses the framework's banner styling which is legible. (→ FR-008, FR-011)

**Result of iteration 1**: 7 ambiguities resolved.

### Session 2026-06-16 (iteration 2)

Re-scanned all taxonomy categories against the updated spec. No new ambiguities
found: scope, state, copy (both locales), integration, placement, theme, and
accessibility are all now decided and reflected in the requirements. Clarify
loop terminates clean.

**Result of iteration 2**: 0 new ambiguities. Loop complete (2 iterations).

### Story mapping

- GitHub story: `alkem-io/documentation#125` (this is the source story; the spec is its single-repo SDD artifact). The PR will reference `Closes #125`.
