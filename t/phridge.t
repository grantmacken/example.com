#!/usr/bin/env node
var  test = require('tape');
// var driver = require('node-phantom-simple');
var properties = require('properties-parser').read('./config');
var website = 'http://' + properties.NAME
var phridge = require("phridge");

test('example tap test using phridge and tape', function (t) {
    t.plan(1);
    phridge.spawn().then(function(phantom) {
        return phantom.openPage("http://example.com");})
        .then(
            function(page) {
                return page.run(function() {
                    return this.evaluate(function() {
                        return  { 'title': document.title }
                    });
                });
            })
            .finally(phridge.disposeAll)
            .done(function (jsn) {
                t.equal(jsn.title, properties.NAME, 'home page document title should repo name');
            }, function (err) {
                throw err;
            });
});
