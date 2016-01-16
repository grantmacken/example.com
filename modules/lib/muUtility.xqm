xquery version "3.0";
(:~
This module contains utility functions
that can be called by other libraries

@author Grant MacKenzie
@version 0.01
:)

module namespace muUtility="http://markup.co.nz/#muUtility";

import module namespace system="http://exist-db.org/xquery/system";

(: DEPENDENCIES:  import my libs :)

declare variable $muUtility:app-path :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
	if (starts-with($rawPath, "xmldb:exist://"))
	    then (
		if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server"))
		    then (substring($rawPath, 36))
		else (substring($rawPath, 15))
	    )
	else (
	    $rawPath
	)
    return
    substring-before($modulePath, "/modules")
    ;

declare
function muUtility:getAppPath(){
  $muUtility:app-path
};

declare
function muUtility:getSequenceType( $item ) as xs:string{
    if ($item instance of element()) then 'element'
    else if ( $item instance of attribute()) then 'attribute'
    else if ( $item instance of text()) then 'text'
    else if ( $item  instance of document-node()) then 'document-node'
    else if ( $item instance of comment()) then 'comment'
    else if ( $item instance of processing-instruction())
	    then 'processing-instruction'
    else if ( $item instance of empty())
	    then 'empty'
    else 'unknown'
};


declare
function muUtility:isProblem ( $item ) as xs:boolean{
    if(  muUtility:getSequenceType( $item )  eq  'element' )
	then( local-name( $item ) eq 'problem' )
    else( false()
	 )
};
