# Quickstart: Info banner for pending docs/platform design sync

**Feature**: 001-info-banner-pending-sync | **Date**: 2026-06-16

## Prerequisites

- Node.js >= 22, pnpm >= 9 (repo uses `pnpm@10.17.1`)
- From the worktree root: `pnpm install`

## What was added

1. `app/_components/banner-content.js` — locale-keyed banner strings + versioned
   `BANNER_STORAGE_KEY` + `getBannerText(lang)` helper.
2. `app/[lang]/layout.jsx` — imports `Banner` from `nextra/components` and the
   banner content, and passes `banner={<Banner storageKey={...}>{getBannerText(lang)}</Banner>}`
   to the `nextra-theme-docs` `Layout`.

## Run locally

```bash
pnpm dev      # http://localhost:3010/documentation  (search disabled in dev)
```

Open the site. Expected: a banner across the top of the page with the
"screenshots/visuals are being updated" message. Click the close (×) control →
banner disappears. Reload → banner stays hidden. Switch the locale to Nederlands
→ banner text shows in Dutch.

To reset the dismissed state during testing, clear the `localStorage` key
`docs-visuals-pending-platform-redesign-2026-06` (DevTools → Application →
Local Storage) and reload.

## Verify the production build (exit gate)

```bash
pnpm build    # next build + pagefind postbuild — MUST succeed (SC-004)
pnpm start    # http://localhost:3010/documentation (search works post-build)
```

## Verify iframe height (FR-009 / BC-7)

The banner is part of the document flow; `ClientProviders` observes `document.body`
and reports total height via the `PAGE_HEIGHT` postMessage. With the banner shown
then dismissed, the resize observer fires and a fresh height is posted, so the
embedding iframe is sized correctly and nothing is clipped. No code change needed
in `ClientProviders` — confirm by inspecting that dismissing the banner triggers a
new `PAGE_HEIGHT` message (e.g. via a console log or the parent frame).

## Updating the copy later

Edit `bannerText` in `app/_components/banner-content.js` for both locales, and
bump the version suffix on `BANNER_STORAGE_KEY` so previously-dismissed users see
the new message.
