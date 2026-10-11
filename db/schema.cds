namespace my.bookshop;

using {
  Currency,
  managed,
  sap.common.CodeList
} from '@sap/cds/common';

@assert.unique: { bookNo: [bookNo] } // no two books may share a bookNo
entity Books : managed {
  key ID          : Integer;
      bookNo      : String(10);
      title       : String(111);
      author      : String; // legacy free-text author, still used by app/book
      stock       : Integer default 0;
      writer      : Association to Authors; // managed association -> adds writer_ID
      price       : Decimal(9, 2);
      currency    : Currency;
      rating      : Decimal(2, 1) @assert.range: [0, 5];
      status      : Association to BookStatus default 'A';
      genre       : Association to Genres;
      publishedAt : Date;
      descr       : LargeString;
      coverUrl    : String;
}

entity Authors : managed {
  key ID           : Integer;
      name         : String(111);
      dateOfBirth  : Date;
      placeOfBirth : String;
      email        : String;
      phone        : String;
      books        : Association to many Books on books.writer = $self; // backlink
      addresses    : Composition of many {                              // owned by the author
                       key ID      : Integer;
                           street  : String;
                           city    : String;
                           country : String;
                     };
}

// code lists: code + name + descr (localized) from sap.common.CodeList
entity Genres : CodeList {
  key code : String(10);
}

entity BookStatus : CodeList {
  key code        : String(1);
      criticality : Integer; // 0 neutral, 1 red, 2 orange, 3 green
}
