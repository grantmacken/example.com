xquery version "3.0";
(:~
sanitizer/markup cleaner

@see https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Content_categories
@see http://www.w3.org/TR/html-markup/elements-by-function.html
@see http://www.w3.org/TR/2011/WD-html5-20110525/content-models.html
@see https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Sections_and_Outlines_of_an_HTML5_document

 @see http://www.slideshare.net/uwevoelker/sanitizing-html-5-with-perl-5
 @author Grant MacKenzie
 @version 0.01
:)
module namespace muSan="http://markup.co.nz/#muSan";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace system="http://exist-db.org/xquery/system";
import module namespace http = "http://expath.org/ns/http-client";
(:import module namespace err = "http://www.w3.org/2005/xqt-errors";:)
(: DEPENDENCIES:  import my libs :)
import  module namespace muCache = "http://markup.co.nz/#muCache" at 'muCache.xqm';
import  module namespace muURL = "http://markup.co.nz/#muURL" at 'muURL.xqm';
import  module namespace muUtility = "http://markup.co.nz/#muUtility" at 'muUtility.xqm';

(: NAMESPACES: :)
declare namespace  xhtml = "http://www.w3.org/1999/xhtml";
declare namespace  atom = "http://www.w3.org/2005/Atom";
declare namespace  xlink = "http://www.w3.org/1999/xlink";

(:
https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/Content_categories
:)

(:

@see http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#global-attributes
@see http://www.w3.org/TR/html-markup/global-attributes.html
@see https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes



core attr

"accesskey", "class", "contenteditable", "contextmenu", "dir", "draggable",
"dropzone", "hidden", "id", "lang", "spellcheck", "style", "tabindex", "title",
"translate"

keep some


http://www.w3.org/TR/html-markup/global-attributes.html#common.attrs.event-handler
 event handler attr

drop all

XML attributes
"xml:lang", "xml:space", "xml:base"

drop all

:)


declare variable $muSan:global-attr := ( "id",  "class", "title" );

(:Elements belonging to the flow content category typically contain text or
embedded content. :)
declare variable $muSan:flow-content := (
"a", "abbr", "address", "article", "aside", "audio", "b>,<bdo", "bdi",
"blockquote", "br", "button", "canvas", "cite", "code", "command", "data",
"datalist", "del", "details", "dfn", "div", "dl", "em", "embed", "fieldset",
"figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header",
"hgroup", "hr", "i", "iframe", "img", "input", "ins", "kbd", "keygen", "label",
"main", "map", "mark", "math", "menu", "meter", "nav", "noscript", "object",
"ol", "output", "p", "pre", "progress", "q", "ruby", "s", "samp", "script",
"section", "select", "small", "span", "strong", "sub", "sup", "svg", "table",
"template", "textarea", "time", "ul", "var", "video", "wbr"
);

declare variable $muSan:sectioning-content := (
"article", "aside", "nav", "section"
);

declare variable $muSan:heading-content := (
"h1", "h2", "h3", "h4", "h5", "h6", "hgroup"
);


(:Phrasing content defines the text and the mark-up it contains. Runs of
phrasing content make up paragraphs.:)
declare variable $muSan:phrasing-content := (
"abbr", "audio", "b", "bdo", "br", "button", "canvas", "cite", "code",
"command", "datalist", "dfn", "em", "embed", "i", "iframe", "img", "input",
"kbd", "keygen", "label", "mark", "math", "meter", "noscript", "object",
"output", "progress", "q", "ruby", "samp", "script", "select", "small", "span",
"strong", "sub", "sup", "svg", "textarea", "time", "var", "video", "wbr"
);

declare variable $muSan:embedded-content := (
"audio", "canvas", "embed", "iframe", "img", "math", "object", "svg", "video"
);

declare variable $muSan:interactive-content := (
"a", "button", "details", "embed", "iframe", "keygen", "label", "select", "textarea"
);

declare variable $muSan:form-associated-content := (
"button", "fieldset", "input", "keygen", "label", "meter", "object", "output", "progress", "select", "textarea"
);


(:~
@see http://www.w3.org/TR/html-markup/elements-by-function.html
@see http://www.whatwg.org/specs/web-apps/current-work/multipage/semantics.html
:)
declare variable $muSan:root :=
  ( "html");

(:~
Document metadata
    base command link meta noscript script style title
@see http://www.w3.org/TR/html-markup/elements-by-function.html#document-metadata-elements
@see http://wiki.whatwg.org/wiki/MetaExtensions

<base>, <command>, <link>, <meta>, <noscript>, <script>, <style> and <title>
 :)
declare variable $muSan:metadata :=
  ( "head", "base",  "link", "meta", "title" );

declare variable $muSan:metadata-blacklist :=
  ( "command", "noscript",  "script", "style");

(:~
Sections

@see  http://www.whatwg.org/specs/web-apps/current-work/multipage/sections.html
@see  http://www.w3.org/TR/html-markup/elements-by-function.html#document-metadata-elements
:)

declare variable $muSan:sections :=
  (
   "body", "article", "section", "aside", "footer", "header" , "nav" , "address",
    "h1", "h2", "h3", "h4", "h5", "h6", "hgroup"
   );

(:~
grouping

@see http://www.w3.org/TR/html-markup/elements-by-function.html#grouping-content-elements
@see http://www.whatwg.org/specs/web-apps/current-work/multipage/grouping-content.html
:)

declare variable $muSan:grouping :=
    (
    "p", "hr",  "pre", "blockquote", "ol", "ul", "li", "dl", "dt", "dd",
    "figure", "figcaption", "main" ,"div"
    );

(:~
Text-level semantics

@see http://www.w3.org/TR/html-markup/elements-by-function.html#text-level-semantics-elements
@see http://www.w3.org/TR/html5/text-level-semantics.html
@see http://www.whatwg.org/specs/web-apps/current-work/multipage/text-level-semantics.html
:)

declare variable $muSan:text-level-semantics :=
(
"a", "em", "strong", "small", "s", "cite", "q", "dfn", "abbr",
"ruby", "rt", "rp", "data",  "time",  "code", "var", "samp", "kbd",
"sub", "sup", "i", "b", "u", "mark", "bdi", "bdo", "span" , "br" , "wbr"
);


(:~
edits

@see http://www.w3.org/TR/html-markup/elements-by-function.html#edits-elements
:)
declare variable $muSan:edits :=
(
"ins", "del"
);

(:~
embedded-content
 TODO:
@see http://www.w3.org/TR/html-markup/elements-by-function.html#embedded-content-elements
:)
declare variable $muSan:embedded :=
(
"img", "iframe", "embed", "object", "param", "video", "audio", "source",
"track", "canvas", "map", "area"
);


(:~
tables
TODO:
http://www.w3.org/TR/html-markup/elements-by-function.html#tables-elements:)
declare variable $muSan:tables :=
(
"table", "caption", "colgroup", "col", "tbody", "thead", "tfoot", "tr
", "td", "th"
);


(:~
forms
http://www.w3.org/TR/html-markup/elements-by-function.html#forms-elements:)
declare variable $muSan:forms :=
(
"form", "fieldset", "legend", "label", "input", "button", "select",
"datalist", "optgroup", "option", "textarea", "keygen", "output",
"progress", "meter"
);

(:http://www.w3.org/TR/html-markup/elements-by-function.html#interactive-elements:)
declare variable $muSan:interactive :=
(
"details ", "summary ", "command ", "menu"
);






(: Fakes for tests:)

declare function muSan:fake-sanitizer( $url ) {
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

let $docElement :=  muCache:getRawHTML( $url )
let $baseURL := $getBaseURL( $docElement , $url )
let $cleanedHTML := $getCleanHTML( $docElement , $baseURL )

return
$cleanedHTML
};


declare function muSan:sanitizer( $node as node(), $baseURL as xs:string ) {
    typeswitch ($node)
	case text() return ( $node )
        case element() return
            if (namespace-uri($node) eq "http://www.w3.org/1999/xhtml") then (
		let $tag := local-name($node)
		return (
		    if( $tag = ('html') )
		       then (element { local-name($node) } { muSan:sanitizer-passthru( $node, $baseURL ) } )
		    else if( $tag = $muSan:metadata )
			    then (
				switch ( local-name($node) )
				case 'link' return  ( muSan:link( $node, $baseURL ) )
				case 'meta'  return   ( muSan:meta( $node, $baseURL ) )
				default return
				    element
					{ local-name( $node ) }
					{ muSan:sanitizer-passthru( $node, $baseURL ) }
				)
		    else if( $tag = $muSan:sections ) then
				    ( 	element { local-name($node) }
						{ muSan:set-global-attributes($node, $baseURL ),
						  muSan:sanitizer-passthru( $node, $baseURL )
						}
				    )
		    else if( $tag = $muSan:grouping ) then (
			    element { local-name($node) }
				    {
				    switch ( local-name($node) )
				       case 'blockquote' return  ( muSan:blockquote( $node, $baseURL ) )
				       case 'ol' return  ( muSan:ol( $node, $baseURL ) )
				       default return (
						muSan:set-global-attributes($node, $baseURL )),
				    muSan:sanitizer-passthru( $node, $baseURL )
				    }
			)
		    else if( $tag = $muSan:text-level-semantics ) then (
			    element { local-name($node) }
				    {
				    switch ( local-name($node) )
					case 'a'  return   ( muSan:a( $node, $baseURL ) )
					case 'q'  return   ( muSan:q( $node, $baseURL ) )
					case 'data'  return   ( muSan:data( $node, $baseURL ) )
					case 'time'  return   ( muSan:time( $node, $baseURL ) )
					case 'bdi'
					case 'bdo'  return   ( muSan:bd( $node, $baseURL ) )
					default return (
						muSan:set-global-attributes($node, $baseURL )),
				    muSan:sanitizer-passthru( $node, $baseURL )
				    }
			)
		    else if( $tag = $muSan:edits ) then (
			    element { local-name($node) }
				    {
				    for $att in $node/@*
				       return
				       switch ( name($att) )
					   case 'cite' return  ( muSan:set-attribute($att) )
					   case 'datetime'  return  ( muSan:set-attribute-url($baseURL, $att ) )
					   default return (
							   if( name($att) =  $muSan:global-attr ) then ( muSan:set-attribute($att)  )
							   else ()							   )
				    ,
				    muSan:sanitizer-passthru( $node, $baseURL )
				    }
						    )
		    else if( $tag = $muSan:embedded ) then (
			    element { local-name($node) }
				    {
				    switch ( local-name($node) )
				       case 'img' return  ( muSan:img( $node, $baseURL ) )
				       default return (
						muSan:set-global-attributes($node, $baseURL ) ),
				    muSan:sanitizer-passthru( $node, $baseURL )
				    }
			    )
		    else if( $tag = $muSan:tables ) then (
			    element { local-name($node) }
				    {(:table col and  colgroup  td th:)
				    switch ( local-name($node) )
					case 'table' return  ( muSan:table( $node, $baseURL ) )
					case 'td' return  ( muSan:td( $node, $baseURL ) )
					case 'th' return  ( muSan:th( $node, $baseURL ) )
					case ' col'
					case ' colgroup' return  ( muSan:col( $node, $baseURL ) )
				       default return (
						muSan:set-global-attributes($node, $baseURL ) ),
				    muSan:sanitizer-passthru( $node, $baseURL )
				    }

			)
		    else if( $tag = $muSan:forms ) then (element { local-name($node) } { muSan:sanitizer-passthru( $node, $baseURL ) })
		    else if( $tag = $muSan:interactive ) then (element { local-name($node) } { muSan:sanitizer-passthru( $node, $baseURL ) })

		    else(
			if( $node[ancestor::*[local-name(.) eq 'head' ]] ) then ()

			else(
			 if(  $tag = $muSan:metadata-blacklist ) then ()
			 else()
			)

			 (:
we have come to an end of our whitelist elements.
what do we do with unknown or unwanted elements?

if element contained in head drop any element not in whitelist

			  :)


			 )
		)
		)

            else(muSan:sanitizer-passthru( $node, $baseURL ))
        default return
           muSan:sanitizer-passthru( $node, $baseURL )
};

declare function muSan:sanitizer-passthru( $node, $baseURL ) {
  for $child in $node/node() return muSan:sanitizer( $child , $baseURL )
};



(: ##########################################################################
ATTRIBUTES:


############################################################################ :)
declare function muSan:set-global-attributes( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'title'
	    case 'id'
	    case 'class'
	    return  ( muSan:set-attribute( $att ) )
	    default return ()
};

declare function muSan:set-attribute( $att ) {
   attribute { name($att) } { $att }
};

declare function muSan:set-attribute-url($baseURL, $att ) {
   attribute { name($att)} {   muURL:resolve( $baseURL, $att )}
};









(: ##########################################################################
ELEMENTS:




############################################################################ :)


(:

links rel

Links are a conceptual construct, created by a, area, and link elements,

@see http://www.whatwg.org/specs/web-apps/current-work/multipage/links.html#linkTypes
@see http://microformats.org/wiki/existing-rel-values#HTML5_link_type_extensions


:)
declare function muSan:link( $node, $baseURL ) {
 if( $node[@rel] ) then (
    element { local-name($node) } {
     for $att in $node/@*
	return
	switch ( name($att) )
	    case 'rel' return  ( muSan:set-attribute($att) )
	    case 'href'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	    default return (
			    if( name($att) =  $muSan:global-attr ) then ( muSan:set-attribute($att)  )
	                    else ()
			    )
    }


 )
 else( muSan:sanitizer-passthru( $node, $baseURL ) )
};





(:
@see http://www.w3.org/TR/html-markup/meta.name.html#meta.name
@see http://wiki.whatwg.org/wiki/MetaExtensions
:)
declare function muSan:meta( $node, $baseURL ) {
if( $node[@name] ) then (
    switch (  $node/@name/string() )
	case 'author'
	case 'application-name'
	case 'description'
	case 'generator'
	case 'keywords'
	case 'viewport'
	return  (
		element { local-name($node) } {
		for $att in $node/@*
		   return
		   switch ( name($att) )
		       case 'name' return  ( muSan:set-attribute($att) )
		       case 'content'  return  ( muSan:set-attribute($att) )
		       default return (
			    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	                    else ()
		       )
		}
	    )
	default return ()
 )
 else( muSan:sanitizer-passthru( $node, $baseURL ) )
};




(: ##########################################################################
ELEMENTS: grouping-content
############################################################################ :)

declare function muSan:blockquote( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'cite'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

declare function muSan:ol( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'start'
	case 'type'
	case 'reversed'  return  (  muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

declare function muSan:li( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'value'
	      return  (  muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};


(: ##########################################################################
ELEMENTS: text-level-semantics

for rel
############################################################################ :)

declare function muSan:a( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'href'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	    case 'target'
	    case 'download'
	    case 'ping'
	    case 'rel'
	    case 'type'
	    case 'hreflang'
	    case 'media'  return  ( muSan:set-attribute( $att ) )
	    default return (
		if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
		else ()
	    )
};

declare function muSan:q( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'cite'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	    default return (
		if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
		else ()
	    )
};

declare function muSan:data( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'value'  return  ( muSan:set-attribute($att) )
	    default return (
		if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
		else ()
	    )
};


declare function muSan:time( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'datetime'  return  (  muSan:set-attribute($att) )
	    default return (
		if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
		else ()
	    )
};


(: bdi and bdo :)
declare function muSan:bd( $node, $baseURL ) {
    for $att in $node/@*
	return
	switch ( name($att) )
	    case 'dir'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	    default return (
		if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
		else ()
	    )
};




(: ##########################################################################
ELEMENTS: embedded-content
############################################################################ :)

declare function muSan:img( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'alt'
	case 'width'
	case 'srcset'
	case 'crossorigin'
	case 'height'
	case 'usemap'
	case 'ismap'
	    return  ( muSan:set-attribute($att) )
	case 'src'  return  ( muSan:set-attribute-url($baseURL, $att ) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

(: ##########################################################################
ELEMENTS: tabular-data

table col and  colgroup  td th
############################################################################ :)

declare function muSan:table( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'sortable'  return  ( muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

(:col and  colgroup:)
declare function muSan:col( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'span'  return  ( muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

declare function muSan:td( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'colspan'
	case 'rowspan'
	case 'headers'  return  ( muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};

declare function muSan:th( $node, $baseURL ) {
for $att in $node/@*
    return
    switch ( name($att) )
	case 'colspan'
	case 'rowspan'
	case 'scope'
	case 'abbr'
	case 'headers'
	case 'sorted'  return  ( muSan:set-attribute($att) )
	default return (
	    if( name($att) = $muSan:global-attr) then ( muSan:set-attribute($att)  )
	    else ()
	)
};
