#!/usr/bin/env node
var  test = require('tape');
var  phantom = require('phantom'); 
// var driver = require('node-phantom-simple');
var properties = require('properties-parser').read('./config');
var website = 'http://' + properties.NAME

test('example tap test using phantom and tape', function (t) {
    t.plan(2);
    phantom.create(function (ph) {
        ph.createPage(function (page) {
            page.open(website, function (status) {
                t.equal(status, 'success', 'status should success');
                page.evaluate(function () {
                    return document.title;
                }, function (result) {
                    t.equal(result, properties.NAME, 'home page document title should repo name');
                    ph.exit();
                });
            });
        });
    });

});


 /*
test('example tap test using nightmare and tape', function (t) {
    t.plan(2);
    driver.create({ path: require('phantomjs').path }, function (err, browser) {
        return browser.createPage(function (err, page) {
            return page.open(website, function (err,status) {
                t.equal(status, 'success', 'status should success');
                return page.evaluate(function () { return document.title; }, function (result) {
                    t.equal(result, properties.NAME, 'home page document title should repo name');
                   browser.exit();
                });
            });
        });
    });
}); 
*/
