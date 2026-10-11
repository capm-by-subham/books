const cds = require('@sap/cds')
const { SELECT, UPDATE } = cds.ql

module.exports = class AdminService extends cds.ApplicationService { init() {
  const { Books, Authors } = this.entities

  // Integer keys: Fiori Elements doesn't send an ID on Create, so assign the next free one
  // (checks drafts too, so two open drafts don't get the same ID)
  const nextID = async entity => {
    const [active, drafts] = await Promise.all([
      SELECT.one`max(ID) as max`.from(entity),
      SELECT.one`max(ID) as max`.from(entity.drafts)
    ])
    return Math.max(active?.max ?? 0, drafts?.max ?? 0) + 1
  }
  this.before('NEW', Books.drafts, async req => { req.data.ID ??= await nextID(Books) })
  this.before('NEW', Authors.drafts, async req => { req.data.ID ??= await nextID(Authors) })

  // friendly message on the field instead of the raw DB error from @assert.unique
  this.before('SAVE', Books, async req => {
    const { ID, bookNo } = req.data
    if (bookNo && await SELECT.one.from(Books).where({ bookNo, ID: { '!=': ID } }))
      req.error(400, `Book number ${bookNo} already exists`, 'in/bookNo')
  })

  // bound action addStock(quantity): adds to stock and derives the status from it
  this.on('addStock', Books, async req => {
    const { quantity } = req.data
    if (!(quantity > 0)) return req.error(400, 'Quantity must be greater than 0', 'in/quantity')

    const book = await SELECT.one.from(req.subject).columns('stock', 'status_code')
    if (!book) return req.error(404, 'Book not found')
    if (book.status_code === 'D') return req.error(400, 'Discontinued books cannot be restocked')

    const stock = (book.stock ?? 0) + quantity
    const status_code = stock >= 10 ? 'A' : 'L'
    await UPDATE(req.subject).with({ stock, status_code })
    return SELECT.one.from(req.subject)
  })

  return super.init()
}}
