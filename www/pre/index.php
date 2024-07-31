<?php
#Start session
if(!isset($_SESSION)) session_start();

#Identify the call
define('PreDB', TRUE);

#Required scripts
require_once "../include/precheck.php";

#Check if authenticated and using SSL
is_auth();

#Check if mobile
require_once '../include/mobile_detect.php';
$detect = new Mobile_Detect();
$layout = ($detect->isMobile() ? ($detect->isTablet() ? 'tablet' : 'mobile') : 'desktop');

#Redirect to mobile site
if ($layout != "desktop" && !isset($_REQUEST["noredirect"])) {header('Location: https://PRE_SERVER_URL/mobile/index.php'); exit();}

#Check headers
caching_headers($_SERVER['SCRIPT_FILENAME'], filemtime($_SERVER['SCRIPT_FILENAME']));
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
	<meta name="robots" content="noindex">
	<link href="css/main.css" rel="stylesheet" media="screen" type="text/css">
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js" type="text/javascript"></script>
	<title>PreDB</title>
</head>
<body onload="check_token()">
	<div id="background"></div>
	<div id="loading" class="overlay">Loading...</div>
	<div id="header">
		<div id="title">Welcome</div>
		<form id="login" action="javascript:auth()" method="post">
			Username: <input id="username" placeholder="Login" name="username" type="text" maxlength=30><br><br>
			Password: <input id="password" placeholder="Password" name="password" type="password" maxlength=30><br><br>
			Remember Me: <input id="remember" name="remember" type="checkbox"><br><br>
			<div class="buttons">
				<button id="loginbutton" type="submit"><img src="images/lock.png" alt=""/>Login</button>
			</div>
		</form>
	</div>
	<div id="content">
	</div>
<script src="js/func.js" type="text/javascript"></script>
</body>
</html>
