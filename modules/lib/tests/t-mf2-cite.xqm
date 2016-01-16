xquery version "3.0";

(:~
This module provides the functions that test mf2 citations.


@author Grant MacKenzie
@version 1.0
@see http://waterpigs.co.uk/php-mf2/?
tests-h-cite
:)
module namespace st="http://markup.co.nz/#mf2-tests-h-cite";

import module namespace mf2="http://markup.co.nz/#mf2"
at "../mf2.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";



(:
p-name - name of the work

dt-published - date (and optionally time) of publication

p-author - author of publication, with optional nested h-card

u-url - a URL to access the cited work

u-uid - a URL/URI that uniquely/canonically identifies the cited work, canonical permalink.

p-publication - for citing articles in publications with more than one author, or perhaps when the author has a specific publication vehicle for the cited work. Also works when the publication is known, but the authorship information is either unknown, ambiguous, unclear, or collaboratively complex enough to be unable to list explicit author(s), e.g. like with many wiki pages.

dt-accessed - date the cited work was accessed for whatever reason it is being cited. Useful in case online work changes and it's possible to access the dt-accessed datetimestamped version in particular, e.g. via the Internet Archive.

p-content for when the citation includes the content itself, like when citing short text notes (e.g. tweets).

:)

(:
p-name
dt-published
p-author - optional nested h-card
u-url
u-uid
p-publication
dt-accessed
p-content.
:)


declare
    %test:name("nothing here")
    %test:args('<p>nothing here</p>')
    %test:assertError('')
function st:nothing-here($node as element()) as element(){
  mf2:dispatch($node)
};

declare
    %test:name("nothing here also")
    %test:args('<p>nothing here</p>')
    %test:assertEmpty
function st:nothing-here-also($node as element()) as element()*{
  mf2:dispatch($node)
};


declare
    %test:name("cite [reply-context] - Barnaby-Walters")
    %test:args('
<div class="note-reply-context p-in-reply-to h-cite">
		<p class="context-datetime-container">
			<a class="u-url" rel="in-reply-to" href="https://twitter.com/t/status/335176559960936448">
				<time class="dt-published" datetime="2013-05-16T23:34:53+00:00">2013-05-16 23:34</time></a>
		</p>

		<p class="p-author h-card">
					<img class="u-photo" src="http://a0.twimg.com/profile_images/1266918745/2009-068-tantek-headshot-square_normal.jpg" alt=""/>

			<a class="u-url p-name" href="http://tantek.com/">Tantek Çelik</a>
		</p>

		<div class="p-summary p-name e-content">
			<a class="h-x-username auto-link" href="https://twitter.com/wavis">wavis</a> silo #POSSE wishlist: sign-into silo, enter URL, silo subscribe+syndicate PuSH updates, rel=canonical link back (ttk.me t4Q15)		</div>
	</div>
	')
    %test:assertExists
    %test:assertXPath("count($result) = 1")
    %test:assertXPath("local-name($result[1]) eq 'cite'")

    %test:assertXPath("$result[1]/name[text()]")
    (:%test:assertXPath("$result[1]/url[text()]"):)
    (:%test:assertXPath("$result[1]/uid[text()]"):)
    (:%test:assertXPath("$result[1]/publication[text()]"):)
    %test:assertXPath(" not( $result[1]/accessed)")
    %test:assertXPath("$result[1]/content[node()]")
    %test:assertXPath("$result[1]/author[not(text())]")
    %test:assertXPath("$result[1]/author/card/url[text()]")
    %test:assertXPath("$result[1]/author/card/photo[text()]")
    %test:assertXPath("$result[1]/author/card/name[text()]")
(::)
function st:cite-reply-context-Barnaby-Walters($node as element()) as element(){
  mf2:dispatch($node)
};




declare

    %test:args('
<li class="p-in-reply-to h-cite" id="external_http_eschnou_com_entry_testing-indieweb-federation-with-waterpigscouk-aaronpareckicom-and--62-24908_html"><div class="inner">    <div class="minicard h-card vcard author p-author">
      <div style="position: relative; width: 48px; height: 48px; float: left; margin-right: 6px;">
                <img class="photo logo u-photo" src="/images/nouns/user.svg" alt="" width="48"/>
      </div>
              <a href="http://eschnou.com" class="u-url">eschnou.com</a>
        <a class="p-name fn value name" href="http://eschnou.com"></a>
          </div>
<div class="quote-text"><div class="e-content p-name">Testing <a href="/tag/indieweb">#<span class="p-category">indieweb</span></a> federation with <a href="http://waterpigs.co.uk">@waterpigs.co.uk</a>, <a href="http://aaronparecki.com">@aaronparecki.com</a> and <a href="http://indiewebcamp.com">@indiewebcamp.com</a> !</div></div><a href="http://eschnou.com/entry/testing-indieweb-federation-with-waterpigscouk-aaronpareckicom-and--62-24908.html" class="u-url"><time class="date dt-published" datetime="2013-04-19T20:26:16+02:00">April 19, 2013 8:26pm GMT+0200</time></a></div></li>
')
%test:name("cite [REPLY CONTEXT: aaronparecki]  properties: author embeded card (  photo, url and name with no text ) ")
%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name($result[1]) eq 'cite'")
%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/url[text()]")
%test:assertXPath("$result[1]/published[text()]")
(:%test:assertXPath("$result[1]/uid[text()]"):)
(:%test:assertXPath("$result[1]/publication[text()]"):)
(:%test:assertXPath("$result[1]/accessed[text()]"):)
(:%test:assertXPath("$result[1]/content[text()]"):)
%test:assertXPath("$result[1]/author[node()]")
%test:assertXPath("$result[1]/author/card[node()]")
%test:assertXPath("$result[1]/author/card/url[text()]")
%test:assertXPath("$result[1]/author/card/photo[text()]")
%test:assertXPath("$result[1]/author/card/name[not(text())]")


function st:reply-context-example-aaronparecki($node as element()) as element() {
        mf2:dispatch($node)
};



declare

    %test:args('
<div class="h-entry">
				<div class="post-box">
					<div class="content">
						<div>Commented on a <a class="u-in-reply-to" href="http://eschnou.com/entry/testing-indieweb-federation-with-waterpigscouk-aaronpareckicom-and--62-24908.html">post</a> by <a href="http://eschnou.com/">Laurent Eschenauer</a>.</div>
<p></p><blockquote>
	<p>Testing #indieweb federation with @waterpigs.co.uk, @aaronparecki.com and @indiewebcamp.com !</p>
</blockquote><p></p>

<p>Just implemented the ability to send <a href="http://webmention.org">WebMentions</a>/Pingback and added relevant microformats. A little late to the party but here goes...</p>

<p><span class="deem">#</span><a class="p-category" href="http://www.sandeep.io/indieweb/" rel="tag">indieweb</a></p>
					</div>
					<div class="p-name p-summary e-content" style="display:none">Just implemented the ability to send [WebMentions](http://webmention.org)/Pingback and added relevant microformats. A little late to the party but here goes...

#indieweb</div>
					<div class="post-footer">

						<a class="u-url" title="Permalink" href="http://www.sandeep.io/32"><i class="icon-time"></i> <time class="dt-published" datetime="2013-06-04T12:01:04+00:00">4 Jun 2013</time></a>

						<a title="Comments" href="http://www.sandeep.io/32#comments"><i class="icon-comment-alt"></i> 0 Comments</a>
						<a title="Likes" href="http://www.sandeep.io/32#likes"><i class="icon-thumbs-up-alt"></i> 0 Likes</a>
						<a title="Shares" href="http://www.sandeep.io/32#reposts"><i class="icon-retweet"></i> 0 Reposts</a>
						<a title="Mentions" href="http://www.sandeep.io/32#mentions"><i class="icon-hand-right"></i> 0 Mentions</a>

					</div>
				</div>
			</div>
')

%test:name("entry [REPLY CONTEXT: Sandeep Shetty] ) in-reply-to ")
%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name($result[1]) eq 'entry'")
%test:assertXPath("$result[1]/category[text()]")
%test:assertXPath("$result[1]/in-reply-to[text()]")
(::)
%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/summary[text()]")
%test:assertXPath("$result[1]/content[node()]")
%test:assertXPath("$result[1]/url[text()]")
%test:assertXPath("$result[1]/published[text()]")
%test:assertXPath("$result[1]/category[text()]")


function st:reply-context-example-Sandeep-Shetty($node as element()) as element() {
        mf2:dispatch($node)
};



declare
    %test:args('
<div class="h-entry">
				<div class="post-box">
					<div class="content">
						<div>Commented on a <a class="u-in-reply-to" href="http://eschnou.com/entry/testing-indieweb-federation-with-waterpigscouk-aaronpareckicom-and--62-24908.html">post</a> by <a href="http://eschnou.com/">Laurent Eschenauer</a>.</div>
<p></p><blockquote>
	<p>Testing #indieweb federation with @waterpigs.co.uk, @aaronparecki.com and @indiewebcamp.com !</p>
</blockquote><p></p>

<p>Just implemented the ability to send <a href="http://webmention.org">WebMentions</a>/Pingback and added relevant microformats. A little late to the party but here goes...</p>

<p><span class="deem">#</span><a class="p-category" href="http://www.sandeep.io/indieweb/" rel="tag">indieweb</a></p>
					</div>
					<div class="p-name p-summary e-content" style="display:none">Just implemented the ability to send [WebMentions](http://webmention.org)/Pingback and added relevant microformats. A little late to the party but here goes...

#indieweb</div>
					<div class="post-footer">

						<a class="u-url" title="Permalink" href="http://www.sandeep.io/32"><i class="icon-time"></i> <time class="dt-published" datetime="2013-06-04T12:01:04+00:00">4 Jun 2013</time></a>

						<a title="Comments" href="http://www.sandeep.io/32#comments"><i class="icon-comment-alt"></i> 0 Comments</a>
						<a title="Likes" href="http://www.sandeep.io/32#likes"><i class="icon-thumbs-up-alt"></i> 0 Likes</a>
						<a title="Shares" href="http://www.sandeep.io/32#reposts"><i class="icon-retweet"></i> 0 Reposts</a>
						<a title="Mentions" href="http://www.sandeep.io/32#mentions"><i class="icon-hand-right"></i> 0 Mentions</a>

					</div>
				</div>
			</div>
')
%test:name("entry [REPLY CONTEXT: tantek]  properties: in-reply-to, name, content etc ")
%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name($result[1]) eq 'entry'")
%test:assertXPath("$result[1]/in-reply-to[text()]")

%test:assertXPath("$result[1]/category[text()]")

%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/summary[text()]")
%test:assertXPath("$result[1]/content[node()]")

%test:assertXPath("$result[1]/url[text()]")

%test:assertXPath("$result[1]/published[text()]")


(:%test:assertXPath("$result[1]/name[text()]"):)
(:%test:assertXPath("$result[1]/url[text()]"):)
(:%test:assertXPath("$result[1]/uid[text()]"):)
(:%test:assertXPath("$result[1]/publication[text()]"):)
(:%test:assertXPath("$result[1]/accessed[text()]"):)
(:%test:assertXPath("$result[1]/content[text()]"):)
(:%test:assertXPath("$result[1]/author[text()]"):)
(:%test:assertXPath("$result[1]/author/card/url[text()]"):)
(:%test:assertXPath("$result[1]/author/card/photo[text()]"):)
(:%test:assertXPath("$result[1]/author/card/name[text()]"):)


function st:reply-context-example-tantek($node as element()) as element() {
        mf2:dispatch($node)
};


declare

    %test:args('
<div class="span8 h-entry idno-statusupdates idno-object idno-content">
        <div class="visible-phone">
            <p class="p-author author h-card vcard">
                <a href="http://werd.io/profile/benwerd"><img class="u-logo logo u-photo photo" src="http://werd.io/file/52be39babed7deb701668dd8"/></a>
                <a class="p-name fn u-url url" href="http://werd.io/profile/benwerd">Ben Werdmüller</a>
                <a class="u-url" href="http://werd.io/profile/benwerd"><!-- This is here to force the hand of your MF2 parser --></a>
            </p>
        </div>
                        <div class="reply-text">

                                <p>
                                    <i class="icon-reply"></i> Replied to
                                                                                    <a href="http://bret.io/2013/06/24/t4/" rel="in-reply-to" class="u-in-reply-to">a post on <strong>bret.io</strong></a>:
                                </p>

                                            </div>
                <div class="e-content entry-content">
            <div class="">
    <p class="p-name"><a href="http://werd.io/view/51c8fc19bed7de5e23600fb1" rel="in-reply-to" class="u-in-reply-to">@bret</a> - I saw your reply too late, but would totally be up for a drink on Wednesday if you ll be around?</p>
</div>

        </div>
        <div class="footer">
                            <div class="permalink">
        <p>
            <a class="u-url url" href="http://werd.io/view/51c921fcbed7de745b274ae6" rel="permalink"><time title="2013-06-25T04:52:12+00:00" class="dt-published" datetime="2013-06-25T04:52:12+00:00">11 months ago</time></a>
            <a href="http://werd.io/view/51c921fcbed7de745b274ae6#comments"><i class="icon-comments"></i> 1</a>
            <a href="http://werd.io/view/51c921fcbed7de745b274ae6#comments"></a>
            <a href="http://werd.io/view/51c921fcbed7de745b274ae6#comments"></a>
            <a href="http://werd.io/view/51c921fcbed7de745b274ae6#comments"></a>
                                </p>
    </div>
    <br clear="all"/>

            <div class="annotations">

                <a name="comments"></a>
                                        <div class="idno-annotation row">
            <div class="idno-annotation-image span1 hidden-phone">
                <p>
                    <a href="http://bret.io/about" class="icon-container"><img src="http://www.gravatar.com/avatar/8d8b82740cb7ca994449cccd1dfdef5f?s=96"/></a>
                </p>
            </div>
            <div class="idno-annotation-content span6">

<p>I ll certainly be around, I live here! It would be great to see if any other IWC2013 attendees who are still/live in Portland would be interested in coming as well. Maybe it would be a good chance to test out how well an event announcement works on IndieNews.</p>
                <p><small><a href="http://bret.io/about">Bret Comnes</a>,
                    <a href="http://bret.io/2013/06/24/t6/">Jun 25 2013</a></small></p>
            </div>
                    </div>

            </div>

                    <div class="posse">
                <a name="posse"></a>
                <p>
                    Also on:
                    <a href="https://twitter.com/benwerd/status/349389541083316225" rel="syndication" class="u-syndication twitter">twitter</a>                 </p>
            </div>
                </div>
    </div>
')

%test:assertExists
%test:name("cite [REPLY CONTEXT: Ben Werdmüller ]  ")


%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name($result[1]) eq 'entry'")
%test:assertXPath("$result[1]/author[node()]")
%test:assertXPath("$result[1]/author/card/url[text()]")
%test:assertXPath("$result[1]/author/card/photo[text()]")
%test:assertXPath("$result[1]/author/card/logo[text()]")
%test:assertXPath("$result[1]/author/card/name[text()]")
%test:assertXPath("$result[1]/in-reply-to[text()]")
%test:assertXPath("$result[1]/syndication[text()]")
%test:assertXPath("$result[1]/content[node()]")
%test:assertXPath("$result[1]/url[text()]")
%test:assertXPath("$result[1]/published[text()]")

function st:reply-context-example-werd($node as element()) as element() {
        mf2:dispatch($node)
};


declare
    %test:args('
<article class="note h-entry row">
	<header class="span2">
	<p class="muted">
		<time class="dt-published" datetime="2013-06-24T20:30:00-07:00">24 Jun 2013</time></p>

	</header>
<section class="span8">
<p class="muted"><small><i class="icon-share-alt muted"></i> Replied to <a class="u-in-reply-to muted" href="http://werd.io/view/51c8fc19bed7de5e23600fb1">a post on werd.io</a>:</small></p>

<div class="e-content p-summary p-name">

<p>I already ate, but let me know if you end up somewhere this evening or want to meet up tomorrow for some food/drink.</p>


</div>

<p> Mentions:</p>
<ul class="webmentions links" id="http://bret.io/2013/06/24/t4/">


<li><img src="undefined" width="48"/>http://indiewebcamp.com/User:Bret.io<a href="http://indiewebcamp.com/User:Bret.io">2013-07-20T02:04:55+00:00</a></li><li><img src="undefined" width="48"/>http://werd.io/view/51c921fcbed7de745b274ae6<a href="http://werd.io/view/51c921fcbed7de745b274ae6">2013-06-24T21:52:13+00:00</a></li></ul>


</section>

<footer class="span2">
	<div class="h-card p-author">
	<p><img src="http://www.gravatar.com/avatar/8d8b82740cb7ca994449cccd1dfdef5f?s=96" class="img-circle u-photo" alt="A picture of me!"/></p>
	<p><a class="p-name fn muted" href="http://bret.io">Bret Comnes</a></p>
	<p><a class="u-url url muted" href="http://bret.io">bret.io<!-- This is here to force the hand of your MF2 parser --></a></p>
	</div>
</footer>

</article>
')
%test:name("entry with [REPLY CONTEXT: Bret-Comnes] simple in-reply-to ) ")
%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name( $result[1] ) eq  'entry'")

%test:assertXPath("$result[1]/published[text()]")

%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/content[node()]")
%test:assertXPath("$result[1]/summary[node()]")

%test:assertXPath("$result[1]/photo[text()]")

%test:assertXPath("$result[1]/url[text()]")
%test:assertXPath("$result[1]/in-reply-to[text()]")

%test:assertXPath("$result[1]/author/card/url[text()]")
%test:assertXPath("$result[1]/author/card/photo[text()]")
%test:assertXPath("$result[1]/author/card/name[text()]")


function st:reply-context-example-Bret-Comnes($node as element()) as element() {
        mf2:dispatch($node)
};




declare
    %test:name("cite [REPLY CONTEXT: Barry Frost]  properties: in-reply-to, url, photo,author embeded card (  photo, url and name  ) ")
    %test:args('
<div class="h-entry">
    <div style="display: none;">
	<div class="h-card p-author author media">
	    <a class="pull-left" href="#">
		<img src="http://barryfrost.com/barryfrost.jpg" alt="Barry Frost" class="u-photo media-object" />
	    </a>
	    <div class="media-body">
		<h4 class="media-heading">
		    <a rel="author" class="p-name fn" href="http://barryfrost.com/">Barry Frost</a>
		</h4>
		<a href="http://barryfrost.com/" class="u-url">barryfrost.com</a>
	    </div>
	</div>
    </div>
    <article class="post" id="post_4">
	<div class="panel panel-default">
	    <div class="reply-context panel-heading">
	    <i class="icon-comment"></i>Commented on
	    <a class="u-url u-in-reply-to" rel="in-reply-to" href="https://twitter.com/barryf/status/374578078619820032">https://twitter.com/barryf/status/374578078619820032</a>
	    <div class="media">
		<a class="pull-left" href="https://twitter.com/barryf">
		    <img class="media-object img-rounded" src="http://si0.twimg.com/profile_images/1315177813/2010a_normal.jpg" alt="Barry Frost (@barryf)" />
		</a>
		<div class="media-body">
		    <h4 class="media-heading">
			<a href="https://twitter.com/barryf">Barry Frost (@barryf)</a>
		    </h4>
		    <p>Splendid afternoon tea at Great Fosters with
		    <a href="https://twitter.com/larrylou100">@larrylou100</a>(and wasps)
		    <a href="http://t.co/JJmFAQrrYX">http://t.co/JJmFAQrrYX</a>
		    <a href="http://t.co/Spq8HBqmKU">http://t.co/Spq8HBqmKU</a></p>
		</div>
	    </div></div>
	    <div class="panel-body">
		<div class="p-summary summary"></div>
		<div class="p-name e-content">
		    <p>Those sandwiches look tasty.</p>
		</div>
	    </div>
	</div>
    </article>
</div>
')

%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name( $result[1] ) eq  'entry'")

%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/content[node()]")
%test:assertXPath("$result[1]/url[text()]")
%test:assertXPath("$result[1]/in-reply-to[text()]")
%test:assertXPath("$result[1]/photo[text()]")

%test:assertXPath("$result[1]/author/card/url[text()]")
%test:assertXPath("$result[1]/author/card/photo[text()]")
%test:assertXPath("$result[1]/author/card/name[text()]")


function st:reply-context-example-Barry-Frost($node as element()) as element() {
        mf2:dispatch($node)
};

declare
%test:args('
<article id="main-piece" class="main-piece h-entry h-as-note col-all">
    <section class="reply-context col-main">In reply to:
    <ul>
	<li><a class="u-in-reply-to h-cite" href="https://twitter.com/craigmod/status/428681469402169344">https://twitter.com/craigmod/status/428681469402169344</a></li>
    </ul>
    </section><header class="p-author h-card col-auxsmall"><img class="u-photo" src="/static/images/avatar.jpg" alt="Kartik Prabhu" height="50px" width="50px"/><a class="p-name u-url" href="/about#me">Kartik Prabhu</a>
    </header>
    <main id="main-content" class="p-name e-content col-main">Disappearing NY bookstores seem to be getting some attention. @craigmod ref: <a rel="nofollow" href="http://nyti.ms/1fZmbem">http://nyti.ms/1fZmbem</a></main>
    <footer role="contentinfo" class="contentinfo col-main line-border-bottom">
	<time class="dt-published" datetime="2014-04-04T08:44:59-05:00" data-icon="🔗"><a class="u-url" href="/notes/disappearing-ny-book">04 April, 2014</a></time>
    </footer>
 </article>
')

%test:name("entry [REPLY CONTEXT: Kartik Prabhu] properties: in-reply-to emdeded cite ( name, url) author emeded card  ")



%test:assertExists
%test:assertXPath("count($result) = 1")
%test:assertXPath("local-name( $result[1] ) eq  'entry'")
%test:assertXPath("$result[1]/in-reply-to[node()]")
%test:assertXPath("$result[1]/in-reply-to/cite[node()]")
%test:assertXPath("$result[1]/in-reply-to/cite/name[text()]")
%test:assertXPath("$result[1]/in-reply-to/cite/url[text()]")
%test:assertXPath("$result[1]/name[text()]")
%test:assertXPath("$result[1]/url[text()]")

%test:assertXPath("$result[1]/content[node()]")
%test:assertXPath("$result[1]/published[text()]")
%test:assertXPath("$result[1]/url[text()]")
(:%test:assertXPath("$result[1]/author[text()]"):)
%test:assertXPath("$result[1]/author/card/url[text()]")
%test:assertXPath("$result[1]/author/card/photo[text()]")
%test:assertXPath("$result[1]/author/card/name[text()]")


function st:reply-context-example-Kartik-Prabhu($node as element()) as element() {
        mf2:dispatch($node)
};
