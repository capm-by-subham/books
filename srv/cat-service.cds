using my.bookshop as db from '../db/schema';

@odata
service CatalogService {
  entity Books as projection on db.Books actions {
    action increaseStock();
  };

  entity Authors as projection on db.Authors;
}
