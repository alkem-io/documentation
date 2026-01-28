# Alkemio Documentation

Platform documentation for Alkemio, built with Nextra (documentation framework on top of Next.js).

## Technology Stack

- **Framework**: Nextra 2.13.4 with `nextra-theme-docs`
- **Next.js**: 14.2.5
- **React**: 18.3.1
- **Node.js**: >= 20.9.0
- **License**: EUPL-1.2

## Scripts

```bash
npm run dev      # Development server on port 3010
npm run build    # Production build
npm run start    # Start production server on port 3010
npm run export   # Static export
```

## Project Structure

```
pages/              # MDX content files (organized by section)
  _meta.*.json      # Navigation configuration per locale
  *.en-US.mdx       # English content
  *.nl-NL.mdx       # Dutch content
components/         # React components
  iframeCommunication.js  # Parent frame messaging
  Tutorial*.js      # Embedded tutorial videos
public/             # Static assets
theme.config.jsx    # Nextra theme configuration
next.config.js      # Next.js configuration
styles.css          # Global styles
```

## Ignore Folders

- `node_modules/`
- `.next/` (build output)
- `out/` (static export output)

## i18n (Internationalization)

- **Locales**: `en-US` (default), `nl-NL`
- **File naming**: `filename.locale.mdx` (e.g., `support.en-US.mdx`, `support.nl-NL.mdx`)
- **Navigation**: `_meta.en-US.json` and `_meta.nl-NL.json` in each folder
- When updating content, ensure both language versions are kept in sync

## Configuration

- **Base path**: `/documentation`
- **Theme**: Forced light mode
- **Images**: Unoptimized (for static export compatibility)

## Iframe Integration

This documentation is embedded within the main Alkemio platform via an iframe. The `IframeCommunication` component in `_app.js` handles parent-child frame messaging:

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

1. Create MDX files for both locales: `pagename.en-US.mdx` and `pagename.nl-NL.mdx`
2. Add entries to `_meta.en-US.json` and `_meta.nl-NL.json` in the same folder
3. Keep content synchronized between language versions
