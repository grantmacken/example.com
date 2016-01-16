xquery version "3.0";
import module namespace system = "http://exist-db.org/xquery/system";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace file = "http://exist-db.org/xquery/file";
import module namespace http = "http://expath.org/ns/http-client";



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

let $stored_log :=  $project_path || '/.logs/pages-stored.log'

let $username := $GIT_USER
let $password := normalize-space(file:read-unicode($access_token_path))
let $content := file:read-unicode($stored_log)

let $logThis := util:log-app( $priority,  $logger, 'username: ' || $username  )
let $logThis := util:log-app( $priority,  $logger, 'password: ' || $password )
let $logThis := util:log-app( $priority,  $logger, '-------------------------')
let $split :=  tokenize($content,'&#xA;')
let $lastLine :=
  if ( empty( $split[count($split)] ) ) then (
    $split[ count($split) ]
  )
  else ( $split[ count($split) -1 ] )

let $post-stored :=  tokenize($lastLine,' ')[2]
let $documentAvailable :=  doc-available($post-stored)
let $inDoc :=  doc($post-stored)
let $docName :=   $inDoc//name/string()
let $docDraft :=   $inDoc//draft/string() eq 'no'

let $remote-ip := '120.138.30.7'
let $remote := 'http://' || $remote-ip || ':8080'
let $rest := '/exist/rest'
let $urlRemote := $remote || $rest || $post-stored

let $logThis := util:log-app( $priority,  $logger, $urlRemote )


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


let $sendPUT :=
  if( not($docDraft) ) then (
  http:send-request( $reqPut , (), $inDoc) )
  else ( )


let $sendGET :=
  http:send-request( $reqGetRemote  )

let $logThis := util:log-app( $priority,  $logger, $sendGET[1]/@message/string() )
let $logThis := util:log-app( $priority,  $logger, $sendGET[1]/@status/string() )
let $logThis :=
  util:log-app( $priority,  $logger, $sendGET[1]//http:header[@name='last-modified']/@value/string())
let $logThis :=
  util:log-app( $priority,  $logger, $sendGET[1]//http:header[@name='created']/@value/string() )

(:
   ||
  $USER_NAME || '/'  ||
  $GIT_USER
  '.github-access-token'
let $path := $USER_PATH || '/' || $DOMAIN || '/.logs/posts-stored.log'
let $access_token_path :=  $USER_PATH || '/'  || '.github-access-token'
:)
return ()

(:
let $EXIST_HOME  :=   system:get-exist-home()



let $app-path  :=   substring-after( $app-root ,'//')
let $domain  :=   substring-after( $app-root ,'/apps/')
let $abbrev  :=   substring-before( $domain ,'.')
let $collection-uri  :=   $app-root || '/data/jobs'
let $resource-name  :=   'upload-link-atom.xml'
let $contents  :=   <link href="{$uri}" />
let $mime-type  :=   'application/xml'
let $logger-name := $abbrev || '.log'
let $priority := 'info'
let $message :=  $resource-name ||': ' || $abbrev ||  ': '  || $uri
let $logApp := util:log-app($priority, $logger-name, 'hi' )

return ()

let $APP_ROOT  :=   substring-before( system:get-module-load-path() ,'/module')
let $APP_PATH  :=   substring-after( $APP_ROOT ,'//')
let $DOMAIN  :=   substring-after( $APP_ROOT ,'/apps/')
let $DATA_PATH  :=   substring-after( $APP_ROOT ,'/apps/')
let $GIT_USER  :=   'grantmacken'
let $USER_PATH  :=   '/home/gmack/projects/' || $GIT_USER

let $OS_NAME  :=   util:system-property('os.name')
let $OS_VERSION  :=   util:system-property('os.version')
let $USER_NAME  :=   util:system-property('user.name')
let $USER_DIR  :=   util:system-property('user.dir')
let $path := $USER_PATH || '/' || $DOMAIN || '/.logs/posts-stored.log'
let $access_token_path :=  $USER_PATH || '/'  || '.github-access-token'
let $username := $GIT_USER
let $password := file:read-unicode($access_token_path)
let $content := file:read-unicode($path)
let $split :=  tokenize($content,'&#xA;')
let $lastLine :=
  if ( empty( $split[count($split)] ) ) then (
    $split[ count($split) ]
  )
  else ( $split[ count($split) -1 ] )

let $post-stored :=  tokenize($lastLine,' ')[2]
let $documentAvailable :=  doc-available($post-stored)
let $doc :=  doc($post-stored)
let $docName :=   $doc//name/string()
let $docDraft :=   $doc//draft/string() eq 'no'

return
<result>
{ util:system-property('user.name') ,
environment-variable('SHELL')   ,
available-environment-variables(),
environment-variable('NLSPATH'),
environment-variable('LOGNAME'),
environment-variable('USER'),
environment-variable('HOME'),
environment-variable('SERVER') eq 'development'
}
</result>
:)
