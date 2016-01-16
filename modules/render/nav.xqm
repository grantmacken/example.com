xquery version "3.0";
module namespace nav="http://markup.co.nz/#nav";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace system="http://exist-db.org/xquery/system";

declare default element namespace "http://www.w3.org/1999/xhtml";



(:~
A nav element containing a list of navigation items.
The navigation items contain anchors apart from the
'[You are here](http://www.w3.org/wiki/Creating_multiple_pages_with_navigation_menus#Site_navigation)'
item which tells the visitor the they are at the location.
:)

declare
function nav:pages($node as node(), $model as map(*)) {
let $log := util:log-app("DEBUG", "myapp", 'MyApp log message')
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
        then (<li><strong>{$item}</strong></li>)
      else (<li><a href="/">{$item}</a></li> )
      )
    else(
      if( $item eq  $itemCollection ) then (
        if( $isItemIndex )
          then(
          <li><strong>x{$item}</strong></li>
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

(:~
nav:collection.
The navigation items in a collection
 uri absolute path from base

@param $node  template node
@param $model template  map
@return XHTML.
:)


declare
function nav:collection($node as node(), $model as map(*)) {
let $seqResources := xmldb:get-child-resources( $model('data-pages-path') || '/' || $model('data-collection-path') )

let $listItems :=
    for $menu-item in  $seqResources
        let $list-item := substring-before($menu-item , '.')
        where not(  $list-item  eq 'index' ) and (substring-after($menu-item , '.') eq 'xml')
        return
            if( $list-item eq $model('data-item') ) then (
               <li><strong class="is-u-r-here">{ replace( $list-item , '-' ,  ' ') }</strong></li>
               )
            else(
              <li><a href="/{$model('data-collection-path')}/{$list-item}">{ replace( $list-item , '-' ,  ' ') }</a></li>
              )
 return
   <nav id="nav-collection">
    <h1>related pages navigation</h1>
                <ul>
                    {
                    $listItems
                    }
                </ul>
    </nav>
};
