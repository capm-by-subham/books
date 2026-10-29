# Books Freestyle Lab: learning guide

One freestyle UI5 app, two ways to build the same pages:

| | Page A "Classic Smart" | Page B "Building Blocks" |
|---|---|---|
| Library | `sap.ui.comp` (SmartFilterBar, SmartTable, SmartChart, SmartForm, SmartField, SmartVariantManagement, SmartLink) | `sap.fe.macros` (FilterBar, Table, TreeTable, Chart, Form, Field, VariantManagement, MessageButton) |
| Protocol | OData **V2** `/odata/v2/freestyle` (made by `@cap-js-community/odata-v2-adapter`) | OData **V4** `/odata/v4/freestyle` |
| Annotations | `app/books-freestyle/annotations.cds` | the same file |
| Route | `#/classic`, detail `#/classic/book/3` | `#/blocks`, detail `#/Books(3)` |

**Start:** `npm run watch-books-freestyle` (or `cds watch`, then open http://localhost:4004/booksfreestyle/index.html?sap-ui-xx-viewCache=false).
Inside the launchpad: http://localhost:4004/launchpad.html#BooksFreestyle-display. Semantic links only resolve there.

> **Always keep `?sap-ui-xx-viewCache=false` while you edit views.** Fiori elements caches the templated
> XML views in the browser. Without the parameter you keep seeing the OLD view after editing a `.view.xml`.

---

## 1. How the app is built

```
app/books-freestyle/
├─ annotations.cds              shared annotations (both pages) — registered in app/services.cds
├─ FREESTYLE_GUIDE.md           this file
├─ MANIFEST_NOTES.md            manifest.json explained (JSON can't have comments)
└─ webapp/
   ├─ index.html                bootstrap (+ LocalStorageConnector for variants)
   ├─ manifest.json             2 data sources/models ("" = V4, "v2" = V2), FPM routing
   ├─ Component.js              extends sap.fe.core.AppComponent (!)
   ├─ controller/BaseController.js   extends sap.fe.core.PageController: helpers, message popover
   ├─ controller/Home|PageA|DetailA|PageB|DetailB.controller.js
   ├─ view/Home|PageA|DetailA|PageB|DetailB.view.xml
   ├─ fragment/CreateBookDialog|AddStockDialog.fragment.xml
   ├─ control/RatingStars.js    custom control
   ├─ model/formatter.js
   ├─ i18n/i18n.properties
   └─ css/style.css
srv/freestyle-service.cds/.js   FreestyleService (no draft): Books, Authors, Genres, GenreTree, BookSalesAnalytics
```

**Why `sap.fe.core.AppComponent` in a freestyle app?** Building blocks only work inside the Fiori
elements runtime. That means the XML templating, the routing service and the controller extensions (`this.routing`,
`this.editFlow`). Every page is still an **FPM custom page**: our own XML view + our own controller.
Any control can go in it, including the `sap.ui.comp` smart controls. A plain `UIComponent` app could run
Page A but not Page B.

**Why the V2 model is set on the page control (not the view):** smart controls always use the
*default* (unnamed) model. `PageA.controller.js` does `this.byId("pageA").setModel(v2Model)`. The view itself
keeps the V4 model, which the FE runtime expects.

**Why `"contextPattern": ""` on Home/PageA/DetailA/PageB targets:** otherwise FE would turn the route
pattern (`classic/book/{id}`) into a V4 binding path (`/classic/book/3`) and fail. An empty pattern = page unbound.

---

## 2. Feature matrix

| Feature | Page A (sap.ui.comp, V2) | Page B (sap.fe.macros, V4) | Annotation needed | Where in the UI |
|---|---|---|---|---|
| Filter fields | `SmartFilterBar entitySet="Books"` | `macros:FilterBar metaPath="@…SelectionFields"` | `UI.SelectionFields` | header, Books section |
| F4 value help | automatic (`writer_ID`) | automatic | `Common.ValueList` | filter 'Author' |
| Dropdown value help | automatic; `ControlConfiguration controlType="dropDownList"` forces single select | automatic (multi) | `Common.ValueListWithFixedValues` | filter 'Genre', 'Status' |
| Texts instead of keys | automatic | automatic | `Common.Text` + `UI.TextArrangement` | Author column, tokens |
| Default filter values | `ControlConfiguration > defaultFilterValues` (Status ≠ Discontinued) | (via `UI.SelectionVariant` or variant) | none | Page A starts with 9 books |
| Free-text search | `enableBasicSearch="true"` (V2 `search=`) | search field, always on | `@cds.search` | 'Search' field, try "moors" |
| Live mode | `liveMode="{view>/liveMode}"`, switchable at runtime | `liveMode="true"`, templating time only | none | 'Live mode' switch (A) |
| Adapt Filters | `showFilterConfiguration` | built in | none | 'Adapt Filters' |
| Custom filter field | `ControlConfiguration > customControl` + code in `beforeRebindTable` + `beforeVariantFetch/afterVariantLoad` | `macrosFilterBar:FilterField` + `filterValues>` model + `sap.fe.macros.filter.type.Value` (no code) | none | 'In stock only' (A), 'Minimum stock' (B) |
| Page variants | `SmartVariantManagement` + `smartVariant="…"` on each control | `macros:VariantManagement for="fb,table,…"` | none (+ LocalStorageConnector) | title 'Standard ▾' |
| Responsive table | `tableType="ResponsiveTable"` | `type="ResponsiveTable"` | `UI.LineItem` | Books section |
| Grid table | `tableType="Table"` (enum is **Table**, not GridTable) | `type="GridTable"` | `UI.LineItem` | 'Grid' toggle |
| Analytical table | `tableType="AnalyticalTable"` | `type="AnalyticalTable"` | A: `@Analytics.Dimension/Measure` + `ApplySupported.PropertyRestrictions`; B: `Aggregation.ApplySupported` + `CustomAggregate` | Sales section |
| Tree table | `tableType="TreeTable"` | `macros:TreeTable hierarchyQualifier="GenreTreeHierarchy"` | A: `@sap.hierarchy.*`; B: `@hierarchy` (CAP generates `Hierarchy.RecursiveHierarchy`) | Genre Tree section |
| Column importance | all columns shown, popin when narrow | `#Medium/#Low` hidden behind **Show Details** | `UI.Importance` | table toolbar (B) |
| Criticality colours | automatic | automatic | `Criticality` in DataField | Status column |
| Currency | automatic "11.11 GBP" | automatic | `Measures.ISOCurrency` | Price column |
| Personalization | `useTablePersonalisation` (Columns/Sort/Filter/Group) | `personalization="Column,Sort,Filter,Group"` | none | gear icon |
| Export to Excel | `enableExport` | `enableExport`, `exportFileName` | none | export icon |
| Row count in header | `showRowCount` | automatic | `UI.HeaderInfo.TypeNamePlural` (B) | "Books (9)" |
| Custom column | inner `<Table>` + `p13nData` customData + row template | `macrosTable:Column` with `anchor`, `properties` | none | 'Stars' |
| Row press → detail | inner table `itemPress` + `navTo` | **no code**: manifest `navigation: { Books: { detail: { route } } }` | none | click a row |
| Selection + toolbar buttons | `customToolbar` + `enabled="{= ${view>/selectedCount} === 1 }"` | `macrosTable:Action requiresSelection="true"` | none | 'Add Stock', 'Open Selected' |
| Annotated action + parameter dialog | not supported by SmartTable → own dialog + `callFunction("/Books_addStock")` | automatic | `UI.DataFieldForAction`, `Core.OperationAvailable` | 'Add Stock' |
| Hook before data request | `beforeRebindTable` → `bindingParams.filters.push(…)` | `beforeRebindTable` → `collectionBindingInfo.addFilter(…)` | none | 'In stock only' (A), 'Hide discontinued' (B) |
| Chart | `SmartChart` (type switch, drilldown, legend, zoom, details, p13n) | `macros:Chart personalization="Type,Item,Sort"` | `UI.Chart` + analytics (see above) | Sales section |
| Chart selection → filter | inner chart `selectData` → filter only the **table** | `selectionChange` → `FilterBar.setFilterValues` → chart **and** table | none | click a bar |
| Detail form | `SmartForm` with Groups/GroupElements written by hand | `macros:Form metaPath="@…FieldGroup#General"` | B: `UI.FieldGroup` | Detail pages |
| Fields | `SmartField value="{price}"` | `macros:Field metaPath="price"` | labels, ValueList, ISOCurrency, @mandatory, @readonly | Detail pages |
| Edit/display | `SmartForm editable="{view>/editMode}"` | FE `ui>/isEditable` | none | 'Edit' |
| Save | `submitChanges()` (deferred group "changes") | own element binding with `$$updateGroupId` + `submitBatch` | none | footer 'Save' |
| Semantic link | SmartLink, automatic | automatic | `Common.SemanticObject` | 'Book No.' (in launchpad) |
| Messages | `Messaging` + own `MessagePopover` (BaseController) | `macros:MessageButton` | none | message button |

### Freestyle-only extras (things Fiori elements floorplans don't give you)
- **View-state JSONModel** `view` on every page (section, table type, selected count, edit mode, busy).
- **Expression bindings**: `visible="{= ${view>/section} === 'books' }"`, `enabled="{= ${view>/selectedCount} > 0 }"`.
- **Formatters**: `model/formatter.js` (criticality → ValueState, stock icon, ...) and controller formatters (`.formatVisits`).
- **Fragment dialog** with JS validation: `fragment/CreateBookDialog.fragment.xml`, loaded with `this.loadFragment`.
- **Custom control** `control/RatingStars.js`: properties, an event, apiVersion 2 renderer, `IFormContent`.
- **Layout**: DynamicPage (title/snapped/expanded content, pinnable header, footer), FlexBox with wrap, `sap.ui.layout.Grid` (Home).
- **i18n everywhere**: `i18n/i18n.properties`, `getText(key, [args])`, `formatMessage`.
- **Freestyle filling gaps**: the Author ComboBox on Detail A (see Common errors #7).

---

## 3. Smart controls (V2) vs. building blocks (V4) vs. Fiori elements

| | sap.ui.comp smart controls | sap.fe.macros building blocks | Fiori elements floorplan (LR/OP/ALP) |
|---|---|---|---|
| OData | V2 only | V4 only | V4 (also V2 for the old FE V2) |
| Status at SAP | maintained, no new features for V4 | **recommended** for custom pages in new apps (Flexible Programming Model) | **recommended** default for new apps |
| Layout freedom | full (any view) | full (custom page) | fixed floorplan + extension points |
| Code you write | more: wiring, dialogs, save logic, messages | less: navigation, actions, dialogs, messages are built in | least |
| Annotations | many, plus some V2-only (`@sap.hierarchy.*`, `@Analytics.Measure`) | V4 vocabularies only | V4 vocabularies only |
| Runtime changes | many properties changeable at runtime (liveMode, editable) | many settings are templating-time (change + reload) | manifest + annotations |
| Learning value | see how each piece is wired | see how FE composes the same pieces | see the result |

**When to use what**
- New app, standard pattern (list → object, analytics) → **Fiori elements V4** (books_list, book-sales-alp).
- New app, custom layout but standard behaviour → **FPM custom page with building blocks** (Page B).
- Existing OData V2 backend / legacy app maintenance → **smart controls** (Page A).
- Completely custom UX (games, wizards, dashboards) → plain sap.m / sap.f controls (Home page, app/book).

---

## 4. Click path: try every feature

**Home** (`#/`)
1. KPIs (FlexBox) and the low-stock list are live from V4. Click a book → Detail B.
2. Scroll down → the title shows the snapped text. Pin the header (pin icon).
3. Tile footers count visits (app-wide JSONModel `app`).

**Page A, Books** (`#/classic`)
1. Only 9 books: the default filter Status = Available/Low/Out hides *Eleonora*. Click **Restore** / **Clear**.
2. Author → value help icon → pick Edgar Allan Poe → **Go**. Genre = single-select dropdown.
3. Type `moors` in Search → Go (CAP `$search`, `@cds.search`).
4. Toggle **Live mode** → filters apply immediately, no Go needed.
5. **Adapt Filters** → add "Stock".
6. Switch **In stock only** → Go → Catweazle and Usher disappear (custom filter field).
7. Table gear → hide/move columns, sort by Price, group by Genre. Export icon → xlsx.
8. Title **Standard ▾** → Save As "My view" (with your filters + columns) → reload → choose it again.
9. Select one row → **Add Stock** → 5 → stock grows (V2 function import `Books_addStock`).
10. **Create** → type `BK-42` → red field "Use the format BK-0000" → fix → click stars → Create → Detail A.
11. **Grid** toggle → GridTable with a fixed first column and a row-action arrow.

**Page A, Sales Analytics**
1. Chart: chart-type button (bar/line/donut), **View By** (drill down by Channel), legend, zoom, full screen, settings.
2. Click the **West** bar → strip "Table filtered by chart selection: West", table shows 47 rows. Close the strip to reset.
3. Table gear → Group by Region → subtotals. Totals at the bottom.

**Page A, Genre Tree:** expand Speculative → Horror/Fantasy (requests `parentCode eq 'SPE'`).

**Detail A** (row press)
1. Display mode: SmartFields in display, Book No. is a SmartLink inside the launchpad.
2. **Edit** → mandatory asterisks, Genre/Status selects, DatePicker, Price + Currency with value help, TextArea.
3. Change the title → title bar updates live (TwoWay) → **Save** → toast "Changes saved".
4. Edit → Book No. `BK-0001` → Save → red field + message button "1" → open it → **Cancel**.

**Page B** (`#/blocks`): same sections
1. **Show Details** (table toolbar) reveals the `#Medium/#Low` columns.
2. **Minimum stock** filter (custom FilterField) → 20 → Go.
3. **Hide discontinued** → Eleonora disappears (beforeRebindTable).
4. Select a row → **Add Stock** → FE builds the parameter dialog. Select Eleonora → button disabled (`Core.OperationAvailable`).
5. **Open Selected** = custom action. Click a row → Detail B (manifest navigation).
6. Sales: click a bar → Region filter gets "West", chart + table filter, variant shows `Standard*`.
7. Genre Tree: V4 tree (`$apply=…TopLevels`).

**Detail B:** three forms from FieldGroups, rating stars from `UI.DataPoint#rating`. Edit → Author has an F4
value help (V4) → change Stock → Save → Stock Value recalculated.

**Launchpad** (`/launchpad.html`): tile "Books Freestyle Lab" → Page A → click a Book No. link → navigates to Books Manager.

---

## 5. Common errors and fixes (most of them hit while building this app)

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | View changes don't show up | FE view cache | add `?sap-ui-xx-viewCache=false` |
| 2 | Smart control empty, no columns, console: model is not V2 | default model is V4 | `setModel(v2Model)` on the page/container (not the FE view) |
| 3 | SmartChart / AnalyticalTable empty or flat | entity not analytical in V2 | `@Aggregation.ApplySupported.PropertyRestrictions: true` + `@Analytics.Dimension/Measure` + `@Aggregation.default`; check `sap:semantics="aggregate"` in V2 `$metadata` |
| 4 | macros:Chart "no data" | V4 entity has no ApplySupported/CustomAggregate | see annotations.cds section 4 |
| 5 | Variants don't save, console "LrepConnector failed" | no flex storage standalone | bootstrap `data-sap-ui-flexibility-services='[{"connector":"LocalStorageConnector"}]'` (the attribute is `flexibility-services`, not `flex-connectors`) |
| 6 | "Element … is not a valid Form content" | custom control in a SmartForm/Form | add `interfaces: ["sap.ui.core.IFormContent"]` to the control metadata |
| 7 | SmartField for `writer_ID` shows "2" without F4 | SmartField renders no value help for this Edm.Int32 key (String codes work; SmartFilterBar works) | freestyle ComboBox (Detail A) or a String key |
| 8 | "Edit is only allowed for draft or sticky session supported services" | `editFlow.editDocument` on a non-draft service | toggle `ui>/isEditable` yourself (Detail B) or use a draft service |
| 9 | Non-draft V4: every field change is saved immediately | FE page binding uses `$$updateGroupId: "$auto"` | own `bindElement` with a deferred `$$updateGroupId` + `submitBatch` (Detail B) |
| 10 | Grid/Tree/Analytical table shows only 5 rows | default visibleRowCount | inner table with `<rowmodes:Fixed rowCount="10"/>` / `<rowmodes:Auto/>` (namespace `sap.ui.table.rowmodes`) |
| 11 | `tableType="GridTable"` flagged | SmartTable enum is `Table` | `tableType="Table"` |
| 12 | Chart squashed to a thin strip | parent `VBox fitContainer="true"` shrinks it | remove `fitContainer` |
| 13 | macros:Table shows "Let's get some results" | custom pages wait for Go | `initialLoad="true"` |
| 14 | Value help dialog empty until Go | `preventInitialDataFetchInValueHelpDialog` (default true) | set it to `false` in ControlConfiguration |
| 15 | Value help not opening at all | no `Common.ValueList` on the FK, or annotation on the wrong element | annotate the association (`writer`), CAP copies it to `writer_ID`; check `$metadata` |
| 16 | V2 save returns 200 but nothing saved | error inside the `$batch` | check `__batchResponses` (DetailA.controller.js) |
| 17 | SmartLink opens the target with lots of filters | SmartLink passes **all** row properties as parameters | inside one-target links it navigates directly; restrict with SmartLink `beforePopoverOpens` → `setSemanticAttributes` |
| 18 | Console "failed to load Component-preload.js" | normal in development (no build) | ignore, or `ui5 build` |
