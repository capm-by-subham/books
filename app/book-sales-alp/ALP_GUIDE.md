# Analytical List Page (ALP) – learning guide

**Run:** `cds watch` (or `npm run watch-book-sales-alp`), then open

- <http://localhost:4004/booksalesalp/index.html> – the ALP on its own
- <http://localhost:4004/launchpad.html> – launchpad with both apps (needed for navigation to a Book)

All annotations are in `annotations.cds` (sections A–G, each with `[WHAT] [WHERE] [TRY]`), the manifest settings
in `MANIFEST_NOTES.md`. Data: `db/data/my.bookshop-BookSales.csv` (399 sales, Jan 2025 – Sep 2026, all in EUR).
Regenerate it with `node scripts/generate-sales.js` (same seed → same data; `--seed 7` → different data).

Reference numbers (default seed), handy to check what you see:

| | 2025 | 2026 (Jan–Sep) |
|---|---|---|
| Revenue | 12,133.75 EUR | 11,056.58 EUR |
| Target | 12,271.71 EUR | 10,994.03 EUR |
| Margin | 4,883.01 EUR | 4,556.48 EUR |
| Avg discount | 7.27 % | 7.08 % |
| Sale lines | 229 | 170 |

## Feature map

| Feature | Annotation / manifest setting | Where in UI | What to try |
|---|---|---|---|
| Aggregation on/off | `Aggregation.ApplySupported` | everything analytical | remove `channel_code` from GroupableProperties → gone from 'View By' |
| Named measures (UI decides) | `Analytics.AggregatedProperty` + chart `DynamicMeasures` | `UI.Chart#vsTarget` | `AggregationMethod: 'max'` |
| Server measures | `Aggregation.CustomAggregate` + `@Aggregation.default` | main chart, table totals, visual filters, KPIs | discount `#AVG` → `#MAX` |
| Codes → names | `Common.Text` + `TextArrangement` (text on the same entity!) | axis "West", table, filters | `#TextFirst` |
| Currency | `Measures.ISOCurrency`, `@Semantics.currencyCode` | "11,056.58 EUR" | remove ISOCurrency from revenue |
| Year without "2,026" | `Common.IsCalendarYear` on a String(4) | visual filter, table | – |
| Main chart | `UI.Chart` (Column, region) via `UI.PresentationVariant` | chart area | `ChartType: #Bar` |
| Other charts | `UI.Chart#byMonth` (Line), `#byChannel` (Donut), `#regionByChannel` (ColumnStacked), `#vsTarget` (Combination), `#topBooks` (Bar) | KPI cards / switch in PV | put `'@UI.Chart#regionByChannel'` into `UI.PresentationVariant` |
| Chart type at runtime | – (built in) | chart toolbar: chart-type button | pick Line / Pie / Bar |
| Drilldown | any `GroupableProperties` entry | select bar → 'View By' → Quarter; breadcrumb back | West → Quarter → Month |
| Chart filters table | – (built in) | click a bar → table shows only those rows, 'Details (1)' | click West: 170 → 57 sales |
| Sort chart | `PresentationVariant.SortOrder` (`Property: revenue`) | biggest region first | `Descending: false` |
| Top N | `PresentationVariant.MaxItems` | 'Copies Sold' KPI card: top 5 books | `MaxItems: 3` |
| Table columns | `UI.LineItem` | table | add `{ Value: country }` |
| Grouping + totals | `UI.PresentationVariant#table` (`GroupBy`, `Total`) + `AnalyticalTable` | table: groups per region, sub-totals, grand total | `GroupBy: [channel_code]` |
| Row colours | `Criticality: revenueCriticality` (+ `CriticalityRepresentation`) | Revenue column: green/orange/red with icon | `#WithoutIcon` |
| Predefined filters | `UI.SelectionVariant#currentYear`, `#online` | used by KPIs | change `'2026'` to `'2025'` |
| Filter + layout in one | `UI.SelectionPresentationVariant#default` | (alternative primary) | set as manifest `primary` |
| Compact filters | `UI.SelectionFields` | filter bar (compact mode) | remove `author_ID` |
| Visual filters | `Common.ValueList#visualFilter` → `UI.PresentationVariant#vf…` → `UI.Chart#vf…` + manifest `filterFields` | filter bar (visual mode) | click 'West' |
| Visual filters follow each other | `Common.ValueListParameterIn` | Region bars = 2026 values | remove the year `In` → all-years bars |
| Default filter | `Common.FilterDefaultValue: '2026'` | Year = 2026 at start | `'2025'` |
| Visual ↔ compact | manifest `layout: "CompactVisual"`, `initialLayout` | two buttons top right | `initialLayout: "Compact"` |
| Chart / table / hybrid | manifest `views.paths[].defaultPath` | three buttons in the chart/table toolbar | `"secondary"` |
| KPI tags | `UI.KPI#…` (DataPoint + SelectionVariant + Detail) + manifest `keyPerformanceIndicators` | header: R2 / AD% / CS / OR | `ToleranceRangeLowValue: 12000` → orange |
| KPI colour | `DataPoint.CriticalityCalculation` (`#Maximize` / `#Minimize`) | tag colour | `ToleranceRangeHighValue: 8` on discount → green |
| KPI card chart | `UI.KPI.Detail.DefaultPresentationVariant` | click a tag | other chart qualifier |
| Header names | `UI.HeaderInfo` | "Sales (170)" | `TypeNamePlural` |
| Link to another app | `Common.SemanticObject: 'Books'` + `Common.SemanticObjectMapping` | Book No. link (launchpad only) | remove the mapping → Books app opens without the book |
| Button to another app | `UI.DataFieldForIntentBasedNavigation` | 'Open Book' in table toolbar (launchpad only) | `Action: 'manage'` → disabled |

## How the pieces connect

```
                         manifest.json  (sap.fe.templates.ListReport + views.paths = ALP)
                         ├─ primary   ─► UI.PresentationVariant ─► Visualizations ['@UI.Chart', ...]
                         │                 SortOrder / MaxItems           │
                         │                                                ▼
                         │                                   UI.Chart  (Dimensions, Measures,
                         │                                              DimensionAttributes, MeasureAttributes)
                         │                                                │ Measures [revenue]
                         │                                                ▼
                         │          Aggregation.CustomAggregate#revenue + @Aggregation.default: #SUM
                         │          (or DynamicMeasures ─► Analytics.AggregatedProperty#totalRevenue)
                         │                                                │
                         │                                                ▼
                         │                     Aggregation.ApplySupported  ──►  CAP: $apply=groupby((region_code,…),
                         │                     (Groupable / Aggregatable)               aggregate(revenue))
                         ├─ secondary ─► UI.PresentationVariant#table ─► UI.LineItem  (GroupBy, Total)
                         └─ defaultPath: both | primary | secondary

  SelectionVariant ─┐
                    ├─► SelectionPresentationVariant   (filter + layout = one "view"; alternative primary)
  PresentationVariant┘

  VISUAL FILTER (per filter field)
  manifest filterFields.region_code.visualFilter.valueList = "…Common.v1.ValueList#visualFilter"
     ─► region @Common.ValueList#visualFilter  { CollectionPath: 'BookSales',
                                                 PresentationVariantQualifier: 'vfRegion',
                                                 Parameters: InOut region_code, In year, In channel_code }
        ─► UI.PresentationVariant#vfRegion  { SortOrder, Visualizations ['@UI.Chart#vfRegion'] }
           ─► UI.Chart#vfRegion  { Bar, Dimensions [region_code], Measures [revenue] }
  click a bar ─► InOut writes region_code into the filter ─► chart + table + other visual filters reload

  KPI TAG
  manifest keyPerformanceIndicators.revenue { entitySet, qualifier: 'revenue' }
     ─► UI.KPI#revenue { DataPoint (Value revenue, CriticalityCalculation),
                         SelectionVariant (year = 2026),
                         Detail.DefaultPresentationVariant ─► UI.Chart#byMonth (card) }

  NAVIGATION
  bookNo @Common.SemanticObject 'Books' + SemanticObjectMapping bookNo→bookNo
     ─► launchpad resolves intent Books-display ─► app/books_list (inbound, param bookNo)
        ─► Books app sees its SemanticKey bookNo ─► opens Books('BK-0003') Object Page
```

## Click-path checklist

1. **Open** <http://localhost:4004/booksalesalp/index.html>.
   - [ ] Header: 4 KPI tags – R2 11.1k EUR (green), AD% 7.1 (orange), CS 2k pcs, OR 5.9k EUR.
   - [ ] Visual filter bar: Revenue by Year (2026 selected), by Region, by Channel – each shows the top 3 bars.
   - [ ] Chart 'Revenue by Region' (West first), table 'Sales (170)' grouped by region.
2. **Visual filters**
   - [ ] Click 'Online' in 'Revenue by Channel' → the Year and Region bars recalculate at once (In-parameters);
         chart and table grey out until you press **Go** → 'Sales (82)' = online sales 2026.
   - [ ] Click the filter icon "(1)" next to a visual filter title → value-help dialog. Remove the filters again.
3. **Chart click** – click the West column → table shows 57 sales, 'Details (1)' becomes active.
4. **Drilldown** – with West selected: 'View By' → Quarter → breadcrumb "Region / Quarter". Then View By → Month.
   Click 'Region' in the breadcrumb to go back up.
5. **Toggle views** – the three buttons at the right of the toolbar: hybrid / chart only / table only.
6. **Table** – table only: expand 'Region: East'; scroll right: green/orange revenue values, sub-totals per region,
   grand total row (2026: 841 pcs, 11,056.58 EUR, target 10,994.03, margin 4,556.48).
7. **Chart type** – chart toolbar: chart-type button → e.g. Line or Pie.
8. **Compact filter bar** – top right toggle → Year field with token '2026', Region/Channel dropdowns, Book/Author value help.
9. **KPI tags** – click R2 → card: 11.1k vs target 11k, deviation 0.6 %, monthly line chart. Click CS → top 5 books.
10. **Navigate to a Book** – open <http://localhost:4004/launchpad.html> → tile 'Book Sales Analysis' →
    table only → expand a region → click a Book No. (e.g. BK-0003) → The Raven's Object Page in Books Manager.
    Back, select a row, click 'Open Book' → that book.

## Common errors and fixes

| Symptom | Cause | Fix |
|---|---|---|
| No chart, only a table; or "Aggregation not supported" | `Aggregation.ApplySupported` missing / on the wrong entity | annotate the entity set that the ALP shows (`BookSales`) |
| `Result type for custom aggregation of property "x" not found` (HTTP 500) | the UI sent `aggregate(x)` but there's no `@Aggregation.CustomAggregate#x` | add CustomAggregate with the property name as qualifier |
| `Default aggregation for property "x" not found` | CustomAggregate without `@Aggregation.default` | add `x @Aggregation.default: #SUM` |
| `no such function: topcount` | CAP Node.js doesn't support `topcount`/`bottomcount`/`search`/`compute` in `$apply` | use `MaxItems` + `SortOrder` (UI5 sends `$orderby`/`$top`), don't list them in `Transformations` |
| Measure not shown / chart empty | measure not in `AggregatableProperties`, or texts/measures from an **association** (not supported in V4 charts) | copy the value into the fact entity (like `regionName`, `bookTitle`) |
| Codes ("W") instead of names | `Common.Text` points through an association | text must be a property of the same entity |
| Visual filter empty or "Invalid data type – Line charts only support dimensions based on Edm.Date…" | line visual filter on a non-date dimension | use `#Bar` (or a real `Edm.Date` dimension) |
| Visual filter shows other numbers than the chart | visual filters ignore other filters by default | add `Common.ValueListParameterIn` for each filter it should respect |
| Chart/table greyed out after picking a filter | filter bar is not in live mode | press Go |
| Donut visual filter doesn't render | donut is not supported for visual filters | `#Bar` / `#Line` |
| Chart sort order ignored | sorting on a `DynamicProperty`, or primary = SPV | sort by a custom-aggregate `Property` in the PresentationVariant used as primary |
| Years shown as "2,026" | Integer formatting | String(4) + `@Common.IsCalendarYear` |
| Amount totals empty | different currencies in one group (CAP returns null on purpose with `@Semantics.currencyCode`) | one reporting currency, or group by currency |
| 'Open Book' button missing / Book No. not a link | no launchpad (no `sap.ushell` Container) | open via `launchpad.html` |
| Target app gets weird filters (ID, currency …) | Fiori passes all row fields as parameters | `SemanticObjectMapping` + inbound `"additionalParameters": "ignored"` |
| Compiler: "Element region_code has not been found" in `annotate … with { region_code … }` | foreign keys can't be annotated directly | annotate the association (`region`) – CAP copies it to `region_code` |
| `@Analytics.Measure is deprecated` | old vocabulary terms | not needed by Fiori V4; leave them out |
| Console: `S/CUBE is not yet supported`, `LrepConnector`, `Component-preload` | Fiori/UI5 local-preview noise | harmless |
| Console in launchpad.html: `[FUTURE FATAL] Deprecated API … sandbox` | classic sandbox | harmless for local testing |
