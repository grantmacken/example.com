xquery version "3.0";

(:~
This module provides the functions that test my mf2 functions

@author Grant MacKenzie
@version 1.0
http://markup.co.nz/archive/2014/03/16/141619
:)
module namespace st="http://markup.co.nz/#st";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace mf2 = "http://markup.co.nz/#mf2"
    at "../mf2.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare
    %test:name("given URL when parsed for MF2 should return ")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619')
    %test:assertXPath("$result[1]")
function st:fetch( $url ) {
  mf2:parse( $url)
};


(:
declare
    %test:name("nothing here")
    %test:args('<p>nothing here</p>')
    %test:assertError('')
function st:nothing-here($node as element()) as element(){
  mf2:dispatch($node)
};

declare
    %test:name("nothing here also")
    %test:args('<p>nothing here</p>')
    %test:assertEmpty
function st:nothing-here-also($node as element()) as element()*{
  mf2:dispatch($node)
};

declare
    %test:name("entry with implied name")
    %test:args('<p class="h-entry">microformats.org at 7</p>')
    %test:assertExists
    %test:assertTrue
    %test:assertXPath("count($result) = 1")
    %test:assertXPath("local-name($result[1]) eq 'entry'")
    %test:assertXPath(" 'name' = local-name($result[1]/*) ")
    %test:assertXPath(" not('quack' = local-name($result[1]/*)) ")
function st:entry-with-just-a-name($node as element()) as element() {
        mf2:dispatch($node)
};






declare
    %test:name("parse (my url)")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619')
    %test:assertXPath("$result[1]")
function st:parse( $url ) {
    try {  mf2:parse( $url )}
    catch * {()}
};



declare
    %test:name("parse (adactio.com)")
    %test:args('http://adactio.com/notes/6820/')
    %test:assertXPath("$result[1]")
function st:parse( $url ) {
    try {  mf2:parse( $url )}
    catch * {()}
};

:)
