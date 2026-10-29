sap.ui.define([
	"sap/fe/core/AppComponent",
	"sap/ui/model/json/JSONModel",
	"sap/ui/Device"
], function (AppComponent, JSONModel, Device) {
	"use strict";

	// [WHAT] The app component. It extends sap.fe.core.AppComponent (NOT sap.ui.core.UIComponent).
	// [WHY]  sap.fe.macros building blocks (Page B) only work inside an app run by the Fiori elements
	//        runtime: it provides the templating, the routing service, editFlow, side effects, ...
	//        Every page is still a custom XML view with our own controller ("Flexible Programming Model"),
	//        so we can put any control on it — also sap.ui.comp smart controls (Page A).
	// [TRY]  change it to "sap/ui/core/UIComponent" -> Page A still works, Page B fails to template.
	return AppComponent.extend("booksfreestyle.Component", {
		metadata: {
			// [WHAT] read everything (models, routing, libraries) from webapp/manifest.json
			manifest: "json"
		},

		init: function () {
			// [WHAT] always call the parent init first: it creates the models and starts the router
			AppComponent.prototype.init.apply(this, arguments);

			// [WHAT] app-wide state model (JSONModel = client-side only, never sent to a server)
			// [WHY]  pages share it through the component, e.g. the Home page shows how often a page was opened
			// [TRY]  in the browser console: sap.ui.core.Component.get("booksfreestyle").getModel("app").getData()
			this.setModel(new JSONModel({
				visits: { classic: 0, blocks: 0 }
			}), "app");

			// [WHAT] device model: phone/tablet/desktop, touch, orientation -> bind e.g. stretch="{device>/system/phone}"
			// [WHY]  OneWay: the app must never write into it
			const oDeviceModel = new JSONModel(Device);
			oDeviceModel.setDefaultBindingMode("OneWay");
			this.setModel(oDeviceModel, "device");
		}
	});
});
