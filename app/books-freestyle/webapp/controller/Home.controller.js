sap.ui.define([
	"./BaseController"
], function (BaseController) {
	"use strict";

	return BaseController.extend("booksfreestyle.controller.Home", {

		onInit: function () {
			BaseController.prototype.onInit.apply(this, arguments);

			// [WHAT] view-state model "view": the KPI numbers and a busy flag
			// [WHY]  the KPIs are CALCULATED in JS, so they live in a JSONModel the view binds to
			this.createViewModel({ busy: true, bookCount: 0, totalStock: 0, lowStockCount: 0 });

			// [WHAT] load the KPIs every time the Home route is shown (not only once)
			this.getAppComponent().getRouter().getRoute("Home").attachPatternMatched(this._loadKpis, this);
		},

		// [WHAT] reads all books once through the V4 model and computes the KPIs
		// [WHY]  shows how to read data in code (bindList + requestContexts) instead of binding a control
		_loadKpis: async function () {
			const oViewModel = this.getView().getModel("view");
			oViewModel.setProperty("/busy", true);
			try {
				// [WHAT] bindList(path, context, sorters, filters, parameters) -> requestContexts(start, length)
				//        sends GET /odata/v4/freestyle/Books?$select=ID,stock&$skip=0&$top=1000
				const oList = this.getV4Model().bindList("/Books", null, [], [], { $select: "ID,stock" });
				const aContexts = await oList.requestContexts(0, 1000);
				const aStocks = aContexts.map(c => c.getProperty("stock") || 0);
				oViewModel.setData({
					busy: false,
					bookCount: aStocks.length,
					totalStock: aStocks.reduce((a, b) => a + b, 0),
					lowStockCount: aStocks.filter(s => s < 10).length
				}, true); // true = merge into the existing data
			} finally {
				oViewModel.setProperty("/busy", false);
			}
		},

		onRefresh: function () {
			this._loadKpis();
			// [WHAT] refresh() reloads every V4 binding (the low-stock list too)
			this.getV4Model().refresh();
		},

		// [WHAT] formatter defined in the controller (used as '.formatVisits' in the view)
		formatVisits: function (iCount) {
			return this.getText("homeVisits", [iCount || 0]);
		},

		onOpenPageA: function () {
			const oApp = this.getAppComponent().getModel("app");
			oApp.setProperty("/visits/classic", oApp.getProperty("/visits/classic") + 1);
			this.navTo("PageA");
		},

		onOpenPageB: function () {
			const oApp = this.getAppComponent().getModel("app");
			oApp.setProperty("/visits/blocks", oApp.getProperty("/visits/blocks") + 1);
			this.navTo("PageB");
		},

		// [WHAT] list item press -> Detail B (V4). Route "Books({key})", key = the book ID
		onLowStockPress: function (oEvent) {
			const oContext = oEvent.getSource().getBindingContext();
			this.navTo("DetailB", { key: oContext.getProperty("ID") });
		}
	});
});
