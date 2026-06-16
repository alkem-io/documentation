---
description: "Task list for feature: Info banner for pending docs/platform design sync"
---

# Tasks: Info banner for pending docs/platform design sync

**Input**: Design documents from `/specs/001-info-banner-pending-sync/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/banner.md

**Tests**: This repo has no unit-test harness (validation is via `pnpm build` +
manual/visual verification per quickstart). No test tasks are included; the spec
did not request automated tests. Verification is captured as build + manual gates.

**Organization**: Tasks grouped by user story (US1 P1, US2 P2, US3 P3) for
independent implementability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3 (or none for shared phases)

## Path Conventions

Single Next.js/Nextra web project; paths are relative to the worktree root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the framework banner mechanism is available before wiring it.

- [X] T001 Verify `Banner` is exported from `nextra/components` and the `banner` prop is accepted by `nextra-theme-docs` `Layout` in the installed versions (inspect `node_modules/nextra/dist/client/components/index.js` and `node_modules/nextra-theme-docs/dist/types.generated.d.mts`). No dependency changes expected (FR-010).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Centralized banner content module that all stories consume.

**⚠️ CRITICAL**: US1/US2/US3 all depend on this module.

- [X] T002 Create `app/_components/banner-content.js` exporting `BANNER_STORAGE_KEY` (descriptive + versioned, e.g. `docs-visuals-pending-platform-redesign-2026-06`), `bannerText` (locale map for `en-US` and `nl-NL`), and `getBannerText(lang)` with fallback to `en-US` (per data-model.md / contracts/banner.md). Acceptance: module exports match the contract; both locales non-empty; fallback returns `en-US` for unknown locale.

**Checkpoint**: Banner content available for layout wiring.

---

## Phase 3: User Story 1 - Reader is informed visuals are pending (Priority: P1) 🎯 MVP

**Goal**: A global info banner shows the pending-visuals message at the top of every page in `en-US`.

**Independent Test**: Load any page in `en-US`; banner appears at top with the message.

### Implementation for User Story 1

- [X] T003 [US1] Edit `app/[lang]/layout.jsx`: import `Banner` from `nextra/components` and `getBannerText` + `BANNER_STORAGE_KEY` from `app/_components/banner-content.js`; build a `banner` element `<Banner storageKey={BANNER_STORAGE_KEY}>{getBannerText(lang)}</Banner>` and pass it to `<Layout banner={banner} ...>`. Acceptance: banner renders globally above the navbar on all routes (FR-001, FR-003, FR-010); message matches FR-002.

**Checkpoint**: MVP — banner visible site-wide in the default locale.

---

## Phase 4: User Story 2 - Reader can dismiss the banner (Priority: P2)

**Goal**: Banner is dismissible and dismissal persists; re-shows when the message changes.

**Independent Test**: Dismiss the banner → it hides → reload/navigate → stays hidden.

### Implementation for User Story 2

- [X] T004 [US2] Confirm the native `Banner` is dismissible (default `dismissible=true`) and persists via `BANNER_STORAGE_KEY` in `localStorage`; ensure the key passed in T003 is the versioned key from T002 so a future copy change re-shows the banner (FR-004, FR-005, FR-006). No extra code beyond passing `storageKey`. Acceptance: close control hides banner; dismissal survives reload; changing the key re-shows.

**Checkpoint**: US1 + US2 functional.

---

## Phase 5: User Story 3 - Dutch reader sees the notice in Dutch (Priority: P3)

**Goal**: Banner message renders in Dutch for `nl-NL`.

**Independent Test**: Load an `nl-NL` page / switch locale; banner shows Dutch text.

### Implementation for User Story 3

- [X] T005 [US3] Ensure the `nl-NL` entry exists in `bannerText` (added in T002) and that `app/[lang]/layout.jsx` selects text via `getBannerText(lang)` using the resolved `lang` param (FR-007). Acceptance: `nl-NL` pages show the Dutch message; `en-US` unchanged.

**Checkpoint**: All stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T006 [P] Verify iframe height: confirm `app/_components/ClientProviders.jsx` needs no change — the `ResizeObserver` on `document.body` already reports total height incl. the banner, and dismissing fires a new `PAGE_HEIGHT` (FR-009, SC-005, BC-7). Document the verification in the PR.
- [X] T007 [P] Verify light-theme rendering and accessibility: banner legible under forced light theme (no dark variant), close control keyboard-focusable (FR-008, FR-011, BC-8, BC-9). Apply a minimal `className` only if contrast needs tuning.
- [X] T008 Run exit gate: `pnpm build` (incl. Pagefind postbuild) succeeds with the banner in place (SC-004). NOTE: this repo has no separate lint/format/typecheck pipeline (no eslint/tsconfig; plain JSX); `pnpm build` (next build) is the repo's full validation, matching CI which runs `pnpm install` + `pnpm build`.
- [X] T009 Run quickstart.md validation (banner shows, dismiss persists, locale switch shows Dutch).

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1) → no deps.
- Foundational (Phase 2) → depends on Setup; BLOCKS all user stories.
- User Stories (Phases 3–5) → depend on Foundational (T002). US1/US2/US3 all touch
  the same two files (`layout.jsx`, `banner-content.js`), so they are effectively
  delivered together in this small feature rather than in parallel.
- Polish (Phase 6) → after user stories.

### Within Each User Story

- T002 (content module) before T003 (layout wiring).
- T003 before T004/T005 (they refine the same wiring).

### Parallel Opportunities

- T006 and T007 are independent verification tasks ([P]).
- Because US1–US3 modify the same two files, their implementation tasks are NOT
  parallelizable across each other; they are sequenced T003 → T004 → T005.

---

## Implementation Strategy

### MVP First

1. T001 (Setup) → T002 (Foundational) → T003 (US1). STOP and validate banner shows in `en-US`.

### Incremental Delivery

1. Setup + Foundational → ready.
2. US1 (T003) → MVP (banner visible).
3. US2 (T004) → dismissible + persistent.
4. US3 (T005) → Dutch.
5. Polish (T006–T009) → verify iframe/a11y/build, run quickstart.

---

## Notes

- [P] = different files, no dependencies.
- No automated test tasks: repo has no test runner; gates are `pnpm build` + manual.
- Commit after each logical group (content module; layout wiring; verification).
- Keep the working tree green between tasks (`pnpm build` must pass).
