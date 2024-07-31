<?php

#Start session
if(!isset($_SESSION)) session_start();

#Identify the call
define('PreDB', TRUE);

#Required scripts
require_once "../include/precheck.php";

#If not an AJAX request deny it
if (!isset($_SERVER['HTTP_X_REQUESTED_WITH']) || ($_SERVER['HTTP_X_REQUESTED_WITH'] != 'XMLHttpRequest')) { header("HTTP/1.0 401 Authorization Required"); echo $denied; exit(); }

#Check if authenticated if not redirect
if (!is_auth()) {header('Location: https://PRE_SERVER_URL/index.php'); exit();}

#Check headers
caching_headers($_SERVER['SCRIPT_FILENAME'], filemtime($_SERVER['SCRIPT_FILENAME']));
?>
<script type="text/javascript">
<?php
#Echo token so browser can cache it for automatic logins
if (isset($_SESSION['token'])) { echo "	localStorage.setItem('token', '".$_SESSION['token']."');\n"; unset($_SESSION['token']);}
?>
	$.getScript('js/after.js');
</script>
<div id="title">PreDB Search</div>
<p>Search the database by entering your search query and choosing your options below</p>
<div id="switches">
	<form id="presearch" action="javascript:get()" method="post">
		<input id="search" placeholder="Enter search query" name="search" type="text" maxlength=255>
		<span class="nobr">Exact Mode<input id="exact" name="exact" type="checkbox"></span>
		<span class="nobr">English Only<input id="lfilter" name="lfilter" type="checkbox"></span>
		<span class="nobr">No Crap Filter<input id="cfilter" name="cfilter" type="checkbox"></span>
		<span class="nobr">NFO Only<input id="nonly" name="nonly" type="checkbox"></span>
		<span class="nobr">JPG Only<input id="jonly" name="jonly" type="checkbox"></span>
		<span class="nobr">No Nukes<input id="nonuke" name="nonuke" type="checkbox"></span>
		<span class="nobr">Case Sensitive<input id="case" name="case" type="checkbox"></span>
		<span class="nobr">Blocked<input id="blocked" name="blocked" type="checkbox"></span>
		<span class="nobr">No NFO Only<input id="nonfo" name="nonfo" type="checkbox"></span>
		<span class="nobr">No JPG Only<input id="nojpg" name="nojpg" type="checkbox"></span>
		<span class="nobr">Nukes Only<input id="nukeonly" name="nukeonly" type="checkbox"></span>
		<span class="nobr">Exclude: <input placeholder="This will be excluded" id="exclude" name="exclude" type="text" maxlength=30></span>
		<span class="nobr">Group: <input placeholder="Group Name" id="group" name="group" type="text" maxlength=30></span>
		<span class="nobr"><select id="section" name="section"><option value="">Section</option><option value="0DAY">0DAY</option><option value="ANIME">ANIME</option><option value="APPS">APPS</option><option value="BD">BD</option><option value="COVERS">COVERS</option><option value="DOX">DOX</option><option value="GAMES">GAMES</option><option value="GBA">GBA</option><option value="GC">GC</option><option value="HDDVD">HDDVD</option><option value="MOVIE">MOVIE</option><option value="MOVIE-DIVX">MOVIE-DIVX</option><option value="MOVIE-DVDR">MOVIE-DVDR</option><option value="MOVIE-SVCD">MOVIE-SVCD</option><option value="MOVIE-VCD">MOVIE-VCD</option><option value="MOVIE-X264">MOVIE-X264</option><option value="MOVIE-XVID">MOVIE-XVID</option><option value="MP3">MP3</option><option value="MV">MV</option><option value="MV-DVDR">MV-DVDR</option><option value="NDS">NDS</option><option value="NULL">NULL</option><option value="PDA">PDA</option><option value="PS2">PS2</option><option value="PS3">PS3</option><option value="PSP">PSP</option><option value="TRAILER">TRAILER</option><option value="TV">TV</option><option value="TV-DVDR">TV-DVDR</option><option value="TV-X264">TV-X264</option><option value="TV-XVID">TV-XVID</option><option value="WII">WII</option><option value="X360">X360</option><option value="XBOX">XBOX</option><option value="XXX">XXX</option></select></span>
		<span class="nobr"><select id="genre" name="genre"><option value="">Genre</option><option value="Acoustic">Acoustic</option><option value="Alternative">Alternative</option><option value="Ambient">Ambient</option><option value="Avantgarde">Avantgarde</option><option value="Bass">Bass</option><option value="Beat">Beat</option><option value="Blues">Blues</option><option value="Classical">Classical</option><option value="Club">Club</option><option value="Comedy">Comedy</option><option value="Country">Country</option><option value="Dance">Dance</option><option value="Drum">Drum</option><option value="Drum_&_Bass">Drum_&_Bass</option><option value="Electronic">Electronic</option><option value="Ethnic">Ethnic</option><option value="Folk">Folk</option><option value="Gothic">Gothic</option><option value="Hard_Rock">Hard_Rock</option><option value="Hardcore">Hardcore</option><option value="House">House</option><option value="Indie">Indie</option><option value="Industrial">Industrial</option><option value="Funk">Funk</option><option value="Instrumental">Instrumental</option><option value="Jazz">Jazz</option><option value="Latin">Latin</option><option value="Lo-Fi">Lo-Fi</option><option value="Metal">Metal</option><option value="Oldies">Oldies</option><option value="Pop">Pop</option><option value="Psychadelic">Psychadelic</option><option value="Punk">Punk</option><option value="R&B">R&B</option><option value="Rap">Rap</option><option value="Reggae">Reggae</option><option value="Rock">Rock</option><option value="Soul">Soul</option><option value="Soundtrack">Soundtrack</option><option value="Techno">Techno</option><option value="Top">Top</option><option value="Trance">Trance</option><option value="Various">Various</option></select></span>
		<input type="submit" style="position: absolute; left: -9999px; width: 1px; height: 1px;">
	</form>
</div>