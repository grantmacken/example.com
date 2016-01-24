xquery version "3.1";
module namespace data-map="http://markup.co.nz/#data-map";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://exist-db.org/xquery/apps/config"  at "config.xqm";
import module namespace session="http://exist-db.org/xquery/session";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace  xhtml =  "http://www.w3.org/1999/xhtml";
declare namespace  atom =  "http://www.w3.org/2005/Atom";



(:~
 : Maps are efficient in-memory structures implimented using a hash tables
 : ( key:value pairs ) Key Values stored in the Map can be used later on.
 : Like JavaScript these values can be functions.
 : Our Model as Map is used to pass information between templating instructions
 :
 : @param $node  	the sequence of nodes which will be processed
 : @param $model
 : @return Map  a sequence of items which will be passed to all called template
 : functions. Use this to pass information between templating instructions.
 : http://atomic.exist-db.org/blogs/eXist/XQueryMap
:)



(:~
Notes:
reworking my data-map

Every 'html page' served has access to the data-map
which will enable the 'template page' to generate

1. navigational links
2. page element items, titles, content, etc


What to include in my data-map

* path data: {mpPaths}  fixed common shorthand vars in one place

* site data:  {$mpSite}	site wide data

* request: {$mpRequest}

* link-rel: this URLs link relationships:
 contains	$mpNav

* data object :

  a templated  page can be generated from data pulled from

  1. a page-entry:
		template URI ```/{collection}/{item}```
		data item:  a stored 'atom-entry' document item located under named collection

	2. a post-entry:  archived entry ( a entry  that is a  blog post )
	  template URI ```/archive/{year}/{month}/{day}/{item}```
		data item:  a stored 'atom-entry' document item located in a date stamped collection

  3. a generated query:
		a result of a query of collections and resources stored in the the database:

		1. feed: list-entries  summarised last 20 posted entries.
			template URI ```/index```
			data item:  a sequence of items

		2. feed: archived-entries  :  index of  posted entries organised by date
				template URI ```/archive/index```  archive template
				template URI ```/archive/{year}/index```  archive-year template
				template URI ```/archive/{year}/{month}/index```  archive-year-month template

		3. tags:    entries tagged as {tagname}
				template URI ```/tags/{tagname}```  tags template


:)




declare
function data-map:loadPageModel($node as node(), $model as map(*)) {
(:  some usefull vars :)
let $app-data := $config:data-root
let $app-root := templates:get-app-root($model)
let $site-domain := substring-after($app-root, 'apps/' )
let $site-title := config:expath-descriptor()/expath:title/text()
let $site-name := config:expath-descriptor()/@name/string()
let $site-abbrev := config:expath-descriptor()/@abbrev/string()

(:  Maps :)
let $mpPaths :=
 map {
 'data' :=
  map {
   'pages' := xs:anyURI( $app-data || '/pages'),
   'posts' := xs:anyURI($app-data || '/archive'),
   'citations' := xs:anyURI($app-data || '/citations')
  }
 }

let $mpSite := map {
  'name'  := $site-name,
  'title'  := $site-title,
  'abbrev'  := $site-abbrev,
  'domain' := $site-domain
 }

let $mpRequest := map {
  'path'  := request:get-parameter('exist-path',()),
  'resource'  := request:get-parameter('exist-resource',()),
  'remote-addr' := request:get-remote-addr(),
  'header-names' := request:get-header-names(),
  'IP' := request:get-header('X-Real-IP'),
  'is-localhost' := string(request:get-header('X-Real-IP'))  eq '127.0.0.1',
  'nginx-request-uri' := request:get-header('nginx-request-uri')
 }

(:  Functions :)

let $getDataCollection :=  function( $col ){
 map:get($mpPaths('data'), $col )
}

let $getItemName :=  function(){
 substring-before( $mpRequest('resource'), '.html')
}

let $getItemCollection :=  function(){
 if( matches($mpRequest('path'), '^/index.html$')) then ('home')
 else( substring-before(substring-after($mpRequest('path'), '/'), '/'))
}

let $isItemIndex :=  function(){
 $getItemName()  eq 'index'
}

let $getItemType :=  function(){
 if( $getItemCollection() eq 'archive') then ('posts')
 else ('pages')
}


let $getDataPath := function(){
 if( $getItemCollection() eq 'home')
  then (
   $getDataCollection('pages') ||
   '/'||
   $getItemName() ||
   '.xml'
   )
 else if (matches($mpRequest('path') ,'^/archive/index.html$'))
  then (
   $getDataCollection('posts') ||
   '/'||
   $getItemName() ||
   '.xml'
   )
 else if (contains($mpRequest('path') ,'/archive/'))
  then (
   $getDataCollection('posts') ||
   '/'||
   substring-before(
	substring-after($mpRequest('path'), '/archive/'),
		concat('/', $mpRequest('resource'))
   ) || '/' ||
   $getItemName() ||
   '.xml'
  )
 else(
  $getDataCollection('pages') ||
  '/' ||
  substring-before(
   substring-after($mpRequest('path') , '/'),
	   concat( '/', $mpRequest('resource'))
  ) || '/' ||
  $getItemName() ||
  '.xml'
  )
}

let $getDoc := function( $path ){
 let $docAvailable := doc-available( $path)
return
 if( $docAvailable ) then (doc( $path ))
 else()
}

let $seqPages :=
 ('home', 'archive',
  distinct-values (
   xmldb:get-child-collections (
	$getDataCollection('pages')
   )[not(starts-with(.,'_'))][not( . eq 'home' )]
  )
 )
 

let $mpNav := map {
 'top-level-pages' := $seqPages,
 'item'  :=  $getItemName(),
 'item-is-index' := $isItemIndex(),
 'item-collection'	:= $getItemCollection(),
 'item-type'	:= $getItemType(),
 'data-path' := $getDataPath()
 }


let $mpEntry := map {
 'path' := $getDataPath(),
 'doc'  := $getDoc($getDataPath())
}

let $mpData := map {
 'type' := $getItemType(),
 'is-index' := $isItemIndex(),
 'item'	:= $getItemType()
}

(:
let $jsn := '{
 "site-title": "' || $site-name || '"
 }'
let $options := map {"liberal": true()}
let $map := parse-json($jsn,$options)


return
    element {local-name($node)} {
    templates:process(
      $node/node(),
      map:new((
       $model, $map
      ))
      )
     }
};
:)
return
    element {local-name($node)} {
    templates:process(
      $node/node(),
      map:new((
       $model,
        map {
        'data' := $mpData,
        'entry' := $mpEntry,
        'nav' := $mpNav,
        'paths':= $mpPaths,
        'request' := $mpRequest,
        'site' := $mpSite
        }
      ))
      )
     }
};
