sap.ui.define([
	"sap/fe/core/PageController",
	"sap/ui/model/json/JSONModel",
	"sap/ui/core/Messaging",
	"sap/m/MessagePopover",
	"sap/m/MessageItem",
	"sap/base/strings/formatMessage",
	"../model/formatter"
], function (PageController, JSONModel, Messaging, MessagePopover, MessageItem, formatMessage, formatter) {
	"use strict";

	// [WHAT] Common base for all page controllers of this app.
	// [WHY]  it extends sap.fe.core.PageController (not sap.ui.core.mvc.Controller): every page is an
	//        FPM custom page, and PageController gives us the FE controller extensions:
	//        this.routing (navigate), this.editFlow (edit/save on V4), this.intentBasedNavigation, ...
	return PageController.extend("booksfreestyle.controller.BaseController", {

		// [WHAT] makes the formatter usable in views as '.formatter.stockState'
		formatter: formatter,

		// [WHAT] formatMessage("Add Stock to \"{0}\"", "Jane Eyre") -> 'Add Stock to "Jane Eyre"'
		//        used in views with parts: ['i18n>key', 'model>/value'], formatter: '.formatMessage'
		formatMessage: formatMessage,

		onInit: function () {
			// [WHAT] ALWAYS call the parent onInit: it initialises the FE controller extensions
			PageController.prototype.onInit.apply(this, arguments);

			// [WHAT] the message model: one central list of all messages (validation + backend errors),
			//        filled by sap.ui.core.Messaging for both the V2 and the V4 model
			// [WHERE] the message button in each page title, bound to {message>/}
			this.getView().setModel(Messaging.getMessageModel(), "message");
		},

		// ---------- small helpers ----------

		// [WHAT] text from i18n/i18n.properties with placeholders: getText("deleted", [3]) -> "3 book(s) deleted"
		getText: function (sKey, aArgs) {
			return this.getAppComponent().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
		},

		// [WHAT] the OData V2 model (manifest model "v2") and the V4 model (default model "")
		getV2Model: function () {
			return this.getAppComponent().getModel("v2");
		},
		getV4Model: function () {
			return this.getAppComponent().getModel();
		},

		// [WHAT] page-local view-state model: busy flags, edit mode, counts, ... (named "view")
		// [WHY]  UI state belongs in a JSONModel, not in controller variables: views can BIND to it
		createViewModel: function (oData) {
			const oModel = new JSONModel(oData);
			this.getView().setModel(oModel, "view");
			return oModel;
		},

		// [WHAT] navigate to a route of manifest.json (sap.ui5.routing.routes[].name)
		// [WHY]  in an FE app, use the FE routing extension instead of router.navTo: it keeps FE's
		//        internal navigation state (back navigation, context handling) consistent
		navTo: function (sRoute, oParams) {
			return this.routing.navigateToRoute(sRoute, oParams || {});
		},

		onNavBack: function () {
			// [WHAT] browser history back (keeps filters/variants of the previous page) or Home
			if (window.history.length > 1) {
				window.history.go(-1);
			} else {
				this.navTo("Home");
			}
		},

		// [WHAT] opens the message popover next to the pressed button (created once, reused)
		onMessagePopoverPress: function (oEvent) {
			if (!this._oMessagePopover) {
				this._oMessagePopover = new MessagePopover({
					items: {
						path: "message>/",
						template: new MessageItem({
							type: "{message>type}",           // Error, Warning, Success, Information
							title: "{message>message}",
							subtitle: "{message>additionalText}",
							description: "{message>description}"
						})
					}
				});
				// [WHY] addDependent: popover gets the view's models (message, i18n) and is destroyed with the view
				this.getView().addDependent(this._oMessagePopover);
			}
			this._oMessagePopover.toggle(oEvent.getSource());
		},

		// [WHAT] remove all messages (e.g. after cancel)
		clearMessages: function () {
			Messaging.removeAllMessages();
		}
	});
});
