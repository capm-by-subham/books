# manifest.json explained

JSON can't have comments, so the notes are here. Same convention as `app/books_list/MANIFEST_NOTES.md`.

## sap.app
| Setting | What / why |
|---|---|
| `id: booksfreestyle` | app id = UI5 namespace (`booksfreestyle.view.Home`), also used as the flex/variant key |
| `dataSources.mainService` | `/odata/v4/freestyle/`, `odataVersion 4.0`, used by Page B, Home, Detail B |
| `dataSources.v2Service` | `/odata/v2/freestyle/`, `odataVersion 2.0`, made by the V2 adapter, used by Page A, Detail A |
| `crossNavigation.inbounds.BooksFreestyle-display` | intent for the launchpad tile (`app/launchpad.html`) |
| `sourceTemplate` | informational only (would be `@sap/generator-fiori:fpm` from the generator) |

## sap.ui5
| Setting | What / why |
|---|---|
| `handleValidation: true` | type errors (e.g. "abc" in a number field) become messages in the message model |
| `dependencies.libs` | `sap.fe.core` + `sap.fe.macros` (Page B), `sap.ui.comp` + `sap.chart` + `sap.viz` (Page A smart controls/chart), `sap.ui.table` (grid/tree/analytical tables), `sap.f` (DynamicPage), `sap.ui.layout` (forms, Grid) |
| `models[""]` | V4 model (default). `autoExpandSelect` = $select/$expand from the bindings; `operationMode Server` = filter/sort on the server |
| `models.v2` | V2 model. `defaultBindingMode TwoWay` (SmartForm edits write into it), `defaultCountMode Inline` ($inlinecount for "Books (9)"), `useBatch`, `refreshAfterChange`. `preload false`: only loaded when Page A needs it |
| `models.i18n` / `@i18n` | texts; `@i18n` is the name Fiori elements looks for |
| `resources.css` | `css/style.css` |

## routing
FE apps use FE routing: each target is a Component `sap.fe.core.fpm` = an **FPM custom page** with our own `viewName`.

| Route | Pattern | Target settings |
|---|---|---|
| Home | `:?query:` | `contextPattern: ""` (unbound) |
| PageA | `classic:?query:` | `contextPattern: ""` |
| DetailA | `classic/book/{id}:?query:` | `contextPattern: ""`; the controller binds the V2 model itself |
| PageB | `blocks:?query:` | `contextPattern: ""`, `navigation.Books.detail.route = DetailB` → row press in `macros:Table` navigates without code |
| DetailB | `Books({key}):?query:` | no contextPattern → FE binds the view to `/Books(<key>)` |

`contextPath: "/Books"` is required by FPM pages: building blocks without their own `contextPath` resolve `metaPath` against it.

[TRY] Remove `"contextPattern": ""` from DetailA. FE then tries to bind `/classic/book/3` on the V4 model and shows an error page.
