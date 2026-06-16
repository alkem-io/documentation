# Implementation Plan: Info banner for pending docs/platform design sync

**Branch**: `story/125-info-banner-pending-sync-docs-platform-design` | **Date**: 2026-06-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-info-banner-pending-sync/spec.md`

## Summary

Add a global, dismissible informational banner to the top of the Alkemio
documentation site informing users that the screenshots/visuals are pending an
update to match the new platform UI, so discrepancies are expected and temporary.
Technical approach: use the documentation framework's native banner mechanism —
the `Banner` component from `nextra/components` passed to the `banner` prop of the
`nextra-theme-docs` `Layout` in `app/[lang]/layout.jsx`. Banner text is
locale-aware (`en-US`, `nl-NL`), centralized in a small co-located module, and
keyed by a descriptive/versioned `storageKey` so a future copy change re-shows it.

## Technical Context

**Language/Version**: JavaScript (JSX), Node.js >= 22, React 19.2
**Primary Dependencies**: Next.js 16 (App Router), Nextra 4.6 + `nextra-theme-docs` 4.6 (already installed; `Banner` is exported from `nextra/components`)
**Storage**: Client-side `localStorage` (banner dismissal), provided by the native `Banner` (no backend; static docs site)
**Testing**: No unit-test harness and no separate lint/format/typecheck pipeline exist in this repo (no eslint/tsconfig; plain JSX). Validation is via `pnpm build` (next build = the repo's full static validation + Pagefind index) and manual/visual verification per quickstart. CI runs `pnpm install` + `pnpm build`.
**Target Platform**: Static/SSR docs site served at base path `/documentation`, viewed standalone and embedded in the Alkemio platform iframe (forced light theme)
**Project Type**: Single web project (Next.js App Router with Nextra)
**Performance Goals**: No measurable performance impact; banner is a single small DOM node rendered at the layout level
**Constraints**: Forced light theme only; must not clip in iframe (`PAGE_HEIGHT` messaging must include banner); bilingual parity; minimal footprint (no new dependencies)
**Scale/Scope**: One layout edit + one small locale string module; affects all routes/locales globally

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against `.specify/memory/constitution.md` v1.0.0:

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Bilingual Content Sync | PASS | Banner string provided for both `en-US` and `nl-NL` (FR-007). It is a layout UI string, not MDX content, so it lives in code keyed by locale; Dutch working text included, subject to later Crowdin refinement (recorded as clarification). |
| II. Iframe Compatibility | PASS | No change to `ClientProviders`; existing `ResizeObserver` on `document.body` already measures total height incl. banner; renders standalone and embedded (FR-009). |
| III. Build Integrity | PASS | `pnpm build` + Pagefind postbuild must pass (SC-004); no new build steps. |
| IV. Light Theme & Visual Consistency | PASS | No dark-mode variant added; banner uses native styling under forced light theme (FR-008). |
| V. Simplicity & Minimal Footprint | PASS | Uses the framework's native `Banner`; no new dependency; one layout edit + one tiny module (FR-010). |

No violations. Complexity Tracking not required.

## Project Structure

### Documentation (this feature)

```text
specs/001-info-banner-pending-sync/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── banner.md        # Behavioural contract for the banner
├── checklists/
│   └── requirements.md  # Requirements quality checklist
├── spec.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
app/
├── [lang]/
│   └── layout.jsx           # EDIT: pass <Banner> to Layout banner prop, locale-aware text
└── _components/
    └── banner-content.js    # NEW: centralized locale-keyed banner strings + storage key
```

**Structure Decision**: Single Next.js/Nextra web project. The banner is wired at
the locale layout (`app/[lang]/layout.jsx`), which already receives the resolved
`lang` param, making it the natural place to choose the localized message. The
message strings and the versioned storage key are extracted to a small co-located
module `app/_components/banner-content.js` so copy is centralized and editable in
one place (supports FR-006 key/text coupling and easy future updates). No new
directories or dependencies are introduced.

## Complexity Tracking

> No constitution violations — section intentionally empty.

## Cross-Artifact Analysis (speckit-analyze)

Read-only consistency check of spec.md ↔ plan.md ↔ tasks.md ↔ codebase ↔ constitution.

**Iteration 1 findings**:
- **F1 (resolved)**: tasks/plan referenced a lint/format/typecheck pipeline that
  does not exist in this repo (no eslint config, no tsconfig; plain JSX). CI and
  the repo's only validation is `pnpm build`. Amended T008 and the plan's Testing
  context to make `pnpm build` the sole exit gate.
- Coverage verified: every FR maps to a task (FR-001/003/010→T003; FR-002→T003;
  FR-004/005/006→T004; FR-007→T002/T005; FR-008/011→T007; FR-009→T006); every SC
  maps (SC-001/002/003→T009 quickstart; SC-004→T008; SC-005→T006); all three user
  stories have phases; constitution gates all PASS.

**Iteration 2 findings**: 0. After F1 amendment, artifacts are mutually
consistent and consistent with the codebase and constitution. Analyze loop
terminates clean (2 iterations).
