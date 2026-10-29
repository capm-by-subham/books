using my.bookshop as db from '../db/schema';

// Service for the Fiori Elements app (app/books_list): draft-enabled.
// CatalogService stays draft-free for the freestyle app (app/book).
@odata
service myservice {

  @odata.draft.enabled
  entity Books   as projection on db.Books {
    *,
    price * stock as stockValue        : Decimal(11, 2), // recalculated on every read
    case when status.code = 'D' then 1 else 3 end
                  as priceFieldControl : Integer, // 1 = read-only, 3 = editable
    case when status.code = 'D' then true else false end
                  as isDiscontinued    : Boolean,
    'https://en.wikipedia.org/wiki/Special:Search?search=' || title
                  as lookupUrl         : String // used by DataFieldWithUrl
  } actions {
    action addStock(quantity : Integer) returns Books;
  };

  @odata.draft.enabled
  entity Authors as projection on db.Authors;

  @readonly
  entity Genres     as projection on db.Genres;

  @readonly
  entity BookStatus as projection on db.BookStatus;
}
