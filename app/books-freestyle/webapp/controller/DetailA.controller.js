sap.ui.define([
	"./BaseController",
	"sap/m/MessageToast"
], function (BaseController, MessageToast) {
	"use strict";

	return BaseController.extend("booksfreestyle.controller.DetailA", {

		onInit: function () {
			BaseController.prototype.onInit.apply(this, arguments);
			this.createViewModel({ editMode: false, busy: false });

			// [WHAT] V2 model as default model of the page (see PageA.controller.js for the why)
			this.byId("detailA").setModel(this.getV2Model());

			// [WHAT] called every time the URL matches #/classic/book/{id}
			this.getAppComponent().getRouter().getRoute("DetailA").attachPatternMatched(this._onRouteMatched, this);
		},

		// [WHAT] bind the page to ONE book: /Books(3)
		// [WHY]  bindElement = "element binding": all relative bindings inside ({title}, {price}, ...) read from it
		_onRouteMatched: function (oEvent) {
			const sId = oEvent.getParameter("arguments").id;
			const oModel = this.getV2Model();
			// leave edit mode + throw away unsaved changes from a previous book
			oModel.resetChanges();
			this.getView().getModel("view").setProperty("/editMode", false);
			this.clearMessages();

			this.byId("detailA").bindElement({
				// [WHAT] createKey builds the key path from the metadata: "/Books(3)"
				path: "/" + oModel.createKey("Books", { ID: Number(sId) }),
				events: {
					dataRequested: () => this.getView().getModel("view").setProperty("/busy", true),
					dataReceived: () => this.getView().getModel("view").setProperty("/busy", false)
				}
			});
		},

		onEdit: function () {
			this.getView().getModel("view").setProperty("/editMode", true);
		},

		// [WHAT] SAVE: 1) client-side check of all SmartFields  2) send all pending changes in one $batch
		onSave: async function () {
			const oModel = this.getV2Model();
			const oForm = this.byId("sfBook");

			// [WHAT] SmartForm.check() validates every field (types, mandatory). validationMode="Async"
			//        -> it returns a Promise with the ids of the erroneous fields
			const aErrors = await oForm.check();
			if (aErrors.length) {
				MessageToast.show(this.getText("validationFailed"));
				return;
			}

			// [WHAT] pending changes = what TwoWay bindings wrote into the V2 model since the last save
			if (!oModel.hasPendingChanges()) {
				MessageToast.show(this.getText("noChanges"));
				this.getView().getModel("view").setProperty("/editMode", false);
				return;
			}

			this.getView().getModel("view").setProperty("/busy", true);
			// [WHAT] submitChanges sends the deferred group "changes" (default for TwoWay changes) as one $batch
			//        with a MERGE /Books(3) inside
			oModel.submitChanges({
				success: (oData) => {
					this.getView().getModel("view").setProperty("/busy", false);
					// [WHY] a $batch is HTTP 200 even when a change inside fails -> look at the inner responses
					const bFailed = (oData.__batchResponses || []).some(r =>
						r.response && Number(r.response.statusCode) >= 400 ||
						(r.__changeResponses || []).some(c => Number(c.statusCode) >= 400));
					if (bFailed) { return; } // error messages are already in the message model -> message button
					MessageToast.show(this.getText("saved"));
					this.getView().getModel("view").setProperty("/editMode", false);
				},
				error: () => this.getView().getModel("view").setProperty("/busy", false)
			});
		},

		// [WHAT] CANCEL: throw away all pending changes -> the fields show the old values again
		onCancel: function () {
			this.getV2Model().resetChanges();
			this.clearMessages();
			this.getView().getModel("view").setProperty("/editMode", false);
		}
	});
});
