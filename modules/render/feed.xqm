xquery version "3.0";
module namespace feed="http://markup.co.nz/#feed";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace note="http://markup.co.nz/#note" at "../lib/note.xqm";
(:~
: FEED
: @author Grant MacKenzie
: @version 0.01
: info: pages vs posts
: this is the xQuery module for providing a 'feed' view of data in /data/posts
: posts are organised into date-stamped folders
:
: date view 'landing pages'
:   a feed of last 20 entries /archive
:   a feed of enties for month etc  /archive/YY/MM
: tagged view (all posted categorised as ) /tags/[tag-name]
: search view
:)

declare
function feed:list-entries($node as node(), $model as map(*)) {
 let $dataPath := map:get(map:get($model('paths'), 'data'), 'posts')
 let $seq := for $item in collection($dataPath)//entry
             order by xs:dateTime($item/published) descending
             return $item

 return for $item  at $i in $seq
   where $i lt 20
   return
    templates:process(
      element article {
       attribute class {
       'templates:include?path=templates/includes/sections/archive-feed-entry.html' }
       },
      map:new(($model, map { "item" := $item }))
      )
};

declare
function feed:archived-entries($node as node(), $model as map(*)) {
 let $itemCount :=  function( $seq ){
                             if( count( $seq ) eq 1 )
                             then(  string(count( $seq )) ||  ' post')
                             else( string(count( $seq )) ||  ' posts') }

 let $getMonth :=  function( $month ){
  ('January', 'February', 'March', 'April', 'May', 'June','July', 'August', '
   September', 'October', 'November', 'December')[$month]
   }

 let $dataType := map:get($model('data'), 'type')
 let $dataPath := map:get(map:get($model('paths'), 'data'), 'posts')

 let $seq := for $item in collection($dataPath)//entry
             order by xs:dateTime($item/published) descending
             return $item

 return for $item  at $i in $seq
   group by $year := year-from-dateTime($item/published)
   order by $year descending
   return
   <dl>
      <dt><strong>{$year}</strong>{ ': '  || $itemCount($year) }</dt>
         <dd>{
         for $itm in $item
            group by $month := month-from-dateTime($itm/published)
            order by $month descending
         return
            <dl>
               <dt><strong>{$getMonth($month)}</strong>{ ': ' || $itemCount($itm)}</dt>
               <dd><ol>{
                for $i in $itm
                order by day-from-dateTime($i/published) descending
                return
                templates:process(
                 element {  local-name($node) } {
                  attribute class {
                  'templates:include?path=templates/includes/sections/archive-feed-entry.html' }
                  },
                 map:new(($model, map { "item" := $i }))
                 )
               }</ol></dd>
              </dl>
         }</dd>
   </dl>
};




(: no titles for notes and comments:)
declare
function feed:entry-name($node as node(), $model as map(*)) {
  let $item :=  $model('item')
  return
   switch (feed:getPostType($item))
    case "note"
    case "comment"
      return ()
    default
     return
     element {  local-name($node) } {
      attribute class { $node/@class/string() },
      $model('item')//name/string()
      }
};

declare
function feed:entry-permalink($node as node(), $model as map(*)) {
 let $item :=  $model('item')
 let $svgNode :=  $node//*[1]
  return
  element {local-name($node)} {
   attribute class {'u-url'},
   attribute href {$item/url/string()},
   attribute title {$item/name/string()},
    element {local-name($svgNode)} {
    attribute class {$svgNode/@class/string()},
      <use xmlns:xlink="http://www.w3.org/1999/xlink"
           xlink:href="#{feed:getPostType($item)}"/>
    },
  $item/name/string()
  }
};


declare
function feed:entry-summary($node as node(), $model as map(*)) {
 if( empty(feed:getSummary($model('item'))) ) then ()
 else (
  element {local-name($node) } {
       attribute class { $node/@class/string() },
       feed:getSummary($model('item'))
   }
   )
};

declare
function feed:entry-published($node as node(), $model as map(*)) {
  if(  empty( $model('item')//published ) ) then ()
  else(
  let $item :=  $model('item')
  let $published :=  xs:dateTime( $item/published/string() )
  let $publishedFormated := format-date($published , "[D1o] of [MNn] [Y]", "en", (), ())
   return
    element {  local-name($node) } {
       attribute class { $node/@class/string() },
       attribute datetime { $published },
       $publishedFormated
      }
   )

};



declare
function feed:getPostType($item) {
 let $flags := ''
 let $input := $item/uid/string()
 let $pattern := "(:)"
 let $seqIdentifier := tokenize($input, $pattern)
 return  $seqIdentifier[3]
};

declare
function feed:getSummary($item) {
  switch (feed:getPostType($item))
   case "note"
   case "comment"
     return
      if(empty(feed:getNoteFirstLine($item/content/text()) )) then ()
      else ( feed:getNoteFirstLine($item/content/text()))
   default
    return
     if(empty($item/summary/text())) then ()
     else($item/summary/string())

};


declare
function feed:getNoteFirstLine($text) {
   let $input := note:trim($text)
   let $line := note:seqLines($input)[1]
   let $replaced := '<div>' || note:hashTag(note:urlToken($line)) || '<br/>' || '</div>'

   return util:parse($replaced )/*/node()
};
