<?php

#Start session
if(!isset($_SESSION)) session_start();

#Identify the call
define('PreDB', TRUE);

#Source required files
require_once "../../include/precheck.php";

#Check if authenticated
is_auth();
?>
<!DOCTYPE html>
<html>
    <head>
        <title>Login</title>
        <meta name="viewport" content="height=device-height,width=device-width,initial-scale=1.0,minimum-scale=1.0,user-scalable=no">
        <meta content="yes" name="apple-mobile-web-app-capable">
        <meta name="apple-mobile-web-app-title" content="PreDB DB">
        <meta name="apple-mobile-web-app-status-bar-style" content="black">
        <link rel="apple-touch-icon" href="img/icon.png">
        <link rel="stylesheet" href="//code.jquery.com/mobile/1.4.0/jquery.mobile-1.4.0.min.css" />
        <link rel="stylesheet" href="css/main.css?_=183" />
    </head>
    <body style="display:none">
        <div data-role="page" id="begin" data-theme="a">
        </div>

        <div data-role="dialog" id="login" data-theme="a">
                <div data-role="header" data-position="fixed">
                    <h1 class="center">Welcome</h1>
            </div>
            <div data-role="content">
                    <form action="javascript:dologin()" method="post">
                        <fieldset>
                            <label for="username" class="ui-hidden-accessible">Username:</label>
                            <input type="text" name="username" id="username" value="" placeholder="username" data-theme="a" />
                            <label for="password" class="ui-hidden-accessible">Password:</label>
                            <input type="password" name="password" id="password" value="" placeholder="password" data-theme="a" />
                            <label><input type="checkbox" name="remember" id="remember" />Remember Me</label>
                            <button type="submit" data-theme="b">Sign in</button>
                        </fieldset>
                    </form>
                </div>
        </div>
        <script src="//code.jquery.com/jquery-1.10.2.min.js"></script>
        <script src="js/auth.js.php"></script>
        <script src="//code.jquery.com/mobile/1.4.0/jquery.mobile-1.4.0.min.js"></script>
    </body>
</html>
