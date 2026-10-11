using my.bookshop as db from '../db/schema';

// Read-only analytics service for the Analytical List Page (app/book-sales-alp).
// No draft: ALP only reads, and aggregation ($apply) is simplest on plain entities.
@odata
service AnalyticsService {

  @readonly
  entity BookSales as projection on db.BookSales {
    *,
    // time dimensions for drilldown (year -> quarter -> month), derived from saleDate
    cast(year(saleDate) as String)                              as year      : String(4), // '2026'
    'Q' || cast(floor((month(saleDate) + 2) / 3) as Integer)    as quarter   : String(2),
    substring(cast(saleDate as String), 0, 7)                   as yearMonth : String(7), // e.g. 2026-03, sorts chronologically (substring is 0-based, like in OData)
    round(revenue - cost, 2)                                    as margin    : Decimal(11, 2),
    // colour of a sale line: 1 red = loss, 2 orange = below target, 3 green = on/above target
    case when revenue < cost then 1 when revenue < target then 2 else 3 end
                                                                as revenueCriticality : Integer,
    // texts copied from associated entities: Fiori charts can't show texts or dimensions
    // that live on another entity, so they become own properties of BookSales
    book.title                                                  as bookTitle  : String(111),
    book.bookNo                                                 as bookNo     : String(10), // passed on when navigating to the Books app
    book.writer.ID                                              as author_ID  : Integer,
    book.writer.name                                            as authorName : String(111),
    region.name                                                 as regionName : String,
    channel.name                                                as channelName: String
  };

  @readonly entity Regions  as projection on db.Regions;
  @readonly entity Channels as projection on db.Channels;
  @readonly entity Books    as projection on db.Books { ID, bookNo, title };  // for the Book value help
  @readonly entity Authors  as projection on db.Authors { ID, name };         // for the Author value help
}
