#!/usr/bin/env node
var  test = require('tape');
var Nightmare = require('nightmare');
var properties = require('properties-parser').read('./config');

var website = 'http://' + properties.NAME
test('example tap test using nightmare and tape', function (t) {
    t.plan(1);
    new Nightmare()
    .goto(website)
    .evaluate(function(){
        return document.title
    },function( title ){
        t.equal(title, properties.NAME, 'home page document title should repo name');
    } )
    .run();
}); 

