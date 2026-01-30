<!--
Sync Impact Report
==================
Version change: 0.0.0 → 1.0.0 (initial ratification)
Modified principles: N/A (first version)
Added sections:
  - Core Principles (5 principles)
  - Content Standards
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ no changes needed (Constitution Check is generic)
  - .specify/templates/spec-template.md ✅ no changes needed
  - .specify/templates/tasks-template.md ✅ no changes needed
Follow-up TODOs: none
-->

# Alkemio Documentation Constitution

## Core Principles

### I. Bilingual Content Sync

All documentation content MUST exist in both `en-US` and `nl-NL`
locales. Every new page, edit, or structural change MUST be reflected
in both language directories. Dutch translations MUST go through
Crowdin; direct edits to Dutch files are prohibited. Navigation
`_meta.js` files MUST stay synchronized across locales.

**Rationale**: The platform serves Dutch and English-speaking users.
Drift between locales degrades the experience for one audience.

### II. Iframe Compatibility

All pages MUST render correctly when embedded in the Alkemio platform
iframe. The `ClientProviders` component MUST handle `PAGE_HEIGHT` and
`PAGE_CHANGE` messages. Allowed origins MUST be explicitly listed and
kept current. Standalone (non-iframe) rendering MUST also work via
the `not-in-iframe` body class.

**Rationale**: Documentation is consumed primarily inside the Alkemio
platform. Broken iframe communication makes docs inaccessible to most
users.

### III. Build Integrity

`pnpm build` MUST succeed without errors before any merge. The
Pagefind search index MUST be generated during postbuild. The Docker
multi-stage build MUST produce a working production image. Travis CI
and GitHub Actions MUST validate builds on every push.

**Rationale**: Search depends on a successful build. A broken build
means no search and no deployment.

### IV. Light Theme & Visual Consistency

The documentation MUST use forced light mode with a pure white
background. No dark mode variants are permitted. Styling MUST remain
consistent whether viewed standalone or in the iframe.

**Rationale**: Visual consistency with the Alkemio platform brand
requires a single, controlled theme.

### V. Simplicity & Minimal Footprint

Prefer MDX content over custom components. New dependencies MUST be
justified. Avoid client-side JavaScript beyond what Nextra and the
iframe integration require. Pages MUST load fast and remain
accessible. Do not over-engineer; documentation is content-first.

**Rationale**: Documentation sites should be fast, simple, and
focused on content. Complexity increases maintenance burden
disproportionately.

## Content Standards

- Every MDX file MUST have a corresponding entry in `_meta.js`.
- Images MUST be placed in `public/` and referenced with the
  `/documentation` base path.
- Image optimization is disabled; use appropriately sized source
  images.
- Page structure MUST follow Nextra conventions (frontmatter,
  headings, components).
- Tutorial videos use the shared `Tutorial*.js` components.

## Development Workflow

- **Branch strategy**: Feature branches merge to `develop` (deploys
  to dev/acc). `develop` merges to `main` for production.
- **Version bumps**: Required on every merge to `main` (use
  `npm version patch` or manual update).
- **After production merge**: Merge `main` back to `develop` to sync
  versions.
- **Translations**: English content merges first; Crowdin syncs and
  generates Dutch via `l10n_develop` branch, squashed into a signed
  commit before PR.
- **Node.js**: >= 22.0.0 required. pnpm >= 9.0.0 required.

## Governance

This constitution is the authoritative source of project standards.
All pull requests MUST comply with the principles above. Amendments
require:

1. A pull request documenting the proposed change with rationale.
2. Review and approval from at least one maintainer.
3. Version bump per semantic versioning (MAJOR for principle
   removal/redefinition, MINOR for additions, PATCH for
   clarifications).
4. Update of the `Last Amended` date.

Compliance is verified during code review. The plan template's
"Constitution Check" gate references this document.

**Version**: 1.0.0 | **Ratified**: 2026-01-28 | **Last Amended**: 2026-01-28
