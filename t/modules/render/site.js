casper.test.begin('Homepage', 1, function suite(test) {
    casper.start("http://gmack.nz", function() {
        test.assertTitle("gmack", "homepage title is the one expected");
    });

    casper.run(function() {
        test.done();
    });
});
