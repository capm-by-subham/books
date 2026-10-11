namespace my.bookshop;

entity Books {
  key ID     : Integer;
      title  : String;
      author : String;
      stock  : Integer default 0;
      writer : Association to Authors; // managed association -> adds writer_ID
}

entity Authors {
  key ID        : Integer;
      name      : String;
      books     : Association to many Books on books.writer = $self; // backlink
      addresses : Composition of many {                              // owned by the author
                    key ID      : Integer;
                        street  : String;
                        city    : String;
                        country : String;
                  };
}
