# manifest.json – what was changed and why

JSON has no comments, so every change to `webapp/manifest.json` is explained here.
Paths are written as `sap.ui5 > routing > targets > BooksList > options > settings` etc.

## 1. Data source → the draft-enabled AdminService

```json
"sap.app": { "dataSources": { "mainService": { "uri": "/odata/v4/admin/" } } }
```

- **Why:** `AdminService` (srv/admin-service.cds) has `@odata.draft.enabled`. `CatalogService` stays draft-free
  because the freestyle app `app/book` creates and deletes rows directly.
- **Where to see it:** Edit/Save/Discard Draft buttons on the Object Page, 'Editing Status' filter on the List Report.
- **Try:** switch back to `/odata/v4/catalog/` → no Edit button (and the annotations no longer apply, they target `AdminService`).

## 2. Micro chart library

```json
"sap.ui5": { "dependencies": { "libs": { "sap.suite.ui.microchart": {} } } }
```

- **Why:** `UI.Chart #stockBullet` (a Bullet micro chart in a table cell) is rendered by this library.
- **Where:** List Report column 'Stock vs. Target'.
- **Try:** remove it → the column stays empty and the console shows a load error.

## 3. List Report: initial load

```json
"BooksList": { "options": { "settings": { "initialLoad": "Enabled" } } }
```

- **Why:** the table loads immediately, without pressing 'Go'.
- **Try:** `"Disabled"` → empty table until you press Go. `"Auto"` (default) loads only if there are default filter values.

## 4. List Report: table tabs ("views")

```json
"views": {
  "paths": [
    { "key": "all",        "annotationPath": "com.sap.vocabularies.UI.v1.SelectionPresentationVariant#all" },
    { "key": "inStock",    "annotationPath": "com.sap.vocabularies.UI.v1.SelectionPresentationVariant#inStock" },
    { "key": "outOfStock", "annotationPath": "com.sap.vocabularies.UI.v1.SelectionPresentationVariant#outOfStock" }
  ],
  "showCounts": true
}
```

- **Why:** each `UI.SelectionPresentationVariant` from annotations.cds becomes one tab with its own filter and sort.
- **Where:** tabs 'All (10)', 'In Stock (8)', 'Out of Stock (2)' above the table.
- **Try:** `"showCounts": false` → no numbers in the tab titles. Remove one entry → that tab disappears.

## 5. Table settings

```json
"controlConfiguration": {
  "@com.sap.vocabularies.UI.v1.LineItem": {
    "tableSettings": {
      "type": "ResponsiveTable",
      "selectionMode": "Multi",
      "enableExport": true,
      "condensedTableLayout": true
    }
  }
}
```

| Setting | Effect | Try |
|---|---|---|
| `type: "ResponsiveTable"` | `sap.m.Table`: columns that don't fit move under the row ("pop-in") or are hidden by `UI.Importance`; supports grouping (`GroupBy`) | `"GridTable"`: horizontal scrolling, all columns visible, but no grouping by genre |
| `selectionMode: "Multi"` | checkboxes, several rows can be selected (Delete several books at once) | `"Single"` → radio buttons; `"None"` → no selection, so the toolbar 'Add Stock' can't be used |
| `enableExport: true` | 'Export to Spreadsheet' button in the table toolbar | `false` → button disappears |
| `condensedTableLayout: true` | tighter rows (only visible in compact density, e.g. on desktop) | `false` |

## 6. Variant management (unchanged)

`"variantManagement": "Page"` (generator default) → the 'Standard ⌄' title on the List Report.
You can save filter + table settings as your own view. `"Control"` = separate variants for filter bar and table; `"None"` = off
(used on the Authors list).

## 7. Extra routes and targets for authors

```json
"routes": [
  { "pattern": ":?query:",                              "target": "BooksList" },
  { "pattern": "Books({key}):?query:",                  "target": "BooksObjectPage" },
  { "pattern": "Authors:?query:",                       "target": "AuthorsList" },
  { "pattern": "Authors({key}):?query:",                "target": "AuthorsObjectPage" },
  { "pattern": "Authors({key})/books({key2}):?query:",  "target": "AuthorBooksObjectPage" }
]
```

- **AuthorsList:** a second List Report (`contextPath: "/Authors"`) at `index.html#/Authors`.
- **AuthorsObjectPage:** shows author details, a 'Books' table (association `books`) and 'Addresses' (composition).
- **AuthorBooksObjectPage:** opening a book from the author's 'Books' table (`contextPath: "/Authors/books"`), with a breadcrumb back to the author.
- **Why not a link from a book to its author's page?** In UI5 1.153, a form field cannot navigate to the Object Page
  of a to-one association (`DataFieldWithNavigationPath` is ignored there). The author name shows a quick view card instead
  (`UI.QuickViewFacets`). In a real Fiori Launchpad, 'Authors' would be its own tile.

## 8. i18n: no more "fallback locale" console errors

```json
"sap.app": { "i18n": { "bundleUrl": "i18n/i18n.properties", "supportedLocales": [""], "fallbackLocale": "" } }
```

The same two settings are on the `i18n` and `@i18n` models. There is only one `i18n.properties` (no `_en`, `_de` …),
so UI5 should not look for language-specific files. Also changed: `appTitle=Books Manager` in `i18n.properties`
and `<title>` in `index.html`.

## Not done: flexible column layout

The flexible column layout (list and detail side by side) needs a different router (`sap.f.routing.Router`), an `Fcl` root view and
a `controlAggregation` on every target. With five routes it's a bigger change, so I left it out to keep the app easy to follow.
Fiori tools can add it: *Fiori: Open Page Map* → *Flexible Column Layout* toggle.

## Console messages that are expected

| Message | Why it's harmless |
|---|---|
| `failed to load … Component-preload.js` | no build step in local dev, UI5 loads single files instead |
| `Connector (LrepConnector) failed …` | no key-user adaptation backend locally |
| `S/CUBE is not yet supported` | from the `sap.insights` library that Fiori Elements loads by itself, not from this app |
| `SimpleLinkDelegate: Service 'CrossApplicationNavigation' … could not be obtained` | the 'Author (legacy text)' column uses intent-based navigation, which needs a Fiori Launchpad |
