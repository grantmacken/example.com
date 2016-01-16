xquery version "3.0";
module namespace entry="http://markup.co.nz/#entry";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(:~
: ENTRY
: @author Grant MacKenzie
: @version 0.01
: info: pages vs posts
: this is the xQuery module for providing a html view of data in /data/pages
: pages are organised into folders
: unless it starts with an underscore ( e.g. _drafts, _tests , _styleguide )
: a pages folder determines what appears in the top-level-navigation
:)


declare
function entry:name($node as node(), $model as map(*)) {
 let $doc := map:get($model('entry'), 'doc')
return
 if( $doc/entry/name/text()  ) then (
  element {local-name($node)} {
  (  $doc/entry/name/text() )
  }
 )
 else()
};


declare
function entry:summary($node as node(), $model as map(*)) {
 let $doc := map:get($model('entry'), 'doc')
return
 if( $doc/entry/summary/text()  ) then (
  element {local-name($node)} {
  (  $doc/entry/summary/text() )
  }
 )
 else()
};

declare
function entry:content($node as node(), $model as map(*)) {
 let $doc := map:get($model('entry'), 'doc')
return
 if( $doc/entry/content  ) then (
  element {local-name($node)} {
  (  $doc/entry/content/node() )
  }
 )
 else()
};

