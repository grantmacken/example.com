xquery version "3.0";
module namespace trigger = "http://exist-db.org/xquery/trigger";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";
import module namespace system = "http://exist-db.org/xquery/system";
import module namespace process = "http://exist-db.org/xquery/process" at
"java:org.exist.xquery.modules.process.ProcessModule";

declare function trigger:update-remote( $uri as xs:anyURI ) {
let $app-root  :=   substring-before( system:get-module-load-path() ,'/module')
let $app-path  :=   substring-after( $app-root ,'//')
let $DOMAIN  :=   substring-after( $app-root ,'/apps/')
let $logger  :=   substring-before( $DOMAIN ,'.')
let $path  :=   substring-after( $uri ,'/' || $DOMAIN || '/')
let $route  :=   substring-before( $path ,'/')
let $remoteCall  :=   xs:anyURI( system:get-module-load-path() || '/remote-' || $route || '.xq' )
let $message :=  'route: remote-' || $route || '.xq'
let $USER_NAME  :=   util:system-property('user.name')
let $USER_DIR  :=   util:system-property('user.dir')
let $GIT_USER  :=   sm:id()//sm:username/string()
let $access_token_path :=
  '/home/' || $USER_NAME || '/projects/' || $GIT_USER || '/.github-access-token'

let $project_path :=
  '/home/' || $USER_NAME || '/projects/' || $GIT_USER || '/' || $DOMAIN

let $username := $GIT_USER
let $password := normalize-space(file:read-unicode($access_token_path))
let $inDoc :=  doc($uri)
let $docName :=   $inDoc//name/string()
let $shouldPublish :=
  if ( exists($inDoc//draft/text()) ) then
    ( $inDoc//draft/string() eq 'no' )
  else ( exists($inDoc//draft/text()) )

let $doPUT :=
 if ( $shouldPublish ) then (
    let $remote-ip := process:execute(('dig','+short', 'gmack.nz'),<options/>)//line/text()
    let $remote := 'http://' || $remote-ip || ':8080'
    let $rest := '/exist/rest'
    let $urlRemote := $remote || $rest || $uri
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

  return (http:send-request( $reqPut , (), $inDoc))
 )
else ()

return (
if(empty($doPUT)) then (
    util:log-system-out('URL: ' || $uri),
    util:log-system-out('Publish to Remote: ' || $shouldPublish)
)
else (
  let $put-message := $doPUT[1]/@message/string()
  let $put-status := $doPUT[1]/@status/string()
  return (
    util:log-system-out('URL: ' || $uri),
    util:log-system-out('Publish to Remote: ' || $shouldPublish),
    util:log-system-out(concat('PUT status: ', $put-message, ' ', $put-status))
    )
  )
)
(:
util:log-system-out($USER_NAME || ' : ' || $USER_DIR || ' : ' || $GIT_USER ),
util:log-system-out($access_token_path),
util:log-system-out($project_path),
util:log-system-out($username),
util:log-system-out($password),
util:log-system-out($docName),
util:log-system-out('IP:'),
util:log-system-out($IP),
util:log-system-out('Is Not Draft: ' || $isNotDraft),
util:log-system-out($uri)
:)
};

declare function trigger:after-create-document($uri as xs:anyURI) {
trigger:update-remote($uri) };

declare function trigger:after-update-document($uri as xs:anyURI) {
  trigger:update-remote($uri)
};
