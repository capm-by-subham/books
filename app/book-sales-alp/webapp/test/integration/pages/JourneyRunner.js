sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"booksalesalp/test/integration/pages/BookSalesList",
	"booksalesalp/test/integration/pages/BookSalesObjectPage"
], function (JourneyRunner, BookSalesList, BookSalesObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('booksalesalp') + '/test/flpSandbox.html#booksalesalp-tile',
        pages: {
			onTheBookSalesList: BookSalesList,
			onTheBookSalesObjectPage: BookSalesObjectPage
        },
        async: true
    });

    return runner;
});

