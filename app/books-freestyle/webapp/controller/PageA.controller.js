sap.ui.define([
	"./BaseController",
	"sap/ui/model/Filter",
	"sap/ui/model/FilterOperator",
	"sap/ui/model/json/JSONModel",
	"sap/m/MessageToast",
	"sap/m/MessageBox"
], function (BaseController, Filter, FilterOperator, JSONModel, MessageToast, MessageBox) {
	"use strict";

	// texts of chart dimensions, for the "Table filtered by chart selection: West" strip
	const TEXT_OF = { region_code: "regionName", channel_code: "channelName", book_ID: "bookTitle" };

	return BaseController.extend("booksfreestyle.controller.PageA", {

		onInit: function () {
			BaseController.prototype.onInit.apply(this, arguments);

			// [WHAT] view-state model "view" (busy flags, current section, counts, ...)
			this.createViewModel({
				section: "books",        // books | sales | tree
				tableType: "responsive", // responsive | grid
				liveMode: false,
				selectedCount: 0,
				filterSummary: "",
				chartFilterText: ""
			});

			// [WHAT] make the V2 model the DEFAULT model for everything inside the DynamicPage
			// [WHY]  smart controls (sap.ui.comp) always work with the default (unnamed) model, and they need V2.
			//        We set it on the page control, not on the view: the view itself keeps the V4 model,
			//        which the FE runtime (PageController extensions) expects.
			// [TRY]  comment this line out -> SmartTable logs "... model is not an ODataModel V2" and stays empty
			this.byId("pageA").setModel(this.getV2Model());
		},

		// ======================================================================
		// Section switch
		// ======================================================================
		onSectionChange: function () {
			this._updateFilterSummary();
		},

		// ======================================================================
		// SmartFilterBar (Books)
		// ======================================================================

		// [WHAT] fired once the filter bar has read the metadata and created its fields
		onFilterBarInitialized: function () {
			this._updateFilterSummary();
		},

		onSearchBooks: function () {
			this._updateFilterSummary();
		},

		onFilterChangeBooks: function () {
			this._updateFilterSummary();
		},

		// [WHAT] live mode on/off. The binding liveMode="{view>/liveMode}" already updated the filter bar.
		onLiveModeChange: function (oEvent) {
			MessageToast.show("liveMode = " + oEvent.getParameter("state"));
		},

		// [WHAT] the CUSTOM filter (Switch) changed. Tell the filter bar about it:
		// [WHY]  fireFilterChange marks the variant as modified ("*") and, in live mode, triggers a search
		onInStockChange: function (oEvent) {
			const oFilterBar = this.byId("sfbBooks");
			oFilterBar.fireFilterChange(oEvent);
			if (oFilterBar.getLiveMode()) {
				oFilterBar.search();
			}
		},

		// [WHAT] variant SAVE: put the custom field's value into the variant (key _CUSTOM)
		// [WHY]  the SmartFilterBar only knows its own fields; custom fields must be stored by us
		onBeforeVariantFetch: function () {
			this.byId("sfbBooks").setFilterData({
				_CUSTOM: { inStockOnly: this.byId("swInStock").getState() }
			});
		},

		// [WHAT] variant LOAD: restore the custom field from the variant
		onAfterVariantLoad: function () {
			const oData = this.byId("sfbBooks").getFilterData();
			this.byId("swInStock").setState(!!(oData._CUSTOM && oData._CUSTOM.inStockOnly));
		},

		// [WHAT] "Filtered By: Genre, Status (2)" for the collapsed header (snappedContent)
		_updateFilterSummary: function () {
			const oViewModel = this.getView().getModel("view");
			const sId = oViewModel.getProperty("/section") === "sales" ? "sfbSales" : "sfbBooks";
			const oFilterBar = this.byId(sId);
			oViewModel.setProperty("/filterSummary",
				oFilterBar.isInitialised() ? oFilterBar.retrieveFiltersWithValuesAsText() : "");
		},

		// ======================================================================
		// SmartTable (Books) — both table types share these handlers
		// ======================================================================

		// [WHAT] beforeRebindTable: called before EVERY data request of the table.
		//        bindingParams = { filters, sorter, parameters, events, ... } — change them as you like.
		// [WHY]  this is how custom filter fields, mandatory filters or extra $expand/$select get into the request
		onBeforeRebindBooks: function (oEvent) {
			const mBindingParams = oEvent.getParameter("bindingParams");

			// 1) our custom filter field "In stock only"
			if (this.byId("swInStock").getState()) {
				mBindingParams.filters.push(new Filter("stock", FilterOperator.GT, 0));
			}

			// 2) data events: e.g. recount the selection after new data arrived (selected rows may be gone)
			// [TRY] add `console.log(oEvt.getParameter("data"))` to see the raw V2 response
			mBindingParams.events = mBindingParams.events || {};
			mBindingParams.events.dataReceived = () => {
				const bGrid = this.getView().getModel("view").getProperty("/tableType") === "grid";
				return bGrid ? this.onGridSelectionChange() : this.onSelectionChange();
			};
		},

		onSelectionChange: function () {
			this.getView().getModel("view").setProperty("/selectedCount",
				this.byId("innerBooks").getSelectedItems().length);
		},

		onGridSelectionChange: function () {
			this.getView().getModel("view").setProperty("/selectedCount",
				this.byId("innerBooksGrid").getSelectedIndices().length);
		},

		// [WHAT] row press (ResponsiveTable) -> Detail A. listItem = the pressed row, its context = the book
		onRowPress: function (oEvent) {
			const oContext = oEvent.getParameter("listItem").getBindingContext();
			this.navTo("DetailA", { id: oContext.getProperty("ID") });
		},

		// [WHAT] row action press (GridTable)
		onGridRowPress: function (oEvent) {
			const oContext = oEvent.getParameter("row").getBindingContext();
			this.navTo("DetailA", { id: oContext.getProperty("ID") });
		},

		formatSelected: function (iCount) {
			return this.getText("selectedRows", [iCount]);
		},

		_getSelectedContexts: function () {
			return this.byId("innerBooks").getSelectedContexts();
		},

		// ======================================================================
		// Toolbar actions: Add Stock (V2 function import), Delete
		// ======================================================================

		// [WHAT] opens a small dialog (fragment) asking for the quantity
		onAddStock: async function () {
			const oContext = this._getSelectedContexts()[0];
			// [WHAT] loadFragment: loads fragment/AddStockDialog.fragment.xml ONCE; ids get the view prefix,
			//        so this.byId("addStockQty") works; the dialog becomes a dependent of the view
			this._pAddStock ??= this.loadFragment({ name: "booksfreestyle.fragment.AddStockDialog" });
			const oDialog = await this._pAddStock;
			oDialog.setModel(new JSONModel({ quantity: 5, title: oContext.getProperty("title") }), "addStock");
			oDialog.data("context", oContext); // remember the book (customData)
			oDialog.open();
		},

		onAddStockConfirm: function () {
			const oDialog = this.byId("addStockDialog");
			const oContext = oDialog.data("context");
			const iQuantity = oDialog.getModel("addStock").getProperty("/quantity");
			oDialog.close();

			// [WHAT] bound action addStock in OData V2 = a FUNCTION IMPORT "Books_addStock" (created by the adapter)
			//        with the key (ID) and the action parameters as URL parameters
			// [TRY]  look at the request in the browser's network tab: POST /odata/v2/freestyle/$batch
			//        containing POST Books_addStock?ID=3&quantity=5
			this.getV2Model().callFunction("/Books_addStock", {
				method: "POST",
				urlParameters: { ID: oContext.getProperty("ID"), quantity: iQuantity },
				success: (oData) => {
					MessageToast.show(this.getText("addStockDone", [oData.title, oData.stock]));
				}
				// error: nothing to do — backend errors land in the message model -> message button
			});
		},

		onAddStockCancel: function () {
			this.byId("addStockDialog").close();
		},

		// [WHAT] delete the selected books after confirmation
		onDelete: function () {
			const aContexts = this._getSelectedContexts();
			MessageBox.confirm(this.getText("deleteConfirm", [aContexts.length]), {
				onClose: (sAction) => {
					if (sAction !== MessageBox.Action.OK) { return; }
					const oModel = this.getV2Model();
					// [WHAT] remove() = DELETE request; all go into one $batch
					Promise.all(aContexts.map(oCtx => new Promise((resolve, reject) => {
						oModel.remove(oCtx.getPath(), { success: resolve, error: reject });
					}))).then(() => MessageToast.show(this.getText("deleted", [aContexts.length])));
				}
			});
		},

		// ======================================================================
		// Create dialog (freestyle form with client-side validation)
		// ======================================================================
		onOpenCreateDialog: async function () {
			this._pCreate ??= this.loadFragment({ name: "booksfreestyle.fragment.CreateBookDialog" });
			const oDialog = await this._pCreate;
			// [WHY] the dialog is a dependent of the VIEW (default model V4), but it reads Genres/Currencies
			//       from the V2 model -> give it the V2 model as its default model
			oDialog.setModel(this.getV2Model());
			// [WHAT] a fresh JSONModel per opening = the form data + the value states of the fields
			oDialog.setModel(new JSONModel({
				title: "", bookNo: "", genre_code: "ROM", price: 9.99, currency_code: "EUR", stock: 10, rating: 3,
				state: { title: "None", bookNo: "None", price: "None" }
			}), "create");
			oDialog.open();
		},

		// [WHAT] validation in JS: set ValueState + text on the fields, return true if all is fine
		_validateCreate: function (oData) {
			const oModel = this.byId("createDialog").getModel("create");
			const mState = {
				title: oData.title.trim() ? "None" : "Error",
				bookNo: /^BK-\d{4}$/.test(oData.bookNo) ? "None" : "Error",
				price: oData.price > 0 ? "None" : "Error"
			};
			oModel.setProperty("/state", mState);
			return Object.values(mState).every(s => s === "None");
		},

		// [WHAT] liveChange of the inputs: validate while typing
		onCreateLiveChange: function () {
			this._validateCreate(this.byId("createDialog").getModel("create").getData());
		},

		onCreateConfirm: function () {
			const oDialog = this.byId("createDialog");
			const oData = oDialog.getModel("create").getData();
			if (!this._validateCreate(oData)) {
				MessageToast.show(this.getText("validationFailed"));
				return;
			}
			oDialog.setBusy(true);
			// [WHAT] V2 model.create = POST /Books. Edm.Decimal values are sent as strings in V2.
			//        No ID: srv/freestyle-service.js assigns the next free one.
			this.getV2Model().create("/Books", {
				title: oData.title.trim(),
				bookNo: oData.bookNo,
				genre_code: oData.genre_code,
				price: String(oData.price),
				currency_code: oData.currency_code,
				stock: oData.stock,
				rating: String(oData.rating)
			}, {
				success: (oCreated) => {
					oDialog.setBusy(false);
					oDialog.close();
					MessageToast.show(this.getText("createdToast", [oCreated.title]));
					// navigate to the new book
					this.navTo("DetailA", { id: oCreated.ID });
				},
				error: () => {
					// e.g. "Book number BK-0001 already exists" -> message model (message button)
					oDialog.setBusy(false);
				}
			});
		},

		onCreateCancel: function () {
			this.byId("createDialog").close();
		},

		// ======================================================================
		// SmartChart -> filters the analytical table (chart selection)
		// ======================================================================

		// [WHAT] SmartChart is ready: get the INNER chart (sap.chart.Chart) and listen to selection
		onChartInitialized: function () {
			this.byId("scSales").getChartAsync().then((oChart) => {
				this._oChart = oChart;
				oChart.attachSelectData(this._onChartSelection, this);
				oChart.attachDeselectData(this._onChartSelection, this);
			});
		},

		// [WHAT] build ONE filter from all selected bars: (region = W) OR (region = E) ...
		//        Each data point has a binding context with the values of the visible dimensions.
		_onChartSelection: function () {
			const aDimensions = this._oChart.getVisibleDimensions();
			const aPoints = this._oChart.getSelectedDataPoints().dataPoints || [];
			const aTexts = [];
			const aPointFilters = aPoints.filter(p => p.context).map((oPoint) => {
				const aAnd = aDimensions.map((sDim) => {
					aTexts.push(oPoint.context.getProperty(TEXT_OF[sDim] || sDim));
					return new Filter(sDim, FilterOperator.EQ, oPoint.context.getProperty(sDim));
				});
				return new Filter({ filters: aAnd, and: true });
			});
			this._oChartFilter = aPointFilters.length ? new Filter({ filters: aPointFilters, and: false }) : null;
			this.getView().getModel("view").setProperty("/chartFilterText", [...new Set(aTexts)].join(", "));
			// [WHAT] rebindTable() -> beforeRebindTable -> new request with the filter
			this.byId("stSales").rebindTable();
		},

		onBeforeRebindSales: function (oEvent) {
			if (this._oChartFilter) {
				oEvent.getParameter("bindingParams").filters.push(this._oChartFilter);
			}
		},

		onClearChartSelection: function () {
			if (this._oChart) { this._oChart.setSelectedDataPoints([]); }
			this._oChartFilter = null;
			this.getView().getModel("view").setProperty("/chartFilterText", "");
			this.byId("stSales").rebindTable();
		},

		onSearchSales: function () {
			this._updateFilterSummary();
		},

		formatChartFilter: function (sText) {
			return this.getText("chartFilterInfo", [sText]);
		},

		// ======================================================================
		// TreeTable
		// ======================================================================
		// [WHAT] tree binding parameters: numberOfExpandedLevels = how many levels are expanded at the start
		// [TRY]  set it to 2 -> Fiction > Speculative > Fantasy all open
		onBeforeRebindTree: function (oEvent) {
			oEvent.getParameter("bindingParams").parameters.numberOfExpandedLevels = 1;
		}
	});
});
