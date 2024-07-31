<?php
#Start session
if(!isset($_SESSION)) session_start();

if(!defined('PreDB')) {

    #Identify the call
    define('PreDB', TRUE);

    #Required files
    require_once "../../include/precheck.php";

}

#Redirect if not authenticated or grabbing page directly
if (!is_auth() || !isset($_SERVER['HTTP_X_REQUESTED_WITH']) || $_SERVER['HTTP_X_REQUESTED_WITH'] != 'XMLHttpRequest') {header('Location: https://PRE_SERVER_URL/mobile/index.php'); exit();}

#If this is a notify request output notify
if (isset($_GET['do_notify']) && $_GET['do_notify'] === "1") { get_notify(); exit(); }

function make_panel() {
    $buttons = array(
        "Logout" => array(
            "icon" => "delete",
            "url" => "javascript:logout()"
        ),
        "About" => array(
            "icon" => "info",
            "url" => "#about"
        )
    );
    $panel = '<div data-role="panel" id="settings" data-theme="a"><ul data-role="listview" data-theme="a"><li>Logged in as: '.$_SESSION["username"].'</li><li><div class="ui-grid-a"><div class="ui-block-a"><br><label for="autologin">Auto Login</label></div><div class="ui-block-b"><select name="autologin" id="autologin" data-role="slider"><option value="off">Off</option><option value="on">On</option></select></div></div></li>';
    foreach ($buttons as $button => $data) {
        if ($data["url"] == "close") {
            $url = '#" data-rel="close';
        } else {
            $url = $data["url"];
        }
        $panel .= '<li data-icon="'.$data["icon"].'"><a href="'.$url.'">'.$button.'</a></li>';
    }
    $panel .= '</ul></div>';
    return $panel;
}
?>

<script src="js/main.js.php"></script>

<!-- Start of search page -->
<div data-role="page" id="start">

	<div data-role="header">
        <a data-icon="gear" data-iconpos="notext" href="#settings"></a>
        <h3 class="center">PreDB DB</h3>
        <a data-icon="bars" data-iconpos="notext" href="#options"></a>
	</div>

	<div data-role="content">
        <p class="center">Search the database by entering your search query below</p><br>
        <form id="presearch" action="javascript:get()" method="post">
            <input type="search" name="search" id="search" value="" />
            <input type="submit" value="Submit">
        </form>
        <br><p class="center" id="new"></p>
	</div>

    <?php echo make_panel(); ?>

    <div data-role="panel" id="options" data-theme="a" data-position="right">
            <form id="triggers" action="javascript:get()" method="post">
                <select data-mini="true" id="section" name="section">
                    <option value="">Section</option>
                    <option value="0DAY">0DAY</option>
                    <option value="ANIME">ANIME</option>
                    <option value="APPS">APPS</option>
                    <option value="BD">BD</option>
                    <option value="COVERS">COVERS</option>
                    <option value="DOX">DOX</option>
                    <option value="GAMES">GAMES</option>
                    <option value="GBA">GBA</option>
                    <option value="GC">GC</option>
                    <option value="HDDVD">HDDVD</option>
                    <option value="MOVIE">MOVIE</option>
                    <option value="MOVIE-DIVX">MOVIE-DIVX</option>
                    <option value="MOVIE-DVDR">MOVIE-DVDR</option>
                    <option value="MOVIE-SVCD">MOVIE-SVCD</option>
                    <option value="MOVIE-VCD">MOVIE-VCD</option>
                    <option value="MOVIE-X264">MOVIE-X264</option>
                    <option value="MOVIE-XVID">MOVIE-XVID</option>
                    <option value="MP3">MP3</option>
                    <option value="MV">MV</option>
                    <option value="MV-DVDR">MV-DVDR</option>
                    <option value="NDS">NDS</option>
                    <option value="NULL">NULL</option>
                    <option value="PDA">PDA</option>
                    <option value="PS2">PS2</option>
                    <option value="PS3">PS3</option>
                    <option value="PSP">PSP</option>
                    <option value="TRAILER">TRAILER</option>
                    <option value="TV">TV</option>
                    <option value="TV-DVDR">TV-DVDR</option>
                    <option value="TV-X264">TV-X264</option>
                    <option value="TV-XVID">TV-XVID</option>
                    <option value="WII">WII</option>
                    <option value="X360">X360</option>
                    <option value="XBOX">XBOX</option>
                    <option value="XXX">XXX</option>
                </select>
                <select data-mini="true" id="genre" name="genre">
                    <option value="">Genre</option>
                    <option value="Acoustic">Acoustic</option>
                    <option value="Alternative">Alternative</option>
                    <option value="Ambient">Ambient</option>
                    <option value="Avantgarde">Avantgarde</option>
                    <option value="Bass">Bass</option>
                    <option value="Beat">Beat</option>
                    <option value="Blues">Blues</option>
                    <option value="Classical">Classical</option>
                    <option value="Club">Club</option>
                    <option value="Comedy">Comedy</option>
                    <option value="Country">Country</option>
                    <option value="Dance">Dance</option>
                    <option value="Drum">Drum</option>
                    <option value="Drum_&_Bass">Drum_&_Bass</option>
                    <option value="Electronic">Electronic</option>
                    <option value="Ethnic">Ethnic</option>
                    <option value="Folk">Folk</option>
                    <option value="Gothic">Gothic</option>
                    <option value="Hard_Rock">Hard_Rock</option>
                    <option value="Hardcore">Hardcore</option>
                    <option value="House">House</option>
                    <option value="Indie">Indie</option>
                    <option value="Industrial">Industrial</option>
                    <option value="Funk">Funk</option>
                    <option value="Instrumental">Instrumental</option>
                    <option value="Jazz">Jazz</option>
                    <option value="Latin">Latin</option>
                    <option value="Lo-Fi">Lo-Fi</option>
                    <option value="Metal">Metal</option>
                    <option value="Oldies">Oldies</option>
                    <option value="Pop">Pop</option>
                    <option value="Psychadelic">Psychadelic</option>
                    <option value="Punk">Punk</option>
                    <option value="R&B">R&B</option>
                    <option value="Rap">Rap</option>
                    <option value="Reggae">Reggae</option>
                    <option value="Rock">Rock</option>
                    <option value="Soul">Soul</option>
                    <option value="Soundtrack">Soundtrack</option>
                    <option value="Techno">Techno</option>
                    <option value="Top">Top</option>
                    <option value="Trance">Trance</option>
                    <option value="Various">Various</option>
                </select>
                <fieldset data-role="controlgroup">
                    <label for="exact">Exact Mode</label>
                    <input data-mini="true" id="exact" name="exact" type="checkbox" />
                    <label for="lfilter">English Only</label>
                    <input data-mini="true" id="lfilter" name="lfilter" type="checkbox" />
                    <label for="cfilter">No Crap Filter</label>
                    <input data-mini="true" id="cfilter" name="cfilter" type="checkbox" />
                    <label for="opposite">Opposite Sort</label>
                    <input data-mini="true" name="opposite" id="opposite" type="checkbox" />
                    <label for="nonly">NFO Only</label>
                    <input data-mini="true" id="nonly" name="nonly" type="checkbox" />
                    <label for="jonly">JPG Only</label>
                    <input data-mini="true" id="jonly" name="jonly" type="checkbox" />
                    <label for="nonuke">No Nukes</label>
                    <input data-mini="true" id="nonuke" name="nonuke" type="checkbox" />
                    <label for="blocked">Blocked</label>
                    <input data-mini="true" id="blocked" name="blocked" type="checkbox" />
                    <label for="case">Case Sensitive</label>
                    <input data-mini="true" id="case" name="case" type="checkbox" />
                    <label for="nonfo">No NFO Only</label>
                    <input data-mini="true" id="nonfo" name="nonfo" type="checkbox" />
                    <label for="nojpg">No JPG Only</label>
                    <input data-mini="true" id="nojpg" name="nojpg" type="checkbox" />
                    <label for="nukeonly">Nukes Only</label>
                    <input data-mini="true" id="nukeonly" name="nukeonly" type="checkbox" />
                </fieldset>
                <div class="ui-grid-a">
                    <div class="ui-block-a" style="padding-right:5px">
                        <input data-mini="true" placeholder="Exclusion" id="exclude" name="exclude" type="text" />
                    </div>
                    <div class="ui-block-b" style="padding-left:5px">
                        <input data-mini="true" placeholder="Group Name" id="group" name="group" type="text" />
                    </div>
                </div>
                <input data-mini="true" data-theme="a" type="submit" value="Submit" />
            </form>
    </div>
</div>

<!-- Start of results page -->
<div data-role="page" id="results">

	<div data-role="header">
        <a href="#start" data-icon="back">Back</a>
        <h3>Results</h3>
	</div>

	<div data-role="content" id="post_results">
	</div>
</div>

<!-- Start of about page -->
<div data-role="page" id="about">

    <div data-role="header">
        <a href="#start" data-icon="back">Back</a>
        <h3>About</h3>
    </div>

    <div data-role="content">
        <div data-role="collapsible-set" data-content-theme="a">
            <div data-role="collapsible" data-collapsed="false">
                <h3>Background</h3>
                <p>This began as a project to develop a webapp in order to explore iOS specific design. During the process I learned quickly how heavily dependent the project was on javascript and CSS. I soon discovered the real application was on the desktop and struggled to make both sites as one. Clearly, that is no longer. The mobile site (found in /mobile) is just that now while this is the desktop variant. During the creation of this site one goal was left in mind, simplicity. Combined with a desire to create animations I set forward and created this site in two days. Once I discovered jQuery everything changed. By discover, I more so mean adopt. I was reluctant to add jQuery on the mobile site to keep it small however now being on a desktop coupled with the fact the Google hosts the script on its CDN made it a no brainer.</p>
            </div>
            <div data-role="collapsible">
                <h3>Version History</h3>
                <p>Release 4.1</p><ul><li>Fixed onload events including resolving rememeber me issues</li><li>Fixed section searchs</li></ul>
                <p>Release 4.0</p><ul><li>Complete redesign of the entire mobile site</li></ul>
                <p>Release 3.1</p><ul><li>Redesigned the results layout. Now results are spit out using tables and additional rows are appended to the same table. Additionally if the window is sized below 760px the table will reflow into a list using some CSS3 hackery. This is used for iPhones and other mobile devices.</li></ul>
                <p>Release 3.0</p><ul><li>Added wide screen device support with sidebar access</li><li>Sidebar is scrollable just like the content and is dynamically used depending on the current page</li><li>Squashed some bugs with favorites mainly fixed the inability to delete on iOS</li><li>Now updates start at value on sidebar when present</li><li>Fixed bug where more results would not display</li><li>Imports notifies from IRC if your username matches your nick and lists them on the favorites</li></ul>
                <p>Release 2.5</p><ul><li>iPhone application support discontinued in favor of webapp</li><li>Scrolling is now much improved due to iOS5 CSS support. Users on iOS4 and below (also android) will need to use two-finger scrolling to scroll content</li><li>Support for iPad now complete</li><li>Now detects and respondes to device rotation properly</li><li>Fixed bug with favorites preventing scrolling of content (temporarly disabled slideup effect until Apple releases iOS 5.1)</li><li>Removed bubble popup to optimize webapp size</li><li>Removed SSL links since they are no longer needed on iOS5</li><li>Disabled cache manifest due to authenitcation issues and will enable once bugs are resolved</li><li>Fixed a bug where Google Chrome would not recognize a lack of favorites</li><li>Sorted sections alphabetically</li><li>Reduced CSS filesize from 28KB to 9KB and trimmed other files down to improve load times significantly in the absence of a cache manifest</li><li>Fixed bug where loading box was not centered. Should be centered on all devices now</li></ul>
                <p>Release 2.4</p><ul><li>Enabled UUID authentication for iPhone application</li><li>Now shows nuke reason and changes release name to red to indicate a nuked release</li></ul>
                <p>Release 2.3</p><ul><li>Fixed some auto login errors</li></ul>
                <p>Release 2.2</p><ul><li>Fixed NFO/JPG viewer on iPhone</li><li>Fixed a lot of the bouncing issues on the iPhone scrolling area (note: sometimes the page will bounce intially this is due to Safari's webview nature and will stop as soon as the javascript kicks in)</li></ul>
                <p>Release 2.1</p><ul><li>Complete overhaul of the favorites system. Now brings up panel with options. Old favorites are automatically imported into the new system</li><li>Added slide up effect on favorites</li><li>Fixed minor UI issues such as loading wheel not being centered on more results</li><li>Fixed a bug displaying query time</li><li>Fixed header on all pages now and only content will scroll. Should be supported on all browsers and mobile devices</li><li>Apache will now gzip compress all files being sent to save time/bandwidth</li><li>Firefox support has been reestablished</li></ul>
                <p>Release 2.0</p><ul><li>Complete overhaul using full AJAX support no links should cause the browser to load from start</li><li>Redid authentication system by dropping cookie support completely</li><li>Redid presearch duration now more accurate information is shown</li><li>Resolved PHP warning about global variables</li><li>Fixed keyboard not hiding on iPhone after submit</li><li>Minor bug fixes</li></ul>
                <p>Release 1.6</p><ul><li>NFO/JPG now properly hyperlinked and show up using AJAX/DOM with back button to results instantly</li><li>Properly added caching to iPhone webapp using cache manifest</li><li>Added caching for browsers using Apache</li></ul>
                <p>Release 1.5</p><ul><li>Added favorites</li><li>iPhone support for favorites added</li><li>Changed next to get more results for in page addition</li><li>Sorted favorites</li><li>Fixed delete button for iPhone</li><li>Enabled slide to delete at anytime for iPhone</li><li>Switched to SSL and added CA link on index</li><li>Added icon for homepage to webapp and bubble popup to remind users to install</li></ul>
                <p>Release 1.4</p><ul><li>Added iPhone splash screen</li><li>Added loading screen while query is found</li><li>Added 'Rememeber Me' option during login</li></ul>
                <p>Release 1.3</p><ul><li>Overhaul of authentication now properly does sessions</li><li>iPhone will now properly retain session information</li></ul>
                <p>Release 1.2</p><ul><li>Added start and end selection</li><li>Added Next and Prev buttons in results (not yet working)</li><li>Support for Firefox now complete</li><li>Support for IE and other non webkit browsers</li></ul>
                <p>Release 1.1</p><ul><li>Activated all triggers via form</li><li>Fixed loop when no results found</li><li>Added submit button at the bottom</li></ul>
                <p>Release 1.0</p><ul><li>WebkitUI</li><li>All fields now show correctly</li><li>Minor speed improvements</li></ul>
                <p>Beta 1</p><ul><li>Now supports multiple users</li><li>Added login requirement</li><li>Internal optimizations</li></ul>
                <p>Alpha 2</p><ul><li>Major speed up</li></ul>
                <p>Alpha 1</p><ul><li>First Release</li></ul>
            </div>
            <div data-role="collapsible">
                <h3>Feedback</h3>
                <form id="feedbacka" action="javascript:submit_feedback()" method="post">
                    <label for="feedbacki">Feedback:</label>
                    <textarea name="feedback" placeholder="Enter feedback here..." id="feedbacki"></textarea>
                    <input type="submit" value="Submit" />
                </form>
            </div>
        </div>
    </div>
</div>

<div data-role="dialog" id="nfo">
    <div data-role="header">
        <h1>Viewer</h1>
    </div>
    <div data-role="content" data-theme="a">
    </div>
</div>
