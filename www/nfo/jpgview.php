<?php
/* Configuration */
$mysql['host']  = '';
$mysql['user']  = '';
$mysql['pass']  = '';
$mysql['db']    = '';

$nfopass = "secretpasswordhere";

//open mysql connection
$link = mysql_connect($mysql['host'], $mysql['user'], $mysql['pass']);
mysql_select_db($mysql['db'], $link);

$keys = array_keys($_GET);
$get = $keys[0];

list($id, $pass, $expiry, $mode, $scaled) = explode(":", base64_decode($get));

if (!$_GET) die("You lack access to this site. <a href='mailto:help@email.com'>E-Mail</a> if you believe you should.");

if (md5($nfopass.$expiry) != $pass) die("Bad password.");
if (time() > $expiry) die("Hash expired.");

if($mode == "image") {
  if ($result = mysql_query("SELECT `release`,`filename`,`image` FROM samplejpg WHERE id=$id")) {
    header("Content-Type: image/jpeg");
    $line = mysql_fetch_object($result);
    if (!$scaled) echo $line->image;
    //thumb($source, $scale, $quality = 80)
    else thumb($line->image, 1.5, 85);
  }
}

else {
echo <<<STOP
<body topmargin=0 bottommargin=0 rightmargin=5 leftmargin=5 marginwidth=0>
<style type="text/css">
a.imgviewn {
  color: gray;
  font-size: 10pt;
  font-family:"Lucidia Console, Arial, Verdana, Heveletica, sans serif";
  text-decoration: none;
}
a.imgviewi {
  color: red;
  text-decoration: none;
  font-size: 10pt;
  font-family:"Lucidia Console, Arial, Verdana, Heveletica, sans serif";
  font-style: none;
}
</style>
<script>
function closeWindow() {
        top.self.close();
}

function overMe(t){
 if (t.className == "imgviewn"){
 t.className = "imgviewi";
 }
else {
 t.className = "imgviewn";
 }
}
</script>
<center>

STOP;

//list($id, $pass, $expiry, $mode, $scaled)

$newhash = base64_encode("$id:$pass:$expiry:image:$scaled");
echo "<img src='?$newhash' /><br>\n";
echo "<a href=\"javascript:closeWindow()\" class=\"imgviewn\" onMouseOut=overMe(this) onMouseOver=overMe(this)>&lt;Close&gt;</a>\n";

echo "</center>\n";
}

function thumb($image, $scale, $quality=80) {
  $image = imagecreatefromstring($image);
  $size[0] = imagesx($image);
  $size[1] = imagesy($image);
  $size['mime'] = 'image/jpeg';
  $w = $size[0] / $scale; // Width divided
  $h = $size[1] / $scale; // Height divided
  $resize = imagecreatetruecolor($w, $h); // Create a blank image
  imagecopyresampled($resize, $image, 0, 0, 0, 0, $w, $h, $size[0], $size[1]); // Resample the original JPEG
  imagejpeg($resize, '', $quality); // Output the new JPEG
}

?>

