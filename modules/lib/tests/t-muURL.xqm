xquery version "3.0";

(:~
This module provides the functions that test my url functions

@author Grant MacKenzie
@version 1.0

:)
module namespace st="http://markup.co.nz/#st";

import module namespace muURL="http://markup.co.nz/#muURL" at "../muURL.xqm";
declare namespace test="http://exist-db.org/xquery/xqsuite";


declare function test:setup(){
()
};

declare function test:testdown(){
()
};


(: HAS NO ILLEGAL CHARS :)

declare
    %test:name("given URL ( http://example.com/maori) should be TRUE when we check it has No Illegal Chars")
    %test:args("http://example.com/maori")
    %test:assertTrue
function st:hasNoIllegalChars_4($url){
 muURL:hasNoIllegalChars($url )
};



declare
    %test:name("given URL ( http://example.com/${duh!} )should be False when we check it has No Illegal Chars")
    %test:args('http://markup.co.nz/{duh!}')
    %test:assertFalse
function st:hasNoIllegalChars_2($url){
 muURL:hasNoIllegalChars($url )
};

declare
    %test:name("given URL ( http://example.com ) with XSS attack,  should be FALSE when we check it has No Illegal Chars")
    %test:args("http://example.com/page.asp?title=Section%20Title</h1><script>alert(‘XSS%20attack’)</script>")
    %test:assertFalse
function st:hasNoIllegalChars_3($url){
 muURL:hasNoIllegalChars($url )
};

declare
    %test:name("given URL ( http://example.com/māori with  codepoint above 127 )should be FALSE when we check if has No Illegal Chars")
    %test:args("http://example.com/māori")
    %test:assertFalse
function st:hasNoIllegalChars_5($url){
 muURL:hasNoIllegalChars($url )
};

declare
    %test:name(" given URL (http://markup.co.nz/) should check if can caste anyURL")
    %test:args('http://markup.co.nz')
    %test:assertTrue
function st:hasNoIllegalChars_1( $url ){
 muURL:hasNoIllegalChars( $url  )
};



(: CAN CASTE TO anyURL :)


declare
    %test:name(" given bad URL (http*://markup.co.nz) should  should be true when we check if can caste to anyURL")
    %test:args('http*://markup.co.nz')
    %test:assertFalse
function st:canCaste_2(  $u ){
 muURL:canCaste(  $u  )
};


declare
    %test:name(" given good URL (http://markup.co.nz?q=a) should be true when we check if can caste to anyURL")
    %test:args('http://markup.co.nz?q=a')
    %test:assertTrue
function st:canCaste_3(  $u ){
 muURL:canCaste(  $u  )
};



declare
    %test:name(" given bad URL (http://markup.co.nz?q=/a|b) should check if can caste anyURL")
    %test:args('http://markup.co.nz?q=a|b')
    %test:assertTrue
function st:canCaste_4(  $u ){
 muURL:canCaste(  $u  )
};


declare
    %test:name("given URL ( http://markup.co.nz ) check if meets Acceptable Criteria")
    %test:args('http://markup.co.nz')
    %test:assertTrue
function st:meetsAcceptableCriteria_1($url){
 muURL:meetsAcceptableCriteria($url )
};



(: url safe hash  :)

declare
    %test:name("given URL get a url safe hash that can stored as a file name")
    %test:args('http://markup.co.nz')
    %test:assertEquals('QqMFMuqvFRbgiL97n4Km_A')
function st:urlHash($url as xs:anyURI){
 muURL:urlHash($url )
};

declare
    %test:name("check is 'Base' In Doc given document node with no base element")
     %test:args('<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <title>markup.co.nz</title>
    <link href="/resources/styles/style.css" rel="Stylesheet" type="text/css" />
    <meta name="author" content="Grant MacKenzie" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script type="text/javascript" src="/resources/scripts/lib/sarissa.js"></script>
    <script type="text/javascript" src="/resources/scripts/main.js"></script>
</head>' )
   %test:assertFalse
function st:isBaseInDoc_1($node as element()) as xs:boolean{
    muURL:isBaseInDoc(  $node )
};


declare
    %test:name("check is 'Base' In Doc given document node  with base element ")
     %test:args('<head>
    <base href="http://markup.co.nz"/>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <title>markup.co.nz</title>
    <link href="/resources/styles/style.css" rel="Stylesheet" type="text/css" />
    <meta name="author" content="Grant MacKenzie" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script type="text/javascript" src="/resources/scripts/lib/sarissa.js"></script>
    <script type="text/javascript" src="/resources/scripts/main.js"></script>
</head>' )
  %test:assertTrue
function st:isBaseInDoc_2($node as element()) as xs:boolean{
    muURL:isBaseInDoc(  $node )
};







(: URL PARTS
http://www.ietf.org/rfc/rfc2396.txt

"generic URI" syntax consists of a sequence of four main components:
<scheme>://<authority><path>?<query>
:)


declare
    %test:name(" given URL (http://markup.co.nz) should return scheme component 'http'")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619')
    %test:assertEquals('http')
function st:scheme_1(  $u ){
 muURL:getScheme(  $u  )
};

declare
    %test:name(" given URL (https://bear.im/) get 'scheme' should return scheme component 'https'")
    %test:args('https://bear.im/')
    %test:assertEquals('https')
function st:scheme_2(  $u ){
 muURL:getScheme(  $u  )
};


declare
    %test:name(" given URL (htt#p://markup.co.nz)  get scheme should throw ERROR ")
    %test:args('htt#p://markup.co.nz')
    %test:assertError('muURL:urlHasBadScheme')
function st:scheme_3(  $u ){
 muURL:getScheme(  $u  )
};


declare
    %test:name(" given URL ( //markup.co.nz ) ) get scheme should throw  ERROR ")
    %test:args('//markup.co.nz')
     %test:assertError('')
function st:scheme_4(  $u ){
 muURL:getScheme(  $u  )
};

declare
    %test:name(" given URL(http://markup.co.nz) has HTTP Scheme  should be true")
    %test:args('http://markup.co.nz')
    %test:assertTrue
function st:scheme_5(  $u ){
 muURL:hasHttpScheme(  $u  )
};

declare
    %test:name(" given URL(https://bear.im/) has HTTP Scheme  should be true ")
    %test:args('https://bear.im/')
    %test:assertTrue
function st:scheme_6(  $u ){
 muURL:hasHttpScheme(  $u  )
};


declare
    %test:name(" given URL( ftp ) has HTTP Scheme should be false" )
    %test:args('ftp://markup.co.nz')
    %test:assertFalse
function st:scheme_7(  $u ){
 muURL:hasHttpScheme(  $u  )
};



declare
    %test:name(" given URL (with path and query  ) should get 'authority' component  ")
    %test:args('http://markup.co.nz/webmention?target=http://markup.co.nz')
    %test:assertEquals('markup.co.nz')
function st:getAuthority_1($u ){
 muURL:getAuthority( $u  )
};


declare
    %test:name("given URL( http://localhost ) should throw  ERROR ")
    %test:args('http://localhost')
    %test:assertError
function st:getAuthority_2($u ){
 muURL:getAuthority( $u  )
};

declare
    %test:name("given URL ( with / ) should get 'authority' component   ")
    %test:args('http://markup.co.nz/')
    %test:assertEquals('markup.co.nz')
function st:getAuthority_3($base ){
 muURL:getAuthority(  $base )
};


declare
    %test:name(" given URL (scheme + authority only) should get 'authority' component ")
    %test:args('http://markup.co.nz')
    %test:assertEquals('markup.co.nz')
function st:getAuthority_4($base ){
 muURL:getAuthority( $base  )
};

declare
    %test:name("given URL (scheme + authority + query) should get 'authority' component ")
    %test:args('http://markup.co.nz?login=joe')
    %test:assertEquals('markup.co.nz')
function st:url-authority_4($base ){
 muURL:urlAuthority( $base  )
};

declare
    %test:name("given 'base url' ( base ends with /,   url is absolute) resolve 'url' ")
    %test:args('http://waterpigs.co.uk/notes/1083/' ,'/mentions/webmention/' )
    %test:assertEquals('http://waterpigs.co.uk/mentions/webmention/')
function st:url-resolve_0($url ,  $absolute  ){
 muURL:resolve( $url , $absolute  )
};


(::)


declare
    %test:name("get 'absolute path' component given base URL (without query)")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619')
    %test:assertEquals('/archive/2014/03/16/141619')
function st:url-abs_path_1($base ){
 muURL:urlAbsolutePath( $base  )
};

declare
    %test:name("get 'absolute path' component given base URL (with query)")
    %test:args('http://markup.co.nz/webmention?target=http://markup.co.nz')
    %test:assertEquals('/webmention')
function st:url-abs_path_2($base ){
 muURL:urlAbsolutePath( $base  )
};

declare
    %test:name("get 'absolute path' given  base URL (no path)")
    %test:args('http://markup.co.nz')
    %test:assertEquals('/')
function st:url-abs_path_3($base ){
 muURL:urlAbsolutePath( $base  )
};


declare
    %test:name("get 'query' component given base URL (with query)")
    %test:args('http://markup.co.nz/webmention?target=http://markup.co.nz')
    %test:assertEquals('target=http://markup.co.nz')
function st:url-query($base ){
 muURL:urlQuery( $base  )
};

declare
    %test:name("check url-is-relative should be false given absolute path ")
    %test:args('/archive/2014/03/16/141619')
    %test:assertFalse
function st:url-is-relative_1($path ){
 muURL:isRelative( $path )
};

declare
    %test:name("check url-is-relative should be true given relative path")
    %test:args('archive/2014/03/16/141619')
    %test:assertTrue
function st:url-is-relative_2($path ){
 muURL:isRelative( $path )
};




declare
    %test:name("given 'base' resolve 'url' (  base ends with path,   url is absolute)  ")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619' ,'/cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_1($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};


declare
    %test:name("given 'base' resolve 'url' ( base ends with '/'  , url is absolute )")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619/' ,'/cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_2($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};


declare
    %test:name("given 'base' resolve 'url' ( 'base' ends with 'authority' component, url is 'absolute' )")
    %test:args('http://markup.co.nz' ,'/cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_3($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( url has scheme and authority so base is ignored ) ")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619' ,'http://markup.co.nz/cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_4($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base path only a /,    url is absolute)"  )
    %test:args('http://markup.co.nz/' ,'/cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_5($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base with path,  url is relative path with parent steps ../../ ) ")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619' ,'../../../../resources/images' )
    %test:assertEquals('http://markup.co.nz/resources/images')
function st:url-resolve_6($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base with path,  url is relative)")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619' ,'141620' )
    %test:assertEquals('http://markup.co.nz/archive/2014/03/16/141620')
function st:url-resolve_7($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base with path,  url is relative with current context './' ")
    %test:args('http://markup.co.nz/archive/2014/03/16/141619' ,'./141620' )
    %test:assertEquals('http://markup.co.nz/archive/2014/03/16/141620')
function st:url-resolve_8($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};


declare
    %test:name("given 'base' resolve 'url' ( base,  url is only current context '.' ")
    %test:args('http://markup.co.nz' ,'.' )
    %test:assertEquals('http://markup.co.nz/')
function st:url-resolve_8($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base no path,  url is  current context './'  with path ")
    %test:args('http://markup.co.nz' ,'./cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_10($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

declare
    %test:name("given 'base' resolve 'url' ( base no path,  url is relative ")
    %test:args('http://markup.co.nz' ,'cards/me' )
    %test:assertEquals('http://markup.co.nz/cards/me')
function st:url-resolve_11($base ,  $relative  ){
 muURL:resolve( $base , $relative  )
};

(::)
