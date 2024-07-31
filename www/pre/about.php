<?php

#Start session
if(!isset($_SESSION)) session_start();

#Identify the call
define('PreDB', TRUE);

#Required scripts
require_once "../include/precheck.php";

#If not an AJAX request deny it
if (!isset($_SERVER['HTTP_X_REQUESTED_WITH']) || ($_SERVER['HTTP_X_REQUESTED_WITH'] != 'XMLHttpRequest')) { header("HTTP/1.0 401 Authorization Required"); echo $denied; exit(); }

#Check headers
caching_headers($_SERVER['SCRIPT_FILENAME'], filemtime($_SERVER['SCRIPT_FILENAME']));

#Check if authenticated if not redirect
if (!is_auth()) {header('Location: https://PRE_SERVER_URL/index.php'); exit();}
?>
<p class="title">About</span>
<div id="abouttext">
	<span class="subtitle">Shortcuts</span>
		<p>Listed below are various keyboard shortcuts available on this site:</p><ul><li>W - Exact Mode</li><li>L - English Only</li><li>C - Crap Filter</li><li>I - NFO Only</li><li>J - JPG Only</li><li>N - No Nukes</li><li>M - More Results</li></ul>
	<span class="subtitle">Background</span>
		<p>This began as a project to develop a webapp in order to explore iOS specific design. During the process I learned quickly how heavily dependent the project was on javascript and CSS. I soon discovered the real application was on the desktop and struggled to make both sites as one. Clearly, that is no longer. The mobile site (found in /mobile) is just that now while this is the desktop variant. During the creation of this site one goal was left in mind, simplicity. Combined with a desire to create animations I set forward and created this site in two days. Once I discovered jQuery everything changed. By discover, I more so mean adopt. I was reluctant to add jQuery on the mobile site to keep it small however now being on a desktop coupled with the fact the Google hosts the script on its CDN made it a no brainer.</p>
	<span class="subtitle">Version History for Desktop</span>
		<p class="version">Release 2.2</p><ul><li>Fixed onload events including resolving rememeber me issues</li><li>Fixed section searchs</li></ul>
		<p class="version">Release 2.1</p><ul><li>Redesigned the header, making it static</li><li>100% compatible with IE7/8 now</li><li>Fixed visual bugs in Opera</li></ul>
		<p class="version">Release 2.0</p><ul><li>Completely rewrote prepared statements and improved query time on average by 800% even on wild card queries</li><li>Changed gradient to a top/bottom orientation</li><li>Added full IE8 support and limited IE7 support</li></ul>
		<p class="version">Release 1.1</p><ul><li>Nuke reasons can now be seen on mouse over of a red/nuked row</li><li>Rewrote backend now using prepared statements to MySQL directly from PHP</li><li>Added error messages for login, empty query, and no results found</li><li>Added keyboard shortcuts</li></ul>
		<p class="version">Release 1.0</p><ul><li>First release</li></ul>
	<span class="subtitle">Version History for Mobile</span>
		<p class="version">Release 4.1</p><ul><li>Fixed onload events including resolving rememeber me issues</li></ul>
		<p class="version">Release 4.0</p><ul><li>Complete redesign of the entire mobile site</li></ul>
		<p class="version">Release 3.1</p><ul><li>Redesigned the results layout. Now results are spit out using tables and additional rows are appended to the same table. Additionally if the window is sized below 760px the table will reflow into a list using some CSS3 hackery. This is used for iPhones and other mobile devices.</li></ul>
		<p class="version">Release 3.0</p><ul><li>Added wide screen device support with sidebar access</li><li>Sidebar is scrollable just like the content and is dynamically used depending on the current page</li><li>Squashed some bugs with favorites mainly fixed the inability to delete on iOS</li><li>Now updates start at value on sidebar when present</li><li>Fixed bug where more results would not display</li><li>Imports notifies from IRC if your username matches your nick and lists them on the favorites</li></ul>
		<p class="version">Release 2.5</p><ul><li>iPhone application support discontinued in favor of webapp</li><li>Scrolling is now much improved due to iOS5 CSS support. Users on iOS4 and below (also android) will need to use two-finger scrolling to scroll content</li><li>Support for iPad now complete</li><li>Now detects and respondes to device rotation properly</li><li>Fixed bug with favorites preventing scrolling of content (temporarly disabled slideup effect until Apple releases iOS 5.1)</li><li>Removed bubble popup to optimize webapp size</li><li>Removed SSL links since they are no longer needed on iOS5</li><li>Disabled cache manifest due to authenitcation issues and will enable once bugs are resolved</li><li>Fixed a bug where Google Chrome would not recognize a lack of favorites</li><li>Sorted sections alphabetically</li><li>Reduced CSS filesize from 28KB to 9KB and trimmed other files down to improve load times significantly in the absence of a cache manifest</li><li>Fixed bug where loading box was not centered. Should be centered on all devices now</li></ul>
		<p class="version">Release 2.4</p><ul><li>Enabled UUID authentication for iPhone application</li><li>Now shows nuke reason and changes release name to red to indicate a nuked release</li></ul>
		<p class="version">Release 2.3</p><ul><li>Fixed some auto login errors</li></ul>
		<p class="version">Release 2.2</p><ul><li>Fixed NFO/JPG viewer on iPhone</li><li>Fixed a lot of the bouncing issues on the iPhone scrolling area (note: sometimes the page will bounce intially this is due to Safari's webview nature and will stop as soon as the javascript kicks in)</li></ul>
		<p class="version">Release 2.1</p><ul><li>Complete overhaul of the favorites system. Now brings up panel with options. Old favorites are automatically imported into the new system</li><li>Added slide up effect on favorites</li><li>Fixed minor UI issues such as loading wheel not being centered on more results</li><li>Fixed a bug displaying query time</li><li>Fixed header on all pages now and only content will scroll. Should be supported on all browsers and mobile devices</li><li>Apache will now gzip compress all files being sent to save time/bandwidth</li><li>Firefox support has been reestablished</li></ul>
		<p class="version">Release 2.0</p><ul><li>Complete overhaul using full AJAX support no links should cause the browser to load from start</li><li>Redid authentication system by dropping cookie support completely</li><li>Redid presearch duration now more accurate information is shown</li><li>Resolved PHP warning about global variables</li><li>Fixed keyboard not hiding on iPhone after submit</li><li>Minor bug fixes</li></ul>
		<p class="version">Release 1.6</p><ul><li>NFO/JPG now properly hyperlinked and show up using AJAX/DOM with back button to results instantly</li><li>Properly added caching to iPhone webapp using cache manifest</li><li>Added caching for browsers using Apache</li></ul>
		<p class="version">Release 1.5</p><ul><li>Added favorites</li><li>iPhone support for favorites added</li><li>Changed next to get more results for in page addition</li><li>Sorted favorites</li><li>Fixed delete button for iPhone</li><li>Enabled slide to delete at anytime for iPhone</li><li>Switched to SSL and added CA link on index</li><li>Added icon for homepage to webapp and bubble popup to remind users to install</li></ul>
		<p class="version">Release 1.4</p><ul><li>Added iPhone splash screen</li><li>Added loading screen while query is found</li><li>Added 'Rememeber Me' option during login</li></ul>
		<p class="version">Release 1.3</p><ul><li>Overhaul of authentication now properly does sessions</li><li>iPhone will now properly retain session information</li></ul>
		<p class="version">Release 1.2</p><ul><li>Added start and end selection</li><li>Added Next and Prev buttons in results (not yet working)</li><li>Support for Firefox now complete</li><li>Support for IE and other non webkit browsers</li></ul>
		<p class="version">Release 1.1</p><ul><li>Activated all triggers via form</li><li>Fixed loop when no results found</li><li>Added submit button at the bottom</li></ul>
		<p class="version">Release 1.0</p><ul><li>WebkitUI</li><li>All fields now show correctly</li><li>Minor speed improvements</li></ul>
		<p class="version">Beta 1</p><ul><li>Now supports multiple users</li><li>Added login requirement</li><li>Internal optimizations</li></ul>
		<p class="version">Alpha 2</p><ul><li>Major speed up</li></ul>
		<p class="version">Alpha 1</p><ul><li>First Release</li></ul>
</div>