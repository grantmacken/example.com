xquery version "3.0";
import module namespace system = "http://exist-db.org/xquery/system";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace file = "http://exist-db.org/xquery/file";
import module namespace http = "http://expath.org/ns/http-client";

let $log_name := 'posts-stored.log'
let $app-root  :=   substring-before( system:get-module-load-path() ,'/module')
let $app-path  :=   substring-after( $app-root ,'//')
let $DOMAIN  :=   substring-after( $app-root ,'/apps/')
let $ROOT  :=   substring-before( $app-root ,'/apps/')
let $logger  :=   substring-before( $DOMAIN ,'.')
let $priority := 'info'
let $USER_NAME  :=   util:system-property('user.name')
let $USER_DIR  :=   util:system-property('user.dir')
let $GIT_USER  :=   sm:id()//sm:username/string()
let $access_token_path :=
  '/home/' || $USER_NAME || '/projects/' || $GIT_USER || '/.github-access-token'

let $project_path :=
  '/home/' || $USER_NAME || '/projects/' || $GIT_USER || '/' || $DOMAIN

let $username := $GIT_USER
let $password := normalize-space(file:read-unicode($access_token_path))
let $content := file:read-unicode( $project_path || '/.logs/' || $log_name )
let $split :=  tokenize($content,'&#xA;')
let $lastLine :=
  if ( empty( $split[count($split)] ) ) then (
    $split[ count($split) ]
  )
  else ( $split[ count($split) -1 ] )

let $stored :=  tokenize($lastLine,' ')[2]
let $documentAvailable :=  doc-available($stored)
let $inDoc :=  doc($stored)
let $docName :=   $inDoc//name/string()
let $docDraft :=   $inDoc//draft/string() eq 'no'
let $isNotDraft :=
  if ( exists($inDoc//draft/text()) ) then
    ( $inDoc//draft/string() eq 'no' )
  else ( exists($inDoc//draft/text()) )

let $logThis :=
  util:log-app(
    $priority,
    $logger,
    concat('do PUT to remote: ', $isNotDraft )
  )

let $doPUT :=
 if ( $isNotDraft ) then (
  let $remote-ip := '120.138.30.7'
  let $remote := 'http://' || $remote-ip || ':8080'
  let $rest := '/exist/rest'
  let $urlRemote := $remote || $rest || $stored

  let $logThis := util:log-app( $priority,  $logger, concat('data store: ', $stored ))

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
  return (http:send-request( $reqPut , (), $inDoc))
 )
else ()

let $logPUT :=
if(empty($doPUT)) then ()
else (
  let $put-message := $doPUT[1]/@message/string()
  let $put-status := $doPUT[1]/@status/string()
  return
    util:log-app(
      $priority,
      $logger,
      concat('PUT status: ', $put-message, ' ', $put-status )
      )
  )

return ()
