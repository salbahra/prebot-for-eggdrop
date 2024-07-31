<?php
#Start session
if(!isset($_SESSION)) session_start();

if(!defined('PreDB')) {

    #Tell main we are calling it
    define('PreDB', TRUE);

    #Required files
    require_once "../../../include/precheck.php";
    
    header("Content-type: application/x-javascript");
}

#Kick if not authenticated
if (!is_auth()) {exit();}

#Echo token so browser can cache it for automatic logins
if (isset($_SESSION['sendtoken']) && $_SESSION['sendtoken']) { echo "localStorage.setItem('token', '".$_SESSION['token']."');\n"; $_SESSION['sendtoken'] = false; }
?>
var pastIntro = false;

$(document).on("pagebeforeshow", "#start", function (e) {
    new_item();
});

$(document).on("pageshow", "#start", function(e){
    check_auto($("select[data-role='slider']"));
});

$(document).on("swipeleft", "#start", function(e){
    eventtype = e.type;
    page = $(e.target).closest(".ui-page-active");
    pageid = page.attr("id");
    panel = $("#options");
    otherpanel = $("#settings");

    if (panel.length == 0 || (!otherpanel.hasClass("ui-panel-open") && !otherpanel.hasClass("ui-panel-closed"))) return false;

    panel.panel("open");

});
$(document).on("swiperight", "#start", function(e){
    eventtype = e.type;
    page = $(e.target).closest(".ui-page-active");
    pageid = page.attr("id");
    panel = $("#settings");
    otherpanel = $("#options");

    if (panel.length == 0 || (!otherpanel.hasClass("ui-panel-open") && !otherpanel.hasClass("ui-panel-closed"))) return false;

    panel.panel("open");
});

$(document).on('pageinit', function (e, data) {
    var newpage = e.target.id;

    if (newpage == "start" || newpage == "results" || newpage == "about") {
        currpage = $(e.target);

        currpage.find("a[data-rel=back]").bind('vclick', function (e) {
            e.preventDefault(); e.stopImmediatePropagation();
            highlight(this);
            history.back();
        })
        currpage.find("a[data-rel=close]").bind('vclick', function (e) {
            e.preventDefault(); e.stopImmediatePropagation();
            highlight(this);
            $(".ui-panel-open").panel("close");
        })
        currpage.find("a[href='#settings'], a[href='#options']").bind('vclick', function (e) {
            e.preventDefault(); e.stopImmediatePropagation();
            highlight(this);
            panel = $(this).attr("href");
            $(panel).panel("open");
        });
        currpage.find("a[href^=javascript\\:]").bind('vclick', function (e) {
            e.preventDefault(); e.stopImmediatePropagation();
            var func = $(this).attr("href").split("javascript:")[1];
            highlight(this);
            eval(func);
        });
    }
});

$("select[data-role='slider']").change(function(){
    var slide = $(this);
    var type = this.name;
    var pageid = slide.closest(".ui-page-active").attr("id");
    var changedTo = slide.val();
    if(window.sliders[type]!==changedTo){
        if (changedTo=="on") {
            if (type === "autologin") {
                if (localStorage.getItem("token") != null) return;
                $("#login form").attr("action","javascript:grab_token('"+pageid+"')");
                $("body").pagecontainer("change","#login");
            }
        } else {
            localStorage.removeItem(typeToKey(type));
        }
    }
});

function check_auto(sliders){
    if (typeof(window.sliders) !== "object") window.sliders = [];
    sliders.each(function(i){
        var type = this.name;
        var item = typeToKey(type);
        if (!item) return;
        if (localStorage.getItem(item) != null) {
            window.sliders[type] = "on";
            $(this).val("on").slider("refresh");
        } else {
            window.sliders[type] = "off";
            $(this).val("off").slider("refresh");
        }
    })
}

function typeToKey(type) {
    if (type == "autologin") {
        return "token";            
    } else {
        return false;
    }
}

function grab_token(pageid){
    $.mobile.loading("show");
    var parameters = "action=gettoken&username=" + $('#username').val() + "&password=" + $('#password').val() + "&remember=" + $('#remember').is(':checked');
    if (!$('#remember').is(':checked')) {
        $("#autologin").val("off").slider("refresh");
        window.sliders["autologin"] = "off";
        $("body").pagecontainer("change","#"+pageid);
        return;
    }
    $.post("index.php",parameters,function(reply){
        $.mobile.loading("hide");
        if (reply == 0) {
            showerror("Invalid Login");
            $("body").pagecontainer("change","#"+pageid);
        } else if (reply === "") {
            $("#autologin").val("off").slider("refresh");
            window.sliders["autologin"] = "off";
            $("body").pagecontainer("change","#"+pageid);
        } else {
            localStorage.setItem('token',reply);
            $("body").pagecontainer("change","#"+pageid);
        }
    }, "text");
    $("#login form").attr("action","javascript:dologin()");
}

//Random news
function new_item() {
    var news = [
        "Advanced: Refine your search using the <a href='#options'>advanced settings</a> panel."
    ];
    var i = Math.floor((Math.random()*news.length));
    $("#new").html(news[i]);
}

function highlight(button) {
    $(button).addClass("ui-btn-active").delay(150).queue(function(next){
        $(this).removeClass("ui-btn-active");
        next();
    });
}

function breakrls(str) {
    return str.replace(/(\.|_|-)/g, "<wbr></wbr>$1");
}

function timeSince(dateDiff) {
    var t = [];var str = "";
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
}

function submit_feedback(){
    var data = $("#feedbacka").serialize() + "&action=feedback";
    $("#feedbacka").fadeOut("fast",function(){
        showerror("Thank you!");
        $("#feedbacki").val('');
        setTimeout(function(){$("#feedbacka").fadeIn();}, 1500);
    });
    $.post("index.php", data);
}

function logout(){
    if (confirm('Are you sure you want to logout?')) {
        $.get("index.php","action=logout",function(reply){
            if (reply) {
                location.href = "index.php";
            }
        })
    }
}

function get() {
    //Check if query is missing
    if ($("#search").val() == "") {
            showerror("Search Query Required");
            return;
    }
    $("#search").blur();
    //Since this is a new request remove old results, if any
    $("#post_results").empty();
    $.mobile.loading( 'show' );
    //Grabs the values of the inputs, removes any empty values, removes trailing &, and appends the chunk number and search action
    var str = $("#start :input").serialize().replace(/[^&]+=\.?(&|$)/g, '').replace(/&$/, '') + "&action=search";
    //Send search query to the server
    $.get("search.php",str,function(results){
        //If no results notify the user
        if ($.isEmptyObject(results)) {
                showerror("No Results Found");
                return;
        }
        //Inject results into the DOM
        inject(results);
        //Show results tab on other pages
        //pages = ["#about","#start","#favs"];
        //$.each(pages,function(a,b){
        //    if (!pastIntro) {
        //        $(b + ' a[href="#start"]').after('<a data-role="button" data-theme="a" data-transition="fade" href="#results">Results</a>').trigger('create');
        //        $(b + ' div[data-role="controlgroup"] a').button();
        //        $(b + ' div[data-role="controlgroup"]').controlgroup();
        //    }
        //  });
        //Change globals
        pastIntro = true;
        $.mobile.loading('hide');
        //Finally change the page for the user
        $.mobile.changePage("#results", {transition: "fade"} );
        //Refresh list view
        $("#post_results > ul").listview().listview('refresh');
    }, 'json');
}

//Loads next set of results
function getnext() {
    $.mobile.loading('show')
    $("#getmore").remove();
    $.getJSON("search.php","next=1&action=search",function(results){
        if ($.isEmptyObject(results)) return;
        var posts = ''
        $.each(results,function(i,l){
            posts += list_item(l)
        });
        if (results.length >= 50) posts += "<li onclick='getnext()' id='getmore'>Get More Results</li>"
        $("#post_results > ul").append(posts).listview('refresh')
        $.mobile.loading('hide')
    });	
}

function inject(results) {
    var posts = '<ul data-role="listview" data-divider-theme="d" data-theme="d" data-filter="true" data-split-theme="d" data-split-icon="info">';
    //Iterate through each post/comment and create list element then append it to posts
    $.each(results,function(i,l){
        posts += list_item(l);
    });
    if (results.length >= 50) posts += "<li onclick='getnext()' id='getmore'>Get More Results</li>"
    $(posts + "</ul>").appendTo("#post_results").trigger('create');
}

function list_item(l) {
    var item = "<li data-role='list-divider'>" + breakrls(l[0]) + "</li><li>";
    if (l[6] != 0) item += "<a href=\"javascript:loadNfo('nfo','" + l[6] + "')\">";
    
    item += "<div class='ui-grid-a'><p class='ui-block-a rls-detail'><strong>Age:</strong> " + timeSince(l[1]) + "</p><p class='ui-block-b rls-detail'><strong>Type:</strong> " + l[2] + "</p></div>";
    
    //Letter 'a''
    var letter = 97;
    item += "<div class='ui-grid-a'>"
    if (l[4]) {
        item += "<p class='ui-block-" + String.fromCharCode(letter) + " rls-detail'><strong>Files:</strong> " + l[4] + "</p>"
        letter++
    }
    if (l[5]) {
        item += "<p class='ui-block-" + String.fromCharCode(letter) + " rls-detail'><strong>Size:</strong> " + l[5] + "MB</p>"
    }
    item += "</div>"
    if (l[3] != "") {
        item += "<div class='ui-grid-solo'><p class='ui-block-a rls-detail'><strong>Genre:</strong> " + l[3] + "</p></div>"
        letter++
    }
    if (l[6] != 0) item += "</a>";
    if (l[7] != 0) {item += "<a href=\"javascript:loadNfo('jpg','" + l[6] + "')\">JPG</a>";}

    item += "</li>";
    return item;
}

//Load NFO and JPG into body
function loadNfo(type,url) {
    $.mobile.loading('show')
    var src = ""
    switch(type) {
        case 'nfo':
            src = "http://NFO_SERVER_URL/?" + url + "=image";
            break;
        case 'jpg':
            src = "http://NFO_SERVER_URL/jpgview.php?" + url + "OmltYWdlOjA=";
            break;
    }
    var image = new Image();
    image.onload = function(){
        $.mobile.changePage("#nfo", { role: "dialog"} );
        var maxWidth = $(window).width() * (92.5/100) - 30
        if (maxWidth > image.width) maxWidth = image.width
        $(".ui-dialog-contain").css('max-width', maxWidth+30)
        $("#nfo div[data-role='content']").html(image)
        $("#nfo img").css('max-width', maxWidth)
        $.mobile.loading('hide')
    };
    image.src = src;
};