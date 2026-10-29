const cds = require('@sap/cds')
const { SELECT, UPDATE } = cds.ql

// Handlers for FreestyleService. They run for BOTH /odata/v4/freestyle and /odata/v2/freestyle:
// the V2 adapter translates every V2 request into a V4 request against this same service.
module.exports = class FreestyleService extends cds.ApplicationService { init() {
  const { Books } = this.entities

  // Integer key: the create dialog (Page A) doesn't send an ID, so assign the next free one
  this.before('CREATE', Books, async req => {
    if (req.data.ID == null) {
      const { max } = await SELECT.one`max(ID) as max`.from(Books)
      req.data.ID = (max ?? 0) + 1
    }
  })

  // friendly message on the field (target 'bookNo') instead of the raw DB error from @assert.unique.
  // The UI shows it on the field: SmartField (V2) and macros:Field (V4) both pick up the target.
  this.before(['CREATE', 'UPDATE'], Books, async req => {
    const { bookNo } = req.data
    const ID = req.data.ID ?? req.params?.[0]?.ID ?? req.params?.[0]
    if (bookNo && await SELECT.one.from(Books).where({ bookNo, ID: { '!=': ID } }))
      req.error(400, `Book number ${bookNo} already exists`, 'bookNo')
  })

  // bound action addStock(quantity): same logic as in AdminService
  this.on('addStock', Books, async req => {
    const { quantity } = req.data
    if (!(quantity > 0)) return req.error(400, 'Quantity must be greater than 0', 'quantity')

    const book = await SELECT.one.from(req.subject).columns('stock', 'status_code')
    if (!book) return req.error(404, 'Book not found')
    if (book.status_code === 'D') return req.error(400, 'Discontinued books cannot be restocked')

    const stock = (book.stock ?? 0) + quantity
    await UPDATE(req.subject).with({ stock, status_code: stock >= 10 ? 'A' : 'L' })
    return SELECT.one.from(req.subject)
  })

  return super.init()
}}
