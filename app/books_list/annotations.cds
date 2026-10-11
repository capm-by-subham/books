using AdminService as service from '../../srv/admin-service';

// Every annotation below has a comment in the form:
//   [WHAT] what it does  [WHERE] where to see it in the UI  [TRY] what to change to see the effect
// LR = List Report (the table page), OP = Object Page (the detail page of one book/author).
// After editing this file, cds watch restarts by itself — just reload the browser tab.


// =====================================================================================
// A. LABELS, TEXTS, VALUE HELPS
// =====================================================================================

annotate service.Books with {
  // [WHAT] @title becomes Common.Label: the human-readable name of a field
  // [WHERE] column headers (LR), filter bar labels (LR), form labels (OP)
  // [TRY] rename 'Book No.' to 'Book Number' and reload: header, filter and form all change
  bookNo      @title: 'Book No.';
  title       @title: 'Title';
  author      @title: 'Author (legacy text)';
  stock       @title: 'Stock';
  price       @title: 'Price';
  currency    @title: 'Currency';
  rating      @title: 'Rating';
  publishedAt @title: 'Published On';
  stockValue  @title: 'Stock Value';
  coverUrl    @title: 'Cover Image';

  // [WHAT] @Common.Label is the long form of @title (same result, OData vocabulary name)
  // [WHERE] 'Internal ID' would show wherever ID appears (it is hidden, see section D)
  // [TRY] remove @UI.Hidden from ID in section D to see this label
  ID          @Common.Label: 'Internal ID';

  // [WHAT] @UI.Placeholder is the grey hint text inside an empty input
  // [WHERE] OP in edit mode -> click 'Create' on the LR -> empty 'Title' and 'Book No.' inputs
  // [TRY] change the text, then create a new book
  title       @UI.Placeholder: 'e.g. Wuthering Heights';
  bookNo      @UI.Placeholder: 'BK-0000';

  // [WHAT] @UI.MultiLineText renders a text area instead of a one-line input / single line
  // [WHERE] OP -> 'Description' section (display shows the full text, edit shows a text area)
  // [TRY] remove it: the description is cut to one line / edited in a small input
  descr       @title: 'Description'  @UI.MultiLineText;

  // [WHAT] @UI.IsImageURL tells Fiori the string is an image link and renders the picture
  // [WHERE] OP -> 'Description' section -> 'Cover Image' shows the picture, not the URL
  // [TRY] remove it: you see the raw https://... text instead
  coverUrl    @UI.IsImageURL;

  // [WHAT] Common.Text + TextArrangement: show the author's NAME instead of the writer_ID number
  //        #TextOnly = name only, #TextFirst = "name (1)", #TextLast = "1 (name)", #TextSeparate = "1"
  // [WHERE] LR column 'Author', filter 'Author', OP field 'Author'
  // [TRY] change #TextOnly to #TextFirst and reload: "Emily Brontë (1)"
  writer      @title: 'Author'
              @Common.Text: writer.name
              @Common.TextArrangement: #TextOnly
              // [WHAT] Common.ValueList: an F4 value-help dialog (search + table) for the field
              // [WHERE] OP in edit mode -> 'Author' -> click the small icon at the end of the input; also the filter bar
              // [TRY] add { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'email' } to see an extra column
              @Common.ValueList: {
                Label         : 'Authors',
                CollectionPath: 'Authors',
                Parameters    : [
                  { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: writer_ID, ValueListProperty: 'ID' },
                  { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
                  { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'placeOfBirth' }
                ]
              };

  // [WHAT] ValueList + ValueListWithFixedValues: a short, fixed list -> a DROPDOWN instead of a dialog
  // [WHERE] OP in edit mode -> 'Genre' and 'Status' dropdowns; filter bar 'Genre' / 'Status'
  // [TRY] remove @Common.ValueListWithFixedValues from genre: it turns back into an F4 dialog
  genre       @title: 'Genre'
              @Common.Text: genre.name
              @Common.TextArrangement: #TextFirst // dropdown and table show "Gothic (GOT)"
              @Common.ValueListWithFixedValues
              @Common.ValueList: {
                CollectionPath: 'Genres',
                Parameters    : [
                  { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: genre_code, ValueListProperty: 'code' },
                  { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
                ]
              };

  status      @title: 'Status'
              @Common.Text: status.name
              @Common.TextArrangement: #TextOnly
              @Common.ValueListWithFixedValues
              @Common.ValueList: {
                CollectionPath: 'BookStatus',
                Parameters    : [
                  { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: status_code, ValueListProperty: 'code' },
                  { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
                ]
              };
};

// code-list texts: the dropdown shows the name next to the code
annotate service.Genres with {
  code @title: 'Genre'  @Common.Text: name  @Common.TextArrangement: #TextFirst;
  name @title: 'Genre Name';
};
annotate service.BookStatus with {
  code @title: 'Status' @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name @title: 'Status Name';
};

annotate service.Authors with {
  ID           @title: 'Author ID'  @Common.Text: name  @Common.TextArrangement: #TextOnly;
  name         @title: 'Name'  @UI.Placeholder: 'First and last name';
  dateOfBirth  @title: 'Date of Birth';
  placeOfBirth @title: 'Place of Birth';
  // [WHAT] Communication.IsEmailAddress / IsPhoneNumber turn the value into a mailto: / tel: link
  // [WHERE] Author OP -> 'Details' section; also the author quick view (click an author name in the LR)
  // [TRY] remove the annotation: the value becomes plain text
  email        @title: 'Email'  @Communication.IsEmailAddress;
  phone        @title: 'Phone'  @Communication.IsPhoneNumber;
};

annotate service.Authors.addresses with {
  ID      @title: 'No.';
  street  @title: 'Street';
  city    @title: 'City';
  country @title: 'Country';
};


// =====================================================================================
// B. LIST REPORT
// =====================================================================================

annotate service.Books with @(
  // [WHAT] UI.HeaderInfo: how ONE book / MANY books are named, plus the OP title, subtitle and picture
  // [WHERE] LR table title "Books (10)"; OP header: title, author as subtitle, cover image on the left
  // [TRY] set Description: { Value: genre.name } -> the OP subtitle becomes the genre
  UI.HeaderInfo: {
    TypeName      : 'Book',
    TypeNamePlural: 'Books',
    Title         : { Value: title },
    Description   : { Value: writer.name },
    ImageUrl      : coverUrl,
    TypeImageUrl  : 'sap-icon://course-book' // icon used when there is no ImageUrl (e.g. a new book)
  },

  // [WHAT] UI.SelectionFields: which filters are visible in the filter bar from the start
  // [WHERE] LR filter bar (more filters stay available under 'Adapt Filters')
  // [TRY] add 'rating' to the list, reload, and a Rating filter appears
  UI.SelectionFields: [
    genre_code,
    status_code,
    writer_ID,
    publishedAt,
    price
  ],

  // [WHAT] UI.LineItem: the table columns, in order. Each entry is a DataField of some type.
  // [WHERE] LR table
  // [TRY] swap the first two entries and reload: the column order changes
  UI.LineItem: [
    // [WHAT] DataFieldForAction: a button for a bound action in the table toolbar
    //        (enabled once you select a row where Core.OperationAvailable is true, see section E)
    // [WHERE] LR table toolbar, top right: 'Add Stock'
    // [TRY] add Inline: true -> the button moves into every row instead of the toolbar
    {
      $Type : 'UI.DataFieldForAction',
      Action: 'AdminService.addStock',
      Label : 'Add Stock'
    },
    // [WHAT] plain DataField with UI.Importance. When the columns don't fit, the responsive table
    //        drops #Low (and #Medium) columns and keeps #High ones. Here the 3 #Low columns at the
    //        end (Look Up, Author (legacy text), Published On) are dropped on a normal laptop screen.
    // [WHERE] LR column 'Book No.' (bold, because it is the SemanticKey, see section D)
    // [TRY] change 'Published On' to #High -> it appears; make the window narrow -> more columns go
    {
      Value              : bookNo,
      ![@UI.Importance]  : #High
    },
    {
      Value              : title,
      ![@UI.Importance]  : #High
    },
    // [WHAT] a field whose association target has UI.QuickViewFacets becomes a link that opens a quick view
    // [WHERE] LR column 'Author' -> click a name -> small card with the author's details
    // [TRY] delete UI.QuickViewFacets on Authors (section C) and the name becomes plain text
    {
      Value: writer_ID,
      ![@UI.Importance]: #High
    },
    {
      Value: genre_code,
      ![@UI.Importance]: #High
    },
    // [WHAT] DataFieldForAnnotation pointing to a DataPoint with Visualization #Rating -> stars
    // [WHERE] LR column 'Rating' shows 0–5 stars
    // [TRY] change TargetValue in UI.DataPoint#rating to 10 -> ten stars per row
    {
      $Type : 'UI.DataFieldForAnnotation',
      Target: '@UI.DataPoint#rating',
      Label : 'Rating',
      ![@UI.Importance]: #High
    },
    // [WHAT] DataFieldForAnnotation pointing to a UI.Chart -> a micro chart inside a cell
    // [WHERE] LR column 'Stock vs. Target': bullet chart; the vertical line is the target (10)
    // [TRY] set TargetValue in UI.DataPoint#stockChart to 50 -> the target line moves right
    {
      $Type : 'UI.DataFieldForAnnotation',
      Target: '@UI.Chart#stockBullet',
      Label : 'Stock vs. Target',
      ![@UI.Importance]: #High
    },
    // [WHAT] price shows with its currency because of @Measures.ISOCurrency (below)
    // [WHERE] LR column 'Price': "11.11 GBP"
    {
      Value: price,
      ![@UI.Importance]: #High
    },
    // [WHAT] Criticality colours the value (0 grey, 1 red, 2 orange, 3 green);
    //        CriticalityRepresentation #WithIcon adds a matching icon, #WithoutIcon only colours
    // [WHERE] LR column 'Status': green 'Available', orange 'Low stock', red 'Out of stock'
    // [TRY] change #WithIcon to #WithoutIcon
    {
      Value                    : status_code,
      Criticality              : status.criticality,
      CriticalityRepresentation: #WithIcon,
      ![@UI.Importance]        : #High
    },
    // [WHAT] DataFieldWithUrl: the value becomes a hyperlink to any URL (here built with an expression)
    // [WHERE] LR column 'Look Up': click opens a Wikipedia search for the title in a new tab
    // [TRY] in srv/admin-service.cds change lookupUrl to 'https://www.google.com/search?q=' || title
    {
      $Type: 'UI.DataFieldWithUrl',
      Label: 'Look Up',
      Value: 'Wikipedia',
      Url  : lookupUrl, // built in srv/admin-service.cds from the title
      ![@UI.Importance]: #Low
    },
    // [WHAT] DataFieldWithIntentBasedNavigation: a link to ANOTHER app via the Fiori Launchpad
    //        (semantic object + action). It only navigates inside a launchpad that has a
    //        target for "Author-display"; in this local preview the link shows but goes nowhere.
    // [WHERE] LR column 'Author (legacy text)'
    // [TRY] in a real launchpad, register an app for the intent Author-display
    {
      $Type         : 'UI.DataFieldWithIntentBasedNavigation',
      Value         : author,
      SemanticObject: 'Author',
      Action        : 'display',
      ![@UI.Importance]: #Low
    },
    {
      Value: publishedAt,
      ![@UI.Importance]: #Low
    }
  ],

  // [WHAT] DataPoint with Visualization #Rating -> star rating; TargetValue = number of stars
  // [WHERE] LR column 'Rating' and OP header 'Rating'
  UI.DataPoint #rating: {
    Value        : rating,
    Title        : 'Rating',
    Visualization: #Rating,
    TargetValue  : 5
  },

  // [WHAT] UI.Chart #Bullet + the DataPoint it uses: a micro chart (needs sap.suite.ui.microchart, see manifest)
  // [WHERE] LR column 'Stock vs. Target'
  // [TRY] change ChartType to #Radial -> a ring showing stock as a share of the target
  UI.Chart #stockBullet: {
    ChartType        : #Bullet,
    Title            : 'Stock vs. Target',
    Measures         : [stock],
    MeasureAttributes: [{
      Measure  : stock,
      Role     : #Axis1,
      DataPoint: '@UI.DataPoint#stockChart'
    }]
  },
  UI.DataPoint #stockChart: {
    Value       : stock,
    TargetValue : 10,
    MinimumValue: 0,
    Criticality : status.criticality
  },

  // [WHAT] UI.PresentationVariant: the table's DEFAULT sort and grouping
  // [WHERE] LR table: rows grouped by genre, each group sorted by title (A–Z)
  // [TRY] remove GroupBy -> one flat list; set Descending: true -> Z–A
  UI.PresentationVariant: {
    SortOrder     : [{ Property: title, Descending: false }],
    GroupBy       : [genre_code],
    Visualizations: ['@UI.LineItem']
  },

  // [WHAT] UI.SelectionPresentationVariant: a saved filter + table setup. The manifest
  //        ("views") turns each one into a TAB above the table (see MANIFEST_NOTES.md)
  // [WHERE] LR: tabs 'All', 'In Stock', 'Out of Stock' with counts
  // [TRY] change Low: 0 in #inStock to Low: 20 -> 'In Stock' shows only well-stocked books
  UI.SelectionPresentationVariant #all: {
    Text               : 'All',
    SelectionVariant   : { SelectOptions: [] },
    PresentationVariant: {
      SortOrder     : [{ Property: title }],
      GroupBy       : [genre_code],
      Visualizations: ['@UI.LineItem']
    }
  },
  UI.SelectionPresentationVariant #inStock: {
    Text               : 'In Stock',
    SelectionVariant   : {
      SelectOptions: [{
        PropertyName: stock,
        Ranges      : [{ Sign: #I, Option: #GT, Low: 0 }]
      }]
    },
    PresentationVariant: {
      SortOrder     : [{ Property: stock, Descending: true }], // most copies first
      Visualizations: ['@UI.LineItem']
    }
  },
  UI.SelectionPresentationVariant #outOfStock: {
    Text               : 'Out of Stock',
    SelectionVariant   : {
      SelectOptions: [{
        PropertyName: stock,
        Ranges      : [{ Sign: #I, Option: #EQ, Low: 0 }]
      }]
    },
    PresentationVariant: {
      SortOrder     : [{ Property: title }],
      Visualizations: ['@UI.LineItem']
    }
  },

  // [WHAT] Capabilities: what the service allows; Fiori hides UI for things that are not allowed
  // [WHERE] LR: search field, filters, sorting in table settings, Create and Delete buttons
  Capabilities: {
    // [TRY] Searchable: false -> the 'Search' field in the filter bar disappears
    SearchRestrictions: { Searchable: true },
    // [TRY] remove descr from the list -> 'Description' becomes available under 'Adapt Filters'
    FilterRestrictions: { NonFilterableProperties: [descr, coverUrl] },
    // [TRY] check table settings (gear icon) -> Sort: 'Description' and 'Cover Image' are not offered
    SortRestrictions  : { NonSortableProperties: [descr, coverUrl] },
    // [TRY] Insertable: false -> the 'Create' button disappears
    InsertRestrictions: { Insertable: true },
    // [TRY] Deletable: false -> the 'Delete' button disappears (LR and OP)
    DeleteRestrictions: { Deletable: true }
  }
);

annotate service.Books with {
  // [WHAT] Measures.ISOCurrency: the amount belongs to this currency (formatting + decimals + shown together)
  // [WHERE] LR 'Price' "11.11 GBP"; OP edit mode: price input with the currency next to it
  // [TRY] remove it from price -> the currency disappears from the Price column
  price      @Measures.ISOCurrency: currency_code;
  stockValue @Measures.ISOCurrency: currency_code;
  // [WHAT] Measures.Unit: like ISOCurrency, for non-currency units (here a fixed text 'pcs')
  // [WHERE] OP 'Stock' field and header: "12 pcs"
  // [TRY] change 'pcs' to 'copies'
  stock      @Measures.Unit: 'pcs';
};

// search: which text fields the 'Search' box looks in (CAP annotation, not OData)
// [TRY] type "Heathcliff" into Search: it finds Wuthering Heights through descr
annotate service.Books with @cds.search: { title, bookNo, author, descr };


// =====================================================================================
// C. OBJECT PAGE
// =====================================================================================

annotate service.Books with @(
  // [WHAT] UI.HeaderFacets: key figures shown in the OP header (each points to a DataPoint)
  // [WHERE] OP header area under the title: Price, Stock, Rating, Stock Target
  // [TRY] reorder the entries, or remove one
  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', ID: 'HeaderPrice',    Target: '@UI.DataPoint#price' },
    { $Type: 'UI.ReferenceFacet', ID: 'HeaderStock',    Target: '@UI.DataPoint#stock' },
    { $Type: 'UI.ReferenceFacet', ID: 'HeaderRating',   Target: '@UI.DataPoint#rating' },
    { $Type: 'UI.ReferenceFacet', ID: 'HeaderProgress', Target: '@UI.DataPoint#progress' }
  ],

  // [WHAT] plain DataPoint: a big key figure
  // [WHERE] OP header 'Price'
  UI.DataPoint #price: {
    Value: price,
    Title: 'Price'
  },
  // [WHAT] DataPoint with Criticality: the figure is coloured green/orange/red
  // [WHERE] OP header 'Stock' (e.g. red 0 for 'Catweazle', orange for 'Villette')
  // [TRY] use the 'Add Stock' action on Villette with 10 -> turns green after the refresh
  UI.DataPoint #stock: {
    Value      : stock,
    Title      : 'Stock',
    Criticality: status.criticality
  },
  // [WHAT] DataPoint with Visualization #Progress: a progress bar towards TargetValue
  // [WHERE] OP header 'Stock Target (50)'
  // [TRY] change TargetValue to 20 and open 'Shirley' (25 copies): the bar is full
  UI.DataPoint #progress: {
    Value        : stock,
    Title        : 'Stock Target (50)',
    TargetValue  : 50,
    Visualization: #Progress,
    Criticality  : status.criticality
  },

  // [WHAT] UI.Identification: actions here become buttons in the OP header toolbar
  // [WHERE] OP top right, next to 'Edit': 'Add Stock' (disabled while editing, see section E)
  // [TRY] remove it -> the action is only available from the LR table
  UI.Identification: [{
    $Type : 'UI.DataFieldForAction',
    Action: 'AdminService.addStock',
    Label : 'Add Stock'
  }],

  // [WHAT] UI.Facets: the sections of the OP. A CollectionFacet groups several ReferenceFacets
  //        (each ReferenceFacet points to a FieldGroup, a LineItem, ... = a sub-section)
  // [WHERE] OP anchor bar (tabs below the header): Book Details, Stock, Description, About the Author, Administrative Data
  // [TRY] move the 'Description' facet into the CollectionFacet -> it becomes a sub-section
  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'BookDetails',
      Label : 'Book Details',
      Facets: [
        { $Type: 'UI.ReferenceFacet', ID: 'General', Label: 'General', Target: '@UI.FieldGroup#General' },
        { $Type: 'UI.ReferenceFacet', ID: 'Pricing', Label: 'Pricing', Target: '@UI.FieldGroup#Pricing' }
      ]
    },
    // [WHAT] dynamic UI.Hidden on a facet: path to a Boolean -> the section disappears when true
    // [WHERE] OP of 'Eleonora' (discontinued) has no 'Stock' section; other books do
    // [TRY] set a book's Status to 'Discontinued' and save -> its Stock section disappears
    {
      $Type            : 'UI.ReferenceFacet',
      ID               : 'Stock',
      Label            : 'Stock',
      Target           : '@UI.FieldGroup#Stock',
      ![@UI.Hidden]    : isDiscontinued
    },
    { $Type: 'UI.ReferenceFacet', ID: 'Description', Label: 'Description', Target: '@UI.FieldGroup#Description' },
    // [WHAT] a ReferenceFacet can point THROUGH an association to the target's annotations
    // [WHERE] OP section 'About the Author' shows fields from the Authors entity
    // [TRY] change the target to 'writer/@UI.FieldGroup#AuthorContact'
    { $Type: 'UI.ReferenceFacet', ID: 'AuthorInfo', Label: 'About the Author', Target: 'writer/@UI.FieldGroup#AuthorInfo' },
    { $Type: 'UI.ReferenceFacet', ID: 'Admin', Label: 'Administrative Data', Target: '@UI.FieldGroup#Admin' }
  ],

  // [WHAT] UI.FieldGroup#Qualifier: a named group of fields shown as a form
  // [WHERE] OP 'Book Details' -> 'General'
  // [TRY] add { Value: rating } to this group
  UI.FieldGroup #General: {
    Data: [
      { Value: bookNo },
      { Value: title },
      // link with quick view card (UI.QuickViewFacets on Authors). Note: a form field cannot navigate
      // to the Author OP in Fiori Elements V4 1.153 (DataFieldWithNavigationPath is ignored here);
      // the Author OP is reached via the Authors list: index.html#/Authors
      { Value: writer_ID },
      { Value: author },
      { Value: genre_code },
      { Value: status_code, Criticality: status.criticality, CriticalityRepresentation: #WithIcon },
      { Value: publishedAt }
    ]
  },
  // [WHERE] OP 'Book Details' -> 'Pricing'. In edit mode, change Price: 'Stock Value' updates (side effect, section E)
  UI.FieldGroup #Pricing: {
    Data: [
      { Value: price },
      { Value: rating },
      { Value: stockValue }
    ]
  },
  UI.FieldGroup #Stock: {
    Data: [
      { Value: stock },
      // [WHAT] DataFieldForAnnotation -> UI.ConnectedFields: two fields in ONE form row with a template
      // [WHERE] OP 'Stock' section -> 'Stock / Value': "12 pcs / 133.32 GBP"
      // [TRY] change the Template to '{stock} copies worth {stockValue}'
      { $Type: 'UI.DataFieldForAnnotation', Target: '@UI.ConnectedFields#stockAndValue', Label: 'Stock / Value' }
    ]
  },
  UI.ConnectedFields #stockAndValue: {
    Label   : 'Stock / Value',
    Template: '{stock} / {stockValue}',
    Data    : {
      stock     : { $Type: 'UI.DataField', Value: stock },
      stockValue: { $Type: 'UI.DataField', Value: stockValue }
    }
  },
  UI.FieldGroup #Description: {
    Data: [
      { Value: descr },
      { Value: coverUrl }
    ]
  },
  // fields from the 'managed' aspect (filled by CAP automatically, read-only)
  UI.FieldGroup #Admin: {
    Data: [
      { Value: createdAt },
      { Value: createdBy },
      { Value: modifiedAt },
      { Value: modifiedBy }
    ]
  }
);

// smaller table of books, used on the Author OP
annotate service.Books with @(
  // [WHAT] a qualified LineItem (#byAuthor): a second, different table layout for the same entity
  // [WHERE] Author OP -> 'Books' section
  // [TRY] add { Value: rating } and reload an author page
  UI.LineItem #byAuthor: [
    { Value: bookNo },
    { Value: title },
    { Value: genre_code },
    { Value: price },
    { Value: stock },
    { Value: status_code, Criticality: status.criticality, CriticalityRepresentation: #WithIcon }
  ]
);

annotate service.Authors with @(
  UI.HeaderInfo: {
    TypeName      : 'Author',
    TypeNamePlural: 'Authors',
    Title         : { Value: name },
    Description   : { Value: placeOfBirth },
    TypeImageUrl  : 'sap-icon://person-placeholder'
  },
  // Authors list (index.html#/Authors): filter bar + table, each row opens the Author OP
  UI.SelectionFields: [name, placeOfBirth],
  UI.LineItem: [
    { Value: name },
    { Value: dateOfBirth },
    { Value: placeOfBirth },
    { Value: email }
  ],
  UI.FieldGroup #AuthorInfo: {
    Data: [
      { Value: name },
      { Value: dateOfBirth },
      { Value: placeOfBirth },
      { Value: email },
      { Value: phone }
    ]
  },
  UI.FieldGroup #AuthorContact: {
    Data: [
      { Value: email },
      { Value: phone }
    ]
  },
  // [WHAT] UI.QuickViewFacets: content of the small card that opens when you click a link to this entity
  // [WHERE] LR column 'Author' -> click a name
  // [TRY] point it to '@UI.FieldGroup#AuthorContact' -> the card shows only email and phone
  UI.QuickViewFacets: [{ $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#AuthorInfo' }],

  // [WHAT] Author OP sections: details form, a TABLE of the author's books (to-many association
  //        + LineItem#byAuthor) and a table of the composition 'addresses'
  // [WHERE] Author OP (open a book -> 'About the Author' -> click the author name)
  // [TRY] change 'books/@UI.LineItem#byAuthor' to 'books/@UI.LineItem' -> the full LR column set
  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', ID: 'AuthorDetails', Label: 'Details',   Target: '@UI.FieldGroup#AuthorInfo' },
    { $Type: 'UI.ReferenceFacet', ID: 'AuthorBooks',   Label: 'Books',     Target: 'books/@UI.LineItem#byAuthor' },
    { $Type: 'UI.ReferenceFacet', ID: 'Addresses',     Label: 'Addresses', Target: 'addresses/@UI.LineItem' }
  ],

  // [WHAT] DeleteRestrictions.Deletable: false -> no Delete button for authors
  // [WHERE] Author OP header toolbar: only 'Edit', no 'Delete'
  // [TRY] set it to true
  Capabilities.DeleteRestrictions.Deletable: false
);

annotate service.Authors.addresses with @(
  UI.LineItem: [
    { Value: street },
    { Value: city },
    { Value: country }
  ]
);


// =====================================================================================
// D. FIELD BEHAVIOR
// =====================================================================================

annotate service.Books with {
  // [WHAT] @mandatory: required field -> asterisk in the form, CAP rejects saving without it
  // [WHERE] OP edit mode: 'Title *' and 'Book No. *'; clear Title and click Save -> error on the field
  // [TRY] remove @mandatory from title and save a book without a title
  title       @mandatory;
  bookNo      @mandatory;

  // [WHAT] @Core.Immutable: can be entered when CREATING, but never changed afterwards
  // [WHERE] OP: 'Book No.' is editable for a new book, read-only when editing an existing one
  // [TRY] edit Wuthering Heights: Book No. is locked; click 'Create': it is editable
  bookNo      @Core.Immutable;

  // [WHAT] @readonly: never editable in the UI (CAP also ignores it in writes)
  // [WHERE] OP edit mode: 'Author (legacy text)' stays plain text (it is maintained by app/book)
  // [TRY] remove it -> the field becomes an input
  author      @readonly;

  // [WHAT] @Core.Computed: the server computes the value; the UI never offers an input for it
  // [WHERE] OP edit mode: 'Stock Value' stays read-only and is recalculated by the server
  // [TRY] remove it from stockValue -> Fiori shows an input, but the server would ignore your value
  stockValue  @Core.Computed;
  ID          @Core.Computed; // assigned in srv/admin-service.js when you click 'Create'

  // [WHAT] @UI.Hidden (static): the field never shows, not even in 'Adapt Filters' / table settings
  // [WHERE] nowhere — that's the point (ID, helper fields)
  // [TRY] remove @UI.Hidden from ID and look for 'Internal ID' under table settings -> Columns
  ID                @UI.Hidden;
  lookupUrl         @UI.Hidden;
  isDiscontinued    @UI.Hidden;
  priceFieldControl @UI.Hidden;

  // [WHAT] Common.FieldControl via a PATH: the field state comes from data
  //        (1 = read-only, 3 = optional/editable, 7 = mandatory, 0 = hidden)
  // [WHERE] OP edit mode on 'Eleonora' (Discontinued): Price and Currency are read-only;
  //         on other books they are editable. Change Status to 'Discontinued' while editing:
  //         Price becomes read-only immediately (side effect in section E)
  // [TRY] change the 'then 1' in srv/admin-service.cds to 'then 7' -> price becomes mandatory instead
  price       @Common.FieldControl: priceFieldControl;
  currency    @Common.FieldControl: priceFieldControl;
};

// [WHAT] Common.SemanticKey: the business key users recognise (instead of the technical ID)
// [WHERE] LR: 'Book No.' is bold and shows draft markers ('Draft', 'Unsaved Changes') under it
// [TRY] change it to [title] -> the title column becomes bold instead
annotate service.Books with @Common.SemanticKey: [bookNo];
annotate service.Authors with @Common.SemanticKey: [name];

// Validation lives in db/schema.cds (the model), errors show on the field in the UI:
//   @assert.range: [0, 5] on rating  -> CAP also publishes it as @Validation.Minimum/Maximum, so the UI
//                                       checks it right away (the server checks again on Save)
//                                       [TRY] enter Rating 7: "Enter a number with a maximum value of 5.0"
//   @assert.unique on bookNo          -> [TRY] create a book with Book No. BK-0001 and Save:
//                                        "Book number BK-0001 already exists" (friendly text from srv/admin-service.js)


// =====================================================================================
// E. ACTIONS, SIDE EFFECTS, DRAFT
// =====================================================================================
// Draft: @odata.draft.enabled is on AdminService.Books/Authors (srv/admin-service.cds).
// [WHERE] OP: 'Edit' creates a draft, changes are saved as you type, 'Save' activates it;
//         LR shows 'Draft' under the Book No. and has an 'Editing Status' filter.

annotate service.Books actions {
  addStock @(
    // [WHAT] Core.OperationAvailable: enable/disable the action per book (path expression on 'in' = the book)
    //        here: only for saved books (not while editing) that are not discontinued
    // [WHERE] LR: select 'Eleonora' -> 'Add Stock' disabled; select 'Villette' -> enabled.
    //         OP: the 'Add Stock' button is disabled on Eleonora and while editing
    // [TRY] replace the expression with true -> always enabled (the server still refuses Eleonora)
    Core.OperationAvailable: {$edmJson: {$And: [
      {$Path: 'in/IsActiveEntity'},
      {$Not: {$Path: 'in/isDiscontinued'}}
    ]}},
    // [WHAT] Common.IsActionCritical: ask "Are you sure?" before running the action.
    //        Only for actions WITHOUT parameters: here the 'Quantity' dialog already acts as the
    //        confirmation, so you see no extra popup.
    // [TRY] remove the (quantity ...) parameter below (and in srv/admin-service.cds) -> a confirmation popup appears
    Common.IsActionCritical: true,
    // [WHAT] Common.SideEffects on an action: which fields to reload after it ran
    // [WHERE] OP header Stock / Progress and the Status colour update right after 'Add Stock'
    // [TRY] remove 'in/stockValue' -> 'Stock Value' keeps the old number until you reload the page
    Common.SideEffects: {
      TargetProperties: [
        'in/stock',
        'in/stockValue',
        'in/status_code'
      ],
      // the status row itself changes (A/L/O), so reload the whole association, not status/name
      TargetEntities  : ['in/status']
    }
  )
  // action parameter: label + mandatory -> the dialog shows 'Quantity *'
  (quantity @title: 'Quantity' @mandatory);
};

annotate service.Books with @(
  // [WHAT] Common.SideEffects on the entity: when a SOURCE field changes in edit mode,
  //        Fiori asks the server again for the TARGET fields
  // [WHERE] OP edit mode: change Price or Stock and leave the field -> 'Stock Value' updates
  // [TRY] remove 'price' from SourceProperties -> changing the price no longer updates Stock Value
  Common.SideEffects #stockValue: {
    SourceProperties: [price, stock],
    TargetProperties: ['stockValue']
  },
  // [WHERE] OP edit mode: change Status to 'Discontinued' -> Price/Currency become read-only at once
  Common.SideEffects #status: {
    SourceProperties: [status_code],
    TargetProperties: ['priceFieldControl', 'isDiscontinued'],
    TargetEntities  : [status] // new status row -> new name and criticality colour
  }
);
