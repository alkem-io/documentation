## Documentation site based on [Nextra](https://nextra.site/docs/docs-theme/start) docs (based on next.js)

#### to run the project

`npm i`
`npm run dev`

###### prerequisites

It's recommended to use [volta](https://docs.volta.sh/guide/getting-started)
```
"node": ">=20.9.0"
"npm": ">=10"
```
#### to build the project

1. npm run build


#### Create a page

In order to get a new page create an .md or .mdx file in the pages folder.
Then you can control the page details (title, sidebar, pagination, etc) from the _meta.json. We need it there in order to disable the footer.


pages -> new-page.md

_meta.en-US.json
```
"new-page": {
    "title": "The new Page",
    "theme": {
        "breadcrumb": true,
        "footer": false,
        "sidebar": true,
        "toc": true,
        "pagination": true
    }
},
```

[More details.](https://nextra.site/docs/guide/organize-files)


#### Editing

[Markdown](https://nextra.site/docs/guide/markdown)

[Template Configuration](https://nextra.site/docs/docs-theme/theme-configuration)


#### i18n

The project uses **Crowdin** for internationalization (i18n) management. All English `.mdx` files automatically generate corresponding `.nl` versions through Crowdin.

**Translation Process:**
- **Do not edit Dutch translation files directly** in the repository.
- All translations must be done through the **Crowdin platform**.
- When English content is updated or new pages are added:
  1. Changes sync automatically to Crowdin after it was merged to develop.
  2. Translators update Dutch versions in Crowdin.
  3. Translated content is pulled back into the repository via a **Crowdin-generated PR**.

**Handling Crowdin Updates:**
- Crowdin pushes unsigned commits to a `l10n_develop` branch.
- After translating the content, the translator should:
  1. **Create a new branch** (e.g., `git checkout -b translations-<date>`) from the up-to-date `develop` branch.
  2. **Squash all unsigned commits** from Crowdin:
     ```bash
     git merge l10n_develop --squash
     ```
  3. **Commit the changes** with a clear message:
     ```bash
     git commit -s -m "translation updates"
     ```
  . **Publish the branch** and create a PR against `develop`.

### Build & Deployment

The build and deployments are automatic on merge.

In order to deploy it to dev/acc, merge to `develop` branch.

For production release you need to merge to `main` branch.
For proper redeployment make sure you bump the version on every merge to main.

Use the following:
```
npm version patch
```
this will bump the patch version and make a commit (e.g. 0.0.1 -> 0.0.2).

Or manually update the npm version in the package.json file.
Then run `npm install` and commit the changes.

Once merged into `main`, make sure to merge `main` back to `develop` (to sync the version). 