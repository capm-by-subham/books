using AnalyticsService as service from '../../srv/analytics-service';

// Every annotation below has a comment in the form:
//   [WHAT] what it does  [WHERE] where it appears in the ALP  [TRY] what to change to see the effect
// ALP = Analytical List Page. Its parts: filter bar (visual or compact) at the top, KPI tags in the
// header, then a CHART (top) and a TABLE (bottom) = "hybrid view".
// After editing this file, cds watch restarts by itself — just reload the browser tab.
//
// Note: the aggregation annotations in section A are also read by the CAP SERVER (to answer $apply
// requests). They live here so everything is in one place; cds serve/watch loads app/*.cds too.


// =====================================================================================
// A. AGGREGATION BASICS
// =====================================================================================

annotate service.BookSales with @(
  // [WHAT] Aggregation.ApplySupported: "this entity understands $apply" + which properties may be
  //        grouped (dimensions) and aggregated (measures). Without it the ALP shows no chart and
  //        the table is a plain list.
  // [WHERE] everything analytical: chart, visual filters, table grouping/totals, KPIs
  // [TRY] remove 'channel_code' from GroupableProperties -> chart 'Drill Down' no longer offers Channel
  Aggregation.ApplySupported: {
    // only what CAP Node.js really supports (no topcount/search/compute, see ALP_GUIDE.md)
    Transformations       : ['aggregate', 'groupby', 'filter', 'concat', 'identity'],
    GroupableProperties   : [
      year, quarter, yearMonth, saleDate,
      region_code, regionName, country,
      channel_code, channelName,
      book_ID, bookTitle, bookNo,
      author_ID, authorName,
      currency_code, revenueCriticality
    ],
    AggregatableProperties: [
      { Property: revenue },
      { Property: quantity },
      { Property: discount },
      { Property: margin },
      { Property: target },
      { Property: cost }
    ]
  },

  // [WHAT] Analytics.AggregatedProperty: a NAMED measure = property + aggregation method, chosen
  //        by the UI. Used in charts via DynamicMeasures (UI5 >= 1.106). The server needs nothing
  //        special: the UI sends e.g. aggregate(revenue with sum as totalRevenue).
  // [WHERE] main chart (Revenue by Region) and the 'Avg Discount' measure in the chart settings
  // [TRY] change AggregationMethod of #avgDiscount to 'max' -> the chart shows the highest discount
  Analytics.AggregatedProperty #totalRevenue : {
    Name                : 'totalRevenue',
    AggregationMethod   : 'sum',
    AggregatableProperty: revenue,
    ![@Common.Label]    : 'Total Revenue'
  },
  Analytics.AggregatedProperty #totalQuantity: {
    Name                : 'totalQuantity',
    AggregationMethod   : 'sum',
    AggregatableProperty: quantity,
    ![@Common.Label]    : 'Copies Sold'
  },
  Analytics.AggregatedProperty #avgDiscount  : {
    Name                : 'avgDiscount',
    AggregationMethod   : 'average',
    AggregatableProperty: discount,
    ![@Common.Label]    : 'Avg Discount'
  },
  Analytics.AggregatedProperty #totalMargin  : {
    Name                : 'totalMargin',
    AggregationMethod   : 'sum',
    AggregatableProperty: margin,
    ![@Common.Label]    : 'Total Margin'
  },
  Analytics.AggregatedProperty #totalTarget  : {
    Name                : 'totalTarget',
    AggregationMethod   : 'sum',
    AggregatableProperty: target,
    ![@Common.Label]    : 'Total Target'
  },

  // [WHAT] Aggregation.CustomAggregate: the measure is aggregated BY THE SERVER with its default
  //        method (@Aggregation.default below). The UI just sends aggregate(revenue) and doesn't
  //        need to know it's a sum. Used in charts via Measures and by the analytical TABLE (totals).
  //        Difference to AggregatedProperty: CustomAggregate = server decides (one method per
  //        property); AggregatedProperty = UI decides (several named measures per property).
  // [WHERE] table totals, line/donut/stacked/combination charts, visual filters, KPI tags
  // [TRY] change discount's @Aggregation.default from #AVG to #MAX -> 'Avg Discount' KPI shows the maximum
  Aggregation.CustomAggregate #revenue : 'Edm.Decimal',
  Aggregation.CustomAggregate #quantity: 'Edm.Int32',
  Aggregation.CustomAggregate #discount: 'Edm.Decimal',
  Aggregation.CustomAggregate #margin  : 'Edm.Decimal',
  Aggregation.CustomAggregate #target  : 'Edm.Decimal',
  Aggregation.CustomAggregate #cost    : 'Edm.Decimal'
);

annotate service.BookSales with {
  // [WHAT] @Aggregation.default: the method the SERVER uses for a custom aggregate (CAP annotation)
  revenue  @Aggregation.default: #SUM;
  quantity @Aggregation.default: #SUM;
  discount @Aggregation.default: #AVG;
  margin   @Aggregation.default: #SUM;
  target   @Aggregation.default: #SUM;
  cost     @Aggregation.default: #SUM;

  // [WHAT] @Analytics.Measure / @Analytics.Dimension: old tags marking a property as a number to
  //        aggregate or a "by" field. The OData vocabulary now marks them DEPRECATED (replaced by
  //        @Analytics.AnalyticalContext), and Fiori V4 reads neither: it only uses ApplySupported (above).
  //        So they are not used here — the compiler would warn about them.

  // [WHAT] @title = Common.Label: names of dimensions and measures
  // [WHERE] chart axis/legend, table headers, filter labels, chart 'Drill Down' list
  // [TRY] rename 'Region' to 'Sales Region' -> axis title and filter label change
  saleDate           @title: 'Sale Date';
  // [WHAT] Common.IsCalendarYear: the 4-character string is a year (no "2,026" number formatting)
  year               @title: 'Year'  @Common.IsCalendarYear;
  quarter            @title: 'Quarter';
  yearMonth          @title: 'Month';
  country            @title: 'Country';
  quantity           @title: 'Copies';
  revenue            @title: 'Revenue';
  discount           @title: 'Discount %';
  cost               @title: 'Cost';
  margin             @title: 'Margin';
  target             @title: 'Target';
  currency           @title: 'Currency';
  bookNo             @title: 'Book No.';
  bookTitle          @title: 'Book Title';
  authorName         @title: 'Author Name';
  regionName         @title: 'Region Name';
  channelName        @title: 'Channel Name';
  revenueCriticality @title: 'Revenue Status'  @UI.Hidden;
  ID                 @UI.Hidden;

  // [WHAT] Common.Text + TextArrangement: show the NAME next to/instead of the code. For charts the
  //        text must be a property of the SAME entity (that's why regionName etc. are copied into
  //        BookSales in srv/analytics-service.cds — texts via associations don't work in V4 charts)
  // [WHERE] chart axis "West" instead of "W", table, filters
  // [TRY] change region_code to #TextFirst -> "West (W)"
  // (annotations on the association 'region' are copied by CAP to its foreign key region_code)
  region       @title: 'Region'   @Common.Text: regionName   @Common.TextArrangement: #TextOnly;
  channel      @title: 'Channel'  @Common.Text: channelName  @Common.TextArrangement: #TextOnly;
  book         @title: 'Book'     @Common.Text: bookTitle    @Common.TextArrangement: #TextOnly;
  author_ID    @title: 'Author'   @Common.Text: authorName   @Common.TextArrangement: #TextOnly;

  // [WHAT] Measures.ISOCurrency: amounts are shown with their currency ("1,234.56 EUR")
  // [WHERE] table columns Revenue/Margin/Target, chart tooltips, KPI tag
  // [TRY] remove it from revenue -> plain numbers without EUR
  revenue  @Measures.ISOCurrency: currency_code;
  margin   @Measures.ISOCurrency: currency_code;
  target   @Measures.ISOCurrency: currency_code;
  cost     @Measures.ISOCurrency: currency_code;
  quantity @Measures.Unit: 'pcs';
  // [WHAT] @Semantics.currencyCode (CAP): when the UI aggregates the currency itself, CAP returns
  //        'EUR' if all rows share it, otherwise null — so amounts in different currencies are never
  //        silently added up. All sales are in EUR (reporting currency), so you always see EUR.
  currency @Semantics.currencyCode;
};

annotate service.Regions with {
  code @title: 'Region'  @Common.Text: name  @Common.TextArrangement: #TextOnly;
};
annotate service.Channels with {
  code @title: 'Channel' @Common.Text: name  @Common.TextArrangement: #TextOnly;
};
annotate service.Books with {
  ID    @title: 'Book' @Common.Text: title  @Common.TextArrangement: #TextOnly;
  title @title: 'Title';
};
annotate service.Authors with {
  ID   @title: 'Author' @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name @title: 'Name';
};


// =====================================================================================
// B. MAIN CHART (+ alternative charts)
// =====================================================================================

annotate service.BookSales with @(
  // [WHAT] UI.Chart (no qualifier) = the DEFAULT chart of the ALP (referenced by the
  //        SelectionPresentationVariant#default in section D). Measures [revenue] = the custom
  //        aggregate (section A). (A chart with DynamicMeasures: UI.Chart#vsTarget below.)
  // [WHERE] the chart above the table: "Revenue by Region" columns, biggest region first
  // [TRY] ChartType: #Bar -> horizontal bars; or use the chart-type button in the chart toolbar
  UI.Chart: {
    Title              : 'Revenue by Region',
    ChartType          : #Column,
    Dimensions         : [region_code],
    Measures           : [revenue],
    // [WHAT] DimensionAttributes / MeasureAttributes: the ROLE of each field
    //        #Category = x-axis, #Series = colour split, #Axis1/#Axis2 = which value axis
    DimensionAttributes: [{ Dimension: region_code, Role: #Category }],
    // [WHAT] a DataPoint in MeasureAttributes would normally give semantic colours (red/green by
    //        criticality). Not supported in Fiori elements V4 charts (official restriction) -> the
    //        criticality is shown in the TABLE (section C) and the KPI tags (section F) instead.
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },

  // ---- alternative charts: switch the ALP to one of them by changing the Visualizations of
  //      UI.PresentationVariant (section D) from '@UI.Chart' to e.g. '@UI.Chart#byMonth'.
  //      They are also used by the KPI cards (section F).

  // [WHAT] Line chart over time; Measures (not DynamicMeasures) = uses the CustomAggregates
  // [WHERE] KPI 'Revenue' -> click the tag -> card shows this chart
  // [TRY] set it as the main chart (section D) -> revenue vs target per month, Q4 peaks visible
  UI.Chart #byMonth: {
    Title              : 'Revenue per Month',
    ChartType          : #Line,
    Dimensions         : [yearMonth],
    Measures           : [revenue, target],
    DimensionAttributes: [{ Dimension: yearMonth, Role: #Category }],
    MeasureAttributes  : [
      { Measure: revenue, Role: #Axis1 },
      { Measure: target,  Role: #Axis1 }
    ]
  },

  // [WHAT] Donut: share of each channel in the total
  // [WHERE] KPI 'Avg Discount' -> click the tag -> card
  // [TRY] set it as the main chart (section D)
  UI.Chart #byChannel: {
    Title              : 'Revenue by Channel',
    ChartType          : #Donut,
    Dimensions         : [channel_code],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: channel_code, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },

  // [WHAT] Stacked columns: region on the x-axis (#Category), channel as coloured stack parts (#Series)
  // [TRY] set it as the main chart (section D); swap the Roles -> channels on the x-axis
  UI.Chart #regionByChannel: {
    Title              : 'Revenue by Region and Channel',
    ChartType          : #ColumnStacked,
    Dimensions         : [region_code, channel_code],
    Measures           : [revenue],
    DimensionAttributes: [
      { Dimension: region_code,  Role: #Category },
      { Dimension: channel_code, Role: #Series }
    ],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },

  // [WHAT] Combination: first measure as columns, second as a line -> actual vs target at a glance.
  //        Uses DynamicMeasures = the named Analytics.AggregatedProperty measures from section A
  //        (the UI sends "aggregate(revenue with sum as totalRevenue)").
  //        Note: a SortOrder on a DynamicProperty is ignored by the chart in UI5 1.153, so charts
  //        that must be sorted by their measure use Measures (custom aggregates) instead.
  // [TRY] set it as the main chart (section D); drill down to Quarter
  UI.Chart #vsTarget: {
    Title              : 'Revenue vs Target',
    ChartType          : #Combination,
    Dimensions         : [year],
    DynamicMeasures    : ['@Analytics.AggregatedProperty#totalRevenue', '@Analytics.AggregatedProperty#totalTarget'],
    DimensionAttributes: [{ Dimension: year, Role: #Category }],
    MeasureAttributes  : [
      { DynamicMeasure: '@Analytics.AggregatedProperty#totalRevenue', Role: #Axis1 },
      { DynamicMeasure: '@Analytics.AggregatedProperty#totalTarget',  Role: #Axis2 }
    ]
  }

  // DRILLDOWN (year -> quarter -> month): there is no extra annotation for it in V4. Every property
  // in GroupableProperties (section A) can be used: select a column in the chart, click 'Drill Down'
  // in the chart toolbar and pick Year, then Quarter, then Month. The breadcrumbs above the chart
  // let you go back up.
);


// =====================================================================================
// C. TABLE
// =====================================================================================

annotate service.BookSales with @(
  // [WHAT] UI.LineItem: the table columns (secondary visualization of the ALP)
  // [WHERE] table below the chart
  // [TRY] reorder entries; add { Value: country }
  UI.LineItem: [
    // [WHAT] DataFieldForIntentBasedNavigation: a toolbar button that opens ANOTHER app
    //        (semantic object 'Books' -> the Books app), passing the selected row's bookNo
    // [WHERE] table toolbar 'Open Book' (select one sale row first; only in the launchpad, see section G)
    // [TRY] change Action to 'manage' -> button disabled (no such target in launchpad.html)
    {
      $Type         : 'UI.DataFieldForIntentBasedNavigation',
      SemanticObject: 'Books',
      Action        : 'display',
      Label         : 'Open Book',
      RequiresContext: true
    },
    { Value: bookNo },
    { Value: book_ID },
    { Value: author_ID },
    { Value: region_code },
    { Value: channel_code },
    { Value: saleDate },
    { Value: quantity },
    // [WHAT] Criticality on a column: red = loss, orange = below target, green = on target
    //        (path to a per-row field; fine in tables, not supported in V4 charts/visual filters)
    // [WHERE] 'Revenue' column colours + icons on single sale rows (not on group/total rows)
    // [TRY] CriticalityRepresentation: #WithoutIcon
    {
      Value                    : revenue,
      Criticality              : revenueCriticality,
      CriticalityRepresentation: #WithIcon
    },
    { Value: target },
    { Value: margin },
    { Value: discount }
  ],

  // [WHAT] UI.HeaderInfo: singular/plural name of one row
  // [WHERE] table title "Sales (399)", Object Page of a single sale
  // [TRY] TypeNamePlural: 'Sale Lines'
  UI.HeaderInfo: {
    TypeName      : 'Sale',
    TypeNamePlural: 'Sales',
    Title         : { Value: bookTitle },
    Description   : { Value: saleDate }
  },

  // detail page of one sale line (generated by Fiori tools; reached by clicking a single row)
  UI.Facets: [{ $Type: 'UI.ReferenceFacet', ID: 'SaleDetails', Label: 'Sale', Target: '@UI.FieldGroup#Sale' }],
  UI.FieldGroup #Sale: {
    Data: [
      { Value: bookNo }, { Value: book_ID }, { Value: author_ID }, { Value: saleDate },
      { Value: region_code }, { Value: country }, { Value: channel_code },
      { Value: quantity }, { Value: revenue }, { Value: target }, { Value: discount },
      { Value: cost }, { Value: margin }
    ]
  }
);


// =====================================================================================
// D. PRESENTATION VARIANT / SELECTION VARIANTS
// =====================================================================================

annotate service.BookSales with @(
  // [WHAT] UI.PresentationVariant: WHICH visualizations to show and HOW (sort, group, top N).
  //        For the ALP the first chart in Visualizations is the main chart, the LineItem the table.
  //        The manifest points the ALP "primary" (chart) area to this annotation.
  // [WHERE] the ALP chart area (manifest "primary"): Revenue by Region, biggest region first
  // [TRY] '@UI.Chart' -> '@UI.Chart#byMonth' (or #byChannel, #regionByChannel, #vsTarget): another main chart
  UI.PresentationVariant: {
    Text          : 'Default',
    SortOrder     : [{ Property: revenue, Descending: true }],
    Visualizations: ['@UI.Chart', '@UI.LineItem']
  },

  // [WHAT] a second PresentationVariant for the TABLE: initial grouping and totals
  //        (the manifest points the ALP "secondary" (table) area to it)
  // [WHERE] table grouped by Region with a total row per group and a grand total
  // [TRY] GroupBy: [channel_code] -> grouped by channel; remove Total -> no sum rows
  UI.PresentationVariant #table: {
    Text          : 'Sales Table',
    GroupBy       : [region_code],
    Total         : [revenue, quantity, margin, target],
    SortOrder     : [{ Property: saleDate, Descending: true }],
    Visualizations: ['@UI.LineItem']
  },

  // [WHAT] Top N: MaxItems limits the chart to the N biggest values (with the SortOrder)
  // [WHERE] KPI 'Top Books' card (section F) shows only the 5 best-selling books
  // [TRY] MaxItems: 3
  UI.PresentationVariant #top5Books: {
    Text          : 'Top 5 Books',
    MaxItems      : 5,
    SortOrder     : [{ Property: revenue, Descending: true }],
    Visualizations: ['@UI.Chart#topBooks']
  },
  UI.Chart #topBooks: {
    Title              : 'Top Books by Revenue',
    ChartType          : #Bar,
    Dimensions         : [book_ID],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: book_ID, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },

  // [WHAT] UI.SelectionVariant: a named, predefined FILTER (property + range)
  // [WHERE] used by the KPI tags (section F): each KPI only counts these rows
  // [TRY] change Low: '2026' to '2025' -> the 'Revenue 2026' KPI shows last year
  UI.SelectionVariant #currentYear: {
    Text         : 'Current Year (2026)',
    SelectOptions: [{ PropertyName: year, Ranges: [{ Sign: #I, Option: #EQ, Low: '2026' }] }]
  },
  UI.SelectionVariant #online: {
    Text         : 'Online Only',
    SelectOptions: [{ PropertyName: channel_code, Ranges: [{ Sign: #I, Option: #EQ, Low: 'ONL' }] }]
  },

  // [WHAT] UI.SelectionPresentationVariant: filter (SelectionVariant) + layout (PresentationVariant)
  //        in one = a complete "view". The ALP docs allow it for the chart area ("primary") instead of
  //        a PresentationVariant. Tested with UI5 1.153: the chart then ignores the SortOrder (regions
  //        come A–Z), so the manifest uses UI.PresentationVariant and this SPV is an alternative.
  //        Note: an ALP has ONE chart + ONE table; it doesn't support tabs like the List Report.
  // [WHERE] not shown by default
  // [TRY] manifest primary annotationPath -> "com.sap.vocabularies.UI.v1.SelectionPresentationVariant#default"
  //       and compare the bar order
  UI.SelectionPresentationVariant #default: {
    Text               : 'Revenue by Region',
    SelectionVariant   : {
      Text         : 'All Sales',
      SelectOptions: []
    },
    PresentationVariant: {
      // [TRY] Descending: false -> smallest region first
      SortOrder     : [{ Property: revenue, Descending: true }],
      Visualizations: ['@UI.Chart']
    }
  }
);


// =====================================================================================
// E. FILTER BAR: COMPACT + VISUAL FILTERS
// =====================================================================================

annotate service.BookSales with @(
  // [WHAT] UI.SelectionFields: the filter fields (compact filter bar) = also the candidates for visual filters
  // [WHERE] filter bar; switch 'Visual' <-> 'Compact' with the toggle button at the top right of the filter bar
  // [TRY] remove author_ID -> no Author filter
  UI.SelectionFields: [year, region_code, channel_code, book_ID, author_ID]
);

// HOW A VISUAL FILTER IS WIRED (for region_code):
//   filter field region_code
//     -> @Common.ValueList#visualFilter  (CollectionPath 'BookSales', PresentationVariantQualifier 'vfRegion')
//       -> @UI.PresentationVariant#vfRegion  (on BookSales: Visualizations ['@UI.Chart#vfRegion'], sort)
//         -> @UI.Chart#vfRegion  (Bar chart: Dimensions [region_code], Measures [revenue])
//   + manifest: controlConfiguration > @...SelectionFields > filterFields > region_code > visualFilter
//               > valueList: "com.sap.vocabularies.Common.v1.ValueList#visualFilter"
//   Clicking a bar -> the bar's region_code (ValueListParameterInOut) becomes the filter value.
// The UNqualified Common.ValueList stays the normal value help (compact filter / dialog).

annotate service.BookSales with {
  // [WHAT] visual filter for Region: a bar chart of revenue per region inside the filter bar
  // [WHERE] filter bar (visual mode), first chart 'Revenue by Region'
  // [TRY] click the 'West' bar -> chart + table + other visual filters show West only
  region @Common.ValueList #visualFilter: {
    CollectionPath              : 'BookSales',
    PresentationVariantQualifier: 'vfRegion',
    Parameters                  : [
      { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: region_code, ValueListProperty: 'region_code' },
      // [WHAT] ValueListParameterIn: the visual filter chart RESPECTS this other filter. Without it a
      //        visual filter ignores the rest of the filter bar (it would show all years here).
      // [TRY] remove the year line -> the Region bars show all-years revenue, while the main chart shows 2026
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: year, ValueListProperty: 'year' },
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: channel_code, ValueListProperty: 'channel_code' }
    ]
  }
  // [WHAT] normal value help (compact filter bar and the value-help icon of the visual filter)
  // [TRY] remove ValueListWithFixedValues -> a dialog instead of a dropdown in compact mode
  @Common.ValueList: {
    CollectionPath: 'Regions',
    Parameters    : [{ $Type: 'Common.ValueListParameterInOut', LocalDataProperty: region_code, ValueListProperty: 'code' }]
  }
  @Common.ValueListWithFixedValues;

  // [WHAT] visual filter for Channel (bar chart: donut is NOT supported in visual filters)
  // [TRY] click 'Online' -> everything filters to online sales
  channel @Common.ValueList #visualFilter: {
    CollectionPath              : 'BookSales',
    PresentationVariantQualifier: 'vfChannel',
    Parameters                  : [
      { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: channel_code, ValueListProperty: 'channel_code' },
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: year, ValueListProperty: 'year' },
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: region_code, ValueListProperty: 'region_code' }
    ]
  }
  @Common.ValueList: {
    CollectionPath: 'Channels',
    Parameters    : [{ $Type: 'Common.ValueListParameterInOut', LocalDataProperty: channel_code, ValueListProperty: 'code' }]
  }
  @Common.ValueListWithFixedValues;

  // [WHAT] visual filter for Year as a BAR chart. A LINE visual filter needs a real date dimension
  //        (Edm.Date/DateTimeOffset); year is an Integer, so #Line shows "Invalid data type".
  // [WHERE] filter bar (visual mode), 'Revenue by Year'
  // [TRY] change ChartType in UI.Chart#vfYear to #Line -> see the error message in the filter bar
  year @Common.ValueList #visualFilter: {
    CollectionPath              : 'BookSales',
    PresentationVariantQualifier: 'vfYear',
    Parameters                  : [
      { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: year, ValueListProperty: 'year' },
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: region_code, ValueListProperty: 'region_code' },
      { $Type: 'Common.ValueListParameterIn', LocalDataProperty: channel_code, ValueListProperty: 'channel_code' }
    ]
  }
  // [WHAT] Common.FilterDefaultValue: initial filter value when the app opens
  // [WHERE] Year filter preset to 2026 (visual filter: the 2026 bar is selected)
  // [TRY] change it to 2025, or remove it -> all years
  @Common.FilterDefaultValue: '2026';

  // compact-only filters with value help dialogs
  book @Common.ValueList: {
    CollectionPath: 'Books',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: book_ID, ValueListProperty: 'ID' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'bookNo' }
    ]
  };
  author_ID @Common.ValueList: {
    CollectionPath: 'Authors',
    Parameters    : [{ $Type: 'Common.ValueListParameterInOut', LocalDataProperty: author_ID, ValueListProperty: 'ID' }]
  };
};

// the small charts INSIDE the visual filter bar (PresentationVariant -> Chart, on the value-list entity BookSales)
annotate service.BookSales with @(
  UI.PresentationVariant #vfRegion : {
    SortOrder     : [{ Property: revenue, Descending: true }], // biggest bar first
    Visualizations: ['@UI.Chart#vfRegion']
  },
  UI.Chart #vfRegion : {
    Title              : 'Revenue by Region',
    ChartType          : #Bar,
    Dimensions         : [region_code],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: region_code, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },
  UI.PresentationVariant #vfChannel: {
    SortOrder     : [{ Property: revenue, Descending: true }],
    Visualizations: ['@UI.Chart#vfChannel']
  },
  UI.Chart #vfChannel: {
    Title              : 'Revenue by Channel',
    ChartType          : #Bar,
    Dimensions         : [channel_code],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: channel_code, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },
  UI.PresentationVariant #vfYear   : {
    SortOrder     : [{ Property: year, Descending: true }], // newest year on top
    Visualizations: ['@UI.Chart#vfYear']
  },
  UI.Chart #vfYear   : {
    Title              : 'Revenue by Year',
    ChartType          : #Bar,
    Dimensions         : [year],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: year, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  }
);


// =====================================================================================
// F. KPI TAGS (header)
// =====================================================================================
// Wiring: manifest "keyPerformanceIndicators" { name: { entitySet, qualifier } }
//           -> UI.KPI#qualifier -> DataPoint (value + criticality) + SelectionVariant (which rows)
//                               -> Detail.DefaultPresentationVariant (chart in the KPI card)
//         (The docs also allow a KPI qualifier without UI.KPI to fall back to a SelectionPresentationVariant
//          with that qualifier; with this setup that tag stayed empty, so every KPI here uses UI.KPI.)

annotate service.BookSales with @(
  // [WHAT] KPI 'Revenue 2026': total 2026 revenue, coloured by CriticalityCalculation
  //        (#Maximize: >= ToleranceRangeLowValue green, between the two orange, < DeviationRangeLowValue red)
  // [WHERE] header, next to the page title: tag "Revenue 2026 11.1K" (green); click it -> card with monthly chart
  // [TRY] ToleranceRangeLowValue: 12000 -> the tag turns orange (2026 revenue is ~11,057 EUR)
  UI.KPI #revenue: {
    ID              : 'revenue2026',
    DataPoint       : {
      Title                 : 'Revenue 2026',
      Description           : 'Revenue this year vs. target',
      Value                 : revenue,
      TargetValue           : 10994, // sum of the 2026 targets (see ALP_GUIDE.md)
      CriticalityCalculation: {
        ImprovementDirection  : #Maximize,
        ToleranceRangeLowValue: 10500,
        DeviationRangeLowValue: 9500
      }
    },
    SelectionVariant: {
      SelectOptions: [{ PropertyName: year, Ranges: [{ Sign: #I, Option: #EQ, Low: '2026' }] }]
    },
    Detail          : {
      DefaultPresentationVariant: {
        Visualizations: ['@UI.Chart#byMonth']
      }
    }
  },

  // [WHAT] KPI 'Avg Discount' with #Minimize: lower is better (<= 6 green, 6–10 orange, > 10 red)
  // [WHERE] header tag "Avg Discount 7.1" (orange); click -> donut of revenue by channel
  // [TRY] ToleranceRangeHighValue: 8 -> green
  UI.KPI #discount: {
    ID              : 'avgDiscount2026',
    DataPoint       : {
      Title                 : 'Avg Discount % 2026',
      Value                 : discount,
      CriticalityCalculation: {
        ImprovementDirection   : #Minimize,
        ToleranceRangeHighValue: 6,
        DeviationRangeHighValue: 10
      }
    },
    SelectionVariant: {
      SelectOptions: [{ PropertyName: year, Ranges: [{ Sign: #I, Option: #EQ, Low: '2026' }] }]
    },
    Detail          : {
      DefaultPresentationVariant: {
        Visualizations: ['@UI.Chart#byChannel']
      }
    }
  },

  // [WHAT] KPI with a filter: only ONLINE sales (all years)
  // [WHERE] header tag 'Online Revenue'; click -> monthly line chart
  // [TRY] change 'ONL' to 'PAR' -> partner revenue
  UI.KPI #online: {
    ID              : 'onlineRevenue',
    DataPoint       : {
      Title: 'Online Revenue',
      Value: revenue
    },
    SelectionVariant: {
      SelectOptions: [{ PropertyName: channel_code, Ranges: [{ Sign: #I, Option: #EQ, Low: 'ONL' }] }]
    },
    Detail          : {
      DefaultPresentationVariant: {
        SortOrder     : [{ Property: yearMonth }],
        Visualizations: ['@UI.Chart#byMonth']
      }
    }
  },

  // [WHAT] KPI using MaxItems: the card shows the top 5 books only (PresentationVariant#top5Books)
  // [WHERE] header tag 'Copies Sold'; click -> top 5 books bar chart
  UI.KPI #copies: {
    ID              : 'copiesSold',
    DataPoint       : {
      Title: 'Copies Sold',
      Value: quantity
    },
    SelectionVariant: { SelectOptions: [] },
    Detail          : {
      DefaultPresentationVariant: {
        MaxItems      : 5,
        SortOrder     : [{ Property: revenue, Descending: true }],
        Visualizations: ['@UI.Chart#topBooks']
      }
    }
  }
);


// =====================================================================================
// G. NAVIGATION TO THE BOOKS APP
// =====================================================================================

annotate service.BookSales with {
  // [WHAT] Common.SemanticObject: the value is a link to every app registered for semantic object
  //        'Books' in the launchpad. The link passes bookNo, the SemanticKey of the Books app, so
  //        the Books app opens that book's Object Page directly.
  // [WHERE] table column 'Book No.' (link) -> popover 'Books Manager' -> click; ONLY in app/launchpad.html
  // [TRY] open the ALP via /booksalesalp/index.html (no launchpad): the value is plain text
  bookNo @Common.SemanticObject: 'Books'
  // [WHAT] Common.SemanticObjectMapping: under which NAME the value is passed. Without it the
  //        value of the semantic-object field arrives as "Books=BK-0003" instead of "bookNo=BK-0003".
  // [TRY] remove it -> the Books app opens without selecting the book
         @Common.SemanticObjectMapping: [{ LocalProperty: bookNo, SemanticObjectProperty: 'bookNo' }];
  // Fiori passes ALL fields of the row (ID, currency_code, ...) as parameters. The Books app's
  // inbound in app/books_list/webapp/manifest.json has "additionalParameters": "ignored", so only
  // bookNo arrives (otherwise the sale's ID and currency would end up as filters in the Books app).
};
