using my.bookshop as db from '../db/schema';

// ---------------------------------------------------------------------------------------------
// Service for the freestyle app app/books-freestyle. It is served TWICE:
//   /odata/v4/freestyle  -> OData V4, read by Page B (sap.fe.macros building blocks)
//   /odata/v2/freestyle  -> OData V2, made by @cap-js-community/odata-v2-adapter (a CDS plugin,
//                           no code needed), read by Page A (sap.ui.comp smart controls)
// Both protocols use the SAME model and the SAME annotations (app/books-freestyle/annotations.cds),
// so the two pages can be compared fairly.
// [WHY no draft] draft over OData V2 needs extra adapter settings and is awkward with SmartForm;
//                AdminService (draft) and its app books_list stay untouched.
// ---------------------------------------------------------------------------------------------
@odata
service FreestyleService {

  // [WHAT] Books with a few calculated fields that the UI needs as OWN properties:
  //        V2 smart controls can't show texts/criticality that live on another entity.
  entity Books        as projection on db.Books {
    *,
    price * stock      as stockValue        : Decimal(11, 2),
    writer.name        as authorName        : String(111), // text for writer_ID
    genre.name         as genreName         : String,      // text for genre_code
    status.name        as statusName        : String,      // text for status_code
    status.criticality as statusCriticality : Integer      // 1 red, 2 orange, 3 green
  } actions {
    // bound action: Page A calls it as V2 function import /Books_addStock, Page B as V4 action
    action addStock(quantity : Integer) returns Books;
  };

  entity Authors      as projection on db.Authors;

  // [WHY @cds.redirection.target] there are two projections on db.Genres in this service
  // (Genres and GenreTree). Associations like Books.genre must point to the plain one.
  @readonly @cds.redirection.target
  entity Genres       as projection on db.Genres;

  @readonly
  entity BookStatus   as projection on db.BookStatus;

  // -------------------------------------------------------------------------------------------
  // Genre hierarchy for the TREE TABLES. One entity serves both protocols:
  //  - V4 (Page B, macros:TreeTable): @hierarchy makes CAP generate the Hierarchy.RecursiveHierarchy
  //    annotations + the computed fields (DrillState, DistanceFromRoot, ...) and answer the
  //    $apply=...TopLevels(...) requests of the V4 tree table.
  //  - V2 (Page A, SmartTable tableType="TreeTable"): the V2 tree binding needs four plain
  //    properties (node, parent, level, drill state), annotated with @sap.hierarchy.* in
  //    app/books-freestyle/annotations.cds. They are calculated here.
  // -------------------------------------------------------------------------------------------
  @readonly @hierarchy
  entity GenreTree    as projection on db.Genres {
    *,
    parent   : redirected to GenreTree, // association to SELF (required by @hierarchy)
    children : redirected to GenreTree,
    parent.code as parentCode : String(10),
    // level 0 = root; our tree has at most 3 levels
    case when parent.code is null        then 0
         when parent.parent.code is null then 1
         else 2 end                     as hierarchyLevel : Integer,
    // V2 drill state: 'collapsed' = has children (shows an expand arrow), 'leaf' = no children
    case when exists children then 'collapsed' else 'leaf' end
                                        as drillState     : String(10)
  };

  // -------------------------------------------------------------------------------------------
  // Sales FACTS for charts and the analytical table. Same idea as AnalyticsService.BookSales,
  // but its own entity so the V2 analytics annotations don't touch the ALP app.
  // -------------------------------------------------------------------------------------------
  @readonly
  entity BookSalesAnalytics as projection on db.BookSales {
    key ID,
    saleDate,
    cast(year(saleDate) as String)                            as year       : String(4),
    'Q' || cast(floor((month(saleDate) + 2) / 3) as Integer)  as quarter    : String(2),
    substring(cast(saleDate as String), 0, 7)                 as yearMonth  : String(7),
    region.code                                               as region_code  : String(1),
    region.name                                               as regionName   : String,
    country,
    channel.code                                              as channel_code : String(3),
    channel.name                                              as channelName  : String,
    book.ID                                                   as book_ID    : Integer,
    book.title                                                as bookTitle  : String(111),
    book.bookNo                                               as bookNo     : String(10),
    book.writer.name                                          as authorName : String(111),
    book.genre.code                                           as genre_code : String(10),
    currency.code                                             as currency_code : String(3),
    quantity,
    revenue,
    cost,
    target,
    round(revenue - cost, 2)                                  as margin     : Decimal(11, 2)
  };

  @readonly entity Regions  as projection on db.Regions;
  @readonly entity Channels as projection on db.Channels;
}
