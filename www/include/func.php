<?php

$mysql_host = '';
$mysql_user = '';
$mysql_pass = '';
$mysql_db = '';

function caching_headers($file, $timestamp) {
	$gmt_mtime = gmdate('r', $timestamp);
	header('ETag: "'.md5($timestamp.$file).'"');
	if(isset($_SERVER['HTTP_IF_MODIFIED_SINCE']) || isset($_SERVER['HTTP_IF_NONE_MATCH'])) {
		if ($_SERVER['HTTP_IF_MODIFIED_SINCE'] == $gmt_mtime || str_replace('"', '', stripslashes($_SERVER['HTTP_IF_NONE_MATCH'])) == md5($timestamp.$file)) {
			header('HTTP/1.1 304 Not Modified');
			exit();
		}
	}

	header('Last-Modified: '.$gmt_mtime);
	header('Cache-Control: public');
}

function endc($array) { return end( $array ); }

function get_notify() {
	global $mysql_host, $mysql_user, $mysql_pass, $mysql_db;
	$link = mysql_connect($mysql_host, $mysql_user, $mysql_pass)
		or die('Could not connect: ' . mysql_error());
	mysql_select_db($mysql_db) or die('Could not select database');
	$query = "SELECT `nick` FROM `notify` GROUP BY `nick`";
	$result = mysql_query($query) or die('Query failed: ' . mysql_error());
	while ($nick = mysql_fetch_array($result, MYSQL_ASSOC)) {
		if (strtolower($nick['nick']) == strtolower($_SESSION['username'])) { $_SESSION['notify'] = true; }
	}
	if (!isset($_SESSION['notify'])) return "";
	$query = "SELECT `regex_name`,`is_group`,`is_section` FROM `notify` WHERE `nick` = '".$_SESSION['username']."'";
	$result = mysql_query($query) or die('Query failed: ' . mysql_error());
	echo "<span class=\"graytitle\">Notifies</span>";
	echo "<ul class=\"pageitem\">";
	while ($notify = mysql_fetch_array($result, MYSQL_ASSOC)) {
		if ($notify['is_group'] != "") $notify['is_group'] = str_replace("*-", "", $notify['is_group']);
		$array = array("search" => $notify['regex_name'], "section" => $notify['is_section'], "group" => $notify['is_group'], "action" => "search");
		$link = http_build_query(array_filter($array));
		$line = "<li class=\"menu\"><a class=\"noeffect\" onclick=\"get('".$link."')\"><span class=\"name\">".$notify['regex_name']."</span></a></li>";
		echo $line;
	}
	echo "</ul>";
}

function resetvars() {
	unset($_SESSION['lfilter']);
	unset($_SESSION['nonly']);
	unset($_SESSION['jonly']);
	unset($_SESSION['blocked']);
	unset($_SESSION['case']);
	unset($_SESSION['nonfo']);
	unset($_SESSION['nojpg']);
	unset($_SESSION['nonuke']);
	unset($_SESSION['nukeonly']);
	unset($_SESSION['cfilter']);
	unset($_SESSION['exact']);
	unset($_SESSION['section']);
	unset($_SESSION['genre']);
	unset($_SESSION['group']);
	unset($_SESSION['exclude']);
	unset($_SESSION['start']);
	unset($_SESSION['preend']);
	unset($_SESSION['prestart']);
	unset($_SESSION['override']);
}

function time_since($dateDiff) {
	$print = "";
	$suffix = array("y","w","d","h","m","s");
	$y   = floor($dateDiff/(60*60*24*7*52));
	$w   = floor(($dateDiff-($y*60*60*24*7*52))/(60*60*24*7));
	$d    = floor(($dateDiff-($y*60*60*24*7*52)-($w*60*60*24*7))/(60*60*24));
	$h   = floor(($dateDiff-($y*60*60*24*7*52)-($w*60*60*24*7)-($d*60*60*24))/(60*60));
	$m = floor(($dateDiff-($y*60*60*24*7*52)-($w*60*60*24*7)-($d*60*60*24)-($h*60*60))/60);
	$s = $dateDiff-($y*60*60*24*7*52)-($w*60*60*24*7)-($d*60*60*24)-($h*60*60)-($m*60);
	for ($i = 0; $i <= sizeof($suffix); $i++) {
		if ($$suffix[$i]>0) { $print = $print." ".$$suffix[$i].$suffix[$i]; }
	}
	return $print;
}

function getnfolink($id) {
	$time = explode(" ",microtime());
	$time = $time[1];
	$link = "http://NFO_SERVER_URL/?".str_replace("=","",base64_encode($id.":".md5("secretpasswordhere".($time + 600)).":".($time+600)));
	return $link;
}

function feedback() {
    $fb = fopen("/var/www/feedback.txt", "a");
    fwrite($fb, "\n".date(DATE_RFC822)." ".$_SERVER['REMOTE_ADDR']."\n".$_POST['feedback']);
    fclose($fb);
    exit();
}

if ($_SERVER['REQUEST_URI'] == "func.php") echo $denied;

?>