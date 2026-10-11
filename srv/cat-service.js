const cds = require('@sap/cds')
const { UPDATE } = cds.ql

module.exports = class CatalogService extends cds.ApplicationService { init() {
  const { Books } = this.entities

  // bound action: req.subject points to the book it was called on
  this.on('increaseStock', Books, async req => {
    await UPDATE(req.subject).with({ stock: { '+=': 1 } })
  })

  return super.init()
}}
