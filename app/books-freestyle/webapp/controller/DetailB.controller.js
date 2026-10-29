sap.ui.define([
	"./BaseController",
	"sap/m/MessageToast"
], function (BaseController, MessageToast) {
	"use strict";

	// [WHAT] our own update group for this page. A group name WITHOUT "$" is DEFERRED: changes typed
	//        into fields are collected and only sent when we call submitBatch("bookChanges").
	const UPDATE_GROUP = "bookChanges";

	// [WHAT] Fiori elements binds the VIEW to /Books(<key>) from the route automatically.
	//        But FE uses $$updateGroupId "$auto" for that binding: in a NON-draft service every field
	//        change would be PATCHed immediately ("auto save"), and Cancel could not undo it.
	//        So we give the DynamicPage its own element binding with a deferred update group.
	//        The building blocks inside bind relative to it.
	// [TRY]  delete onInit/_onRouteMatched -> edit a field and watch the network tab: PATCH right away
	return BaseController.extend("booksfreestyle.controller.DetailB", {

		onInit: function () {
			BaseController.prototype.onInit.apply(this, arguments);
			this.getAppComponent().getRouter().getRoute("DetailB").attachPatternMatched(this._onRouteMatched, this);
		},

		_onRouteMatched: function (oEvent) {
			this.getV4Model().resetChanges(UPDATE_GROUP);
			this._setEditable(false);
			// route "Books({key})" -> key = "3" -> /Books(3)
			this.byId("detailB").bindElement({
				path: "/Books(" + oEvent.getParameter("arguments").key + ")",
				parameters: { $$updateGroupId: UPDATE_GROUP }
			});
		},

		// [WHAT] edit mode = FE's ui model, property /isEditable. All macros:Field/Form bind to it.
		// [WHY]  FE's editFlow.editDocument() only supports DRAFT or STICKY services ("Edit is only allowed
		//        for draft or sticky session supported services"). FreestyleService is plain (non-draft),
		//        so we switch the mode ourselves. With a draft service (AdminService) you'd call
		//        this.editFlow.editDocument(context) / saveDocument / cancelDocument instead.
		_setEditable: function (bEditable) {
			this.getView().getModel("ui").setProperty("/isEditable", bEditable);
		},

		onEdit: function () {
			this._setEditable(true);
		},

		// [WHAT] SAVE: send all collected changes of the group in one $batch (PATCH /Books(3))
		onSave: async function () {
			const oModel = this.getV4Model();
			if (!oModel.hasPendingChanges(UPDATE_GROUP)) {
				MessageToast.show(this.getText("noChanges"));
				this._setEditable(false);
				return;
			}
			await oModel.submitBatch(UPDATE_GROUP);
			// [WHY] submitBatch resolves even if the server rejected the PATCH. Failed changes stay pending,
			//       and the error is in the message model (MessageButton + red field).
			if (oModel.hasPendingChanges(UPDATE_GROUP)) { return; }
			MessageToast.show(this.getText("saved"));
			this._setEditable(false);
		},

		// [WHAT] CANCEL: throw away the collected changes -> fields show the server values again
		onCancel: function () {
			this.getV4Model().resetChanges(UPDATE_GROUP);
			this.clearMessages();
			this._setEditable(false);
		}
	});
});
