sap.ui.define([
    "sap/ui/core/mvc/Controller"
], (Controller) => {
    "use strict";

    return Controller.extend("book.controller.View1", {
        async onInit() {
            this.model = this.getOwnerComponent().getModel();
            this.byId("booksTable").setModel(this.model);
            const list = this.model.bindList("/Books(5)");
            const data = await list.requestContexts();
        },
        async onAdd(oEvent) {
            const binding = this.byId("booksTable").getBinding("items");
            const newRow = binding.create({ ID: Math.round(Math.random() * 100), title: "The Hobbit", author: "J.R.R. Tolkien" }, false, true)
            // await newRow.created(); its proves that its submitted so that we can run task after that
            //  otherwise its create end of the current JS task.
        },
        async onDelete(oEvent) {
            await oEvent.mParameters.listItem.getBindingContext().delete();
        },
        async onIncreaseStock(oEvent) {
            const oContext = oEvent.getSource().getBindingContext();
            // bound action: relative path "<service namespace>.<action>(...)" on the row's context
            await this.model.bindContext("CatalogService.increaseStock(...)", oContext).invoke();
            oContext.refresh(); // reload the row so the new stock shows
        },
        async onSave() {// require in case of group 'myGroup'.
            if (!this.model.hasPendingChanges()) return;
            await this.model.submitBatch();
        }
    });
});