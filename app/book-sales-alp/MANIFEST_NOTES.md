# manifest.json – ALP settings explained

The app was generated with the SAP Fiori generator (headless mode, floorplan `FE_ALP`) and then adjusted.
JSON has no comments, so every setting is explained here. All ALP settings live in
`sap.ui5 > routing > targets > BookSalesList > options > settings`.

> In OData V4 an ALP is **not** a separate template: it's `sap.fe.templates.ListReport` with
> `views.paths[ { primary, secondary, defaultPath } ]`. That combination turns the List Report into an ALP
> (chart + table + visual filters).

## 1. Chart and table: `views`

```json
"views": {
  "paths": [{
    "primary":   [{ "annotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant" }],
    "secondary": [{ "annotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#table" }],
    "defaultPath": "both"
  }]
}
```

| Key | Meaning | Allowed values (docs) |
|---|---|---|
| `primary` | the **chart** area | `UI.Chart`, `UI.PresentationVariant`, `UI.SelectionPresentationVariant` |
| `secondary` | the **table** area | `UI.LineItem`, `UI.PresentationVariant`, `UI.SelectionPresentationVariant` |
| `defaultPath` | what's visible on start | `"primary"` = chart only, `"secondary"` = table only, `"both"` = hybrid |

- **Where:** the three toggle buttons at the right end of the chart/table toolbar (hybrid ▤ / chart 📊 / table ▦).
  The user's choice is kept in the app state (and in saved variants).
- **Try:** `"defaultPath": "secondary"` → the app opens with the table only.
- **Note (docs):** use only ONE entry in `paths`, `primary` and `secondary`. An ALP has one chart and one table, no tabs.
- **Note (tested):** `primary` → `SelectionPresentationVariant#default` works, but the chart then ignores the
  `SortOrder`. So the plain `PresentationVariant` is used; the SPV stays in annotations.cds as an alternative.

## 2. Table: type, selection, export

```json
"@com.sap.vocabularies.UI.v1.LineItem": {
  "tableSettings": { "type": "AnalyticalTable", "selectionMode": "Multi", "enableExport": true }
}
```

| Setting | Effect | Try |
|---|---|---|
| `type: "AnalyticalTable"` | grouping with sub-totals and a grand-total row (uses `$apply` with `groupby`/`aggregate`/`concat`) | `"GridTable"` → flat list, no totals; `"ResponsiveTable"` → no totals either |
| `selectionMode: "Multi"` | checkboxes; needed for the 'Open Book' button (one row) | `"Single"` |
| `enableExport: true` | 'Export to Spreadsheet' (the icon with ⌄) | `false` |

## 3. Filter bar: visual + compact

```json
"@com.sap.vocabularies.UI.v1.SelectionFields": {
  "layout": "CompactVisual",
  "initialLayout": "Visual",
  "filterFields": {
    "year":         { "visualFilter": { "valueList": "com.sap.vocabularies.Common.v1.ValueList#visualFilter" } },
    "region_code":  { "visualFilter": { "valueList": "com.sap.vocabularies.Common.v1.ValueList#visualFilter" } },
    "channel_code": { "visualFilter": { "valueList": "com.sap.vocabularies.Common.v1.ValueList#visualFilter" } }
  }
}
```

| Setting | Effect | Try |
|---|---|---|
| `layout: "CompactVisual"` | both filter bars exist; a toggle (two buttons, top right of the page) switches between them | `"Compact"` → no visual filters at all |
| `initialLayout: "Visual"` | opens with the chart filters | `"Compact"` → opens with input fields |
| `filterFields.<field>.visualFilter.valueList` | which `Common.ValueList` (qualifier!) provides the chart for this field | point `year` to a non-existing qualifier → the Year chart disappears |

A field can have several value lists: the unqualified one is the normal value help, `#visualFilter` feeds the chart.
More options per field (from the docs): `"availability": "Default" | "Adaptation" | "Hidden"`.

## 4. KPI tags

```json
"keyPerformanceIndicators": {
  "revenue":  { "model": "", "entitySet": "BookSales", "qualifier": "revenue" },
  "discount": { "model": "", "entitySet": "BookSales", "qualifier": "discount" },
  "copies":   { "model": "", "entitySet": "BookSales", "qualifier": "copies" },
  "online":   { "model": "", "entitySet": "BookSales", "qualifier": "online" }
}
```

- Each entry = one tag in the header next to 'Standard'. `qualifier` → `UI.KPI#<qualifier>` in annotations.cds.
- `model: ""` = the app's main OData model; a KPI could also come from another service.
- **Try:** remove `"copies"` → that tag disappears. Reorder the entries → the tags change order.

## 5. initialLoad, variantManagement

- `"initialLoad": "Enabled"` – chart and table load immediately (otherwise: press 'Go').
- `"variantManagement": "Page"` (generated) – 'Standard ⌄' saves filters + chart/table settings + view mode together.
  After changing something, 'Standard*' shows an asterisk = unsaved change.

## 6. Cross-app navigation

```json
"sap.app": {
  "crossNavigation": {
    "inbounds":  { "BookSales-analyze": { "semanticObject": "BookSales", "action": "analyze", ... } },
    "outbounds": { "openBook": { "semanticObject": "Books", "action": "display" } }
  }
}
```

- **inbound** = how a launchpad starts this app (`#BookSales-analyze`).
- **outbound** = documents that this app navigates to `Books-display` (the Fiori elements links/buttons come from annotations).
- The Books app (`app/books_list/webapp/manifest.json`) got the matching inbound:
  `Books-display` with parameter `bookNo` and `"additionalParameters": "ignored"`. Fiori passes all row fields;
  "ignored" tells a real launchpad to drop everything except `bookNo`.
- Navigation needs a launchpad: **http://localhost:4004/launchpad.html** (`app/launchpad.html`, a classic sandbox).
  Opened standalone (`/booksalesalp/index.html`) the 'Open Book' button is hidden and Book No. is plain text.
- Tested: the local sandbox does **not** strip the extra parameters (you see them in the URL), but the Books app finds the
  book by its semantic key `bookNo` and opens its Object Page anyway.

## 7. i18n

`supportedLocales: [""]` and `fallbackLocale: ""` on `sap.app.i18n` and both i18n models → no "fallback locale" errors
(there is only one `i18n.properties`).

## Things that did not work (so you don't try them again)

| Tried | Result |
|---|---|
| `fiori-tools-preview` with `flp.apps` in ui5.yaml (multi-app sandbox) | with `cds-plugin-ui5` + `cds watch` the server hung on startup → reverted, `app/launchpad.html` used instead |
| `primary` = `SelectionPresentationVariant` | works, but chart sort order ignored |
