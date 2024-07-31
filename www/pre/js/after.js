var oddRow = 0;

$(function(){ 
	$("#content").html("<table class='pretty' id='results'><thead><tr><th>Release</th><th>Age</th><th>Section</th><th>Genre</th><th>Size (MB)</th><th>Files</th><th>NFO</th><th>JPG</th></tr></thead><tbody id='insertresults'></tbody></table>");
	$("#header").before("<div id=\"aboutlink\"><a href=\"javascript:about()\">About</a></div><div id=\"logout\"><a href=\"javascript:logout()\">Logout</a></div>");
	$("#logout").fadeIn("slow");
	$("#aboutlink").fadeIn("slow");
	$("#header").fadeIn("slow");
	submit_ie7();
	chkbor();
	$("#search").focus();
});
//Keyboard shortcuts
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "W") {if (!$(":focus").length) $("#exact").attr("checked", !$("#exact").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "L") {if (!$(":focus").length) $("#lfilter").attr("checked", !$("#lfilter").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "C") {if (!$(":focus").length) $("#cfilter").attr("checked", !$("#cfilter").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "I") {if (!$(":focus").length) $("#nonly").attr("checked", !$("#nonly").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "J") {if (!$(":focus").length) $("#jonly").attr("checked", !$("#jonly").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "N") {if (!$(":focus").length) $("#nonuke").attr("checked", !$("#nonuke").attr("checked")); }});
$(document).bind("keydown", function(e){if (String.fromCharCode(e.keyCode) == "M") {if (!$(":focus").length) getnext(); }});
function chkbor() {
	var top = 0;
	$("#presearch > .nobr").each(function(i){
		if (top < $(this).offset().top) {
			top = $(this).offset().top;
			$(this).css("border",0);
		} else {
			$(this).css("border-left","dotted 1px gray");
		};
	});
}
function submit_ie7(){
    $('#search').keydown(function(e){
        if (e.keyCode == 13) {
            $(this).parents('form').submit();
            return false;
        }
    });
};
//Submits query
function get() {
	//Blur the input to hide the keyboard
	$("#search").blur(); $("#exclude").blur(); $("#group").blur();
	//Check if query is missing
	if ($("#search").val() == "") {
		$("#switches").after("<div id=\"error\">Query Required</div>");
		fadeerror();
		return;
	}
	//Grabs the values of the inputs, removes any empty values, removes trailing &, and appends the chunk number and search action
	var str = $("#presearch").serialize().replace(/[^&]+=\.?(&|$)/g, '').replace(/&$/, '') + "&action=search";
	
	//Hide the canvas
	$("#content").fadeOut("fast");
	$("#header").fadeOut("fast",function(){
		$(this).css({"position":"relative","top":"20px", "margin":"0 0 0 " + -$(this).width() / 2 + "px", "opacity":"0.95"});
	});
	//Show the loading
	$("#loading").fadeIn("fast");
	//Empty results table since this is a new query
	$("#insertresults").empty();
	//Request the rows
	$.getJSON("search.php",str,function(results){
		//Check for no results
		if ($.isEmptyObject(results)) {
			pastIntro = false;
			$("#loading").fadeOut(100, function(){init();});
			$("#header").stop(true,true).css({"position":"absolute","top":"50%"});
			$("#header").fadeIn(800);
			$("#switches").after("<div id=\"error\">No results found</div>");
			fadeerror();
			return;
		}
		inject(results);
		//Fade canvas back in
		$("#loading").fadeOut("fast");
		$("#content").fadeIn("fast");
		$("#header").fadeIn("fast");		
		if ($.browser.msie  && parseInt($.browser.version, 10) === 7) { $("#background").css({"margin-left":$("#header").width() / 2 + "px"}); }
		killScroll = false;
		pastIntro = true;
		nextOff = false;
		//If the document is the same height as the window then grab next set of results to allow scrolling
		if (($(document).height() - ($(window).height())) == 0) getnext();
	});
};

function getnext(){
	//If getnext is disabled return
	if (nextOff) return;
	//If were past the intro AND scrolling is enabled then continue
	if (pastIntro == true && killScroll == false) {
		//Prevent further triggering until we are done
		killScroll = true;
		//Fade the loading screen in
		$("#loading").fadeIn();
		//AJAX request for more rows
		$.getJSON("search.php","next=1&action=search",function(results){
			//If the array is empty then prevent further getnext requests
			if ($.isEmptyObject(results)) { $("#loading").fadeOut("fast"); nextOff = true; killScroll = false; return; }
			inject(results);
			$("#loading").fadeOut("fast");
			//Allow scrolling to fetch more rows again
			killScroll = false;
		});
	}
};
function inject(results) {
	//Cycle through each new row
	$.each(results,function(i,l){
		oddRow ^= true;
		//If NFO or JPG is a string then interpret as URL and display (both results come as a string so we must see if the contents are a number
		if (l[6] != 0) { nfo = "<a class=\"noeffect\" href=\"javascript:loadNfo('nfo','" + l[6] + "')\">Yes</a>"; } else { nfo = "No"; }
		if (l[7] != 0) { jpg = "<a class=\"noeffect\" href=\"javascript:loadNfo('jpg','" + l[7] + "')\">Yes</a>"; } else { jpg = "No"; }			
		//If the nuketime is greater than zero then highlight the row red
		if (parseInt(l[8]) != 0) { nk = "title=\"" + l[9] + "\" style=\"background-color: #9A0000;\"";"" } else { nk = ""; }
		if (oddRow) { or = "class\=\"odd\" "; } else { or = ""; }
		//Insert row
		$("#insertresults").append("<tr " + or + nk + "><td>" + wordwrap(l[0], 20, "<wbr></wbr>", 1) + "</td><td>" + timeSince(l[1]) + "</td><td>" + l[2] + "</td><td>" + l[3] + "</td><td>" + l[4] + "</td><td>" + l[5] + "</td><td>" + nfo + "</td><td>" + jpg + "</td></tr>");
	});
}
function about(){
	$("#loading").fadeIn("fast");
	oldScroll = killScroll; killScroll = true;
	$.get("about.php",function(html){
		$("#header").before("<div id=\"about\" class=\"overlay\">" + html + "</div>");
		$("#about").css({"margin-top": -($("#about").height() / 2), "margin-left":-($("#about").width() / 2)});
		$("#loading").fadeOut("fast");
		$("#about").fadeIn("slow").bind("click touchstart",function(){ event.stopPropagation(); });
		$(document).one("click keydown touchstart", function() {
			$("#about").fadeOut("slow",function(){
				$(this).remove();
				killScroll = oldScroll;
			});
		});
	});
};
function logout(){ 
	localStorage.removeItem('token');
	if ($("#links").length) $("#links").remove();
	if ($("#aboutlink").length) $("#aboutlink").remove();
	$.get("index.php","action=logout",function(){
		location.href = "index.php"; 
	});	
};
function loadNfo(type,url) {
	switch(type) {
		case 'nfo':
			$.slimbox("http://NFO_SERVER_URL/?" + url + "=image")
			break;
		case 'jpg':
			$.slimbox("http://NFO_SERVER_URL/jpgview.php?" + url + "OmltYWdlOjA=");
			break;
	}
};
function timeSince(dateDiff) {
	var t = []; var str = "";
	var suffix = ["y ","w ","d ","h ","m ","s"];
	t.push(Math.floor(dateDiff/(60*60*24*7*52)));
	t.push(Math.floor((dateDiff-(t[0]*60*60*24*7*52))/(60*60*24*7)));
	t.push(Math.floor((dateDiff-(t[0]*60*60*24*7*52)-(t[1]*60*60*24*7))/(60*60*24)));
	t.push(Math.floor((dateDiff-(t[0]*60*60*24*7*52)-(t[1]*60*60*24*7)-(t[2]*60*60*24))/(60*60)));
	t.push(Math.floor((dateDiff-(t[0]*60*60*24*7*52)-(t[1]*60*60*24*7)-(t[2]*60*60*24)-(t[3]*60*60))/60));
	t.push(dateDiff-(t[0]*60*60*24*7*52)-(t[1]*60*60*24*7)-(t[2]*60*60*24)-(t[3]*60*60)-(t[4]*60));
	$.each(t,function(i,l){
		if (l) str = str + l + suffix[i]
	});
	return str
};
function wordwrap( str, width, brk, cut ) { 
    brk = brk || '\n';
    width = width || 75;
    cut = cut || false; 
    if (!str) { return str; }
    var regex = '.{1,' +width+ '}(\\s|$)' + (cut ? '|.{' +width+ '}|.+$' : '|\\S+?(\\s|$)');
    return str.match( RegExp(regex, 'g') ).join( brk ); 
};
/*
*	Slimbox v2.04 - The ultimate lightweight Lightbox clone for jQuery
*	(c) 2007-2010 Christophe Beyls <http://www.digitalia.be>
*	MIT-style license.
*/
(function(w){var E=w(window),u,f,F=-1,n,x,D,v,y,L,r,m=!window.XMLHttpRequest,s=[],l=document.documentElement,k={},t=new Image(),J=new Image(),H,a,g,p,I,d,G,c,A,K;w(function(){w("body").append(w([H=w('<div id="lbOverlay" />')[0],a=w('<div id="lbCenter" />')[0],G=w('<div id="lbBottomContainer" />')[0]]).css("display","none"));g=w('<div id="lbImage" />').appendTo(a).append(p=w('<div style="position: relative;" />').append([I=w('<a id="lbPrevLink" href="#" />').click(B)[0],d=w('<a id="lbNextLink" href="#" />').click(e)[0]])[0])[0];c=w('<div id="lbBottom" />').appendTo(G).append([w('<a id="lbCloseLink" href="#" />').add(H).click(C)[0],A=w('<div id="lbCaption" />')[0],K=w('<div id="lbNumber" />')[0],w('<div style="clear: both;" />')[0]])[0]});w.slimbox=function(O,N,M){u=w.extend({loop:false,overlayOpacity:0.8,overlayFadeDuration:400,resizeDuration:400,resizeEasing:"swing",initialWidth:250,initialHeight:250,imageFadeDuration:400,captionAnimationDuration:400,counterText:"Image {x} of {y}",closeKeys:[27,88,67],previousKeys:[37,80],nextKeys:[39,78]},M);if(typeof O=="string"){O=[[O,N]];N=0}y=E.scrollTop()+(E.height()/2);L=u.initialWidth;r=u.initialHeight;w(a).css({top:Math.max(0,y-(r/2)),width:L,height:r,marginLeft:-L/2}).show();v=m||(H.currentStyle&&(H.currentStyle.position!="fixed"));if(v){H.style.position="absolute"}w(H).css("opacity",u.overlayOpacity).fadeIn(u.overlayFadeDuration);z();j(1);f=O;u.loop=u.loop&&(f.length>1);return b(N)};w.fn.slimbox=function(M,P,O){P=P||function(Q){return[Q.href,Q.title]};O=O||function(){return true};var N=this;return N.unbind("click").click(function(){var S=this,U=0,T,Q=0,R;T=w.grep(N,function(W,V){return O.call(S,W,V)});for(R=T.length;Q<R;++Q){if(T[Q]==S){U=Q}T[Q]=P(T[Q],Q)}return w.slimbox(T,U,M)})};function z(){var N=E.scrollLeft(),M=E.width();w([a,G]).css("left",N+(M/2));if(v){w(H).css({left:N,top:E.scrollTop(),width:M,height:E.height()})}}function j(M){if(M){w("object").add(m?"select":"embed").each(function(O,P){s[O]=[P,P.style.visibility];P.style.visibility="hidden"})}else{w.each(s,function(O,P){P[0].style.visibility=P[1]});s=[]}var N=M?"bind":"unbind";E[N]("scroll resize",z);w(document)[N]("keydown",o)}function o(O){var N=O.keyCode,M=w.inArray;return(M(N,u.closeKeys)>=0)?C():(M(N,u.nextKeys)>=0)?e():(M(N,u.previousKeys)>=0)?B():false}function B(){return b(x)}function e(){return b(D)}function b(M){if(M>=0){F=M;n=f[F][0];x=(F||(u.loop?f.length:0))-1;D=((F+1)%f.length)||(u.loop?0:-1);q();a.className="lbLoading";k=new Image();k.onload=i;k.src=n}return false}function i(){a.className="";w(g).css({backgroundImage:"url("+n+")",visibility:"hidden",display:""});w(p).width(k.width);w([p,I,d]).height(k.height);w(A).html(f[F][1]||"");w(K).html((((f.length>1)&&u.counterText)||"").replace(/{x}/,F+1).replace(/{y}/,f.length));if(x>=0){t.src=f[x][0]}if(D>=0){J.src=f[D][0]}L=g.offsetWidth;r=g.offsetHeight;var M=Math.max(0,y-(r/2));if(a.offsetHeight!=r){w(a).animate({height:r,top:M},u.resizeDuration,u.resizeEasing)}if(a.offsetWidth!=L){w(a).animate({width:L,marginLeft:-L/2},u.resizeDuration,u.resizeEasing)}w(a).queue(function(){w(G).css({width:L,top:M+r,marginLeft:-L/2,visibility:"hidden",display:""});w(g).css({display:"none",visibility:"",opacity:""}).fadeIn(u.imageFadeDuration,h)})}function h(){if(x>=0){w(I).show()}if(D>=0){w(d).show()}w(c).css("marginTop",-c.offsetHeight).animate({marginTop:0},u.captionAnimationDuration);G.style.visibility=""}function q(){k.onload=null;k.src=t.src=J.src=n;w([a,g,c]).stop(true);w([I,d,g,G]).hide()}function C(){if(F>=0){q();F=x=D=-1;w(a).hide();w(H).stop().fadeOut(u.overlayFadeDuration,j)}return false}})(jQuery);
// AUTOLOAD CODE BLOCK (MAY BE CHANGED OR REMOVED)
if (!/android|iphone|ipod|series60|symbian|windows ce|blackberry/i.test(navigator.userAgent)) {
	jQuery(function($) {
		$("a[rel^='lightbox']").slimbox({/* Put custom options here */}, null, function(el) {
			return (this == el) || ((this.rel.length > 8) && (this.rel == el.rel));
		});
	});
}