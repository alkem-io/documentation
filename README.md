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

At the moment the i18n is done manually by the nextra guide - https://nextra.site/docs/guide/i18n

We'll explore the option to use Crowdin instead.

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