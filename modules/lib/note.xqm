xquery version "3.0";
module namespace note="http://markup.co.nz/#note";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://exist-db.org/xquery/apps/config"  at "../../modules/config.xqm";

declare namespace  xhtml =  "http://www.w3.org/1999/xhtml";
declare namespace  atom =  "http://www.w3.org/2005/Atom";

(:~
: Note
: @author Grant MacKenzie
: @version 0.01
:
: a note is plain text
: the server auto generates inline content
:
: hyperlinks
:
: 	@person links to people
:       #hashTags
:       machinetags
	    https://www.flickr.com/groups/api/discuss/72157594497877875
	    http://www.aaronland.info/talks/mw10_machinetags/#102
	    http://tagaholic.me/2009/03/26/what-are-machine-tags.html
: images
: hash tags
:
: http://aaronparecki.com/articles/2013/05/09/1/experimenting-with-auto-embedding-content
: http://sandeep.shetty.in/2013_06_01_archive.html
:)

declare
function note:seqLines($input) {
 let $flags := ''
 let $pattern := '\n\r?'
 let $seqLines := tokenize($input, $pattern)
return $seqLines
};


declare
function note:trim($input) {
  let $flags := 'm'
  let $pattern := '^\s+|\s+$'
  let $replacement := ''
  return  replace($input, $pattern , $replacement, $flags )
};


declare
function note:urlToken($input) {
  let $flags := ''
  let $pattern := '(https?://[\da-z\.-]+\.[a-z\.]{2,6}[\da-z/-]+)'
  let $replacement := '<a href="$1">$1</a>'
  return  replace($input, $pattern , $replacement, $flags )
};


declare
function note:hashTag($input) {
  let $flags := ''
  let $pattern := "(^|\s)((#)([A-Za-z]+[A-Za-z0-9_]{1,15}))(\s|$)"
  let $replacement := '<span>$1$3<a href="/tag/$4">$4</a>$5</span>'
  return  replace($input, $pattern , $replacement, $flags )
};
