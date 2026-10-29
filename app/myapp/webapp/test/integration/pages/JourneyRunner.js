sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"myapp/test/integration/pages/AuthorsMain"
], function (JourneyRunner, AuthorsMain) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('myapp') + '/test/flp.html#app-preview',
        pages: {
			onTheAuthorsMain: AuthorsMain
        },
        async: true
    });

    return runner;
});

