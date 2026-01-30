# Alkemio Documentation

Platform documentation for Alkemio, built with Nextra 4 (documentation framework on top of Next.js App Router).

## Technology Stack

- **Framework**: Nextra 4.6.1 with `nextra-theme-docs`
- **Next.js**: 16.1.6 (App Router)
- **React**: 19.2.4
- **Search**: Pagefind (built during postbuild)
- **Node.js**: >= 22.0.0
- **Package Manager**: pnpm >= 9.0.0
- **License**: EUPL-1.2

## Scripts

```bash
pnpm dev      # Development server on port 3010 (search won't work)
pnpm build    # Production build + generates Pagefind search index
pnpm start    # Start production server on port 3010 (search works)
```

**Note**: Search only works after running `pnpm build` because Pagefind indexes the compiled HTML.

## Project Structure

```
app/                    # Next.js App Router
  layout.jsx            # Root layout (minimal)
  not-found.jsx         # 404 page (light theme)
  [lang]/               # Locale-based routing
    layout.jsx          # Main layout with Nextra theme
    not-found.jsx       # Locale-specific 404
    [[...mdxPath]]/     # Catch-all route for MDX content
      page.jsx          # MDX page renderer
  _components/          # Client-side components
    ClientProviders.jsx # Iframe communication & client logic
    LocaleSwitchWrapper.jsx # Locale cookie tracking
content/                # MDX documentation content
  en-US/                # English content
    _meta.js            # Navigation configuration
    *.mdx               # Content files
    features/           # Feature documentation
    getting-started/    # Getting started guides
    how-to/             # How-to guides
    structure/          # Platform structure docs
  nl-NL/                # Dutch content (mirrors en-US structure)
components/             # Shared React components
  Tutorial*.js          # Embedded tutorial videos
public/                 # Static assets
  _pagefind/            # Search index (generated, gitignored)
mdx-components.js       # MDX component configuration
next.config.mjs         # Next.js configuration (ESM)
proxy.js                # Locale detection middleware
styles.css              # Global styles
.npmrc                  # pnpm configuration (enables pre/post scripts)
```

## Ignore Folders

- `node_modules/`
- `.next/` (build output)
- `public/_pagefind/` (search index, generated)
- `_pagefind/`

## i18n (Internationalization)

- **Locales**: `en-US` (default), `nl-NL`
- **Content structure**: `content/{locale}/` directories
- **Navigation**: `_meta.js` files in each content folder (ES module format)
- **Locale persistence**: Cookie-based (`NEXT_LOCALE`) for sidebar navigation
- When updating content, ensure both language versions are kept in sync

## Configuration

- **Base path**: `/documentation`
- **Theme**: Forced light mode (pure white background)
- **Images**: Unoptimized (for compatibility)

## Iframe Integration

This documentation is embedded within the main Alkemio platform via an iframe. The `ClientProviders` component handles parent-child frame messaging:

**Message Types**:
- `PAGE_HEIGHT`: Sends current page height for dynamic iframe resizing
- `PAGE_CHANGE`: Notifies parent of navigation changes

**Allowed Origins**:
- `https://alkem.io`
- `https://dev-alkem.io`
- `https://acc-alkem.io`
- `https://sandbox-alkem.io`
- `https://test-alkem.io`
- `http://localhost:3000`

When not in an iframe, the body receives class `not-in-iframe` for standalone styling.

## Adding New Pages

1. Create MDX file in both locales: `content/en-US/pagename.mdx` and `content/nl-NL/pagename.mdx`
2. Add entry to `_meta.js` in the same folder for both locales
3. Keep content synchronized between language versions

## Navigation Configuration

Navigation is configured using `_meta.js` files (ES module format):

```javascript
export default {
  'page-name': {
    title: 'Page Title',
    theme: {
      breadcrumb: true,
      sidebar: true
    }
  }
}
```

## Docker Build

The Dockerfile uses multi-stage builds with Node 22 and pnpm:

1. **Build stage**: Installs pnpm via corepack, installs deps, builds Next.js app, generates Pagefind index
2. **Production stage**: Copies only necessary files, installs production deps

Key files copied to production:
- `.next/` - compiled app
- `public/` - static assets including `_pagefind/`
- `app/`, `content/`, `components/` - source files needed at runtime
- `next.config.mjs`, `mdx-components.js`, `proxy.js`, `styles.css`

## CI/CD

- **Travis CI**: Uses Node 22 + pnpm, runs `pnpm install` and `pnpm build` for validation
- **GitHub Actions**: Build Docker image and deploy to Kubernetes clusters
- **Environments**: dev, test, sandbox, acc (acceptance), prod
