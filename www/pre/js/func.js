//Set global variables (name describes them)
var killScroll = true;
var pastIntro = false;
var nextOff = true;
//Detect scrolling towards the bottom of the page (infinity rows)
$(window).scroll(function(){
	//If the window is 200 pixels from the bottom then lets get more
	if  ($(window).scrollTop()+200 >= ($(document).height() - ($(window).height()))){
		getnext();
	};
});
//Detect a window resize
$(window).resize(function(){
	init();
	if ($("#about").length) {
		$("#about").css({"margin-top": -($("#about").height() / 2), "margin-left":-($("#about").width() / 2)});
	}
});
//Fade error message in and out
function fadeerror() {
	//Set the height of the parent div so we do not expand it
	$("#error").parent().css("height",$("#error").parent().height());
	$("#error").fadeIn("fast",function(){
		//Delay for 1000 then fadeout
		$(this).delay(1000).fadeOut("fast",function(){
			//Return the height to auto
			$("#error").parent().height("auto");
			//Remove error DIV
			$(this).remove();
		});
	});
};
function init() {
	if ($("#loading").is(":visible")) { return; }
	if (pastIntro == false) {
		$("#header").css({"margin-top":-$("#header").height() / 2 + "px","margin-left":-$("#header").width() / 2 + "px"});
	} else {
		$("#header").css({"margin":"0 0 0 " + -$("#header").width() / 2 + "px"});
	}
};
function supports_local_storage() {
	try { return 'localStorage' in window && window['localStorage'] !== null; } catch(e) { return false; }
};
function beforeauth() {
	if ($("#username").length) $("#username").blur();
	if ($("#password").length) $("#password").blur();
};
function auth() {
	beforeauth();
	//Check if query is missing
	if ($("#username").val() == "" || $("#password").val() == "") {
		$("#title").after("<div id=\"error\">Invalid Login.</div>");
		fadeerror();
		return;
	};
	var parameters = "action=login&username=" + $('#username').val() + "&password=" + $('#password').val() + "&remember=" + $('#remember').is(':checked');
	$.post("search.php",parameters,function(reply){
		if (reply == 0) { 
			$("#title").after("<p id=\"error\">Invalid Login.</p>");
			fadeerror();
		} else if (reply == 1) {
			$("#header").hide();
			$.ajax({
				url: "search.php"
			}).done(function(html){
				$("#header").css("width","48%");
				$("#header").html(html);
				init();
			});
		}
	});
};
function check_token() {
	if (supports_local_storage()) {
		var token = localStorage.getItem("token");
		parameters = "action=checktoken&token=" + token;
		if (typeof(token) !== 'undefined' && token != null && token != "null") {
			$.post("search.php",parameters,function(reply){
				if (reply == 0) {
					$("#header").fadeIn("slow");
					init();
					localStorage.removeItem("token");
				} else if (reply == 1) {
					$.ajax({
						url: "search.php"
					}).done(function(html){
						$("#header").css("width","48%");
						$("#header").html(html);
						init();
					});
				}
			});
		} else {
			$("#header").fadeIn("slow");
			init();
		}
	}
};