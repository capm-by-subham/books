sap.ui.define([
	"./BaseController",
	"sap/ui/model/Filter",
	"sap/ui/model/FilterOperator",
	"sap/m/MessageToast"
], function (BaseController, Filter, FilterOperator, MessageToast) {
	"use strict";

	// chart dimensions that also exist as filter fields in the sales filter bar
	const FILTERABLE_DIMENSIONS = ["region_code", "channel_code", "year", "genre_code", "book_ID"];

	return BaseController.extend("booksfreestyle.controller.PageB", {

		onInit: function () {
			BaseController.prototype.onInit.apply(this, arguments);
			// [WHAT] view state, same idea as on Page A. No model switching here: the building blocks
			//        use the component's default model = OData V4.
			this.createViewModel({
				section: "books",
				tableType: "responsive",
				hideDiscontinued: false,
				selectedCount: 0
			});
		},

		// ======================================================================
		// Books
		// ======================================================================
		onSearchBooks: function () {
			// [WHAT] the 'Go' event. getActiveFiltersText() -> "Filtered By: Genre (1)"
			MessageToast.show(this.byId("fbBooks").getActiveFiltersText() || "No filters");
		},

		onFilterChangedBooks: function () {
			// [WHAT] fired on every change of a filter value (before 'Go')
		},

		// [WHAT] beforeRebindTable of a building block: collectionBindingInfo has helper methods
		//        addFilter / addSorter / addSelect / attachEvent (sap.fe.macros.CollectionBindingInfo)
		// [WHY]  same purpose as SmartTable's beforeRebindTable (Page A), different API
		onBeforeRebindBooks: function (oEvent) {
			if (this.getView().getModel("view").getProperty("/hideDiscontinued")) {
				oEvent.getParameter("collectionBindingInfo").addFilter(
					new Filter("status_code", FilterOperator.NE, "D"));
			}
		},

		// [WHAT] re-run the search -> both tables rebind -> onBeforeRebindBooks adds/omits the filter
		onHideDiscontinuedChange: function () {
			this.byId("fbBooks").triggerSearch();
		},

		onSelectionChangeBooks: function () {
			this.getView().getModel("view").setProperty("/selectedCount",
				this.byId("tblBooks").getSelectedContexts().length);
		},

		// [WHAT] custom action: open the first selected book
		// [WHY]  this.routing.navigate(context) uses the manifest navigation config (Books -> DetailB)
		onOpenSelected: function () {
			const oContext = this.byId("tblBooks").getSelectedContexts()[0];
			if (oContext) {
				MessageToast.show(this.getText("rowPressedToast", [oContext.getProperty("title")]));
				this.routing.navigate(oContext);
			}
		},

		// ======================================================================
		// Sales: chart selection -> filter bar
		// ======================================================================
		// [WHAT] when bars are selected, put their dimension values into the FILTER BAR and search
		// [WHY]  shows the building block API: FilterBar.setFilterValues + triggerSearch.
		//        Difference to Page A: here the chart is filtered too (it follows the filter bar);
		//        Page A filters only the table. Both are valid UX patterns.
		onChartSelectionChange: async function () {
			const oChart = this.byId("chartSales");
			const aContexts = oChart.getSelectedContexts() || [];
			if (!aContexts.length) { return; }
			const oFilterBar = this.byId("fbSales");
			const oFirst = aContexts[0].getObject();
			for (const sDim of FILTERABLE_DIMENSIONS) {
				if (oFirst && sDim in oFirst) {
					const aValues = [...new Set(aContexts.map(c => c.getProperty(sDim)))];
					// [WHAT] setFilterValues(conditionPath, operator, values)
					await oFilterBar.setFilterValues(sDim, "EQ", aValues);
				}
			}
			oFilterBar.triggerSearch();
		}
	});
});
