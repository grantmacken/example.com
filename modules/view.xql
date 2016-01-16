xquery version "3.0";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
(: import module namespace site="http://exist-db.org/apps/site-utils"; :)
(:include my modules here:)
(:############################################################################:)
import module namespace data-map="http://markup.co.nz/#data-map" at "data-map.xqm";
import module namespace site="http://markup.co.nz/#site" at "render/site.xqm";
import module namespace feed="http://markup.co.nz/#feed" at "render/feed.xqm";
import module namespace entry="http://markup.co.nz/#entry" at "render/entry.xqm";
(:############################################################################:)
(: declare output :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

let $config := map {
 $templates:CONFIG_APP_ROOT := $config:app-root,
 $templates:CONFIG_STOP_ON_ERROR := true()
 }

let $lookup := function($functionName as xs:string, $arity as xs:int) {
 try {
 function-lookup(xs:QName($functionName), $arity)
  } catch * {()}
 }

let $content := request:get-data()

return
 templates:apply($content, $lookup, (), $config)
