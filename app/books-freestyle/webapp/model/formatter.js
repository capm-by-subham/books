sap.ui.define([
	"sap/ui/core/library"
], function (coreLibrary) {
	"use strict";

	const ValueState = coreLibrary.ValueState;

	// [WHAT] Formatters = small pure functions used in bindings:  text="{path: 'stock', formatter: '.formatter.stockText'}"
	// [WHY]  keep display logic out of the views and testable (no side effects, same input -> same output)
	// [HOW]  controllers expose this module as this.formatter (see BaseController), so views can write '.formatter.xyz'
	return {

		// [WHAT] criticality (1 red, 2 orange, 3 green, 0/other neutral) -> ValueState for ObjectStatus/ObjectNumber
		// [TRY] return ValueState.Information for 0 -> neutral statuses turn blue
		criticalityToState: function (vCriticality) {
			switch (Number(vCriticality)) {
				case 1: return ValueState.Error;
				case 2: return ValueState.Warning;
				case 3: return ValueState.Success;
				default: return ValueState.None;
			}
		},

		// [WHAT] same idea, but from the stock number: 0 = red, < 10 = orange, else green
		stockState: function (iStock) {
			const n = Number(iStock);
			if (n <= 0) { return ValueState.Error; }
			if (n < 10) { return ValueState.Warning; }
			return ValueState.Success;
		},

		// [WHAT] icon next to the stock number
		stockIcon: function (iStock) {
			const n = Number(iStock);
			if (n <= 0) { return "sap-icon://error"; }
			if (n < 10) { return "sap-icon://alert"; }
			return "sap-icon://sys-enter-2";
		},

		// [WHAT] "4.5 / 5" for tooltips. OData V2 delivers Edm.Decimal as STRING ("4.5"), V4 as number.
		ratingText: function (vRating) {
			const n = parseFloat(vRating);
			return isNaN(n) ? "" : n.toFixed(1) + " / 5";
		},

		// [WHAT] cover image or a placeholder icon when there is none (e.g. a book created in the dialog)
		coverSrc: function (sUrl) {
			return sUrl || "sap-icon://course-book";
		}
	};
});
