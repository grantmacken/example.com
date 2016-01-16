xquery version "3.0";

declare namespace  xhtml =  "http://www.w3.org/1999/xhtml";
declare namespace  atom =  "http://www.w3.org/2005/Atom";
declare namespace  app =  "http://www.w3.org/2007/app";

declare namespace repo="http://exist-db.org/xquery/repo";
import module namespace system = "http://exist-db.org/xquery/system";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace session = "http://exist-db.org/xquery/session";

(:
   this is happening async yea yea yea
   test: check response using oxygen
:)

let $app-root  :=   substring-before( system:get-module-load-path() ,'/module')
let $app-path  :=   substring-after( $app-root ,'//')
let $domain  :=   substring-after( $app-root ,'/apps/')
let $hosts := 	doc(concat($app-root, "/data/hosts.xml"))
let  $username := $hosts/hosts/@user/string()
let  $password := $hosts/hosts/@password/string()
let  $local-ip := $hosts/hosts/local/string()
let  $remote-ip := $hosts/hosts/remote/string()

let $uri := doc(concat($app-root, "/data/jobs/upload-link-atom.xml"))//@href/string()
let $name := substring-before(tokenize($uri , '/' )[count(tokenize($uri , '/' ))], '.')

let  $local := 'http://'  || $local-ip  || ':8080'
let  $remote := 'http://' || $remote-ip || ':8080'
let  $rest := '/exist/rest'
let  $urlLocal := $local || $rest || $uri
let  $urlRemote := $remote || $rest || $uri
let  $urlWWW := 'http://www.'  || $domain  || substring-before(substring-after( $uri , '/data'), $name ) || $name

let $reqGet := <http:request href="{ $urlLocal }"

method="get"
username="{ $username }"
password="{ $password }"
auth-method="basic"
send-authorization="true"
timeout="4"
>
<http:header name = "Connection"
value = "close"/>
</http:request>

let $reqPut :=
    <http:request
      href="{ $urlRemote }"
      method="put"
      username="{ $username }"
      password="{ $password }"
      auth-method="basic"
      send-authorization="true"
      timeout="10">
      <http:header
         name = "Connection"
         value = "close"/>
      <http:body
         media-type="application/xml"
         method="xml"
         />
    </http:request>

let $inDoc := http:send-request($reqGet)[2]

let $isNotDraft :=
    if($inDoc//app:control/app:draft/string() eq 'no') then ( true() )
    else ( false() )

let $isUpate :=
    if($inDoc//app:control/app:update/string() eq 'yes') then ( true() )
    else ( false() )

let $canSend :=
    if( $isUpate or $isNotDraft ) then ( true() )
    else ( false() )

let $reqGetRemote   :=
    <http:request
        href="{ $urlRemote }"
        method="get"
        username="{ $username }"
        password="{ $password }"
        auth-method="basic"
        send-authorization="false"
        timeout="4"
    >
    <http:header name = "Connection"
    value = "close"/>
    </http:request>

let $sendPut := if( $canSend ) then (http:send-request( $reqPut , (), $inDoc) )
                else ( )

let $query :=
<query xmlns="http://exist.sourceforge.net/NS/exist">
<text>
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace system="http://exist-db.org/xquery/system";

let <![CDATA[$username]]> := '{$username}'
let <![CDATA[$password]]> := '{$password}'
let <![CDATA[$target]]> := '{$name}'
<![CDATA[
let $options := <options>
		    <workingDir>bin/nginx-cache-purge</workingDir>
		    <stdin><line>./nginx-cache-purge '{$target}' /usr/local/nginx/cache</line></stdin>
		</options>

let $check := <options>
		    <workingDir>bin/nginx-cache-inspector/</workingDir>
		    <stdin><line>./nginx-cache-inspector '{$target}' /usr/local/nginx/cache</line></stdin>
		</options>
let $cmd :=  '/bin/sh'
return
( system:as-user($username, $password, process:execute($cmd, $options )))
]]></text>
    <properties>
        <property name="indent" value="yes"/>
    </properties>
</query>


let $clearCache := if( $canSend ) then (
http:send-request( <http:request
    href="{$remote || $rest || $app-path}"
    method="post"
    username="{$username}"
    password="{$password}"
    auth-method="basic"
    send-authorization="true"
    timeout="10"
>
<http:header name="Connection" value="close"/>

<http:body media-type='application/xml'>
 {$query}
</http:body>

</http:request>))
                else ( )

return
if( $canSend ) then (
( $clearCache  , http:send-request( $reqGetRemote  ))
)
else ( ($canSend, $name, $username, $password,   $name, $urlWWW, $urlRemote) )
