<?php

#Start session
if(!isset($_SESSION)) session_start();

date_default_timezone_set('UTC');

#Set denied message
$denied = "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\"><html><head><title>401 Authorization Required</title></head><body><h1>Authorization Required</h1><p>This server could not verify that you are authorized to access the document requested.  Either you supplied the wrong credentials (e.g., bad password), or your browser doesn't understand how to supply the credentials required.</p><hr><address>Apache Server</address></body></html>";

#Set filters
$lfilters = "\[.\]sk\[-\]|\[-\]sp\[-\]|\[-\]de\[-\]|\[-\]jp\[-\]|\[-\]nl\[-\]|\[-\]es\[-\]|\[-\]pt\[-\]|\[-\]gr\[-\]|\[-\]fi\[-\]|\[-\]cn\[-\]|\[-\]se\[-\]|flemish|valencian|vietnamese|slovenian|nordic|persian|azerbaijani|arabic|cz|portuguese|chinese|bulgarian|norwegian|slovak|uzbek|albanian|bosnian|catalan|croatian|finnish|galician|greek|hebrew|japanese|korean|lithuanian|macedonian|polish|romanian|serbian|cyrillic|latin|turkish|thai|ukrainian|hungarian|french|german|custom|czech|spanish|swedish|danish|rus|dutch|italian|\[.\]es\[.\]|\[.\]es\[-\]|\[.\]it\[.\]|\[.\]fr\[.\]|\[.\]sk\[.\]|\[.\]subbed\[.\]|\[.\]nlsub\[.\]|\[.\]nlsubbed\[.\]|\[.\]dub\[.\]|\[.\]pl\[.\]|\[.\]hun\[.\]|heb\[.\]sub|\[.\]multi|subs";
$cfilters = "mp4\[.\]psp|ppc\[.\]xvid|ebook|unlocker|extras|trailer|cover|keygen|bonus|crack|cheat|demo|patch|nfofix|cdkey|\[.\]mini\[.\]image|\[.\]manual\[.\]discs|\[.\]keychanger|fix|\[.\]gameguide|\[.\]nocd|\[.\]trainer|\[.\]custom|\[.\]java|\[.\]solaris|\[.\]pda|\[.\]psp\[.\]mp4|\[.\]int";

#Include required scripts
require_once "func.php";
require_once "auth.php";

#In case the client is able to retrieve this PHP return error message
if ($_SERVER['REQUEST_URI'] == "precheck.php") echo $denied;

function search() {
	global $lfilters, $cfilters, $mysql_host, $mysql_user, $mysql_pass, $mysql_db, $window;

	#If this is a new search reset variables
	if (!isset($_GET['next'])) resetvars();

	#If requesting the next batch of results prepare the environment to retrieve them
	if (isset($_GET['next']) && $_GET['next'] === "1") {
		if (!isset($_SESSION['prestart']) || !isset($_SESSION['preend'])) { echo json_encode(array()); exit(); }
		if (($_SESSION['prestart'] == 0 || $_SESSION['override'] == 1) && $_SESSION['start'] == 0) { echo json_encode(array()); exit(); }
	}

	#If this is a new query copy the post information into $_SESSION
	if(!is_null($_GET)) {
		foreach($_GET as $Name=>$Data) {
			if(is_null($Data)) {
				unset(${$Name});
				unset($_SESSION[$Name]);
			} else {
				$_SESSION[$Name] = $Data;
			}
		}
	}

	#Connect to the database
	$link = new mysqli($mysql_host, $mysql_user, $mysql_pass,$mysql_db);
	if ($link->connect_errno) {
		die("Failed to connect to MySQL: (" . $link->connect_errno . ") " . $link->connect_error);
	}

	#If this is a new search set the start pointer.
	if (!isset($_SESSION['start'])) { $_SESSION['start'] = 0; }
	if (!isset($_SESSION['override'])) { $_SESSION['override'] = 0; }
	$section = ""; $grp = ""; $genre = ""; $nfo = ""; $jpg = ""; $nuke = ""; $case = ""; $exclude = "";
	$search = $link->real_escape_string($_SESSION['search']);
	$window = count(explode(" ",$search)) * 2592000;

	#Check which options are set and convert to the appropriate bot syntax
	if (isset($_SESSION['lfilter']) && $_SESSION['lfilter'] !== 0) { $exclude = (($exclude != "") ? $exclude."|" : "").$lfilters; }
	if (isset($_SESSION['nonly']) && $_SESSION['nonly'] !== 0) { $nfo = "`nfo`.`id`!='' AND "; }
	if (isset($_SESSION['jonly']) && $_SESSION['jonly'] !== 0) { $jpg = "`samplejpg`.`id`!='' AND "; }
	if (isset($_SESSION['blocked']) && $_SESSION['blocked'] !== 0) { $blocked = "`blocked` = 1 AND "; } else { $blocked = "`blocked` = 0 AND "; }
	if (isset($_SESSION['case']) && $_SESSION['case'] !== 0) { $case = "BINARY"; }
	if (isset($_SESSION['nonfo']) && $_SESSION['nonfo'] !== 0) { $nfo = "`nfo`.`id` is NULL AND "; }
	if (isset($_SESSION['nojpg']) && $_SESSION['nojpg'] !== 0) { $jpg = "`samplejpg`.`id` is NULL AND "; }
	if (isset($_SESSION['nonuke']) && $_SESSION['nonuke'] !== 0) { $nuke = "`nukereason`='' AND "; }
	if (isset($_SESSION['nukeonly']) && $_SESSION['nukeonly'] !== 0) { $nuke = "`nukereason`!='' AND "; }
	if (isset($_SESSION['cfilter']) && $_SESSION['cfilter'] !== 0) { $exclude = (($exclude != "") ? $exclude."|" : "").$cfilters; }
	if (isset($_SESSION['section']) && $_SESSION['section'] !== "") { $section = "`cat` = '".$link->real_escape_string($_SESSION['section'])."' AND "; }
	if (isset($_SESSION['genre']) && $_SESSION['genre'] !== "") { $genre = "`genre` = '".$link->real_escape_string($_SESSION['genre'])."' AND "; }
	if (isset($_SESSION['group']) && $_SESSION['group'] !== "") { $grp = "`grp` = '".$link->real_escape_string($_SESSION['group'])."' AND "; }
	if (isset($_SESSION['exclude']) && $_SESSION['exclude'] !== "") { $exclude = (($exclude != "") ? $exclude."|" : "").$link->real_escape_string($_SESSION['exclude']); }
	if (!isset($_SESSION['exact']) || $_SESSION['exact'] != "on") { $search = "%".$search."%"; }
	if ($exclude != "") $exclude = " AND `title` NOT REGEXP '".$exclude."'";
	$search = str_replace(array("_","?","*"," "),array("\\_","_","%","%"), $search);

	if (!isset($_SESSION['prestart'])) {
		$temp = "`pretime` > UNIX_TIMESTAMP(now() - INTERVAL 1 month) AND ";
		$query = "SELECT count(`id`) FROM `pre` WHERE ".$temp.$nuke."`title` LIKE ".$case." '".$search."'";
		$data = $link->query($query);
		$count = $data->fetch_row();
		if ($count[0] < 50) {
			$_SESSION['override'] = 1;
		}
	}

	if ($section != "" || $grp != "" || isset($_SESSION['exact']) || $genre != "") $_SESSION['override'] = 1;

	if (!isset($_SESSION['prestart'])) { $_SESSION['preend'] = intval(microtime(true)); $_SESSION['prestart'] = $_SESSION['preend'] - $window; }
	$results = array(); $x = 0;

	while (count($results) < 50) {
		$x++;
		if ($_SESSION['override'] == 0) {
			$pretime = "`pretime` BETWEEN ".$_SESSION['prestart']." AND ".$_SESSION['preend']." AND ";
		} else {
			$pretime = "";
		}
		#String together the query
		$query = "SELECT HIGH_PRIORITY `pre`.`title`,`pre`.`pretime`,`pre`.`cat`,`pre`.`genre`,`pre`.`rlssize`,`pre`.`files`,`nfo`.`id`,`samplejpg`.`id`,`pre`.`nuketime`,`pre`.`nukereason` FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE ".$pretime.$section.$grp.$genre.$blocked.$nfo.$jpg.$nuke."`title` LIKE ".$case." '".$search."' ".$exclude." ORDER BY `pretime` DESC";

		#Submit the query
		$data = $link->query($query);

		#If results are 0 then cycle
		if (!$data->num_rows) {
			if (($_SESSION['prestart'] == 0 && $_SESSION['start'] == 0) || $_SESSION['override'] == 1) { break; }
			$_SESSION['start'] = 0; advpoint($x); continue;
		}

		#Seek to desired start point
		$data->data_seek($_SESSION['start']);

		for ($i=1; count($results) < 50; $i++) {
			if (!($row = $data->fetch_row())) {
				$_SESSION['start'] = 0;
				if ($_SESSION['override'] == 1) { break 2; } else { break; }
			}
			$nlink = explode("?",getnfolink($row[6]));
			$nlink = $nlink[1];
			if(!is_null($row[6])) { $row[6] = $nlink; } else { $row[6] = 0; }
			if(!is_null($row[7])) { $row[7] = $nlink; } else { $row[7] = 0; }
			$row[1] = intval(microtime(true)) - $row[1];
			$results[]=$row;
		}
		if (count($results) == 50) $_SESSION['start'] += $i;

		#Advance pointer, quit if the prestart has dropped below the first pre in database
		if ($_SESSION['prestart'] == 0) { break; }
		if ($_SESSION['start'] == 0 && count($results) < 50) { advpoint($x); }
	}

	echo json_encode($results);
	exit();
}

function advpoint($x) {
	global $window;
	if ($x > 1) {
		$_SESSION['preend'] = $_SESSION['prestart'];
		$_SESSION['prestart'] = 0;
		return;
	}
	$_SESSION['preend'] = $_SESSION['prestart'];
	$_SESSION['prestart'] -= ($window * ($x * 2));
	if ($_SESSION['prestart'] <= 0 || $_SESSION['preend'] <= 0) { echo json_encode(array()); exit(); }
}
?>
