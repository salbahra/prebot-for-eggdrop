set botsync_nick "mainBot backupBot"

bind link - * bind_link
bind bot - "!update" update
bind bot - "!updatefrom" updatefrom
bind bot - "!synctime" synctime

set db3 [mysqlconnect -host localhost -user user -password password -db db]
proc bind_link {botname via} {transfer_to $botname}

proc transfer_to {botname} {
  global botnet-nick db3 botsync_nick
  set allowed 0
  foreach nick $botsync_nick {
   if {$botname == $nick} { set allowed 1 }
  }
  if {$allowed == 0} { return 0 }
  putlog "Starting BotSync Update to bot $botname"
  putbot $botname "!synctime [unixtime]"
  set rls [lindex [mysqlsel $db3 "SELECT * FROM `pre` ORDER BY `pretime` DESC Limit 1;" -list] 0]
  putbot $botname "!updatefrom [lindex $rls 2]"
}

proc update {from command text} {
  global db3
  putlog "Adding Missing Pre [lindex $text 1] From $from"
  set cat [lindex $text 0]; set rls [lindex $text 1]; set pretime [lindex $text 2]; set nuketime [lindex $text 3]; set size [lindex $text 6]; set files [lindex $text 7]
  if {[lindex $text 5] == "NULL"} { set genre "" } else { set genre [lindex $text 5] }
  if {[lindex $text 4] == "NULL"} { set nukersn "" } else { set nukersn [lindex $text 4] }
  if {$pretime == "0"} { return }
  mysqlexec $db3 "INSERT IGNORE INTO pre VALUES ('','$cat','$rls','$pretime','$nuketime','$nukersn','$genre','$size','$files','[lindex [split $rls "-"] end]','','')"
  return 1
}

proc updatefrom {botname command text} {
  global db3 offset
  putlog "Sending Missing Pre's to $botname"
  set time [lindex [lindex [mysqlsel $db3 "SELECT * FROM `pre` WHERE `title`='$text';" -list] 0] 3]
  if {$time == "" } { return }
  set numrls [mysqlsel $db3 "SELECT * FROM `pre` WHERE `pretime`>'$time';"]
  mysqlseek $db3 0
  set shown 1
  while { $shown <= $numrls } {
	set shown [expr $shown + 1]
	set release [mysqlnext $db3]
	set cat [lindex $release 1]; set rls [lindex $release 2]; set pretime [expr [lindex $release 3] - $offset]; set nuketime [lindex $release 4]; set size [lindex $release 7]; set files [lindex $release 8]
	if {[lindex $release 6] == ""} { set genre "NULL" } else { set genre [lindex $release 6] }
	if {[lindex $release 5] == ""} { set nukersn "NULL" } else { set nukersn [lindex $release 5] }
	set line "$cat $rls $pretime $nuketime $nukersn $genre $size $files"
	putbot $botname "!update $line"
  }
  return 1
}

proc synctime {from command text} {
  global offset
  putlog "Syncing Unixtime with $from"
  set offset [expr [unixtime] - $text]
  return 1
}

putlog "Bot Sync for Pre Bot's now Loaded"
