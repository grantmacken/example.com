xquery version "3.0";
(:~
In order to handle 'webmentions', generarate indieweb
'reply contexts', link previews etc

After an initial constrained get, I want to be able access documents that are
returned from requests using expath [http-client](
http://expath.org/spec/http-client) from a cache store

An initial get is contrained by, the passed parameter 'URL' and request response
header meeting acceptable criteria e.g. media type equals text/html

Proir to storing the HTML the I want to sanitize the document with the goal of
    1. preserving the documents semantic content
    2. preventing 'xss' and 'injection attacks by removing scripting and styling
    elements and attributes
    3. resolving contained links to the base URL.

all function calls return a result as an instance of element()
(not document-node) with the root documentElement tag-name being either
'html' or 'problem'


 get:    given URL do a sanitised get of a HTML doc

 store:  given URL store sanitised HTML

 fetch:  given URL fetch from store

@see http://stackoverflow.com/questions/8554543/element-vs-node-in-xquery
@see http://tools.ietf.org/html/draft-nottingham-http-problem-06
@see https://github.com/dret/I-D-1/blob/master/http-problem/http-problem-03.xsd
@see https://www.owasp.org/index.php/Testing_for_XML_Injection_%28OWASP-DV-008%29


@author Grant MacKenzie
@version 0.01
:)
module namespace muCache="http://markup.co.nz/#muCache";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace system="http://exist-db.org/xquery/system";
import module namespace http = "http://expath.org/ns/http-client";
(:import module namespace err = "http://www.w3.org/2005/xqt-errors";:)
(: import my libs :)
import  module namespace muURL = "http://markup.co.nz/#muURL" at 'muURL.xqm';
import  module namespace muSan = "http://markup.co.nz/#muSan" at 'muSan.xqm';
import  module namespace muUtility = "http://markup.co.nz/#muUtility" at 'muUtility.xqm';

declare variable $muCache:store-path :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
	if (starts-with($rawPath, "xmldb:exist://")) then
	    if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
		substring($rawPath, 36)
	    else
	    substring($rawPath, 15)
	else
	    $rawPath
	return
	substring-before($modulePath, "/modules")  || "/data/cache"
	;


(:~
given URL get sanitised html that can be stored in db.

if there is a problem with the GET then root node (the documentElement ) will
have the tag name 'problem' if GET is successful then the documentElement name
will be 'html' and the document content will be sanitised and any 'links' in the
document will be resolved to the base URL

A GET will return a problem documentElement if the following criteria are not met.
    * url must look like a registed domain name
    * text resources only with media type text/html


NOTE:
   $response[1] is instance of element
   $response[2] is instance of document-node



@param $URL as xs:string
@return element()

@see http://hc.apache.org/httpclient-3.x/exception-handling.html
:)
declare
function muCache:get( $url as xs:string ) as element() {
let $checkURL := function( $u as xs:string ) as element(){
    if( muURL:hasAcceptableAuthority( $u ))
	then(<ok/>)
    else(
	<problem>
	    <title>URL does not meet acceptable criteria </title>
	    <instance>{$u}</instance>
	</problem>
	)
}

let $setRequest := function( $u as xs:string ) as element(){
    if( muUtility:isProblem( $checkURL($u) ) )
	then ( $checkURL($u)  )
    else(
	try {
	    <http:request
		href="{ xs:anyURI( $u ) }"
		method="get"
		send-authorization="false"
		timeout="4"
		>
		<http:header
		    name = "Connection"
		    value = "close"/>
		</http:request>

	}  catch * {
		<problem>
		    <title>Failed to set request</title>
		    <detail>{ string( $err:description ) }</detail>
		    <instance>{$u}</instance>
		</problem>
	}
    )
}

let $getResponse := function($req  as element() , $u  as xs:string ){
    if( muUtility:isProblem( $req ) )
	then ( $req )
    else(
	try {
	http:send-request( $req )
	    } catch * {
	    if( $err:code eq 'java:org.expath.httpclient.HttpClientException')
	       then (
		<problem>
		    <title>Failed request:  Http Client Exception</title>
		    <detail>{ string( $err:description ) }</detail>
		    <instance>{$u}</instance>
		</problem>
	       )
	    else(
	    <problem>
		<title>Failed request: </title>
		<instance>{$u}</instance>
	    </problem>
	    )
	}
    )
}

let $getResponseHeader := function( $res, $u  as xs:string) as element() {
    if( muUtility:isProblem( $res ) )
	then ( $res )
    else(
	try {
	 if( muUtility:getSequenceType( $res[1] ) eq 'element' )
	    then ( $res[1]  treat as element() )
	 else(
	    <problem>
	       <title>Failed to get response header: </title>
	       <instance>{$u}</instance>
	    </problem>
	    )
	} catch * {
	<problem>
	    <title>Failed to get response header: </title>
	    <detail>{ string( $err:description ) }</detail>
	    <instance>{$u}</instance>
	</problem>
	}
    )
}

let $checkHeaderResponse := function( $e as element(), $u as xs:string) as element(){
    if( muUtility:isProblem( $e ) )
	then ( $e )
    else(
	try {
	    if( $e/@status/number()  gt 399 ) then (
	    <problem>
		<title>Failed Request</title>
		<status>{$e/@status/string()}</status>
		<detail>{$e/@message/string()}</detail>
		<instance>{$u}</instance>
	    </problem>
	    )
	    else if( $e/@status/number()  gt 499 ) then (
	    <problem>
		<title>Failed Request: Server generated error</title>
		<detail>{$e/@message/string()}</detail>
		<status>{$e/@status/string()}</status>
		<instance>{$u}</instance>
	    </problem>
	    )
	    else(
		if($e//*/@media-type/string() eq 'text/html') then (
		<ok>
		   <status>{$e/@status/string()}</status>
		   <media-type>{$e//*/@media-type/string()}</media-type>
		   <accessed>{$e//*[@name="date"]/@value/string()}</accessed>
		</ok>
		)
		else(
		<problem>
		    <title>Failed Request: Can not handle media type</title>
		    <detail>media type should be 'text/html' got
		    {$e//*/@media-type/string()}</detail>
		    <status>{$e/@status/string()}</status>
		    <instance>{$u}</instance>
		</problem>
		)
	    )
    	} catch * {
	<problem>
	    <title>Failed to get check header response </title>
	    <detail>{ string( $err:description ) }</detail>
	    <instance>{$u}</instance>
	</problem>
	}
    )
}

let $getResponseBody := function( $res, $u   as xs:string) as element(){
    if( muUtility:isProblem( $checkHeaderResponse( $getResponseHeader($res, $u), $u) ) )
	then ( $checkHeaderResponse( $getResponseHeader($res, $u), $u)  )
    else(
	if( muUtility:getSequenceType( $res[2] ) eq 'document-node')
	    then(
		if( muUtility:getSequenceType( $res[2]/* ) eq 'element')
		    then(
		    $res[2]/element()   treat as element()
		    )
		else(
		<problem>
		    <title>Failed to get response body: element</title>
		    <instance>{$u}</instance>
		</problem>
		)
	    )
	else(
	    <problem>
		<title>Failed to get response body: document-node</title>
		<instance>{$u}</instance>
	    </problem>
	)
    )
}

let $getBaseURL := function( $e as element(), $u as xs:string) as xs:string{
	if( $e//*[local-name(.) eq 'base' ][@href] )
	    then ( $e//*[local-name(.) eq 'base' ][@href]/@href/string() )
	else( $u )
    }



let $getCleanHTML := function( $e as element() , $u as xs:string ){
    if( muUtility:isProblem( $e ))
	then ( $e )
    else(
	try { muSan:sanitizer( $e, $u ) }
	    catch * {
	     <problem>
		<title>Failed to sanitize: element</title>
		<detail>{ string( $err:description ) }</detail>
		<instance>{$u}</instance>
	    </problem>
	}
    )
}

(: proccess :)
let $request := $setRequest( $url )
let $response := $getResponse( $request , $url )
let $responseHeader := $getResponseHeader( $response , $url )
let $responseBody := $getResponseBody( $response , $url )
let $baseURL := $getBaseURL( $responseBody , $url )
let $cleanedHTML := $getCleanHTML( $responseBody , $baseURL )

return
$cleanedHTML
};


(:~
get then store  sanitized  html doc.
hash url to use file name.

@param $URL URL
@return xs:anyURI

:)
declare
function muCache:store( $url as xs:string ) as xs:string  {
let $contents := muCache:getCleanHTML( $url  )
let $resource-name := muURL:urlHash( $url ) || '.xml'
let $collection-uri := $muCache:store-path
let $store :=
	try {
	xmldb:store($collection-uri, $resource-name, $contents )
	}
	catch java:org.xmldb.api.base.XMLDBException {
	"Failed to store document"
	}
return $store
};

declare
function muCache:store-content( $url , $content )  {
let $responseBody :=
	if( empty($content)) then ( muCache:getRawHTML( $url ) )
	else($content)

let $baseURL :=
	if(muURL:isBaseInDoc($responseBody))
	    then ( $responseBody//*[local-name(.) eq 'base' ][@href]/@href/string()  )
	else( $url )

let $contents := if( $responseBody[local-name(.) eq 'problem'] )
			then ( $responseBody )
		else( muSan:sanitizer( $responseBody, $baseURL ) )

let $resource-name := muURL:urlHash( $url ) || '.xml'
let $collection-uri := $muCache:store-path

let $store :=
	try {
	xmldb:store($collection-uri, $resource-name, $contents )
	}
	catch java:org.xmldb.api.base.XMLDBException {
	"Failed to store document"
	}

return $store
};


(:~
give URL fetch from cache xhtml doc stored from a http-client request
if doc is not available in cache then get it and store
hash url to use file name.

@param $URL
@return element()
:)
declare
function muCache:fetch( $url as xs:string) as element() {
let $resource-name := muURL:urlHash( $url ) || '.xml'
let $document-uri := $muCache:store-path || '/'  || $resource-name
return
    if( doc-available( $document-uri ) )
	then (
	      doc( $document-uri )/*  treat as element()
	    )
    else (
	let $location := muCache:store( $url )
	return doc( $location )/* treat as element()
    )
};







declare
function muCache:getRawHTML( $url as xs:string ) as element() {
let $checkURL := function( $u as xs:string ) as element(){
    if( muURL:hasAcceptableAuthority( $u ))
	then(<ok/>)
    else(
	<problem>
	    <title>URL does not meet acceptable criteria </title>
	    <instance>{$u}</instance>
	</problem>
	)
}

let $setRequest := function( $u as xs:string ) as element(){
    if( muUtility:isProblem( $checkURL($u) ) )
	then ( $checkURL($u)  )
    else(
	try {
	    <http:request
		href="{ xs:anyURI( $u ) }"
		method="get"
		send-authorization="false"
		timeout="4"
		>
		<http:header
		    name = "Connection"
		    value = "close"/>
		</http:request>

	}  catch * {
		<problem>
		    <title>Failed to set request</title>
		    <detail>{ string( $err:description ) }</detail>
		    <instance>{$u}</instance>
		</problem>
	}
    )
}

let $getResponse := function($req  as element() , $u  as xs:string ){
    if( muUtility:isProblem( $req ) )
	then ( $req )
    else(
	try {
	http:send-request( $req )
	    } catch * {
	    if( $err:code eq 'java:org.expath.httpclient.HttpClientException')
	       then (
		<problem>
		    <title>Failed request:  Http Client Exception</title>
		    <detail>{ string( $err:description ) }</detail>
		    <instance>{$u}</instance>
		</problem>
	       )
	    else(
	    <problem>
		<title>Failed request: </title>
		<instance>{$u}</instance>
	    </problem>
	    )
	}
    )
}

let $getResponseHeader := function( $res, $u  as xs:string) as element() {
    if( muUtility:isProblem( $res ) )
	then ( $res )
    else(
	try {
	 if( muUtility:getSequenceType( $res[1] ) eq 'element' )
	    then ( $res[1]  treat as element() )
	 else(
	    <problem>
	       <title>Failed to get response header: </title>
	       <instance>{$u}</instance>
	    </problem>
	    )
	} catch * {
	<problem>
	    <title>Failed to get response header: </title>
	    <detail>{ string( $err:description ) }</detail>
	    <instance>{$u}</instance>
	</problem>
	}
    )
}

let $checkHeaderResponse := function( $e as element(), $u as xs:string) as element(){
    if( muUtility:isProblem( $e ) )
	then ( $e )
    else(
	try {
	    if( $e/@status/number()  gt 399 ) then (
	    <problem>
		<title>Failed Request</title>
		<status>{$e/@status/string()}</status>
		<detail>{$e/@message/string()}</detail>
		<instance>{$u}</instance>
	    </problem>
	    )
	    else if( $e/@status/number()  gt 499 ) then (
	    <problem>
		<title>Failed Request: Server generated error</title>
		<detail>{$e/@message/string()}</detail>
		<status>{$e/@status/string()}</status>
		<instance>{$u}</instance>
	    </problem>
	    )
	    else(
		if($e//*/@media-type/string() eq 'text/html') then (
		<ok>
		   <status>{$e/@status/string()}</status>
		   <media-type>{$e//*/@media-type/string()}</media-type>
		   <accessed>{$e//*[@name="date"]/@value/string()}</accessed>
		</ok>
		)
		else(
		<problem>
		    <title>Failed Request: Can not handle media type</title>
		    <detail>media type should be 'text/html' got
		    {$e//*/@media-type/string()}</detail>
		    <status>{$e/@status/string()}</status>
		    <instance>{$u}</instance>
		</problem>
		)
	    )
    	} catch * {
	<problem>
	    <title>Failed to get check header response </title>
	    <detail>{ string( $err:description ) }</detail>
	    <instance>{$u}</instance>
	</problem>
	}
    )
}

let $getResponseBody := function( $res, $u   as xs:string) as element(){
    if( muUtility:isProblem( $checkHeaderResponse( $getResponseHeader($res, $u), $u) ) )
	then ( $checkHeaderResponse( $getResponseHeader($res, $u), $u)  )
    else(
	if( muUtility:getSequenceType( $res[2] ) eq 'document-node')
	    then(
		if( muUtility:getSequenceType( $res[2]/* ) eq 'element')
		    then(
		    $res[2]/element()   treat as element()
		    )
		else(
		<problem>
		    <title>Failed to get response body: element</title>
		    <instance>{$u}</instance>
		</problem>
		)
	    )
	else(
	    <problem>
		<title>Failed to get response body: document-node</title>
		<instance>{$u}</instance>
	    </problem>
	)
    )
}

(: proccess :)
let $request := $setRequest( $url )
let $response := $getResponse( $request , $url )
let $responseHeader := $getResponseHeader( $response , $url )
let $responseBody := $getResponseBody( $response , $url )
return
    $responseBody treat as element()
};


declare
function muCache:getCleanHTML( $url as xs:string ) as element() {

let $getBaseURL := function( $e as element(), $u as xs:string) as xs:string{
	if( $e//*[local-name(.) eq 'base' ][@href] )
	    then ( $e//*[local-name(.) eq 'base' ][@href]/@href/string() )
	else( $u )
    }



let $getCleanHTML := function( $e as element() , $u as xs:string ){
    if( muUtility:isProblem( $e ))
	then ( $e )
    else(
	try { muSan:sanitizer( $e, $u ) }
	    catch * {
	     <problem>
		<title>Failed to sanitize: element</title>
		<detail>{ string( $err:description ) }</detail>
		<instance>{$u}</instance>
	    </problem>
	}
    )
}

(: proccess :)


let $responseBody := muCache:getRawHTML( $url  )
let $baseURL := $getBaseURL( $responseBody , $url )
let $cleanedHTML := $getCleanHTML( $responseBody , $baseURL )

return
$cleanedHTML
};
