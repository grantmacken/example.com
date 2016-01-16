xquery version "3.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
(: The following external variables are set by the repo:deploy function :)
(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

let $domain := substring-after( $target ,'/apps/')
let $base :=  concat( substring-before( $target ,'/apps/'), '/')
let $data_col := concat('data/' ,$domain )
let $archive_col := concat('data/' ,$domain ,'/archive')
let $pages_col := concat('data/' , $domain , '/pages' )
let $apps_config_col := concat('system/config/db/apps/' , $domain)
let $data_config_col := concat('system/config/db/' , $data_col)
let $isDev := environment-variable('SERVER') eq 'development'

return (
  if( xmldb:collection-available( concat($base, $data_col, '/jobs'))) then ()
  else( xmldb:create-collection( $base, concat($data_col, '/jobs') )),
  if( xmldb:collection-available( concat($base, $data_col, '/pages'))) then ()
  else( xmldb:create-collection( $base, concat($data_col, '/pages') )),
  if( xmldb:collection-available( concat($base, $data_col, '/archive'))) then ()
  else( xmldb:create-collection( $base, concat($data_col, '/archive') )),
  if( xmldb:collection-available( concat($base, $apps_config_col))) then (
    xmldb:store-files-from-pattern(
      concat($base, $apps_config_col),
      $dir,
      "collection.xconf"
      )
    )
  else(
    xmldb:create-collection (
      $base,
      $apps_config_col
      ),
    xmldb:store-files-from-pattern(
      concat($base, $apps_config_col),
      $dir,
      "collection.xconf"
      )
    ),
  if( $isDev ) then (
    if(
      xmldb:collection-available(
        concat( $base, $data_config_col )
        )
      ) then (
        xmldb:store-files-from-pattern(
        concat($base, $data_config_col),
        $dir,
        'data.xconf'
        )  
    )
    else(
      xmldb:create-collection(
        $base,
        $data_config_col
        ),
      xmldb:store-files-from-pattern(
        concat($base, $data_config_col),
        $dir,
        'data.xconf'
        )
      )
    )
  else ()
)
