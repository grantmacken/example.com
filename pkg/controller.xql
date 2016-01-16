xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

if (matches($exist:path ,'^/[0-9A-HJ-NP-Z_a-km-z]{3}[0-9]{1,2}\.html$')) then(
  let $strID := replace($exist:path, '^/([0-9A-HJ-NP-Z_a-km-z]{3}[0-9]{1,2})\.html$', '$1')
  let $strB60 := replace($exist:path, '^/([0-9A-HJ-NP-Z_a-km-z]{3})[0-9]{1,2}\.html$', '$1')
  let $base := 60
(:  The entry point is  $strB60 :)
  let $seqDecode :=
  map(function( $codePoint ){
   let $c := xs:integer($codePoint)
   return
           if ($c >= 48 and $c <= 57 ) then ($c - 48)
     else if ($c >= 65 and $c <= 72 ) then ($c - 55)
     else if ($c eq 73 or $c eq 108 ) then (1)
     else if ($c >= 74 and $c <= 78 ) then ($c - 56)
     else if ($c eq 79 ) then (0)
     else if ($c >= 80 and $c <= 90 ) then ($c - 57)
     else if ($c eq 95 ) then (34)
     else if ($c >= 97 and $c <= 107 ) then ($c - 62)
     else if ($c >= 109 and $c <= 122 ) then ($c - 63)
     else(0)
     },
     (map(function($ch){string-to-codepoints($ch)}, (for $ch in string-to-codepoints($strB60)
    return codepoints-to-string($ch)))
     ))
  let $tot := function($n2, $c){xs:integer(($base * $n2) + $c + 1)}
  let $n2 := 0
  let $dc1 := $tot($n2, $seqDecode[1])
  let $dc2 := $tot($dc1, $seqDecode[2])
  let $decoded := $tot($dc2, $seqDecode[3] -1  )
  let $yr := '20' || substring($decoded, 1, 2)
  let $yrStart := xs:date($yr || string('-01-01'))
  let $dysInYr := substring($decoded, 3, 6)
  let $duration := xs:dayTimeDuration("P" || string(xs:integer($dysInYr)- 1)  || "D")
  let $decodedDate := xs:date($yrStart + $duration)
  let $formatedDate := format-date($decodedDate, "[Y0001]/[M01]/[D01]", 'en', (), ())
  let $colPath :=  concat( $exist:root  , $exist:controller , '/data/archive/' , $formatedDate )
  let $redirect :=
    if( xmldb:collection-available( $colPath ) ) then (
      if( exists(xmldb:xcollection($colPath)//id[contains(., $strID)] )) then (
        xmldb:xcollection($colPath)//*[id[contains(., $strID)]]/link[@rel="alternate"]/@href/string()
        )
      else( 'http://' ||  $exist:controller || '/' || 'collection-not-available' ||  '/' || $strB60  ||  '/' || $strID ||   '/' || $formatedDate )
    )
    else( 'http://' ||  $exist:controller || '/' || 'id-not-found' ||  '/' || $strB60  ||  '/' || $strID ||   '/' || $formatedDate )
return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
     <redirect url="{$redirect}"/>
    </dispatch>
)
else if (ends-with($exist:resource, ".html")) then
let $template-pages := '/templates/pages/'
let $template-posts := '/templates/posts/'
let $collection := if( matches($exist:path ,'^/index.html$'))then ('home')
else(tokenize($exist:path, '/')[2])


let $colURL :=
  if( matches( $exist:path , '^/archive/index.html$')) then (
      $exist:controller ||  $template-posts ||  'archive' || '.html'
      )
  else if( contains( $exist:path , 'archive/' )) then (
     $exist:controller ||  $template-posts ||  'entry' || '.html'
    )
  else(
    $exist:controller ||  $template-pages ||  $collection || '.html'
    )

let $errorURL := $exist:controller ||  $template-pages || 'error.html'
let $viewURL := $exist:controller ||  '/modules/view.xql'
return
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <forward method="get" url="{$colURL}" />
  <view>
    <forward url="{$viewURL}">
      <add-parameter name="exist-root" value="{$exist:root}" />
      <add-parameter name="exist-prefix" value="{$exist:prefix}" />
      <add-parameter name="exist-controller" value="{$exist:controller}" />
      <add-parameter name="exist-resource" value="{$exist:resource}" />
      <add-parameter name="exist-path" value="{$exist:path}" />
    </forward>
  </view>
  <error-handler>
    <forward method="get" url="{$errorURL}" />
    <forward url="{$viewURL}" />
  </error-handler>
</dispatch>
else
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
  <cache-control cache="yes" />
</dispatch>
