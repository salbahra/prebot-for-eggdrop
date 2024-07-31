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
?>
$(document).one("mobileinit", function(e){
    $.mobile.defaultPageTransition = 'fade';
    $.mobile.hashListeningEnabled = false;
});
$("#begin").on("pageinit",function(e){
    $("body").show();
});
$("#begin").on("pageshow", function(){
    if (!check_token()) {
        $("body").pagecontainer("change", "#login");
    }
});

(function(){
    var p, l, r = window.devicePixelRatio;
    if (navigator.platform === "iPad") {
        p = r === 2 ? "img/startup-tablet-portrait-retina.png" : "img/startup-tablet-portrait.png";
        l = r === 2 ? "img/startup-tablet-landscape-retina.png" : "img/startup-tablet-landscape.png";
        document.write('<link rel="apple-touch-startup-image" href="'+l+'" media="screen and (orientation: landscape)"><link rel="apple-touch-startup-image" href="'+p+'" media="screen and (orientation: portrait)">');
    } else {
        p = r === 2 ? "img/startup-retina.png": "img/startup.png";
                        if (window.screen.height == 568) p = "img/startup-iphone5-retina.png";
        document.write('<link rel="apple-touch-startup-image" href="'+p+'">');
    }
})()

//Authentication functions
function check_token() {
    var token = localStorage.getItem('token');
    var parameters = "action=checktoken&token=" + token
    if (typeof(token) !== 'undefined' && token != null) {
        $.mobile.loading("show");
        $.post("index.php",parameters,function(reply){
            if (reply == 0) {
                $.mobile.loading("hide");
                localStorage.removeItem('token');
                $("body").pagecontainer("change", "#login");
                return;
            } else {
                $.get("search.php", function(data){
                    $("body").append(data);
                    $("#start").one("pagecreate",function(){
                        $.mobile.loading("hide");
                        $("body").pagecontainer("change", "#start");
                    })
                    $("#start, #results, #about").page();
                });
            }
        }, "html");
    } else {
        return false;
    }
    return true;
}

function dologin() {
    var parameters = "action=login&username=" + $('#username').val() + "&password=" + $('#password').val() + "&remember=" + $('#remember').is(':checked');
    $("#username, #password, #remember").val('');
    $.mobile.loading("show");
    $.post("index.php",parameters,function(reply){
        if (reply == 0) {
            showerror("Invalid Login");
        } else {
            $.get("search.php", function(data){
                $("body").append(data);
                $("#start").one("pagecreate",function(){
                    $.mobile.loading("hide");
                    $("body").pagecontainer("change", "#start");
                })
                $("#start, #results, #about").page();
            });
        }
    }, "html");
}

function showerror(msg) {
	// show error message
        $.mobile.loading( 'show', {
            text: msg,
            textVisible: true,
            textonly: true,
            theme: 'a'
            });
	// hide after delay
	setTimeout( function(){$.mobile.loading('hide')}, 1500);
}