sap.ui.define([
	"sap/ui/core/Control"
], function (Control) {
	"use strict";

	// [WHAT] A small CUSTOM CONTROL: shows a rating as ★★★★☆ and lets the user click a star when editable.
	// [WHY]  freestyle apps can define their own controls; Fiori elements apps can only use them in
	//        extension points. (sap.m.RatingIndicator exists — this is just to learn how controls work.)
	// [WHERE] Page A: 'Stars' column (both tables) + Detail A header/form; Page B: 'Stars' custom column;
	//         create dialog (editable)
	// [TRY]  in a view: <control:RatingStars value="3" maxValue="10" showValue="true"/>
	return Control.extend("booksfreestyle.control.RatingStars", {

		// [WHAT] metadata = the public API of the control: properties, aggregations, events
		metadata: {
			// [WHAT] interfaces: promises that the control can be used in certain places.
			// [WHY]  Form/SmartForm only accept controls implementing sap.ui.core.IFormContent, otherwise:
			//        "Element ... is not a valid Form content!" (Detail A uses RatingStars in a SmartForm)
			interfaces: ["sap.ui.core.IFormContent"],
			properties: {
				// [WHAT] the rating. type "float": UI5 validates values and converts bound model types to it.
				value: { type: "float", defaultValue: 0 },
				// [WHAT] number of stars
				maxValue: { type: "int", defaultValue: 5 },
				// [WHAT] clickable?  [TRY] bind it to {view>/editMode} (done on Detail A)
				editable: { type: "boolean", defaultValue: false },
				// [WHAT] show "4.5" next to the stars
				showValue: { type: "boolean", defaultValue: false }
			},
			events: {
				// [WHAT] fired when the user clicks a star (only if editable). Handler: change=".onRatingChange"
				change: {
					parameters: { value: { type: "float" } }
				}
			}
		},

		// [WHAT] V2 delivers Edm.Decimal as a string ("4.5"). Convert before the "float" type check runs.
		setValue: function (vValue) {
			const n = parseFloat(vValue);
			return this.setProperty("value", isNaN(n) ? 0 : n);
		},

		// [WHAT] browser events: a method "on" + event name is called automatically by UI5 (onclick, onkeydown, ...)
		onclick: function (oEvent) {
			if (!this.getEditable()) { return; }
			const sStar = oEvent.target.getAttribute("data-star");
			if (sStar) {
				const iValue = Number(sStar);
				// [WHAT] setValue updates a TwoWay binding -> the model changes -> e.g. SmartForm save sends it
				this.setValue(iValue);
				this.fireChange({ value: iValue });
			}
		},

		// [WHAT] the renderer writes the HTML. apiVersion 2 = the fast "semantic rendering" API
		//        (DOM patching instead of replacing innerHTML)
		renderer: {
			apiVersion: 2,
			render: function (oRm, oControl) {
				const fValue = oControl.getValue();
				const iMax = oControl.getMaxValue();
				const iFull = Math.round(fValue);

				// openStart(tag, control) writes the control id + data-sap-ui so UI5 finds the control again
				oRm.openStart("div", oControl);
				oRm.class("bfRatingStars");
				if (oControl.getEditable()) { oRm.class("bfEditable"); }
				// accessibility: screen readers read "Rating 4.5 of 5"
				oRm.attr("role", "img");
				oRm.attr("aria-label", "Rating " + fValue + " of " + iMax);
				oRm.attr("title", fValue.toFixed(1) + " / " + iMax);
				oRm.openEnd();

				for (let i = 1; i <= iMax; i++) {
					oRm.openStart("span");
					oRm.class("bfStar");
					if (i <= iFull) { oRm.class("bfStarOn"); }
					oRm.attr("data-star", String(i));
					oRm.openEnd();
					oRm.text(i <= iFull ? "★" : "☆"); // ★ / ☆
					oRm.close("span");
				}

				if (oControl.getShowValue()) {
					oRm.openStart("span");
					oRm.class("bfRatingValue");
					oRm.openEnd();
					oRm.text(fValue.toFixed(1));
					oRm.close("span");
				}
				oRm.close("div");
			}
		}
	});
});
