xquery version "3.0";
(:~
We want LIVE browser preview testing of tests found in the tests collection
when we are working on an xquery library module

gistID: 61082e441e43653b8b75
https://gist.github.com/grantmacken/61082e441e43653b8b75

I use this with a Komodo toolbox macro which on save
uploads working file to existdb localhost server
and then refreshes  browser view

Test pattern:
 given args passed to a function
 when the function returns  a 'result'
 then  returned 'result' should pass our assertion tests

DIRECTORY CONVENTIONS

lib
    - test-runner.xqm
    - {module-name}.xqm
    - {another-module-name}.xqm
    + tests
	- {test-name}.xqm
	- {another-test-name}.xqm


NAMING CONVENTIONS

if we are testing the url lib.
then the test for a function should be the same as the function
with an underscore after the function name if we have more
than one test for the named function e.g.

in our 'muURL' lib module

  function muURL:get($url){};

will have a test named

  function st:get($url){
    muURL:get($url)
  };

if we need more than one test then

 function st:get_1($url){
  muURL:get($url)
 }

  function st:get_2($url){
    muURL:get($url)
  }

LIMITATIONS:

 Need to import libs prior to test
    see  util:eval( $functionCallString )
 Can only test one func at a time

@see http://localhost:8080/exist/apps/doc/xqsuite.xml#D1.2.7
@see https://github.com/wolfgangmm/xqsuite
@see http://en.wikibooks.org/wiki/XQuery/XUnit_Annotations
:)


declare boundary-space preserve;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";
declare option output:indent "yes";
declare option output:encoding "UTF-8";

import module namespace inspect = "http://exist-db.org/xquery/inspection";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace test="http://exist-db.org/xquery/xqsuite"
    at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
(: DEPENDENCIES:  import all my libs unders lib folder:)
import  module namespace muCache = "http://markup.co.nz/#muCache"
    at 'muCache.xqm';
import  module namespace muURL = "http://markup.co.nz/#muURL"
    at 'muURL.xqm';
import  module namespace muSan = "http://markup.co.nz/#muSan"
    at 'muSan.xqm';
import  module namespace mf2 = "http://markup.co.nz/#mf2"
    at 'mf2.xqm';
import  module namespace muUtility = "http://markup.co.nz/#muUtility"
    at 'muUtility.xqm';

(:NOTE:
change test by changing default param
or adding query e.g.
?module=muURL
?module=muCache
?module=muSan
:)
let $module-name := request:get-parameter('module', 'mf2')
let $test-name := request:get-parameter('test', $module-name )

let $module-path := xs:anyURI(  $module-name  || '.xqm' )
let $test-path :=  xs:anyURI(  'tests/t-' || $test-name || ".xqm" )

let $inspectModule :=  inspect:inspect-module( $module-path  )
let $funcs-out :=  inspect:inspect-module( $test-path )
let $test-out := test:suite( inspect:module-functions( $test-path ))

(:
* %test:name("description")
* %test:args()

* %test:assertEmpty() - returns true if the result is an empty string.
* %test:assertExists - returns true if the result exists.
* %test:assertTrue - returns true if the result is true
* %test:assertFalse - returns true if the result is false

* %test:assertEquals('value')

* %test:assertError("error code") - Excepts the function to fail with an error.
  If an error code is given (optional), it should be contained in the error
  message or the test will fail.

* %test:assertXPath("count($result) = 8") - This is the most powerful assertion.
  It checks the result against an arbitrary XPath expression. The assertion is
  true if

* %test:setUp
* %test:tearDown

:)

let $getAtomicType := function($val){
 if ($val instance of xs:untypedAtomic) then 'xs:untypedAtomic'
 else if ($val instance of xs:anyURI) then 'xs:anyURI'
 else if ($val instance of xs:ENTITY) then 'xs:ENTITY'
 else if ($val instance of xs:ID) then 'xs:ID'
 else if ($val instance of xs:NMTOKEN) then 'xs:NMTOKEN'
 else if ($val instance of xs:language) then 'xs:language'
 else if ($val instance of xs:NCName) then 'xs:NCName'
 else if ($val instance of xs:Name) then 'xs:Name'
 else if ($val instance of xs:token) then 'xs:token'
 else if ($val instance of xs:normalizedString)
         then 'xs:normalizedString'
 else if ($val instance of xs:string) then 'xs:string'
 else if ($val instance of xs:QName) then 'xs:QName'
 else if ($val instance of xs:boolean) then 'xs:boolean'
 else if ($val instance of xs:base64Binary) then 'xs:base64Binary'
 else if ($val instance of xs:hexBinary) then 'xs:hexBinary'
 else if ($val instance of xs:byte) then 'xs:byte'
 else if ($val instance of xs:short) then 'xs:short'
 else if ($val instance of xs:int) then 'xs:int'
 else if ($val instance of xs:long) then 'xs:long'
 else if ($val instance of xs:unsignedByte) then 'xs:unsignedByte'
 else if ($val instance of xs:unsignedShort) then 'xs:unsignedShort'
 else if ($val instance of xs:unsignedInt) then 'xs:unsignedInt'
 else if ($val instance of xs:unsignedLong) then 'xs:unsignedLong'
 else if ($val instance of xs:positiveInteger)
         then 'xs:positiveInteger'
 else if ($val instance of xs:nonNegativeInteger)
         then 'xs:nonNegativeInteger'
 else if ($val instance of xs:negativeInteger)
         then 'xs:negativeInteger'
 else if ($val instance of xs:nonPositiveInteger)
         then 'xs:nonPositiveInteger'
 else if ($val instance of xs:integer) then 'xs:integer'
 else if ($val instance of xs:decimal) then 'xs:decimal'
 else if ($val instance of xs:float) then 'xs:float'
 else if ($val instance of xs:double) then 'xs:double'
 else if ($val instance of xs:date) then 'xs:date'
 else if ($val instance of xs:time) then 'xs:time'
 else if ($val instance of xs:dateTime) then 'xs:dateTime'
 else if ($val instance of xs:dayTimeDuration)
         then 'xs:dayTimeDuration'
 else if ($val instance of xs:yearMonthDuration)
         then 'xs:yearMonthDuration'
 else if ($val instance of xs:duration) then 'xs:duration'
 else if ($val instance of xs:gMonth) then 'xs:gMonth'
 else if ($val instance of xs:gYear) then 'xs:gYear'
 else if ($val instance of xs:gYearMonth) then 'xs:gYearMonth'
 else if ($val instance of xs:gDay) then 'xs:gDay'
 else if ($val instance of xs:gMonthDay) then 'xs:gMonthDay'
 else 'unknown'
}

let $getSequenceType := function( $node){
 if ($node instance of element()) then 'element'
 else if ($node instance of attribute()) then 'attribute'
 else if ($node instance of text()) then 'text'
 else if ($node instance of document-node()) then 'document-node'
 else if ($node instance of comment()) then 'comment'
 else if ($node instance of processing-instruction())
         then 'processing-instruction'
 else if ($node instance of empty-sequence())
         then 'empty'
 else if ($node instance of item())
         then 'empty'
 else 'unknown'
 }



let $outCases :=
    for $node at $i in  $test-out//testcase

        let $testFunctionName := $node/@class/string()
        let $id := substring-after($testFunctionName, 'st:')
	let $testFunc := if(contains($id, '_')) then (substring-before($id, '_') )
			else ( $id )

        let $testOK := 	if( $node/failure[@message]  )then( 'failure' )
			else if( $node/error[@message]  )then( 'error' )
			else('success')

        let $functionNode := $funcs-out/function[@name = $testFunctionName]
	let $heading :=  <h3><a href="#t_{$i}">{$i || ':  ' ||  $testFunc  || ' [ ' || $testOK   || ' ]' } </a></h3>
	let $paragraph :=  <p><strong>description: </strong>{$node[@name]/@name/string() }</p>



(: $functionNode lists function calls made by the test
   we are only interested in the last function call
   as this is what returns our result

:)
        let $countFunctionCalls := count($functionNode/calls/* )
        let $functionCall :=
	  if($countFunctionCalls gt 1)
	     then ( $functionNode/calls/*[contains( @name/string(), $testFunc )]/@name/string())
	  else($functionNode/calls/*[$countFunctionCalls]/@name/string())




(:
  TODO: more types
  we are going to call  'util:eval( $functionCallString )'
  with the function calls args
  we need create a string for each type for eval to work
:)

	let $args :=
	    for $item at $i in $functionNode/argument
	      let $type := $item/@type/string()
	      let $value := $functionNode//annotation[@name="test:args"]/value[$i]/node()
	      let $arg :=
		    if( $type eq 'element()' ) then (  $value/string() )
		    else( "'"  || $value/string()  || "'" )
	      return $arg

	let $functionCallString :=
		$functionCall || " ( " ||  string-join($args, ",") ||  " )"


	let $displayfunctionCall := if( 'element()' = $functionNode/argument/@type )
				      then (  $functionCall || " ()")
				    else ( $functionCall || " ( " ||  string-join($args, ",") ||  " )")


	let $functionCallResult :=
		try { util:eval( $functionCallString ) }
		catch * {()}

	let $returnType :=
		if( $getAtomicType( $functionCallResult )  ne 'unknown' )
		    then (substring-after($getAtomicType( $functionCallResult ) , ':') )
		else if ($getSequenceType( $functionCallResult )  ne 'unknown'  )
			    then $getSequenceType( $functionCallResult )
		else  ('TODO: unknown')

	let $getRowsAndCols := function($functionCallResult){
	let $getLineCount := function( $str ){ count( tokenize( $str, '(\r\n?|\n\r?)') )}
	let  $rows := switch ($returnType)
		case "boolean" return (1)
		case "URI"  return (1)
		case "string"
		    return (count( tokenize( $functionCallResult , '(\r\n?|\n\r?)')) )
		case "element" return (
		    let $outNodes :=  $functionCallResult//*[count(child::text()) eq 0]
		    let $outNodesCount := count( ( $functionCallResult/* , $outNodes ) )
		    let $textNodes :=  $functionCallResult//*[./text()]
		    let $textNodesCount := sum( map(function($n) { $getLineCount( $n/node()) }, $textNodes ))
		    let $summed := sum( ( 1 ,  $outNodesCount , $textNodesCount ) )
		    return if ( $summed gt 20 ) then (20)
			else ( $summed )
		    )
		case "item" return (count( tokenize( $functionCallResult , '(\r\n?|\n\r?)')) )
		default return (1)
	    let  $cols := switch ($returnType)
		    case "boolean" return (6)
		    case "URI" return string-length( string($functionCallResult) )
		    case "string"
		    case "item" return (
					  max(
					  for $line in  tokenize( $functionCallResult , '(\r\n?|\n\r?)')
					  return string-length($line)) )
		    case "element" return ( 80 )
		    default return ( 80)
         return ( $cols , $rows )
	}


        let $seqRowsCols :=
		try { $getRowsAndCols($functionCallResult) }
		catch * {(80, 2)}

	let $resultDD := (
	  <dt>Result Returned</dt>,
	  <dd>Number of function calls:  {$countFunctionCalls}</dd>,
	  <dd>Returned instance of: { $returnType  } </dd>,
	  <dd><textarea cols="{$seqRowsCols[1]}" rows="{$seqRowsCols[2]}">{$functionCallResult}</textarea></dd>
	  )

      let $defList :=
	<dl>
	  <dt>function call</dt>
	  <dd>{$displayfunctionCall}</dd>
	  <dt>function arguments</dt>
            {
	    for $item at $i in $functionNode/argument
	    let $type := $item/@type/string()
	    let $value := $functionNode//annotation[@name="test:args"]/value[$i]/node()

	    let $arg :=
		    if( $type eq 'element()' )
		       then ( try {  util:parse( $value/string() ) }
			      catch * {(string(''))}
			    )
		    else( $value/string()  )



	    let $rows := count( tokenize( $value , '(\r\n?|\n\r?)'))
	    let $cols :=  max(
		  for $line in  tokenize( $value , '(\r\n?|\n\r?)')
		  return string-length($line))


	     return
	      ( <dd>{$i || ': '|| $type}</dd>,
		<dd><textarea cols="{80}" rows="{1}">{$arg}</textarea></dd>
	       )
	    }
	    { $resultDD }
	</dl>


      let $message := switch ($testOK)
      case "success" return ( $heading , $paragraph, $defList  )
      case "error" return ($heading , $paragraph,$defList,<p>{  $node/error/@message/string() } </p>)
      case "failure" return ($heading, $paragraph , $defList, <p>{   ' [ ' || $node/failure/@message/string() ||  ' ] ' || $node/failure/string() } </p>)
      default return ()


    return (
    <div class="{$testOK}"  id="{$id }" >
     {$message}
    </div>
    )

let $testCases :=
    for $node at $i in  $test-out//testcase
        let $id := substring-after($node/@class/string(), 'st:')
        let $success := not($node[failure])
        let $testOK := 	if( $node/failure[@message]  )then( 'failure' )
			else if( $node/error[@message]  )then( 'error' )
			else('success')

	let $message := switch ($testOK)
		case "success" return ( $node/@name/string()   )
		case "error" return ($node/@name/string())
		case "failure" return (
			$node/@name/string(), ' [',
                        $node/failure/@message/string(), ' ]  ' ,
                        $node/failure/string())
		default return ()

    return (
    <tr id="t_{$i}" class="{$testOK}">
        <td><a href="#{$id}">{$i}</a></td>
        <td>{$testOK}</td>
        <td>{$message}</td>
    </tr>
    )

let $countCases := count($test-out//testcase )
let $countFailures := count($test-out//testcase/failure[@message] )
let $countErrors :=  count($test-out//testcase/error[@message])
let $sumFailed :=  sum( ($countFailures, $countErrors ) )
let $summary := <p>{$countCases } testcases - ( {$sumFailed} / {$countCases} )   [ {$countFailures}  fail ] [ {$countErrors}  error ] </p>

let $header :=
<header  role="banner" >
<h2>MU: Test module at { $inspectModule/@location/string() } </h2>
<blockquote><pre>{$inspectModule/description/string() }</pre></blockquote>
<h2>MU: running tests at { $funcs-out/@location/string() } </h2>
{$summary}
</header>

let $table  :=  <table>{$testCases}</table>
let $style  := <style><![CDATA[

.failure, .error{
    color: #9F6000;
    background-color: #FEEFB3;
}

.success {
    color: #4F8A10;
    background-color: #DFF2BF;
}

]]></style>


return (
<html>
<head>
    <title>test runner</title>
<!--
    <meta http-equiv="refresh" content="5"/>
-->
    {$style}
</head>
    <body>{$header}
    <section id="main" role="main">
        <h2>Test Result</h2>
        { ($table , $outCases)}
  </section>
  <footer>
     <textarea cols="300" rows="40">{$funcs-out }</textarea>
      <textarea cols="300" rows="40">{$test-out }</textarea>
  </footer>
    </body>
</html>
)
