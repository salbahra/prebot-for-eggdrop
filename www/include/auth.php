<?php

#Refuse if a direct call has been made
if(!defined('PreDB')){echo $denied;exit();}

if (isset($_REQUEST['action'])) {
	if(isset($_SERVER['HTTP_X_REQUESTED_WITH']) && ($_SERVER['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest')) {
		if (is_callable($_REQUEST['action'])) {
			if (($_REQUEST['action'] == "gettoken" || $_REQUEST['action'] == "checktoken" || $_REQUEST['action'] == "login") || is_auth()) {
				call_user_func($_REQUEST['action']);
				exit();
			}
		} else {
			echo 'Function does not exist, request terminated';
			exit();
		}
	} else { header("HTTP/1.0 401 Authorization Required"); echo $denied; exit(); }
}

function http_authenticate($user,$pass,$pass_file='/var/www/include/.htpasswd',$crypt_type='SHA'){
	if(!ctype_alnum($user)){
		return FALSE;
	}
	if(!ctype_alnum($pass)){
		return FALSE;
	}
	if(file_exists($pass_file) && is_readable($pass_file)){
		if($fp=fopen($pass_file,'r')){
			while($line=fgets($fp)){
				$line=preg_replace('`[\r\n]$`','',$line);
				list($fuser,$fpass)=explode(':',$line);
				if($fuser==$user){
					switch($crypt_type){
						case 'DES':
							$salt=substr($fpass,0,2);
							$test_pw=crypt($pass,$salt);
							break;
						case 'PLAIN':
							$test_pw=$pass;
							break;
						case 'SHA':
							$test_pw=base64_encode(sha1($pass));
							break;
						case 'MD5':
							$test_pw=md5($pass);
							break;
						default:
							fclose($fp);
							return FALSE;
					}
					if($test_pw == $fpass){
						fclose($fp);
						return TRUE;
					}else{
						return FALSE;
					}
				}
			}
			fclose($fp);
		}else{
			return FALSE;
		}
	}else{
            return FALSE;
	}
}
function delLineFromFile($fileName, $lineNum){
	$arr = file($fileName);
	$lineToDelete = $lineNum;
	unset($arr["$lineToDelete"]);
	$fp = fopen($fileName, 'w+');
	foreach($arr as $line) { fwrite($fp,$line); }
	fclose($fp);
	return TRUE;
}
function login($tosend = "default") {
	global $denied, $iphonetoken;
	$starttime = explode(' ', microtime());
	$starttime = $starttime[1] + $starttime[0];
	$endtime = $starttime - 2592000;
	$cache = "/var/www/include/.cache";
	$expire=time()+60*60*24*30;
	$auth = base64_encode(sha1($_SERVER['REMOTE_ADDR']).sha1($starttime).sha1($_POST['username']).sha1($_POST['password']));
	if (!http_authenticate($_POST['username'],$_POST['password'])) {
		echo 0;
		exit();
	} else {
		if (isset($_POST['remember']) && $_POST['remember'] == "true") {
			$fh = fopen($cache, 'a+');
			fwrite($fh, $starttime." ".$auth." ".$_POST['username']."\n");
			fclose($fh);
	        $_SESSION['sendtoken'] = true;
		}
		$_SESSION['token'] = $auth;
		$_SESSION['isauth'] = 1;
		$_SESSION['username'] = $_POST['username'];
	}
	if ($tosend == "token") {
		if (isset($_SESSION["token"])) echo $_SESSION["token"];
	} else {
		echo 1;
	}
}
function logout() {
	if(!isset($_SESSION)) session_start();
	global $denied;
	$cache = "/var/www/include/.cache";
	$hashs = file($cache);
	if (isset($_SESSION['token']) && count($hashs) !== 0) {
		$i = 0;
		foreach ($hashs as $hash){
			$hash = explode(" ",$hash);
			$hash[1] = str_replace("\n", "", $hash[1]);
			if ($hash[1] === $_SESSION['token']) {
				delLineFromFile($cache, $i);
			}
			$i++;
		}
	}
	unset($hashs);
	$_SESSION = array();
	session_destroy();
	echo 1;
}

function check_localstorage($token) {
	$starttime = explode(' ', microtime());
	$starttime = $starttime[1] + $starttime[0];
	$endtime = $starttime - 2592000;
	$found = 0;
	$cache = "/var/www/include/.cache";
	$hashs = file($cache);
	if (count($hashs) !== 0) {
		$i = 0;
		foreach ($hashs as $hash){
			$hash = explode(" ",$hash);
			$hash[2] = str_replace("\n", "", $hash[2]);
			if ($hash[0] <= $endtime) {
				delLineFromFile($cache, $i);
				return FALSE;
			}
			if ($token === $hash[1]) { $_SESSION['token'] = $token; $_SESSION['isauth'] = 1; $_SESSION['username'] = $hash[2]; return TRUE; }
			$i++;
		}
	}

	return FALSE;
}
function is_auth() {
//	is_ssl();
	if (isset($_SESSION['isauth']) && $_SESSION['isauth'] === 1) { return TRUE; }
	return FALSE;
}
function is_ssl() {
	if(empty($_SERVER['HTTPS'])) {
		$newurl = 'https://'.$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
		header("location: $newurl");
		exit();
	}
	return TRUE;
}
function checktoken() {
	if (check_localstorage($_POST['token'])) {
		echo 1;
	} else {
		echo 0;
	}
	exit();
}

function gettoken() {
    if (is_auth() && isset($_SESSION["token"])) {
        echo $_SESSION["token"];
        return;
    }
    login("token");
}

if ($_SERVER['REQUEST_URI'] == "auth.php") echo $denied;
?>
