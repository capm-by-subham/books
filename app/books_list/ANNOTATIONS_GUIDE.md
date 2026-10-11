# Fiori Elements annotations – learning guide

Every annotation is in `annotations.cds` (sections A–E) with a `[WHAT] [WHERE] [TRY]` comment.
Model-level ones (`@assert…`, `@odata.draft.enabled`, calculated fields) are in `db/schema.cds` and `srv/admin-service.cds`.

**Run it:** `cds watch` in the project root → open <http://localhost:4004/bookslist/index.html>.
`cds watch` restarts by itself when you save a `.cds` file; reload the browser tab afterwards.
The database is in memory: every restart resets the data to the CSV files in `db/data`.

**Pages:** LR = List Report (table), OP = Object Page (detail). Author list: `index.html#/Authors`.

## Annotation map

### A. Labels, texts, value helps

| Annotation | Where in UI | Page | What to try |
|---|---|---|---|
| `@title` / `@Common.Label` | column headers, filter labels, form labels | LR, OP | rename `bookNo` to 'Book Number' |
| `@UI.Placeholder` | grey hint in empty inputs (Title, Book No.) | 'New Object' dialog, OP (create) | click Create |
| `@UI.MultiLineText` | Description shown in full, text area in edit | OP → Description | remove it |
| `@UI.IsImageURL` | Cover Image shows a picture | OP → Description | remove it → raw URL |
| `@Common.Text` + `@Common.TextArrangement` | author **name** instead of writer_ID; "Gothic (GOT)" | LR, OP, filters | `#TextOnly` → `#TextFirst` on writer |
| `@Common.ValueList` | value-help dialog for Author (search + table) | OP edit → Author input icon; filter bar | add `email` as a display column |
| `@Common.ValueListWithFixedValues` | Genre/Status are dropdowns | OP edit, filter bar | remove it from genre → dialog |
| `@Communication.IsEmailAddress` / `IsPhoneNumber` | mailto: / tel: links | Author OP, quick view | remove it |

### B. List Report

| Annotation | Where in UI | Page | What to try |
|---|---|---|---|
| `UI.HeaderInfo` | "Books (10)" table title; OP title, subtitle, image | LR, OP | Description → `genre.name` |
| `UI.SelectionFields` | visible filters | LR filter bar | add `rating` |
| `UI.LineItem` | table columns | LR | reorder entries |
| `UI.DataField` | plain columns (Book No., Title, …) | LR | – |
| `UI.DataFieldForAction` | 'Add Stock' in table toolbar (select a row) | LR | `Inline: true` → button in each row |
| `UI.DataFieldForAnnotation` → `UI.DataPoint` `#Rating` | stars | LR column Rating, OP header | `TargetValue: 10` |
| `UI.DataFieldForAnnotation` → `UI.Chart` `#Bullet` | bullet micro chart (target line = 10) | LR column 'Stock vs. Target' | `ChartType: #Radial` |
| `UI.DataFieldWithUrl` | 'Wikipedia' link (URL is the calculated field `lookupUrl`) | LR column 'Look Up'¹ | change `lookupUrl` in srv/admin-service.cds |
| `UI.DataFieldWithIntentBasedNavigation` | link to semantic object 'Author' (works only in a launchpad) | LR column 'Author (legacy text)'¹ | – |
| `UI.Importance` | which columns survive on small screens | LR | make the window narrow / set Published On to `#High` |
| `Criticality` + `CriticalityRepresentation` | coloured status with icon | LR, OP | `#WithoutIcon` |
| `UI.PresentationVariant` | grouped by genre, sorted by title | LR | remove `GroupBy` |
| `UI.SelectionPresentationVariant` (+ manifest `views`) | tabs All / In Stock / Out of Stock | LR | `Low: 20` in #inStock |
| `@Measures.ISOCurrency` | "11.11 GBP"; currency input next to price | LR, OP | remove it from price |
| `@Measures.Unit` | "12 pcs" | OP, header, author's books table | 'pcs' → 'copies' |
| `Capabilities.SearchRestrictions` | Search field | LR filter bar | `Searchable: false` |
| `@cds.search` (CAP) | which fields Search looks in | LR | search "Heathcliff" (found in Description) |
| `Capabilities.FilterRestrictions` | Description/Cover not in 'Adapt Filters' | LR | remove `descr` |
| `Capabilities.SortRestrictions` | Description/Cover not sortable | LR → ⚙ table settings → Sort | remove `descr` |
| `Capabilities.InsertRestrictions` | Create button | LR | `Insertable: false` |
| `Capabilities.DeleteRestrictions` | Delete button (Books yes, Authors no) | LR, OP, Author OP | `Deletable: false` on Books |

¹ `#Low` importance: dropped on a normal laptop screen. Make the window wider or set them to `#High` to see them.

### C. Object Page

| Annotation | Where in UI | Page | What to try |
|---|---|---|---|
| `UI.HeaderFacets` | key figures under the title | OP header | reorder / remove one |
| `UI.DataPoint` (plain) | 'Price' | OP header | – |
| `UI.DataPoint` + `Criticality` | 'Stock' green/orange/red | OP header | Add Stock on Villette |
| `UI.DataPoint` `#Progress` | 'Stock Target (50)' bar | OP header | `TargetValue: 20` |
| `UI.DataPoint` `#Rating` | stars with "4.5 out of 5" | OP header | – |
| `UI.Identification` | 'Add Stock' next to Edit | OP header toolbar | remove it |
| `UI.Facets` – `CollectionFacet` | section 'Book Details' with sub-sections General + Pricing | OP | move Description into it |
| `UI.Facets` – `ReferenceFacet` | sections Stock, Description, … | OP anchor bar | reorder |
| `ReferenceFacet` through an association (`writer/@UI.FieldGroup#AuthorInfo`) | 'About the Author' | OP | target `#AuthorContact` |
| `UI.FieldGroup#…` | General, Pricing, Stock, Description, Admin forms | OP | add `rating` to General |
| `UI.ConnectedFields` | 'Stock / Value': "12 pcs / 133.32 GBP" | OP → Stock | change the Template |
| `UI.LineItem#byAuthor` + `books/@UI.LineItem#byAuthor` | author's books table | Author OP → Books | use `books/@UI.LineItem` |
| Composition table (`addresses/@UI.LineItem`) | Addresses table | Author OP | – |
| `UI.QuickViewFacets` | card when clicking an author name | LR, OP | point to `#AuthorContact` |

### D. Field behavior

| Annotation | Where in UI | Page | What to try |
|---|---|---|---|
| `@mandatory` | red `*` at Title / Book No.; Save fails if empty | OP edit | clear Title, Save |
| `@readonly` | 'Author (legacy text)' never editable | OP edit | remove it |
| `@Core.Computed` | Stock Value / ID never editable, filled by the server | OP edit, Create | – |
| `@Core.Immutable` | Book No. asked once in the 'New Object' dialog, locked afterwards | Create, OP edit | Edit Wuthering Heights |
| `@UI.Hidden` (static) | ID and helper fields never shown | – | remove it from ID → 'Internal ID' in table settings |
| `@UI.Hidden` (path, on a facet) | 'Stock' section missing on discontinued books | OP of Eleonora | set a book to Discontinued and save |
| `@Common.FieldControl` (path) | Price/Currency read-only on discontinued books | OP edit of Eleonora | change Status while editing |
| `@Common.SemanticKey` | Book No. bold + draft marker; URL `Books('BK-0002')`; 'New Object' dialog | LR, OP | `[title]` |
| `@assert.range` (→ `@Validation.Minimum/Maximum`) | "Enter a number with a maximum value of 5.0" | OP edit → Rating 7 | – |
| `@assert.unique` (+ check before save) | "Book number BK-0001 already exists" on the field | Create with BK-0001 | – |

### E. Actions, side effects, draft

| Annotation | Where in UI | Page | What to try |
|---|---|---|---|
| `@odata.draft.enabled` | Edit → Draft → Save / Discard; 'Editing Status' filter | OP, LR | edit, leave without saving, come back |
| bound action `addStock(quantity)` | 'Quantity *' dialog, stock + status change | LR toolbar, OP header | Add 10 to Villette → turns green |
| `@Core.OperationAvailable` | Add Stock disabled for Eleonora and while editing | LR (select a row), OP | replace it with `true` |
| `@Common.IsActionCritical` | confirmation popup – **only for actions without parameters** (the Quantity dialog counts as confirmation) | – | remove the parameter to see it |
| `@Common.SideEffects` on the action | header Stock/Progress/Status refresh at once | OP | remove `'in/stockValue'` |
| `@Common.SideEffects #stockValue` | change Price/Stock → Stock Value updates when you leave the field | OP edit | remove `price` from sources |
| `@Common.SideEffects #status` | Status → Discontinued: Price locks, Stock section disappears | OP edit | remove it → happens only after Save |

## Click path checklist

1. **Open the app** – `http://localhost:4004/bookslist/index.html`. The table loads at once (`initialLoad`).
2. **Filter bar**
   - [ ] Genre / Status are dropdowns (`ValueListWithFixedValues`).
   - [ ] Author has a value-help dialog with name + place of birth (`ValueList`).
   - [ ] Type "Heathcliff" into Search → Wuthering Heights (`@cds.search` on `descr`).
   - [ ] 'Adapt Filters' does not offer Description or Cover Image (`FilterRestrictions`).
3. **Tabs** – click 'In Stock (8)' and 'Out of Stock (2)' (`SelectionPresentationVariant` + manifest `views`).
4. **Table**
   - [ ] Rows grouped by genre, sorted by title (`PresentationVariant`).
   - [ ] Book No. bold (`SemanticKey`), author names not IDs (`Text`), status coloured with icons (`Criticality`).
   - [ ] Stars and bullet charts (`DataFieldForAnnotation`).
   - [ ] Price/Status move under the row when the window is narrow (`ResponsiveTable` pop-in, `Importance`).
   - [ ] Click an author name → quick view card with mailto/tel links (`QuickViewFacets`).
   - [ ] Select Eleonora → Add Stock disabled; select Villette → enabled (`OperationAvailable`).
5. **Object page** – open Wuthering Heights.
   - [ ] Header: cover image, Price with currency, green Stock "12 pcs", stars, progress bar (`HeaderInfo`, `HeaderFacets`, `DataPoint`).
   - [ ] Sections: Book Details (General + Pricing), Stock, Description, About the Author, Administrative Data (`Facets`).
   - [ ] 'Stock / Value' in one row (`ConnectedFields`).
   - [ ] Open Eleonora → no Stock section (`UI.Hidden` path), Add Stock disabled.
6. **Edit** – click Edit on Jane Eyre.
   - [ ] Book No. locked (`Immutable`), Author (legacy text) read-only (`readonly`), Title has `*` (`mandatory`).
   - [ ] Change Price, press Tab twice → Stock Value updates (`SideEffects`).
   - [ ] Set Status to Discontinued → Price locks, Stock section disappears (`FieldControl` + `SideEffects`).
   - [ ] Rating 7 → error on the field (`assert.range`).
   - [ ] Click Discard Draft.
7. **Create** – LR → Create.
   - [ ] 'New Object' dialog asks for Book No. (placeholder `BK-0000`).
   - [ ] Enter BK-0001, a title, Create → "Book number BK-0001 already exists" (`assert.unique` + handler). Discard.
8. **Action** – open Villette (Low stock, 4) → Add Stock → 10 → green 14, Available, Stock Value updated (action + `SideEffects`).
9. **Authors** – open `index.html#/Authors` → Edgar Allan Poe.
   - [ ] Books table (association), Addresses table (composition), no Delete button (`DeleteRestrictions`).
   - [ ] Click a book → book OP with breadcrumb back to the author.
