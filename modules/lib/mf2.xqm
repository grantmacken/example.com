xquery version "3.0";

module namespace mf2 = "http://markup.co.nz/#mf2";
import  module namespace muCache = "http://markup.co.nz/#muCache" at 'muCache.xqm';
import  module namespace muURL = "http://markup.co.nz/#muURL" at 'muURL.xqm';

declare namespace  xhtml = "http://www.w3.org/1999/xhtml";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:media-type "text/xml";
declare option output:omit-xml-declaration "yes";
declare option output:indent "yes";


(: import my libs :)


declare function mf2:parse( $url as xs:string )  {
let $node := muCache:fetch( $url  )
return
mf2:dispatch( $node )
};

declare function mf2:p(){
  typeswitch(t  )


}


(:~
 : mf2
 : This module is for dealing with 'responses' that are returned from a requests
 : using expath [http-client](The http-clent http://expath.org/spec/http-client)
 :
 : Response HTML content is 'tidied up and parsed' into a document node
 :
 : These nodes are passed as parameters to the functions contained here
 :
 : Specifically we are looking at our ability to process webmentions

    simpler parsing - parsers can now do a simple stream-parse (or in-order DOM
    tree walk) and parse out all microformat objects, properties, and values,
    without having to know anything about any specific microformats

    http://microformats.org/wiki/microformats2-parsing


   property tasks

         u-  each mf2 relative or absolute urls needs to be resolved from the document base url
             to achieve this we need the base url


         e-  element content needs to be sanitised


  https://github.com/microformats/tests
  @author Grant MacKenzie
  @version 0.01 :
 :
 :
:)



(: mf notes
 prefixed class names h- p- u- dt- e-

'h-*' for root class names, e.g. 'h-card'
'p-*' for simple (text) properties, e.g. 'p-name'
'u-*' for URL properties, e.g. 'u-photo'
'dt-*' for date/time properties, e.g. 'dt-bday'
'e-*' for embedded markup properties, e.g. 'e-note'. See prefix naming conventions for more details.


flat sets of optional properties for all microformats (hierarchical data uses nested microformats).
Properties are all optional and potentially multivalued (applications needing a singular semantic
may use first instance).



 single class markup for common uses imply common properties

 e.g. h-card can imply  name, photo, url


<article class="h-entry">
    <h1 class="p-name">Microformats are amazing</h1>
    <p>Published by <a class="p-author h-card" href="http://example.com">W. Developer</a></p>
    <p class="p-summary">In which I extoll the virtues of using microformats.</p>
</article>


 :)


(:
   parse element 'class' for root class name(s) "h-*"
   "h-*" should contain child nodes ( either text or element nodes )

    1.    may contain common 'explicit' properties
     eg. <p class="h-card"><span class="p-name">Frances Berriman</span></p>
        card contains property name

      parse a child element for properties (p-*,u-*,dt-*,e-*)


    2.
       a.    may have explicit class property on node which implies property belongs to root mf
        eg. <span class="h-card p-name">Frances Berriman</span>
            h-card contains p-name same as  p-name nested in h-card

       a.    may contain nested microformats i.e. another element with root mf

          e.g.
           <article class="h-entry">
               <h1 class="p-name">Microformats are amazing</h1>
               <p>Published by <a class="p-author h-card" href="http://example.com">W. Developer</a></p>
               <p class="p-summary">In which I extoll the virtues of using microformats.</p>
           </article>

            root h-entry contains h-card or h-card nested in  h-entry

         ref:
         http://microformats.org/wiki/microformats2#combining_microformats


       parse a child element for microformats


    4.    may contain common 'implicit' properties
     eg. <span class="h-card">Frances Berriman</span>
        card contains property name

       imply properties for the found microformat





:)

(:  in-reply-to
parse child elements (document order) by:
  parse a child element for properties
    add properties found to current microformat
  parse a child element for microformats (recurse)
:)







(:~
dispatch is the parser entry point
 it will extract mf2 from a given node

 muCache:fetch( url ) will return a node from the cache collection
 retrieve html doc are are
        sanitized/cleaned with whitelist elements and attributes
        and  URLs resolved to the base URL
        and stored in our cache
        with a hash of the URL as the file name

:)
declare function mf2:dispatch( $node ) {
    typeswitch($node)
        case element() return (
                 if ( exists($node[contains(@class, 'h-entry')]) )then( mf2:hEntry($node) )
            else if ( exists($node[contains(@class, 'h-card')]) )then(mf2:hCard($node) )
	    else if ( exists($node[contains(@class, 'h-cite')]) )then(mf2:hCite($node) )
            else ( mf2:passthru($node) )
         )
    default return mf2:passthru($node)
};


declare function mf2:passthru( $nodes ) {
    for $node in $nodes/node() return mf2:dispatch($node)
};


declare function mf2:parseForImpliedProperties( $node , $explicitProperties ) {
(:
http://microformats.org/wiki/microformats2-parsing-faq
parsers only imply properties after parsing an element for all explicit properties,
Parsing for implied properties specifically refers to "name", "photo", and "url"
:)
let $nodeName  := lower-case( string( local-name($node)) )

(:parsing for implied properties :)
let $noExplicitNameProperty := empty( $explicitProperties/name )
let $noExplicitPhotoProperty := empty( $explicitProperties/photo )
let $noExplicitUrlProperty := empty( $explicitProperties/url )

(:if no explicit "name" property then imply by :)
let $parseImpliedNameProperty := if($noExplicitNameProperty) then(
    let $step1 :=
          switch ($nodeName )
    	   case 'img' return if ($node[@alt]) then ( $node/@alt/string())else()
    	   case 'abbr' return if ($node[@title]) then ( $node/@title/string())else()
           default return ()
    let $step2 :=  if(empty($step1)) then (
      if     ( $node//*[local-name(.) eq 'img'][@alt][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1] )
	then ( $node//*[local-name(.) eq 'img'][@alt][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1]/@alt/string())
      else if( $node//*[local-name(.) eq 'abbr'][@title][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1] )
	then ($node//*[local-name(.) eq 'abbr'][@title][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1]/@title/string())
      else if ( $node/text()  ) then ( normalize-space(  string-join($node/text() , '') ) )
      else()
    )
    else($step1)

    return ( if(not(empty($step2)) ) then(element {'name'} {$step2 } )
             else() )
    ) else(
)

(:if no explicit "photo" property then imply by :)
let $parseImpliedPhotoProperty := if($noExplicitPhotoProperty) then(
    let $step1 :=
          switch ($nodeName )
    	   case 'img' return if ($node[@src]) then ( $node/@src/string())else()
    	   case 'object' return if ($node[@data]) then ( $node/@data/string())else()
           default return ()
    let $step2 :=  if(empty($step1)) then (
      if     ( $node//*[local-name(.) eq 'img'][@src][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1] )
	then ( $node//*[local-name(.) eq 'img'][@src][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1]/@src/string()  )
      else if( $node//*[local-name(.) eq 'object'][@data][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1] )
	then ( $node//*[local-name(.) eq 'object'][@data][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1]/@data/string())
      else()
    )
    else($step1)

    return ( if(not(empty($step2))) then(element {'photo'} {$step2 } )
             else() )
    ) else(
)


let $parseImpliedUrlProperty := if($noExplicitUrlProperty) then(
    let $step1 :=
          switch ($nodeName )
    	   case 'a' return if ($node[@href]) then ( $node/@href/string())else()
           default return ()
    let $step2 :=  if(empty($step1)) then (
      if( $node//*[local-name(.) eq 'a'][@href][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1] )
	then ( $node//*[local-name(.) eq 'a'][@href][count(ancestor-or-self::*[contains(@class/string() , 'h-')]) eq 1][1]/@href/string())
      else()
    )
    else($step1)

    return ( if(not(empty($step2))) then(element {'url'} {$step2 } )
             else() )
    ) else(
)


return (  $parseImpliedNameProperty, $parseImpliedPhotoProperty, $parseImpliedUrlProperty)
};


(:  START ENTRY PROCCESSING :)

declare function mf2:hEntry($node ) {
    (:parsing for explicit properties :)
    let $explicitProperties :=
         element {'entry'} {
                     ( mf2:parseForExplicitEntryProperties($node ) )
                }
   (: parsing for implied properties after looking at explicit properties :)
   (: let $impliedProperties := ( :)
   let $impliedProperties := ( mf2:parseForImpliedProperties( $node ,  $explicitProperties) )
   let $seqNodes := ( $explicitProperties/node() , $impliedProperties )

return ( <entry>{$seqNodes}</entry> )
};


(: http://microformats.org/wiki/h-entry
   h-entry properties, inside an element with class h-entry:

    p-name - entry name/title
    p-summary - short entry summary
    e-content - full content of the entry

    p-category - entry categories/tags


    p-author - who wrote the entry, optionally embedded h-card(s)
    p-location - location the entry was posted from, optionally embed h-card, h-adr, or h-geo

    dt-published - when the entry was published
    dt-updated - when the entry was updated

    u-url - entry permalink URL
    u-uid - unique entry ID


    p-comment - optionally embedded (or nested?) h-cite(s), each of which is a comment on/reply to the parent h-entry. See comment-brainstorming (example)
    u-syndication - URL(s) of syndicated copies of this post. The property equivalent of rel-syndication (example)
    u-in-reply-to - the URL which the h-entry is considered reply to (i.e. doesn’t make sense without context, could show up in comment thread), optionally an embedded h-cite (reply-context) (example)
    u-like-of - the URL which the h-entry is considered a “like” (favorite, star) of. Optionally an embedded h-cite (example)
    u-repost-of - the URL which the h-entry is considered a “repost” of. Optionally an embedded h-cite.


:)

declare function mf2:parseForExplicitEntryProperties($node  ) {
    typeswitch($node)
        case element() return (
	    if ( exists( $node[ contains(@class, 'e-content') and contains(@class, ' p-summary') and contains(@class, 'p-name') ]) )
	    then( ( mf2:parseP($node, 'name'),
		    mf2:parseP($node, 'summary'),
		    <content>{element {local-name($node)} {( $node/node()   )}}</content> ,
		    mf2:passthruEntryProperties($node )))
	    else if ( exists( $node[contains(@class, 'e-content') and contains(@class, 'p-name') ]) )
	    then( (mf2:parseP($node, 'name'),
			      <content>{element {local-name($node)} { $node/node() }}</content> ,
			      mf2:passthruEntryProperties($node )))
            else if ( exists($node[contains(@class, 'p-name')]) )then( mf2:parseP($node, 'name'),mf2:passthruEntryProperties($node ) )
            else if ( exists($node[contains(@class, 'p-summary')]) )then( mf2:parseP($node, 'summary'),mf2:passthruEntryProperties($node ) )
            else if ( exists($node[contains(@class, 'e-content')]) )then( <content>{element {local-name($node)} {( $node/node())}}</content> , mf2:passthruEntryProperties($node ) )
	    else if ( exists($node[contains(@class, 'p-category')]) )then( mf2:parseP($node, 'category'),mf2:passthruEntryProperties($node ) )
	    (:  p-author - who wrote the entry, optionally embedded h-card(s)           :)
            else if ( exists($node[contains(@class, 'p-author') and contains(@class, 'h-card')]) )
		 then( element {'author'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'p-author')]) )then( mf2:parseP($node, 'author'),mf2:passthruEntryProperties($node )  )
(: TODO:   h-adr, or h-geo dispatchers          :)
            else if ( exists($node[contains(@class, 'p-location')][contains(@class, 'h-card') or contains(@class, 'h-adr') or contains(@class, 'h-geo')       ]) )
                 then( element {'location'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'p-location')]) )then( mf2:parseP($node, 'location'),mf2:passthruEntryProperties($node )  )


	    else if ( exists($node[contains(@class, 'u-url') and contains(@class, 'u-in-reply-to')  ]) )
		 then(mf2:parseU($node, 'in-reply-to') , mf2:parseU($node, 'url'),mf2:passthruEntryProperties($node )  )

            else if ( exists($node[contains(@class, 'u-url')]) )then( mf2:parseU($node, 'url'),mf2:passthruEntryProperties($node )  )
            else if ( exists($node[contains(@class, 'u-uid')]) )then( mf2:parseU($node, 'uid'),mf2:passthruEntryProperties($node )  )
             (: date time :)
            else if ( exists($node[contains(@class, 'dt-published')]) )then( mf2:parseDT($node, 'published'),mf2:passthruEntryProperties($node )  )
            else if ( exists($node[contains(@class, 'dt-updated')]  ) )then( mf2:parseDT($node, 'updated'),mf2:passthruEntryProperties($node )  )
             (:experimental property p-comment :)

            else if ( exists($node[contains(@class, 'p-comment')][contains(@class, 'h-cite')]) )then( element {'comment'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'p-comment')]) )then( mf2:parseP($node, 'comment'),mf2:passthruEntryProperties($node )  )
            else if ( exists($node[contains(@class, 'u-syndication')]) )then( mf2:parseU($node, 'syndication'),mf2:passthruEntryProperties($node )  )
            else if ( exists($node[contains(@class, 'u-in-reply-to')][contains(@class, 'h-cite')]) )then( element {'in-reply-to'} {( mf2:dispatch($node) )})
	    else if ( exists($node[contains(@class, 'p-in-reply-to')][contains(@class, 'h-cite')]) )then( element {'in-reply-to'} {( mf2:dispatch($node) )})


            else if ( exists($node[contains(@class, 'u-in-reply-to')]) )then( mf2:parseU($node, 'in-reply-to'),mf2:passthruEntryProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-like-of')][contains(@class, 'h-cite')]) )then( element {'in-reply-to'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'u-like-of')][contains(@class, 'h-cite')]) )then( element {'like-of'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'u-like-of')]) )then( mf2:parseU($node, 'like-of'),mf2:passthruEntryProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-repost-of')][contains(@class, 'h-cite')]) )then( element {'in-reply-to'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'u-repost-of')][contains(@class, 'h-cite')]) )then( element {'repost-of'} {( mf2:dispatch($node) )})
            else if ( exists($node[contains(@class, 'u-repost-of')]) )then( mf2:parseU($node, 'repost-of'),mf2:passthruEntryProperties($node )  )

	    (:has a root property with no associated property  could ignore or use 'children' pseudo element  like ref http://waterpigs.co.uk/php-mf2/?
	    else if ( exists($node[contains(@class, 'h-cite')]) )then( element {'children'} {( mf2:dispatch($node) )})
             else if ( exists($node[contains(@class, 'h-card')]) )then( element {'children'} {( mf2:dispatch($node) )})  :)
            else(mf2:passthruEntryProperties($node))
         )
        default return mf2:passthruEntryProperties($node)
};

declare function mf2:passthruEntryProperties($nodes ) {
    for $node in $nodes/node() return mf2:parseForExplicitEntryProperties($node )
};


(:  END ENTRY PROCCESSING :)



(:  START CARD PROCCESSING :)


declare function mf2:hCard($node ) {
    let $explicitProperties :=
     element {'card'} {
                 ( mf2:parseForExplicitCardProperties($node ) )
            }

    let $impliedProperties := ( mf2:parseForImpliedProperties( $node ,  $explicitProperties) )
    let $seqNodes := ( $explicitProperties/node() , $impliedProperties )

return ( element {'card'} { $seqNodes } )
};

(:
h-card properties, inside an element with class h-card:

    p-name - The full/formatted name of the person or organisation
    p-honorific-prefix - e.g. Mrs., Mr. or Dr.
    p-given-name - given (often first) name
    p-additional-name - other/middle name
    p-family-name - family (often last) name
    p-sort-string - string to sort by
    p-honorific-suffix - e.g. Ph.D, Esq.
    p-nickname - nickname/alias/handle

    u-email - email address
    u-logo
    u-photo
    u-url - home page
    u-uid - unique identifier

    p-category - category/tag

    p-adr - postal address, optionally embed an h-adr Main article: h-adr
    p-post-office-box
    p-extended-address
    p-street-address - street number + name
    p-locality - city/town/village
    p-region - state/county/province
    p-postal-code - postal code, e.g. US ZIP
    p-country-name - country name
    p-label

    p-geo or u-geo, optionally embed an h-geo Main article: h-geo
    p-latitude - decimal latitude
    p-longitude - decimal longitude
    p-altitude - decimal altitude
    p-tel - telephone number
    p-note - additional notes

    dt-bday - birth date
    u-key - cryptographic public key e.g. SSH or GPG
    p-org - affiliated organization, optionally embed an h-card
    p-job-title - job title, previously 'title' in hCard, disambiguated.
    p-role - description of role
    u-impp per RFC 4770, new in vCard4 (RFC6350)
    p-sex - biological sex, new in vCard4 (RFC6350)
    p-gender-identity - gender identity, new in vCard4 (RFC6350)
    dt-anniversary
:)


declare function mf2:parseForExplicitCardProperties( $node ) {
    typeswitch($node)
        case element() return (
            if (      exists($node[contains(@class, 'p-name') and contains(@class, 'u-url') ]) )then( (mf2:parseP($node, 'name'),  mf2:parseU($node, 'url'), mf2:passthruCardProperties($node )) )
            else if ( exists($node[contains(@class, 'p-name') and contains(@class, 'u-photo') ]) )then( (mf2:parseP($node, 'name'),  mf2:parseU($node, 'photo') , mf2:passthruCardProperties($node )) )
	    (:
	    p-honorific-prefix - e.g. Mrs., Mr. or Dr.
	    p-given-name - given (often first) name
	    p-additional-name - other/middle name
	    p-family-name - family (often last) name
	    p-sort-string - string to sort by
	    p-honorific-suffix - e.g. Ph.D, Esq.
	    p-nickname - nickname/alias/handle
	    :)

            else if ( exists($node[contains(@class, 'p-name')]) )then( mf2:parseP($node, 'name'),mf2:passthruCardProperties($node ) ) (:The full/formatted name of the person or organisation:)
	    else if ( exists($node[contains(@class, 'p-given-name')]) )then( mf2:parseP($node, 'given-name'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'p-additional-name')]) )then( mf2:parseP($node, 'additional-name'),mf2:passthruCardProperties($node ))
            else if ( exists($node[contains(@class, 'p-family-name')]) )then( mf2:parseP($node, 'family-name'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'p-sort-string')]) )then( mf2:parseP($node, 'sort-string'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'p-honorific-suffix')]) )then( mf2:parseP($node, 'honorific-suffix'),mf2:passthruCardProperties($node ))
	    (:
	    u-email - email address
	    u-logo
	    u-photo
	    u-url - home page
	    u-uid - unique identifier
	    :)
            else if ( exists($node[contains(@class, 'u-email')]) )then( mf2:parseU($node, 'email'),mf2:passthruCardProperties($node )  )

	    else if ( exists($node[contains(@class, 'u-logo') and  contains(@class, 'u-photo') ]) )
		 then( 	mf2:parseU($node, 'logo'),
			mf2:parseU($node, 'photo'),
			mf2:passthruCardProperties($node )  )


	    else if ( exists($node[contains(@class, 'u-logo')]) )then( mf2:parseU($node, 'logo'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'u-photo')]) )then( mf2:parseU($node, 'photo'),mf2:passthruCardProperties($node )  )
            else if ( exists($node[contains(@class, 'u-url')]) )then( mf2:parseU($node, 'url'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'u-uid')]) )then( mf2:parseU($node, 'uid'),mf2:passthruCardProperties($node )  )
	    (:
	    p-category - category/tag
	    p-adr - postal address, optionally embed an h-adr Main article: h-adr
	    p-post-office-box
	    p-extended-address
	    p-street-address - street number + name
	    p-locality - city/town/village
	    p-region - state/county/province
	    p-postal-code - postal code, e.g. US ZIP
	    p-country-name - country name
	    p-label
	    :)
	    else if ( exists($node[contains(@class, 'p-category')]) )then( mf2:parseP($node, 'category'),mf2:passthruCardProperties($node )  )

	    else if ( exists($node[contains(@class, 'p-adr')][contains(@class, 'h-adr')]) )then(  element {'adr'} {( mf2:dispatch($node) )} )
	    else if ( exists($node[contains(@class, 'p-adr')]) )then( mf2:parseP($node, 'adr'),mf2:passthruCardProperties($node )  )	(:TODO: adr:)
	    else if ( exists($node[contains(@class, 'p-post-office-box')]) )then( mf2:parseP($node, 'post-office-box'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'p-extended-address')]) )then( mf2:parseP($node, 'extended-address'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'p-street-address')]) )then( mf2:parseP($node, 'street-address'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'locality')]) )then( mf2:parseP($node, 'locality'),mf2:passthruCardProperties($node ))
            else if ( exists($node[contains(@class, 'p-region')]) )then( mf2:parseP($node, 'region'),mf2:passthruCardProperties($node ))
            else if ( exists($node[contains(@class, 'p-postal-code')]) )then( mf2:parseP($node, 'postal-code'),mf2:passthruCardProperties($node ))
            else if ( exists($node[contains(@class, 'p-country-name')]) )then( mf2:parseP($node, 'country-name'),mf2:passthruCardProperties($node ))
            else if ( exists($node[contains(@class, 'p-label')]) )then( mf2:parseP($node, 'label'),mf2:passthruCardProperties($node ))

	    (:
	    p-geo or u-geo, optionally embed an h-geo Main article: h-geo TODO
	    p-latitude - decimal latitude
	    p-longitude - decimal longitude
	    p-altitude - decimal altitude
	    p-tel - telephone number
	    p-note - additional notes
	    :)

	    else if ( exists($node[contains(@class, 'p-geo')][contains(@class, 'h-geo')]) )then(  element {'geo'} {( mf2:dispatch($node) )} )
	    else if ( exists($node[contains(@class, 'u-geo')][contains(@class, 'h-geo')]) )then(  element {'geo'} {( mf2:dispatch($node) )} )
            else if ( exists($node[contains(@class, 'u-geo')]) )then( mf2:parseU($node, 'latitude'),mf2:passthruCardProperties($node )  )
            else if ( exists($node[contains(@class, 'p-geo')]) )then( mf2:parseP($node, 'latitude'),mf2:passthruCardProperties($node )  )

            else if ( exists($node[contains(@class, 'p-latitude')]) )then( mf2:parseP($node, 'latitude'),mf2:passthruCardProperties($node )  )
            else if ( exists($node[contains(@class, 'p-longitude')]) )then( mf2:parseP($node, 'longitude'),mf2:passthruCardProperties($node )  )
            else if ( exists($node[contains(@class, 'p-altitude')]) )then( mf2:parseP($node, 'altitude'),mf2:passthruCardProperties($node )  )
            else if ( exists($node[contains(@class, 'p-tel')]) )then( mf2:parseP($node, 'tel'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-note')]) )then( mf2:parseU($node, 'note'),mf2:passthruCardProperties($node )  )

	    (:  u-key - cryptographic public key e.g. SSH or GPG
		p-org - affiliated organization, optionally embed an h-card
		p-job-title - job title, previously 'title' in hCard, disambiguated.
		p-role - description of role
		u-impp per RFC 4770, new in vCard4 (RFC6350)
		p-sex - biological sex, new in vCard4 (RFC6350)
		p-gender-identity - gender identity, new in vCard4 (RFC6350)

		dt-bday - birth date
		dt-anniversary  :)
	    else if ( exists($node[contains(@class, 'dt-bday')]) )then( mf2:parseDT($node, 'bday'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'dt-anniversary')]) )then( mf2:parseDT($node, 'anniversary'),mf2:passthruCardProperties($node ))
	    else if ( exists($node[contains(@class, 'u-key')]) )then( mf2:parseU($node, 'key'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'u-impp')]) )then( mf2:parseU($node, 'impp'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-org')][contains(@class, 'h-card')]) )then(  element {'org'} {( mf2:dispatch($node) )} )
	    else if ( exists($node[contains(@class, 'p-org')]) )then( mf2:parseP($node, 'org'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-job-title')]) )then( mf2:parseP($node, 'job-title'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'sex')]) )then( mf2:parseP($node, 'sex'),mf2:passthruCardProperties($node )  )
	    else if ( exists($node[contains(@class, 'p-gender-identity')]) )then( mf2:parseP($node, 'gender-identity'),mf2:passthruCardProperties($node )  )

            else(mf2:passthruCardProperties($node))
         )
        default return mf2:passthruCardProperties($node)
};

declare function mf2:passthruCardProperties($nodes ) {
    for $node in $nodes/node() return mf2:parseForExplicitCardProperties($node )
};


(:  END CARD PROCCESSING :)

(:  START CITE PROCCESSING :)
declare function mf2:hCite($node ) {
    let $explicitProperties :=
     element {'cite'} {mf2:parseForExplicitCiteProperties($node)}

    let $impliedProperties := ( mf2:parseForImpliedProperties( $node ,  $explicitProperties) )
    let $seqNodes := ( $explicitProperties/node() , $impliedProperties )

return ( element {'cite'} { $seqNodes } )
};

declare function mf2:parseForExplicitCiteProperties( $node ) {
typeswitch($node)
    case element() return (
	if ( exists($node[contains(@class, 'e-content') and contains(@class, 'p-name')] ) )then(mf2:parseP($node, 'name'), <content>{element {local-name($node)} {( $node/node() )}}</content> , mf2:passthruCiteProperties($node ) )
        (:NOTE.  might remove this:  'e-content' not included http://microformats.org/wiki/h-cite   :)

	else if ( exists($node[contains(@class, 'p-name')]) )then( mf2:parseP($node, 'name'),mf2:passthruCiteProperties($node ) ) (:name of the work :)
       (:p-author with emdeded h-card													   :)
	else if ( exists($node[contains(@class, 'p-author')][contains(@class, 'h-card')]) )then( element {'author'} { ( mf2:dispatch($node )) })
	else if ( exists($node[contains(@class, 'p-author')]) )then( mf2:parseP($node, 'author'),mf2:passthruCiteProperties($node )  )

	else if ( exists($node[contains(@class, 'dt-published')]))then( mf2:parseDT($node, 'published'),mf2:passthruCiteProperties($node))(:date (and optionally time) of publication :)
	else if ( exists($node[contains(@class, 'dt-accessed')]))then( mf2:parseDT($node, 'accessed'),mf2:passthruCiteProperties($node))
	(: date the cited work was accessed for whatever reason it is being cited. Useful in case online work changes and it's possible
	to access the dt-accessed datetimestamped version in particular, e.g. via the Internet Archive. :)

	else if ( exists($node[contains(@class, 'u-url')]) )then( mf2:parseU($node, 'url'),mf2:passthruCiteProperties($node)) (: a URL to access the cited work :)
	else if ( exists($node[contains(@class, 'u-uud')]) )then( mf2:parseU($node, 'uid'),mf2:passthruCiteProperties($node)) (: a URL/URI that uniquely/canonically identifies the cited work, canonical permalink :)

	else if ( exists($node[contains(@class, 'p-publication')]) )then( mf2:parseP($node, 'publication'),mf2:passthruCiteProperties($node))
	(:
	for citing articles in publications with more than one author, or perhaps when the author has a specific publication vehicle for the cited work
	Also works when the publication is known, but the authorship information
	is either unknown, ambiguous, unclear, or collaboratively complex enough to be unable to list explicit author(s), e.g. like with many wiki pages.
	:)

	else if ( exists($node[contains(@class, 'p-content')]) )then( mf2:parseP($node, 'content'),mf2:passthruCiteProperties($node )  )
	(:for when the citation includes the content itself, like when citing short text notes (e.g. tweets).  :)


	(:has a root property with no associated property  could ignore or use 'children' pseudo element  like ref http://waterpigs.co.uk/php-mf2/?   :)
        (:else if ( exists($node[contains(@class, 'h-card')]) )then( element {'card'} {( mf2:passthruCardProperties($node ) )}):)

	else(mf2:passthruCiteProperties($node))
    )
default return mf2:passthruCiteProperties($node)
};

declare function mf2:passthruCiteProperties($nodes ) {
    for $node in $nodes/node() return mf2:parseForExplicitCiteProperties($node )
};

(:  END CITE PROCCESSING :)

(:
    http://microformats.org/wiki/microformats2-parsing
    parse the element for the value-class-pattern, if a value is found then return it.
    if abbr.p-x[title], then return the title attribute
    else if data.p-x[value] or input.p-x[value], then return the value attribute
    else if img.p-x[alt] or area.p-x[alt], then return the alt attribute
    else return the textContent of the element, replacing any nested <img> elements with their alt attribute if present, or otherwise their src attribute if present.
    :)

declare function mf2:parseP( $node , $name ){
let $nodeName  := lower-case( string( local-name($node)) )
let $step1 :=
    if( exists( $node//*[contains(./@class, "value" )]/text() ) ) then( normalize-space($node//*[contains(./@class, "value" )]/string()))
    else()

let $step2 :=
 if(empty($step1)) then (
      switch ($nodeName )
       case 'abbr' return if ($node[@title]) then ( $node/@title/string() )else()
	case 'data' return if ($node[@value]) then ( $node/@value/string())else()
	case 'input' return if ($node[@value]) then ( $node/@value/string())else()
	case 'img' return if ($node[@alt]) then ( $node/@alt/string())else()
	case 'area' return if ($node[@alt]) then ( $node/@alt/string())else()
       default return (  if ( $node/text()  ) then ( normalize-space($node/string()) )
			 else()
	    )
       )
 else($step1)

return
if(empty($step2)) then ()
else(
    element{ $name }{$step2}
  )
};




declare function mf2:parseU( $node , $tag-name ){
let $nodeName  := lower-case( string( local-name($node)) )
 (:
     if a.u-x[href] or area.u-x[href], then get the href attribute
     if img.u-x[src], then get the src attribute
     if object.u-x[data], then get the data attribute

 TODO
    if there is a gotten value, return the normalized absolute URL of it,
    following the containing document's language's rules for resolving
    relative URLs (e.g. in HTML, use the current URL context as determined
    by the page, and first <base> element if any).

    else parse the element for the value-class-pattern, if a value is found then return it


    if abbr.u-x[title], then return the title attribute
    if data.u-x[value] or input.u-x[value], then return the value attribute
    else return the textContent of the element

 :)

let $step1 :=
    switch ($nodeName )
       case 'a' return if ($node[@href]) then ( $node/@href/string() )else()
	   case 'area' return if ($node[@href]) then ( $node/@href/string())else()
	   case 'img' return if ($node[@src]) then ( $node/@src/string())else()
	   case 'object' return if ($node[@data]) then ( $node/@data/string())else()
       default return (
        if( exists( $node//*[contains(./@class, "value" )]/text() ) ) then($node//*[contains(./@class, "value" )]/string())
        else()
       )

let $step2 := (
 if(empty($step1)) then (
      switch ($nodeName )
       case 'abbr' return if ($node[@title]) then ( $node/@title/string() )else()
	   case 'data' return if ($node[@value]) then ( $node/@value/string())else()
	   case 'input' return if ($node[@value]) then ( $node/@value/string())else()
       default return ( normalize-space( $node/text() ))
       )
 else($step1)
 )

return
if(empty($step2)) then ()
else(
    element{ $tag-name }{$step2}
  )
};


declare function mf2:parseDT( $node , $tag-name ){
let $nodeName  := lower-case( string( local-name($node)) )
let $step1 :=
    switch ($nodeName )
        case 'time' return ( if ($node[@datetime]) then ( $node/@datetime/string() )else())
        case 'abbr' return (if ($node[@title]) then ( $node/@title/string() )else())
        case 'data' return (if ($node[@value]) then ( $node/@value/string() )else())
        case 'input' return (if ($node[@value]) then ( $node/@value/string() )else())
       default return ()

let $step2 := (
 if(empty($step1)) then (
		if ( $node/text() ) then ( $node/string() )
		else()
       )
 else($step1)
 )

return
    if(empty($step2)) then ()
    else(
        element{ $tag-name }{$step2}
      )
};
