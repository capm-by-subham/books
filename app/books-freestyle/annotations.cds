using FreestyleService as service from '../../srv/freestyle-service';

// =================================================================================================
// Annotations for app/books-freestyle, read by BOTH pages:
//   Page A (sap.ui.comp, OData V2): the V2 adapter puts them into /odata/v2/freestyle/$metadata
//                                   (as V4-style <Annotations> + a few sap:* attributes)
//   Page B (sap.fe.macros, OData V4): read from /odata/v4/freestyle/$metadata
// Comment format:  [WHAT] what it does  [WHY] why it's needed  [TRY] change it and reload
//                  [A] / [B] = where you see it on Page A / Page B
// After editing, cds watch restarts by itself — just reload the browser tab.
// =================================================================================================


// =================================================================================================
// 1. BOOKS — labels, texts, value helps, currency, semantic object, field behaviour
// =================================================================================================

annotate service.Books with {
  // [WHAT] @title -> Common.Label: the label of the field everywhere (columns, filters, forms)
  // [TRY] rename 'Title' to 'Book Title' -> column header, filter label and form label change on both pages
  ID          @title: 'ID';
  bookNo      @title: 'Book No.';
  title       @title: 'Title';
  author      @title: 'Author (legacy text)';
  stock       @title: 'Stock';
  price       @title: 'Price';
  currency    @title: 'Currency';
  rating      @title: 'Rating';
  publishedAt @title: 'Published On';
  descr       @title: 'Description'  @UI.MultiLineText; // [WHAT] textarea instead of input in edit mode
  coverUrl    @title: 'Cover URL';
  stockValue  @title: 'Stock Value';
  authorName  @title: 'Author Name';
  genreName   @title: 'Genre Name';
  statusName  @title: 'Status Name';

  // [WHAT] Common.Text + TextArrangement: show the NAME instead of the technical key.
  //        CAP copies annotations on an association (writer) to its foreign key (writer_ID).
  // [WHY]  the text is an own property of Books (authorName), see srv/freestyle-service.cds:
  //        V2 smart controls only show texts that live on the same entity.
  // [A] SmartTable column 'Author' shows "Emily Brontë", SmartFilterBar tokens show names
  // [B] same in macros:Table / FilterBar
  // [TRY] change #TextOnly to #TextFirst -> "Emily Brontë (1)"
  writer      @title: 'Author'  @Common.Text: authorName  @Common.TextArrangement: #TextOnly;
  genre       @title: 'Genre'   @Common.Text: genreName   @Common.TextArrangement: #TextFirst;
  status      @title: 'Status'  @Common.Text: statusName  @Common.TextArrangement: #TextOnly;

  // [WHAT] Common.ValueList: an F4 value help dialog for the field (search + table of authors)
  // [A] SmartFilterBar 'Author' and SmartField 'Author' on Detail A: click the value help icon
  // [B] macros:FilterBar 'Author' and macros:Field on Detail B
  // [TRY] add { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'placeOfBirth' }
  //       -> an extra column 'Place of Birth' in the dialog
  writer      @Common.ValueList: {
    CollectionPath: 'Authors',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: writer_ID, ValueListProperty: 'ID' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };

  // [WHAT] ValueListWithFixedValues: the value help becomes a DROPDOWN (few, fixed values)
  // [A] SmartFilterBar 'Genre'/'Status' = multi-select dropdown; SmartField = Select in edit mode
  // [B] same with the building blocks
  // [TRY] remove @Common.ValueListWithFixedValues from genre -> it becomes an F4 dialog instead
  genre       @Common.ValueListWithFixedValues @Common.ValueList: {
    CollectionPath: 'Genres',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: genre_code, ValueListProperty: 'code' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };
  status      @Common.ValueListWithFixedValues @Common.ValueList: {
    CollectionPath: 'BookStatus',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: status_code, ValueListProperty: 'code' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };
  // (currency_code gets its value help from @sap/cds/common automatically)

  // [WHAT] Measures.ISOCurrency: the amount belongs to a currency -> "11.11 GBP" with the right decimals
  // [A] SmartTable shows "11.11 GBP"; SmartField on Detail A = amount input + currency input side by side
  // [B] same in macros:Table / macros:Field
  // [TRY] remove it from price -> just "11.11"
  price       @Measures.ISOCurrency: currency_code;
  stockValue  @Measures.ISOCurrency: currency_code;
  stock       @Measures.Unit: 'pcs';

  // [WHAT] Common.SemanticObject: "this value identifies a Books object" -> the value becomes a LINK
  //        with a popover listing all apps that can handle "Books" (intent-based navigation)
  // [A] SmartTable renders a SmartLink for 'Book No.'; click it. Inside launchpad.html the popover
  //     offers "Books Manager" (app/books_list, intent Books-display). Standalone: popover without links.
  // [B] macros:Field / Table render the same link
  // [TRY] change 'Books' to 'Nothing' -> the popover shows no targets even in the launchpad
  bookNo      @Common.SemanticObject: 'Books';

  // [WHAT] @mandatory -> Common.FieldControl #Mandatory: asterisk + required check
  // [A] Detail A edit mode: 'Title *', clear it and Save -> error message on the field (from CAP)
  // [B] Detail B edit mode: same
  title       @mandatory;
  bookNo      @mandatory;

  // [WHAT] read-only fields: never an input in edit mode
  // [TRY] remove @readonly from author -> Detail A/B show an input in edit mode
  author      @readonly;
  stockValue  @Core.Computed;
  authorName  @Core.Computed;
  genreName   @Core.Computed;
  statusName  @Core.Computed;
  ID          @Core.Computed; // assigned in srv/freestyle-service.js on CREATE

  // [WHAT] @UI.Hidden: never shown, not even in the table/filter settings
  statusCriticality @UI.Hidden;
  coverUrl          @UI.Hidden;
};

// [WHAT] @cds.search: which fields the free-text search ($search / V2 'search') looks into
// [A] SmartFilterBar 'Search' field (enableBasicSearch)   [B] macros:FilterBar 'Search' field
// [TRY] remove 'descr' -> searching for "moors" no longer finds Wuthering Heights
annotate service.Books with @cds.search: { title, bookNo, author, descr };

annotate service.Books with @(
  // [WHAT] UI.HeaderInfo: how one book / many books are called + the title of a single book
  // [A] SmartTable header falls back to TypeNamePlural; [B] macros:Table header "Books (10)"
  UI.HeaderInfo: {
    TypeName      : 'Book',
    TypeNamePlural: 'Books',
    Title         : { Value: title },
    Description   : { Value: authorName },
    ImageUrl      : coverUrl
  },

  // [WHAT] UI.SelectionFields: filters visible in the filter bar from the start
  // [A] SmartFilterBar (more under 'Adapt Filters')   [B] macros:FilterBar (more under 'Adapt Filters')
  // [TRY] add 'rating' -> a Rating filter appears on both pages
  UI.SelectionFields: [ genre_code, status_code, writer_ID, price, publishedAt ],

  // [WHAT] UI.LineItem: the default columns, in this order
  // [A] SmartTable columns (initiallyVisibleFields can override)   [B] macros:Table columns
  // [TRY] move the 'stock' entry to the top -> Stock becomes the first column
  UI.LineItem: [
    // [WHAT] DataFieldForAction: a toolbar button for the bound action
    // [A] ignored by SmartTable (Page A has its own 'Add Stock' button calling the V2 function import)
    // [B] macros:Table toolbar button 'Add Stock' (enabled when a row is selected) with a parameter dialog
    { $Type: 'UI.DataFieldForAction', Action: 'FreestyleService.addStock', Label: 'Add Stock' },
    { Value: bookNo,      ![@UI.Importance]: #High },
    { Value: title,       ![@UI.Importance]: #High },
    { Value: writer_ID,   ![@UI.Importance]: #High },
    { Value: genre_code,  ![@UI.Importance]: #Medium },
    // [WHAT] Criticality: colours the status (1 red, 2 orange, 3 green) via a path
    // [A] SmartTable shows a coloured ObjectStatus   [B] same in macros:Table
    // [TRY] change Criticality to a constant: Criticality: 1 -> always red
    { Value: status_code, Criticality: statusCriticality, ![@UI.Importance]: #High },
    { Value: stock,       ![@UI.Importance]: #Medium },
    { Value: price,       ![@UI.Importance]: #High },
    { Value: rating,      ![@UI.Importance]: #Low },
    { Value: publishedAt, ![@UI.Importance]: #Low }
  ],

  // [WHAT] UI.PresentationVariant: default sort (+ which LineItem to use)
  // [A] SmartTable initial sort   [B] macros:Table initial sort
  // [TRY] change Descending to true -> Z..A
  UI.PresentationVariant: {
    SortOrder     : [{ Property: title, Descending: false }],
    Visualizations: ['@UI.LineItem']
  },

  // [WHAT] UI.DataPoint #rating with Visualization #Rating: stars (5 = TargetValue)
  // [B] Detail B: the 'Rating' form field shows stars ([A] uses the custom RatingStars control instead)
  UI.DataPoint #rating: {
    Value        : rating,
    Title        : 'Rating',
    TargetValue  : 5,
    Visualization: #Rating
  },

  // [WHAT] UI.FieldGroup: a named group of fields = one form section
  // [A] SmartForm doesn't read FieldGroups itself (only Fiori elements V2 does). Detail A lists the same
  //     fields by hand and each SmartField reads label, value help, currency, mandatory from the annotations.
  // [B] macros:Form metaPath="@com.sap.vocabularies.UI.v1.FieldGroup#General" renders the whole group
  // [TRY] add { Value: rating } to #General -> Detail B shows it in 'General' (Detail A doesn't change)
  UI.FieldGroup #General: {
    Label: 'General',
    Data : [
      { Value: bookNo },
      { Value: title },
      { Value: writer_ID },
      { Value: genre_code },
      { Value: publishedAt },
      { $Type: 'UI.DataFieldForAnnotation', Target: '@UI.DataPoint#rating', Label: 'Rating' }
    ]
  },
  UI.FieldGroup #Pricing: {
    Label: 'Price & Stock',
    Data : [
      { Value: price },
      { Value: stock },
      { Value: status_code, Criticality: statusCriticality },
      { Value: stockValue }
    ]
  },
  UI.FieldGroup #Description: {
    Label: 'Description',
    Data : [ { Value: descr }, { Value: author } ]
  }
);

// [WHAT] Core.OperationAvailable: when is the action allowed? (here: never for discontinued books)
// [B] 'Add Stock' is disabled when a discontinued book (Eleonora) is selected
annotate service.Books actions {
  addStock @(
    Core.OperationAvailable: { $edmJson: { $Ne: [ { $Path: 'in/status_code' }, 'D' ] } },
    Common.SideEffects     : { TargetProperties: ['in/stock', 'in/status_code', 'in/stockValue', 'in/statusName', 'in/statusCriticality'] }
  ) (quantity @title: 'Quantity' @mandatory);
};


// =================================================================================================
// 2. VALUE-HELP ENTITIES
// =================================================================================================

annotate service.Authors with {
  ID   @title: 'Author'  @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name @title: 'Name';
  placeOfBirth @title: 'Place of Birth';
};
annotate service.Genres with {
  code @title: 'Genre'   @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name @title: 'Genre';
};
annotate service.BookStatus with {
  code @title: 'Status'  @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name @title: 'Status';
};


// =================================================================================================
// 3. GENRE TREE — hierarchy for both tree tables
// =================================================================================================

annotate service.GenreTree with {
  code           @title: 'Code';
  name           @title: 'Genre';
  descr          @title: 'Description';
  // [WHAT] V2 hierarchy annotations (become sap:hierarchy-*-for attributes in the V2 $metadata)
  // [WHY]  the V2 tree binding (SmartTable tableType="TreeTable") reads the tree level by level:
  //        $filter=hierarchyLevel eq 0, then parentCode eq 'FIC' when you expand Fiction, ...
  //        The value of each annotation = the name of the NODE property.
  // [A] tab 'Genre Tree': expand Fiction > Speculative > Fantasy
  // [B] not used: macros:TreeTable uses the V4 annotations that @hierarchy generates
  // [TRY] remove @sap.hierarchy.drill.state.for -> every node gets an expand arrow, even leaves
  code           @sap.hierarchy.node.for       : 'code';
  parentCode     @sap.hierarchy.parent.node.for: 'code'   @title: 'Parent';
  hierarchyLevel @sap.hierarchy.level.for      : 'code'   @title: 'Level';
  drillState     @sap.hierarchy.drill.state.for: 'code'   @title: 'Drill State';
  // the V4 hierarchy helpers are not interesting for users
  parent         @UI.Hidden;
};

annotate service.GenreTree with @(
  UI.HeaderInfo: { TypeName: 'Genre', TypeNamePlural: 'Genres', Title: { Value: name } },
  UI.LineItem  : [ { Value: name }, { Value: code }, { Value: descr } ]
);


// =================================================================================================
// 4. SALES ANALYTICS — measures/dimensions for charts and the analytical table
// =================================================================================================

annotate service.BookSalesAnalytics with @(
  // ---- V4 (Page B, macros:Chart + AnalyticalTable) ----
  // [WHAT] Aggregation.ApplySupported: "this entity answers $apply" + groupable/aggregatable props.
  //        Written flattened (one line per sub-property) so it can be combined with PropertyRestrictions.
  // [B] without it macros:Chart shows "no data" and the analytical table is a flat list
  // [TRY] remove channel_code from GroupableProperties -> 'Channel' disappears from the chart drilldown on Page B
  Aggregation.ApplySupported.Transformations       : ['aggregate', 'groupby', 'filter', 'concat', 'identity'],
  Aggregation.ApplySupported.GroupableProperties   : [
    year, quarter, yearMonth, saleDate, region_code, regionName, country,
    channel_code, channelName, book_ID, bookTitle, bookNo, authorName, genre_code, currency_code
  ],
  Aggregation.ApplySupported.AggregatableProperties: [
    { Property: revenue }, { Property: quantity }, { Property: margin }, { Property: target }, { Property: cost }
  ],
  // ---- V2 (Page A, SmartChart + AnalyticalTable) ----
  // [WHAT] PropertyRestrictions: true is the switch the V2 adapter looks for: it marks the entity
  //        as analytical (sap:semantics="aggregate") and turns V2 $select requests into $apply.
  // [A] without it SmartChart stays empty ("entity set not aggregatable") and the analytical table is flat
  Aggregation.ApplySupported.PropertyRestrictions  : true,

  // [WHAT] CustomAggregate: the server aggregates these measures with @Aggregation.default (below)
  // [B] chart measures / table totals   [A] (V2 uses @Aggregation.default directly)
  Aggregation.CustomAggregate #revenue : 'Edm.Decimal',
  Aggregation.CustomAggregate #quantity: 'Edm.Int32',
  Aggregation.CustomAggregate #margin  : 'Edm.Decimal',
  Aggregation.CustomAggregate #target  : 'Edm.Decimal',
  Aggregation.CustomAggregate #cost    : 'Edm.Decimal'
);

annotate service.BookSalesAnalytics with {
  // [WHAT] @Aggregation.default: how the server sums a measure up (both protocols)
  // [TRY] change quantity to #MAX -> 'Copies' shows the largest single sale instead of the total
  revenue  @Aggregation.default: #SUM;
  quantity @Aggregation.default: #SUM;
  margin   @Aggregation.default: #SUM;
  target   @Aggregation.default: #SUM;
  cost     @Aggregation.default: #SUM;

  // [WHAT] @Analytics.Measure / @Analytics.Dimension -> sap:aggregation-role in the V2 $metadata.
  //        Only the V2 adapter reads them (Fiori elements V4 uses ApplySupported above instead).
  // [A] SmartChart offers dimensions on the axis/drilldown and measures as values;
  //     AnalyticalTable groups by dimensions and totals measures
  // [TRY] remove @Analytics.Dimension from country -> 'Country' is no longer offered in the SmartChart drilldown
  revenue       @Analytics.Measure;
  quantity      @Analytics.Measure;
  margin        @Analytics.Measure;
  target        @Analytics.Measure;
  cost          @Analytics.Measure;
  year          @Analytics.Dimension;
  quarter       @Analytics.Dimension;
  yearMonth     @Analytics.Dimension;
  region_code   @Analytics.Dimension;
  country       @Analytics.Dimension;
  channel_code  @Analytics.Dimension;
  book_ID       @Analytics.Dimension;
  bookTitle     @Analytics.Dimension;
  bookNo        @Analytics.Dimension;
  authorName    @Analytics.Dimension;
  genre_code    @Analytics.Dimension;
  currency_code @Analytics.Dimension;
  saleDate      @Analytics.Dimension;

  ID            @UI.Hidden;
  saleDate      @title: 'Sale Date';
  year          @title: 'Year'  @Common.IsCalendarYear;
  quarter       @title: 'Quarter';
  yearMonth     @title: 'Month';
  country       @title: 'Country';
  bookNo        @title: 'Book No.'  @Common.SemanticObject: 'Books';
  bookTitle     @title: 'Book Title';
  authorName    @title: 'Author';
  regionName    @title: 'Region Name';
  channelName   @title: 'Channel Name';
  quantity      @title: 'Copies';
  revenue       @title: 'Revenue';
  cost          @title: 'Cost';
  target        @title: 'Target';
  margin        @title: 'Margin';
  currency_code @title: 'Currency'  @Semantics.currencyCode;

  // [WHAT] Text on a dimension: the chart axis/legend shows "West" instead of "W"
  // [A] SmartChart axis + AnalyticalTable   [B] macros:Chart + Table
  region_code   @title: 'Region'   @Common.Text: regionName   @Common.TextArrangement: #TextOnly;
  channel_code  @title: 'Channel'  @Common.Text: channelName  @Common.TextArrangement: #TextOnly;
  book_ID       @title: 'Book'     @Common.Text: bookTitle    @Common.TextArrangement: #TextOnly;
  genre_code    @title: 'Genre';

  revenue  @Measures.ISOCurrency: currency_code;
  margin   @Measures.ISOCurrency: currency_code;
  target   @Measures.ISOCurrency: currency_code;
  cost     @Measures.ISOCurrency: currency_code;

  // value helps for the sales filter bars (dropdowns)
  region_code  @Common.ValueListWithFixedValues @Common.ValueList: {
    CollectionPath: 'Regions',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: region_code, ValueListProperty: 'code' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };
  channel_code @Common.ValueListWithFixedValues @Common.ValueList: {
    CollectionPath: 'Channels',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: channel_code, ValueListProperty: 'code' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };
  genre_code   @Common.ValueListWithFixedValues @Common.ValueList: {
    CollectionPath: 'Genres',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: genre_code, ValueListProperty: 'code' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
    ]
  };
  book_ID      @Common.ValueList: {
    CollectionPath: 'Books',
    Parameters    : [
      { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: book_ID, ValueListProperty: 'ID' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'title' },
      { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'bookNo' }
    ]
  };
};

annotate service.Regions with {
  code @title: 'Region'  @Common.Text: name  @Common.TextArrangement: #TextOnly;
};
annotate service.Channels with {
  code @title: 'Channel' @Common.Text: name  @Common.TextArrangement: #TextOnly;
};

annotate service.BookSalesAnalytics with @(
  // [WHAT] UI.SelectionFields: filters of the sales filter bars
  UI.SelectionFields: [ year, region_code, channel_code, genre_code, book_ID ],

  // [WHAT] UI.Chart (no qualifier): the default chart
  // [A] SmartChart: starts as a column chart Revenue by Region; use the chart-type button,
  //     'Drill Down' (choose Channel), legend button, settings (personalization)
  // [B] macros:Chart metaPath="@com.sap.vocabularies.UI.v1.Chart": same chart
  // [TRY] change ChartType to #Donut, or Dimensions to [year] -> both pages change
  UI.Chart: {
    Title              : 'Revenue by Region',
    ChartType          : #Column,
    Dimensions         : [region_code],
    Measures           : [revenue],
    DimensionAttributes: [{ Dimension: region_code, Role: #Category }],
    MeasureAttributes  : [{ Measure: revenue, Role: #Axis1 }]
  },

  // [WHAT] UI.LineItem: columns of the analytical tables
  // [A] SmartTable tableType="AnalyticalTable": group by a column header, totals at the bottom
  // [B] macros:Table type="AnalyticalTable": same
  UI.LineItem: [
    { Value: year },
    { Value: region_code },
    { Value: channel_code },
    { Value: bookTitle },
    { Value: quantity },
    { Value: revenue },
    { Value: target },
    { Value: margin }
  ]
);
