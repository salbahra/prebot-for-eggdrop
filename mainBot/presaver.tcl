###########################
# Pre Saver for PreScript #
###########################

#####################################
# BINDS                             #
#####################################
bind bot - !predel bot:delpre
bind bot - !cs bot_chgsec
bind bot - !addpre bot:addpre
bind bot - !preadd bot:addpre
bind bot - !sitepre bot:addpre2
bind bot - !addinfo bot:addinfo
bind bot - !updatesize bot:updates
bind bot - !modnuke modnuke2
bind bot - !prenuke addnuke2
bind bot - !preunnuke delnuke2
bind bot - !preannounce prea
bind bot - !info bot:addinfo2
bind bot - !notify bot_notify
bind bot - !ndel bot_ndel
bind bot - !nlist bot_nlist
bind bot - !sendnfo bot_sendnfo
bind bot - !sendjpg bot_sendjpg
bind bot - !addnfo bot:addnfo
bind bot - !addjpg bot:addjpg
bind msg - !addinfo msg:addinfo
bind msg - !add2dupedb msg:addpre
bind msg - !addpre msg:addpre2
bind msg - !notify msg_notify
bind pub - !getold getold
bind pub - !notify pub_notify
bind pub - !nlist pub_nlist
bind pub - !ndel pub_ndel
bind pub A !preundel pub_undelpre
bind pub A !predel pub_delpre
bind pub A !preadd addpre
bind pub C !prenuke addnuke
bind pub C !modnuke modnuke
bind pub C !preunnuke delnuke
bind pub C !nukelock nukelock
bind pub C !unnukelock unnukelock
bind pub C !cs chgsec
bind pub C !cg chggnr
bind pub C !cf chgcase
bind pub C !cinfo chginfo
bind pub K !ctime chgtime
bind pub K !csall chgsec2
bind pub K !csmask chgsec3
bind pub K !wipenfo wipenfo
bind pub P !sitepre pub:sitepre

#####################################
# DATABASE OPTIONS                  #
#####################################

set databaseUser ""
set databasePassword ""
set databaseDB ""

#####################################
# DATABASE CONNECTION               #
#####################################

proc init {} {
	global db2 lastrls lastrlscur laststripped databaseUser databasePassword databaseDB
	putlog "Presaver for PreSciprt Loaded"
        if {![info exists db2] || ![mysqlstate $db2 -numeric]} { set db2 [mysqlconnect -host localhost -user $databaseUser -password $databasePassword -db $databaseDB] }
	set lastrlscur 1
	set x 1
	while {$x <= 100} {
		set lastrls($x) "."
		incr x
	}
       set x 1
       while {$x <= 100} {
       	set laststripped($x) "."
  		incr x
	}
	freload 0
	if {[llength [utimers]] == 0} { utimer 300 check_link }
}

proc check_database {} {
	global db2 databaseUser databasePassword databaseDB

	putlog "Checking database connection..."
	if {![mysqlping $db2]} {
		putlog "MySQL connection lost. Restoring connection..."
 		set db2 [mysqlconnect -host localhost -user $databaseUser -password $databasePassword -db $databaseDB]
	}
}

#Checks if release exists and if it is blocked or not
proc findpre { rls } {

  global db2
  if {[mysqlsel $db2 "SELECT count(`title`) FROM `pre` WHERE `title`='$rls' AND `blocked`='1';" -list]} {
    return "blocked"
  } elseif {[mysqlsel $db2 "SELECT count(`title`) FROM `pre` WHERE `title`='$rls';" -list]} {
    return "pre"
  } else { return "error" }

}

#####################################
# ADDPRE FUNCTIONS                  #
#####################################

proc getold { nick uhost hand chan arg } {
	tmsg bot "!saypre #import :" leadBot "!getold $arg"
}

proc addpre { nick uhost hand chan arg } {
     set sRelease [lindex $arg 0]
     set sType [lindex $arg 1]
     writeto_sql $sRelease $sType $nick 2 {}
}

proc bot:addpre { frombot command arg } {
     set sRelease [lindex $arg 0]
     set sType [lindex $arg 1]
     writeto_sql $sRelease $sType $frombot 1 {}
}

proc bot:addpre2 { frombot command arg } {
     set secret 2
     set sRelease [lindex $arg 0]
     set sType [lindex $arg 1]
     set file [lindex $arg 2]
     set size [lindex $arg 3]
     writeto_sql $sRelease $sType $frombot $secret "$file $size"
     addinfo_done $frombot fs2 $sRelease "$file $size"
}

proc msg:addpre { nick uhost hand arg } {
     set sRelease [lindex $arg 0]
     set sType [lindex $arg 1]
     set file [lindex $arg 2]
     set size [lindex $arg 3]
     writeto_sql $sRelease $sType $nick 0 "$file $size"
     addinfo_done $nick fs2 $sRelease "$file $size"
}

proc msg:addpre2 { nick uhost hand arg } {
     set sRelease [lindex $arg 1]
     set sType [lindex $arg 0]
     set file [lindex $arg 2]
     set size [lindex $arg 3]
     writeto_sql $sRelease $sType $nick 1 "$file $size"
     addinfo_done $frombot fs2 $sRelease "$file $size"
}

proc pub:sitepre { nick uhost hand chan arg } {
     set sRelease [lindex $arg 0]
     set sType [lindex $arg 1]
     set file [lindex $arg 2]
     set size [lindex $arg 3]
     writeto_sql $sRelease $sType $nick 0 "$file $size"
     addinfo_done $nick fs2 $sRelease "$file $size"
}

proc writeto_sql { rls type frombot senddata fs} {
     global db2
     regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $rls "" rls2
     regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $type "" type
     if {$rls2 != $rls} {
	putlog "Bad: $rls | Filter: Release name contains shit chars | From: $frombot"
	set group [getgroup $rls]
	mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
	putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([strftime "%Y/%m/%d %H:%M:%S " [expr [unixtime] + 21600]]CET)"
	return 0
     }
     if {[findpre $rls] == "pre" || [findpre $rls] == "blocked"} { return }
     set type [string toupper $type]
     set iDate [unixtime]
     if {[regexp {^[a-zA-Z0-9(]+[_\(\)\.-]+[a-zA-Z0-9_\(\)\.-]+[a-zA-Z0-9]+$} "$rls"]} {
      if {[llength [split "$rls" "("]] == [llength [split "$rls" ")"]]} {
	set type2 [sectionize $rls]
	if {$type2 != "CRAP"} { set type $type2 }
       set type [fixtype $rls $type]
       if {[rlsok $rls $type $frombot] == 0} { return 0 }
	set group [getgroup $rls]
       set result [mysqlexec $db2 "INSERT IGNORE INTO pre VALUES ('','$type','$rls','$iDate','','','','','','$group','','')"]
       if {$result == 0} { return 0 }
	if {$senddata == 0} {
		set file [lindex $fs 0]
		set size [lindex $fs 1]
		putlog "Site Pre $rls added from $frombot with $file files weighing in at $size"
	}
	if {$senddata == 1} {
	       putlog "$rls Added by $frombot"
	}
	if {$senddata == 2} {
		set file [lindex $fs 0]
		set size [lindex $fs 1]
		putlog "Site Pre $rls added from $frombot with $file files weighing in at $size"
	}
	prea "bob" "bob" "$rls $type"
	return 1
       } else {
        putlog "$rls Rejected from $frombot"
	return 0
       }
     } else {
       putlog "$rls Rejected from $frombot"
	return 0
     }
}

proc getgroup {release} {
    set spgrps "SD-6 VH-PROD TEG-TV Cheetah-TV DVD-R CRN-TV FSN-EU ELPH-TV XeoN-VorTeX TEG-PSX TEG-VCD X-BRAIN LION-SVCD LION-XXX TEG-DVD Cheetah-DV THEORY-CLS"
    regsub -nocase {[._-]int$|\_internal$|_house$} $release {} release
    # EOSiNT is internal from EOS.. we have to fix that..
    regsub -- {-EOSiNT$} $release {-EOS} release
    foreach i $spgrps {if {[string match -noc *$i $release]} {return $i}}
    set t [split $release -]
    if {[llength $t] > 1} {return [lindex $t end]} else {return NOGRP}
}

#####################
# ANNOUNCE FUNCTION #
#####################

proc prea { frombot command arg } {
	global db2 db toffset lfilters
	set type [lindex $arg 1]
	set ccode [typecolor $type]
	putnow "PRIVMSG #Announce :\[$ccode\PRE-$type\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
	set filters [mysqlsel $db2 "SELECT * FROM `notify`;"]
	set filtersp 1
	while { $filtersp <= $filters } {
		set filter [mysqlnext $db2]
		incr filtersp
		if {[string match [lindex $filter 4] [string tolower [lindex $arg 0]]]} {
			if {[regexp -nocase $lfilters [lindex $arg 0]]} { continue }
			if {[lindex $filter 5] != "" && [string match -nocase [lindex $filter 5] [lindex $arg 0]] == 0} { continue }
			if {[lindex $filter 6] != "" && [string match -nocase [lindex $filter 6] [lindex $arg 1]] == 0} { continue }
			if {[lindex $filter 1] == "email"} {
				send_simple_message [lindex $filter 3] localhost "PreBot Notify System" "[lindex $arg 0] has just been released in section $type."
			} elseif {[lindex $filter 1] == "msn"} {
				if {[islinked msnBot]} { putbot msnBot "!saynotify [lindex $filter 3] [lindex $arg 0] has just been released in section $type." }
			} elseif {[lindex $filter 1] == "bot"} {
				set temp [split [lindex $filter 3] ":"]
				set botnick [lindex $temp 0]
				set botmode [lindex $temp 1]
				if {$botmode == "notice"} { putbot [lindex $filter 2] "!saypre3 $botnick : \[$ccode\PRE-$type\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])" }
				if {$botmode == "privmsg"} { putbot [lindex $filter 2] "!saypre $botnick : \[$ccode\PRE-$type\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])" }
			} else {
				putnow "[lindex $filter 1] [lindex $filter 2] :\[$ccode\PRE-$type\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
			}
			#if {[expr [lindex $filter 7] + 1] == [lindex $filter 8]} {
			#	set results [mysqlexec $db "DELETE FROM `notify` WHERE `id` = '[lindex $filter 0]' LIMIT 1"]
			#	continue
			#}
			set results [mysqlexec $db "UPDATE notify SET matches='[expr [lindex $filter 7] + 1]' WHERE id='[lindex $filter 0]'"]
		}
	}
	mysqlendquery $db2

}

proc send_simple_message {recipient email_server subject body} {
      package require smtp
      package require mime
      set token [mime::initialize -canonical text/plain -string $body]
      smtp::sendmessage $token -header [list From "pre@pre.bot"] -header [list To "$recipient"] -header [list Subject "$subject"] -servers $email_server
      mime::finalize $token
}

proc pub_notify { nick hand uhost chan arg } {
 notify "pub" $nick "NOTICE" $arg
}

proc msg_notify { nick hand uhost arg} {
 notify "pub" $nick "NOTICE" $arg
}

proc bot_notify { frombot command arg} {
 set echonick [lindex $arg 0]
 set arg [lrange $arg 1 end]
 notify "bot" $frombot "!saypre3 $echonick :" $arg
}

proc notify { ttype to form arg } {
	global db2
	set group ""
	set nick $to
	set filters [mysqlsel $db2 "SELECT * FROM `notify`;"]
	mysqlendquery $db2
	if {$filters > 200} {
		tmsg $ttype $form $to "\[4ERROR\] Error adding requested filter because limit of 200 filters in database has been reached."
		return
	}
	set method [split [string tolower [lindex $arg 0]] ":"]
	set email [lindex $method 1]
	set botmode [lindex $method 2]
	set method [lindex $method 0]
	if {$arg == ""} {
		tmsg $ttype $form $to "\[4ERROR\] USAGE: !notify <method> <filter> \[section\] \[group\]"
		return
	}
	if {$method != "privmsg" && $method != "notice" && $method !="email" && $method !="msn" && $method !="bot"} {
		tmsg $ttype $form $to "\[4ERROR\] Error adding requested filter because method is incorrect, please use privmsg, notice, msn:email or email:your@address.com."
		return
	}
	set filter [string tolower [lindex $arg 1]]
	if {$filter == ""} {
		tmsg $ttype $form $to "\[4ERROR\] Error adding requested filter because there is no filter specified."
		return
	}
	set section [string tolower [lindex $arg 2]]
	if {[type_check $section] && $section != ""} {
		tmsg $ttype $form $to "\[4ERROR\] Error adding requested filter because the section is not valid, please refer to !listsections for valid sections."
		return
	}
	if {$section == "movie"} { set section "movie-*" }
	if {$section == "tv"} { set section "tv-*" }
	if {[string tolower [lindex $arg 3]] !=""} { set group "*-[string tolower [lindex $arg 3]]" }
       if {$method == "msn"} { set email [lindex [split $email "@"] 0] }
       if {$method == "bot"} { set email "$email:$botmode" }
	set result [mysqlexec $db2 "INSERT IGNORE INTO notify VALUES ('','$method','$nick','$email','$filter','$group','$section','0','10')"]
       if {$result == 0} {
		tmsg $ttype $form $to "\[4ERROR\] Error adding requested filter because the name is used, please use a different name."
		return
	}
	if {$section == ""} { set section "NONE" }
	if {$group == ""} { set group "NONE" }
	tmsg $ttype $form $to "\[7NOTIFY\] Filter $filter added for $nick via $method using section filter $section and group filter $group"
	putlog "Added notify for $nick via $method with section: $section and group: $group"
}

proc pub_ndel { nick hand uhost chan arg } {
 ndel "pub" $nick "NOTICE" $arg
}

proc bot_ndel { frombot command arg} {
 set echonick [lindex $arg 0]
 set arg [lindex $arg 1]
 ndel "bot" $frombot "!saypre3 $echonick :" $arg
}

proc ndel {ttype to form arg} {
	global db2
       if {[lindex $arg 0] == ""} {
		tmsg $ttype $form $to "\[4ERROR\] No input detected, please select input using !nlist."
		return
	}
	if {$ttype == "pub"} {
		set filters [mysqlsel $db2 "SELECT * FROM `notify` WHERE `nick`='$to';"]
	} else {
		set filters [mysqlsel $db2 "SELECT * FROM `notify` WHERE `email` LIKE '[lindex $form 1]:%';"]
	}
       if {$filters == 0} {
		tmsg $ttype $form $to "\[4ERROR\] No filters for your nickname found."
		mysqlendquery $db2
		return
	}
	set filtersp 1
	mysqlseek $db2 [expr [lindex $arg 0] - 1]
	set filter [mysqlnext $db2]
	mysqlendquery $db2
	set result [mysqlexec $db2 "DELETE FROM notify WHERE id='[lindex $filter 0]'"]
	mysqlendquery $db2
	tmsg $ttype $form $to "\[7NOTIFY\] Filter #[lindex $arg 0] using [lindex $filter 4] as main filter sent via [lindex $filter 1] is deleted"
}

proc pub_nlist { nick hand uhost chan arg } {
 nlist "pub" $nick "NOTICE" $arg
}

proc bot_nlist { frombot command arg} {
 set echonick [lindex $arg 0]
 set arg [lrange $arg 1 end]
 nlist "bot" $frombot "!saypre3 $echonick :" $arg
}

proc nlist {ttype to form arg} {
	global db2
	if {$ttype == "pub"} {
		set filters [mysqlsel $db2 "SELECT * FROM `notify` WHERE `nick`='$to';"]
	} else {
		set filters [mysqlsel $db2 "SELECT * FROM `notify` WHERE `email` LIKE '[lindex $form 1]:%';"]
	}
       if {$filters == 0} {
		tmsg $ttype $form $to "\[4ERROR\] No filters for your nickname found."
		mysqlendquery $db2
		return
	}
	set filtersp 1
	while { $filtersp <= $filters } {
		set filter [mysqlnext $db2]
		set section ""
		set group ""
		if {[lindex $filter 5] != ""} { set group "and group filter [lindex $filter 5]" }
		if {[lindex $filter 6] != ""} { set section "and section filter [lindex $filter 6]" }
		tmsg $ttype $form $to "\[7NOTIFY\] Filter #$filtersp using [lindex $filter 4] as main filter $section$group sent via [lindex $filter 1] triggered [lindex $filter 7] times"
		incr filtersp
	}
	mysqlendquery $db2
}

#####################
# DEL PRE FUNCTIONS #
#####################

proc bot:delpre { frombot command arg } {
  delpre $frombot $arg
}

proc pub_delpre { nick uhost hand chan arg } {
  set rls [lindex $arg 0]
  set rsn [lindex $arg 1]
  delpre $chan $rls
}

proc delpre {from arg} {
  global db2 toffset
  set release [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$arg' AND `blocked`='0' ORDER BY `pretime` DESC LIMIT 0, 1;" -list]
  mysqlendquery $db2
  set release [lindex $release 0]
  set id [lindex $release 0]
  if {$id == ""} { return }
  mysqlexec $db2 "UPDATE `pre` SET `blocked`=1 WHERE `id`='$id' LIMIT 1"
  mysqlendquery $db2
  putlog "$arg Deleted by $from"
  if {[string first "#" $from] == -1} { set from "#Repair" }
  putnow "PRIVMSG $from :\[7PREDEL\] $arg ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

proc pub_undelpre {nick uhost hand chan arg} {
  global db2 toffset
  set release [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$arg' AND `blocked`='1' ORDER BY `pretime` DESC LIMIT 0, 1;" -list]
  mysqlendquery $db2
  set release [lindex $release 0]
  set id [lindex $release 0]
  if {$id == ""} { return }
  mysqlexec $db2 "UPDATE `pre` SET `blocked`=0 WHERE `id`='$id' LIMIT 1"
  mysqlendquery $db2
  putlog "[lindex $arg 0] Restored by $nick"
  putnow "PRIVMSG $chan :\[7PREUNDEL\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

proc wipenfo {nick uhost hand chan arg} {
  global db2 toffset
  set rls [lindex $arg 0]
  if {$rls == ""} { putnow "PRIVMSG $chan :\[7WIPENFO\] No release detected \[0 row(s) affected\]"; return }
  set database [findpre $rls]
  if {$database == "error"} { putnow "PRIVMSG $chan :\[7WIPENFO\] Release not found \[0 row(s) affected\]"; return }
  set id [lindex [lindex [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0] 0]
  set release [mysqlexec $db2 "DELETE FROM `nfo` WHERE `id` = '$id' LIMIT 1"]
  set release [mysqlexec $db2 "DELETE FROM `samplejpg` WHERE `id` = '$id' LIMIT 1"]
  mysqlendquery $db2
  putlog "NFO wiped for release [lindex $arg 0] by $nick"
  putnow "PRIVMSG $chan :\[7WIPENFO\] [lindex $arg 0] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

######################
# ADD NFO FUNCTIONS #
######################
set lastaddnfo ""
proc bot:addnfo {frombot command arg} {
    global db2 lastaddnfo
    set rls [lindex $arg 0]
    if { [string length $rls] < 5 || [string length [lindex $arg 1]] < 5 || [string length [lindex $arg 2]] < 4 } { return }
    if {$lastaddnfo == $rls} { return }
    set lastaddnfo $rls
    set database [findpre $rls]
    if {$database == "error"} { putlog "NFO added from $frombot but pre [lindex $arg 0] not in database. Link: [lindex $arg 1]"; get_old [lindex $arg 0]; timer 1 [list bot:addnfo $frombot $command $arg]; return }
    set id [lindex [lindex [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0] 0]
    if {[mysqlsel $db2 "SELECT count(*) FROM `nfo` WHERE `id` = '$id';" -list]} { return }
    exec /home/mainbot/insert [lindex $arg 0] [lindex $arg 1] [lindex $arg 2] &
    putlog "NFO added for release [lindex $arg 0] from $frombot Link: [lindex $arg 1]"
}

set lastaddjpg ""
proc bot:addjpg {frombot command arg} {
    global db2 lastaddjpg
    set rls [lindex $arg 0]
    if { [string length $rls] < 5 || [string length [lindex $arg 1]] < 5 || [string length [lindex $arg 2]] < 4 } { return }
    if {$lastaddjpg == $rls} { return }
    set lastaddjpg $rls
    set database [findpre $rls]
    if {$database == "error"} { putlog "JPG added from $frombot but pre [lindex $arg 0] not in database. Link: [lindex $arg 1]"; get_old [lindex $arg 0]; timer 1 [list bot:addjpg $frombot $command $arg]; return }
    set id [lindex [lindex [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0] 0]
    if {[mysqlsel $db2 "SELECT count(*) FROM `samplejpg` WHERE `id` = '$id';" -list]} { return }
    exec /home/mainbot/insert2 [lindex $arg 0] [lindex $arg 1] [lindex $arg 2] &
    putlog "JPG added for release [lindex $arg 0] from $frombot Link: [lindex $arg 1]"
}

proc bot_sendnfo { frombot command arg} {
    set password ""
    set expiry [expr [unixtime] + 600]
    set hash [md5 $password$expiry]
    set nindex [lindex $arg 0]
    set url [::base64::encode $nindex:$hash:$expiry]
    regsub -all "=" $url "" url
    set url "[lindex $url 0][lindex $url 1]"
    if {[islinked leafBot]} { tmsg bot "!saypre #addnfo :" leafBot "!addnfo [lindex $arg 1] /?$url=download [lindex $arg 2]"}
    putlog "NFO sent for release [lindex $arg 1]"
}

proc bot_sendjpg { frombot command arg} {
    set password ""
    set expiry [expr [unixtime] + 600]
    set hash [md5 $password$expiry]
    set nindex [lindex $arg 0]
    set url [::base64::encode $nindex:$hash:$expiry]
    regsub -all "=" $url "" url
    set url "jpgview.php?[lindex $url 0][lindex $url 1]"
    if {[islinked leafBot]} { tmsg bot "!saypre #addnfo :" leafBot "!addjpg [lindex $arg 1] $url [lindex $arg 2]"}
    putlog "JPG sent for release [lindex $arg 1]"
}

######################
# ADD INFO FUNCTIONS #
######################

proc chgtime {nick uhost hand chan arg} {
 global db2
 set rls [lindex $arg 0]
 set newtime [lindex $arg 1]
 set override 0
 if {[lindex $arg 0] == "-o"} {
	set override 1
	set rls [lindex $arg 1]
	set newtime [lindex $arg 2]
 }
 if {$newtime == ""} {  putnow "PRIVMSG $chan :\[7UPDATE\] Invalid Time \[0 row(s) affected\]"  ; return}
 if {[findpre $rls] == "error"} { putnow "PRIVMSG $chan :\[7UPDATE\] Release not found \[0 row(s) affected\]"; return }
 set release [lindex [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0]
 if {[lindex $release 3] < $newtime && $override == 0} { putnow "PRIVMSG $chan :\[7UPDATE\] Pretime in db is older \[0 row(s) affected\]"; return }
 set results [mysqlexec $db2 "UPDATE pre SET pretime='$newtime' WHERE title='$rls'"]
 if {$results != 0} { set line "Changed pretime for release $rls to $newtime" } else { set line "Error invalid time" }
 putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc chggnr {nick uhost hand chan arg} {
 global db2
 set rls [lindex $arg 0]
 set newgnr [lindex $arg 1]
 if {![gnrok $rls $newgnr] && $newgnr != ""} {  putnow "PRIVMSG $chan :\[7UPDATE\] Invalid Genre \[0 row(s) affected\]"  ; return}
 set results [mysqlexec $db2 "UPDATE pre SET Genre='$newgnr' WHERE title='$rls' LIMIT 1"]
 if {$results != 0} { set line "Changed genre for release $rls to $newgnr" } else { set line "$rls was not found in database" }
 putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc chgcase {nick uhost hand chan arg} {
 global db2
 set rls [lindex $arg 0]
 set newrls [lindex $arg 1]
 if {[string tolower $rls] != [string tolower $newrls]} { putnow "PRIVMSG $chan :\[7UPDATE\] Not the same release name cannot update case \[0 row(s) affected\]"  ; return}
 set results [mysqlexec $db2 "UPDATE pre SET title='$newrls' WHERE title='$rls' LIMIT 1"]
 if {$results != 0} { set line "Changed case for release $rls to $newrls" } else { set line "$rls was not found in database" }
 putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc chginfo {nick uhost hand chan arg} {
 global db2
 set rls [lindex $arg 0]
 set newfile [lindex $arg 1]
 set newsize [lindex $arg 2]
 if {$newfile == "" || $newsize == ""} {  putnow "PRIVMSG $chan :\[7UPDATE\] Invalid file and size info \[0 row(s) affected\]"  ; return}
 set final ""
 if {$newfile != 0} { set final "files='$newfile'" }
 if {$newsize != 0} { set final "rlssize='$newsize'" }
 if {$newsize != 0 && $newfile != 0} { set final "files='$newfile', rlssize='$newsize'" }
 set results [mysqlexec $db2 "UPDATE pre SET $final WHERE title='$rls' LIMIT 1"]
 if {$results != 0} { set line "Changed info for release $rls to $newfile F $newsize MB" } else { set line "$rls was not found in database" }
 putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc bot_chgsec {frombot command arg} {
 global db2
 set rls [lindex $arg 0]
 set newsec [lindex $arg 1]
 set newsec [fixtype $rls $newsec]
 set results [mysqlexec $db2 "UPDATE pre SET cat='$newsec' WHERE title='$rls' LIMIT 1"]
 if {$results != 0} { putnow "PRIVMSG #Pre :\[7UPDATE\] Changed section for release $rls to $newsec \[$results row(s) affected\]" } else { putlog "Invalid section $newsec from $frombot for release $rls" }
}

proc chgsec {nick uhost hand chan arg} {
 global db2
 set rls [lindex $arg 0]
 set newsec [string toupper [lindex $arg 1]]
 if {[type_check $newsec]} {
   putnow "PRIVMSG $chan :\[7UPDATE\] Invalid section $newsec \[0 row(s) affected\]"
   return
 }
 set results [mysqlexec $db2 "UPDATE pre SET cat='$newsec' WHERE title='$rls' LIMIT 1"]
 if {$results != 0} { set line "Changed section for release $rls to $newsec" } else { set line "$rls was not found in database" }
 putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc chgsec2 {nick uhost hand chan arg} {
 global db2
 set oldsec [lindex $arg 0]
 set newsec [lindex $arg 1]
 set results [mysqlexec $db2 "UPDATE pre SET cat='$newsec' WHERE cat='$oldsec'"]
 putnow "PRIVMSG $chan :\[7UPDATE\] Changed all releases with section $oldsec to $newsec \[$results row(s) affected\]"
}

proc chgsec3 {nick uhost hand chan arg} {
 global db2
 set premask [lindex $arg 0]
 set newsec [lindex $arg 1]
 set oldsec [lindex $arg 2]
 set premask [string map {* %} $premask]
 if {[type_check $newsec]} {
   putnow "PRIVMSG $chan :\[7UPDATE\] Invalid section $newsec \[0 row(s) affected\]"
   return
 }
 if {$oldsec != ""} { set oldsec "AND cat='$oldsec'" }
 set results [mysqlexec $db2 "UPDATE pre SET cat='$newsec' WHERE title LIKE '$premask' $oldsec"]
 putnow "PRIVMSG $chan :\[7UPDATE\] Changed all releases with title $premask to $newsec \[$results row(s) affected\]"
}

proc msg:addinfo {nick uhost hand arg} {
 set rls [lindex $arg 0]
 set info [lindex $arg 2]
 addinfo_done $nick [lindex $arg 1] $rls $info
}

proc bot:addinfo {frombot command arg} {
 set rls [lindex $arg 0]
 set info [lindex $arg 2]
 addinfo_done $frombot [lindex $arg 1] $rls $info
}

proc bot:addinfo2 {frombot command arg} {
 set rls [lindex $arg 0]
 set info [lrange $arg 1 2]
 addinfo_done $frombot fs $rls $info
}

proc bot:updates {frombot command arg} {
 global db2
 set rls [lindex $arg 0]
 set size [lindex $arg 1]
 addinfo_done $frombot "size" $rls $size
}

proc addinfo_done {from infot rls info} {
 global db2
 set sitepre 0
 if {$infot == "genre"} {
  set info [fixgenre $rls $info]
  if {$info == "" || [gnrok $rls $info] == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 6] != ""} { return }
  mysqlexec $db2 "UPDATE pre SET Genre='$info' WHERE title='$rls'"
 }
 if {$infot == "size"} {
  regsub -all {[^0-9\.]} $info "" info
  if {$info == "" || $info == 0 || $info > 10000} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 7] != "0"} { return }
  mysqlexec $db2 "UPDATE pre SET rlssize='$info' WHERE title='$rls'"
 }
 if {$infot == "files"} {
  regsub -all {[^0-9\.]} $info "" info
  if {$info == "" || $info == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 8] != "0"} { return }
  mysqlexec $db2 "UPDATE pre SET files='$info' WHERE title='$rls'"
 }
 if {$infot == "fs2"} {
  set infot "fs"
  set sitepre 1
 }
 if {$infot == "fs"} {
  set files [lindex $info 0]
  set size [lindex $info 1]
  regsub -all {[^0-9\.]} $files "" files
  regsub -all {[^0-9\.]} $size "" size
  if {$size == "" || $size == 0 || $size > 10000 || $files == "" || $files == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [lindex [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$rls';" -list] 0]
  if {[lindex $iCount 7] != "0" && [lindex $iCount 8] != "0"} { return }
  mysqlexec $db2 "UPDATE pre SET rlssize='$size', files='$files' WHERE title='$rls'"
  if {$sitepre == 0 } {
  }
 }
 if {$sitepre == 0} {
  putlog "Pre info updated from $from for release $rls. Now $infot is set to: $info"
 }
}

#####################################
# NUKELOCK FUNCTIONS                #
#####################################

proc nukelock {nick uhost hand chan arg} {
 global db2 toffset
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $arg "" nukerls
 if {[findpre $nukerls] == "error"} { return }
 set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
 if {$iCount == "0"} { return }
 if {[lindex [mysqlnext $db2] 10] == "1000"} { return }
 mysqlendquery $db2
 mysqlexec $db2 "UPDATE pre SET nukelock='1000' WHERE title='$nukerls'"
 putlog "$nukerls Locked by $nick in $chan"
 putnow "PRIVMSG #Pre :\[7NUKELOCK\] \[$nukerls\] ([strftime "%H:%M:%S " [expr [unixtime] +$toffset] ]CET)"
}

proc unnukelock {nick uhost hand chan arg} {
 global db2 toffset
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $arg "" nukerls
 if {[findpre $nukerls] == "error"} { return }
 set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
 if {$iCount == "0"} { return }
 if {[lindex [mysqlnext $db2] 10] != "1000"} { return }
 mysqlendquery $db2
 mysqlexec $db2 "UPDATE pre SET nukelock='0' WHERE title='$nukerls'"
 putlog "$nukerls Unlocked by $nick in $chan"
 putnow "PRIVMSG #Pre :\[7UNNUKELOCK\] \[$nukerls\] ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

#####################################
# NUKE FUNCTIONS                    #
#####################################

proc modnuke {nick uhost hand chan arg} {
 modnukeproc $nick $uhost $hand $chan [lindex $arg 1] [lindex $arg 0]
}

proc modnuke2 {frombot command arg} {
 set nick [lindex $arg 0]
 set chan [lindex $arg 1]
 set arg [lrange $arg 2 end]
 modnukeproc $nick bob bob $chan [lindex $arg 1] [lindex $arg 0]
}

proc modnukeproc {nick uhost hand chan nukersn nukerls} {
 global db2 toffset
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukerls "" nukerls
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukersn "" nukersn
 if {[findpre $nukerls] == "error"} { return }
 set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
 if {$iCount == "0"} { return }
 set next [mysqlnext $db2]
 set nuketime [lindex $next 4]
 set pretime [lindex $next 3]
 set nukersn2 [lindex $next 5]
 set nukelock [lindex $next 10]
 mysqlendquery $db2
 if { $nukersn == $nukersn2 || $nuketime == "0" || $nukelock == "1000"} { return }
 if {$nukelock > 4} {
  mysqlexec $db2 "UPDATE pre SET nukelock='1000' WHERE title='$nukerls'"
  putlog "$nukerls Auto Locked"
  putnow "PRIVMSG #Pre :\[7AUTO-NUKELOCK\] \[$nukerls\] ([strftime "%H:%M:%S " [expr [unixtime] +$toffset] ]CET)"
  return
 }
 mysqlexec $db2 "UPDATE pre SET nuketime='[unixtime]', nukereason='$nukersn', nukelock='[expr $nukelock + 1]' WHERE title='$nukerls'"
 putlog "$nukerls Nuked by $nick in $chan"
 putnow "PRIVMSG #Pre :\[5MODNUKE\] \[$nukerls\] Reason: $nukersn ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

proc addnuke {nick uhost hand chan arg} {
 nukeproc $nick $uhost $hand $chan [lindex $arg 1] [lindex $arg 0]
}

proc delnuke {nick uhost hand chan arg} {
 unnukeproc $nick bob bob $chan [lindex $arg 1] [lindex $arg 0]
}

proc addnuke2 {frombot command arg} {
 set nick [lindex $arg 0]
 set chan [lindex $arg 1]
 set arg [lrange $arg 2 end]
 nukeproc $nick bob bob $chan [lindex $arg 1] [lindex $arg 0]
}

proc delnuke2 {frombot command arg} {
 set nick [lindex $arg 0]
 set chan [lindex $arg 1]
 set arg [lrange $arg 2 end]
 unnukeproc $nick bob bob $chan [lindex $arg 1] [lindex $arg 0]
}

proc nukeproc {nick uhost hand chan nukersn nukerls} {
 global db2 toffset
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukerls "" nukerls
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukersn "" nukersn
 if {[string match {auto.nuke*} $nukersn] != 0} {return}
 if {[string match {satrip.is.forbidden.use.dtv.instead} $nukersn] != 0} {return}
 if {[string match {not.valid.with.hcr.rules.bad.dirname.bad.broadcast} $nukersn] != 0} {return}
 if {[string match {*autonuke(forbidden.word)*} $nukersn] != 0} {return}
 if {[string match {*Autonuke.Bad.Echo.Bad.Dir.Name.Sort.Your.Scripts*} $nukersn] != 0} {return}
 if {[string match {*autonuke.missing.letter(fix.your.scripts)*} $nukersn] != 0} {return}
 if {[string match {fake(autonuke.(v*)-*)*} $nukersn] != 0 || [string match {fake(rlz.must.be.*} $nukersn] != 0 || [string match {*fake(pre.spam)*} $nukersn] != 0 || [string match {*Auto.Nuke-Bad.Echo.Sort.Your.Damn.Scripts*} $nukersn] != 0 || [string match {**Autonuke.Possibility.Of.Nuke.First.Char.Must.Be.Upper**} $nukersn] != 0} {
  bot:delpre bob bob "$nukerls"
  return
 }
 if {[findpre $nukerls] == "error"} { return }
 set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
 if {$iCount == "0"} { return }
 set next [mysqlnext $db2]
 set nuketime [lindex $next 4]
 set pretime [lindex $next 3]
 set nukelock [lindex $next 10]
 mysqlendquery $db2
 if { $nuketime != "0" || $nukelock == "1000"} { return }
 if {$nukelock > 4} {
  mysqlexec $db2 "UPDATE pre SET nukelock='1000' WHERE title='$nukerls'"
  putlog "$nukerls Auto Locked"
  putnow "PRIVMSG #Pre :\[7AUTO-NUKELOCK\] \[$nukerls\] ([strftime "%H:%M:%S " [expr [unixtime] +$toffset] ]CET)"
  return
 }
 mysqlexec $db2 "UPDATE pre SET nuketime='[unixtime]', nukereason='$nukersn', nukelock='[expr $nukelock + 1]' WHERE title='$nukerls'"
 putlog "$nukerls Nuked by $nick in $chan"
 putnow "PRIVMSG #Pre :\[4NUKED\] \[$nukerls\] Reason: $nukersn ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

proc unnukeproc {nick uhost hand chan nukersn nukerls} {
 global db2 toffset
 if {[string match {*Someone.forgot.the.reason*} $nukersn] != 0} {return}
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukerls "" nukerls
 regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukersn "" nukersn
 if {[findpre $nukerls] == "error"} { return }
 set iCount [mysqlsel $db2 "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
 if {$iCount == "0"} { return }
 set next [mysqlnext $db2]
 set nuketime [lindex $next 4]
 set pretime [lindex $next 3]
 set nukelock [lindex $next 10]
 set nukersn2 [lindex $next 5]
 mysqlendquery $db2
 if { $nukersn == $nukersn2 || $nuketime == "0" || $nukelock == "1000"} { return }
 if { [expr [unixtime] - $nuketime] < 10 } { putlog "$nukerls attempted Unnuke by $nick in $chan too soon."; return }
 mysqlexec $db2 "UPDATE pre SET nuketime='0', nukereason='', nukelock='[expr $nukelock + 1]' WHERE title='$nukerls'"
 putlog "$nukerls Unnuked by $nick in $chan"
 putnow "PRIVMSG #Pre :\[3UNNUKED\] \[$nukerls\] Reason: $nukersn Previous Reason: $nukersn2 ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

init
