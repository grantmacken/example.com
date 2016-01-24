xquery version "3.1";
module namespace site="http://markup.co.nz/#site";
(:~
: SITE
: @author Grant MacKenzie
: @version 0.01
: @see  
:)

declare
function site:info($node as node(), $model as map(*)) {
  element {'dl'}{
    element {'dt'}{'site: name'},
    element {'dd'}{map:get($model('site'), 'name')},
    element {'dt'}{'site: abbrev'},
    element {'dd'}{map:get($model('site'), 'abbrev')},
    element {'dt'}{'request: IP'},
    element {'dd'}{map:get($model('request'), 'IP')},
    element {'dt'}{'request: is localhost'},
    element {'dd'}{map:get($model('request'), 'is-localhost')},
    element {'dt'}{'request: nginx-request-uri'},
    element {'dd'}{map:get($model('request'), 'nginx-request-uri')},
    element {'dt'}{'request: header-names'},
    element {'dd'}{map:get($model('request'), 'header-names')}
  }
};

declare
function site:ip($node as node(), $model as map(*)) {
  element {local-name($node)} {
  (  map:get($model('request'), 'IP')  )
  }
};

declare
function site:is-localhost($node as node(), $model as map(*)) {
  element {local-name($node)} {
  (  map:get($model('request'), 'is-localhost')  )
  }
};

declare
function site:nginx-request-uri($node as node(), $model as map(*)) {
  element {local-name($node)} {
  (  map:get($model('request'), 'nginx-request-uri')  )
  }
};

declare
function site:header-names($node as node(), $model as map(*)) {
  element {local-name($node)} {
  (  map:get($model('request'), 'header-names')  )
  }
};

declare
function site:script-livereload($node as node(), $model as map(*)) {
if ( map:get($model('request'), 'is-localhost') ) then (
  <script src=" http://127.0.0.1:35729/livereload.js?snipver=1"></script>
)
else ()
};

declare
function site:title($node as node(), $model as map(*)) {
  element {local-name($node)} {
  ( map:get($model('site'),'title' ))
  }
};

declare
function site:name($node as node(), $model as map(*)) {
  element {local-name($node)} {
  ( map:get($model('site'), 'name') )
  }
};

declare
function site:abbrev($node as node(), $model as map(*)) {
  element {local-name($node)} {
   ( map:get($model('site'), 'abbrev') )
  }
};

declare
function site:pages-nav($node as node(), $model as map(*)) {
let $home := map:get(map:get($model, 'site'), 'abbrev')
let $seq := map:get(map:get($model, 'nav'), 'top-level-pages')
let $reqItem := map:get(map:get($model, 'nav'), 'item')
let $isItemIndex := map:get(map:get($model, 'nav'), 'item-is-index')
let $itemCollection := map:get(map:get($model, 'nav'), 'item-collection')
(:TODO: remove below :)
let $itemPath := map:get(map:get($model, 'request'), 'path')
let $dataPath := map:get(map:get($model, 'nav'), 'data-path')
(:TODO: remove above :)
let $listItems :=
  for $item at $i in  $seq
  return
  if($item eq  'home') then(
    if( $item eq  $itemCollection)
         then (<li><strong>{$home}</strong></li>)
    else (<li><a href="/">{$home}</a></li> )
    )
  else(
    if( $item eq  $itemCollection ) then (
      if( $isItemIndex )
        then(
        <li><strong>{$item}</strong></li>
        )
      else(
        <li>
            <a  class="under-collection" href="/{$item}">{$item}</a>
        </li>
        )
      )
      else (<li><a href="/{$item}">{$item}</a></li> )
  )
return
      <ul>
          {$listItems}
      </ul>
};
