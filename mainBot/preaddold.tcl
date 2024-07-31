#addold.tcl v2006.06.11
#Written for MySQLTcl

bind pub A !addoldline pubaddoldline
bind pub AC !addoldpre addoldpre2
bind pub K !preplay pubpreplay
bind bot - !missing botaddoldline
bind bot - !oldadd addoldpre
bind bot - !addold addoldpre3
bind bot - !getold getoldpre
bind bot - !preplay botpreplay

set lastold ""

proc botaddoldline {bot command arg} {
    putlog "Checking pre for bot $bot for release $arg"
    if {[islinked $bot]} { putbot $bot "[getoldline $arg]" }
}

proc pubaddoldline { nick uhost handle chan arg } {
    putlog "Checking pre for $nick for release $arg"
    putnow "PRIVMSG $chan :[getoldline $arg]"
}

proc getoldline { rls } {
  global db
  set rls "[string map {"'" "" "\\" ""} $rls]"
  set database [findpre $rls]
  if {$database != "pre"} {
    return "$rls not found."
  } else {
    set result [lindex [mysqlsel $db "SELECT * FROM `pre` WHERE `title` = '$rls';" -list] 0]
    if {[lindex $result 5] == "" || [lindex $result 4] == "0"} { set nukersn "-" } else { set nukersn "[lindex $result 5]"}
    return "!oldadd [lindex $result 2] [lindex $result 3] [lindex $result 1] $nukersn [lindex $result 8] [lindex $result 7]"
  }
}

proc getoldpre {bot command arg} {
  global db
  set chan [lindex $arg 0]
  set rls [lindex $arg 1]
  set rls "[string map {"'" "" "\\" ""} $rls]"
  set database [findpre $rls]
  if {$database != "pre"} {
    return "$rls not found."
  } else {
    set result [lindex [mysqlsel $db "SELECT * FROM `pre` WHERE `title` = '$rls';" -list] 0]
    if {[lindex $result 5] == "" || [lindex $result 4] == "0"} { set nukersn "-" } else { set nukersn "[lindex $result 5]"}
    if {[lindex $result 6] == ""} { set genre "-" } else { set genre "[lindex $result 6]"}
    if {[lindex $result 6] != "" && [lindex $result 1] != "MP3"} { set genre "-" }
    if {[lindex $result 8] == "0"} { set file "-" } else { set file "[lindex $result 8]"}
    if {[lindex $result 7] == "0"} { set size "-" } else { set size "[lindex $result 7]"}
    if {[islinked $bot]} { tmsg bot "!saypre $chan :" $bot "!addold [lindex $result 2] [lindex $result 1] [lindex $result 3] $file $size $genre $nukersn" }
  }
}

proc botpreplay {bot command arg} {
  putlog "Running preplay from $bot with command: $arg"
  preplay "" $bot "!saypre [lindex $arg 0] :" bot "" [lindex $arg 1]
}

proc pubpreplay { nick uhost handle chan arg } {
  putlog "Running preplay from $chan with command: $arg"
  preplay $nick $chan privmsg pub $chan $arg
}

proc preplay {nick to form ttype chan arg} {
  global db
  set files "0"
  set command [lindex $arg 0]
  if {$command == "--day"} {

    if {[lindex $arg 1] == "--files"} {
        set files "1"
        set day [lindex $arg 2]
        set query "SELECT `id`,`title`,`nfo`.`filename`,`samplejpg`.`filename` FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE `nfo`.`id`!='' AND `samplejpg`.`id`!='' AND FROM_UNIXTIME(`pretime`,'%Y-%m-%d') = '$day';"
      } else {
        set day [lindex $arg 1]
        set query "SELECT * FROM `pre` WHERE FROM_UNIXTIME(`pretime`,'%Y-%m-%d') = '$day';"
      }

  } elseif {$command == "--between"} {

    if {[lindex $arg 1] == "--files"} {
        set files "1"
        set start [lindex $arg 2]
        set end [lindex $arg 3]
        set offset [lindex $arg 4]
        if {$offset == ""} {set offset "0"}
        set query "SELECT `id`,`title`,`nfo`.`filename`,`samplejpg`.`filename` FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE `nfo`.`id`!='' AND `samplejpg`.`id`!='' AND `pretime` BETWEEN (SELECT `pretime` FROM `pre` WHERE `title`='$start') AND (SELECT `pretime` FROM `pre` WHERE `title`='$end') LIMIT $offset,18446744073709551615;"

      } else {
        set start [lindex $arg 1]
        set end [lindex $arg 2]
        set offset [lindex $arg 3]
        if {$offset == ""} {set offset "0"}
        set query "SELECT * FROM `pre` WHERE `pretime` BETWEEN (SELECT `pretime` FROM `pre` WHERE `title`='$start') AND (SELECT `pretime` FROM `pre` WHERE `title`='$end') LIMIT $offset,18446744073709551615;"
      }
  } else {

    if {[lindex $arg 0] == "--files"} {
        set files "1"
        set search [regsub -all {[^a-zA-Z0-9\%\?\-\.\_()\\]} [string map {_ \\_ ? _ * % " " %} [lindex $arg 1]] ""]
        set offset [lindex $arg 2]
        if {$offset == ""} {set offset "0"}
        set query "SELECT `id`,`title`,`nfo`.`filename`,`samplejpg`.`filename` FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE `nfo`.`id`!='' AND `samplejpg`.`id`!='' AND `title` LIKE '$search' LIMIT $offset,18446744073709551615;"
      } else {
        set search [regsub -all {[^a-zA-Z0-9\%\?\-\.\_()\\]} [string map {_ \\_ ? _ * % " " %} [lindex $arg 0]] ""]
        set offset [lindex $arg 1]
        if {$offset == ""} {set offset "0"}
        set query "SELECT * FROM `pre` WHERE `title` LIKE '$search' LIMIT $offset,18446744073709551615;"
      }

  }

  #Query the database and requery blocked/deleted queries if no results found. If still no results then request an addold when possible then terminate.
  set numreleases [::mysql::sel $db $query]
  for {set i 0} {$i < $numreleases} {incr i} {
    if {$files == "1"} {
      lassign [::mysql::fetch $db] id title nfile jfile
      set password "secretpasswordhere"
      set expiry [expr [unixtime] + 600]
      set hash [md5 $password$expiry]
      set url [::base64::encode $id:$hash:$expiry]
      regsub -all "=" $url "" url

      set nurl "http://NFO_SERVER_URL/?[lindex $url 0][lindex $url 1]=download"
      set jurl "http://NFO_SERVER_URL/jpgview.php?[lindex $url 0][lindex $url 1]OmltYWdlOjA="

      tmsg $ttype $form $to "!oldnfo $title $nurl $nfile"
      tmsg $ttype $form $to "!oldjpg $title $jurl $jfile"
    } else {
      lassign [::mysql::fetch $db] id type title time nuketime nrsn genre weight file grp nlock blocked nfound sfound

      if {$nrsn == "" || $nuketime == "0"} { set nrsn "-" }
      if {$genre == ""} { set genre "-" }
      if {$genre != "" && $type != "MP3"} { set genre "-" }
      if {$file == "0"} { set file "-" }
      if {$weight == "0"} { set weight "-" }
      tmsg $ttype $form $to "!addold $title $type $time $file $weight $genre $nrsn"
    }
  }

  mysqlendquery $db
}

proc addoldpre2 {nick uhost hand chan arg} {
  global db2
  set rls [lindex $arg 0]
  set database [findpre $rls]
  if {$database != "error"} {
    putquick "PRIVMSG $chan :\[7OLDADD\] Pre $rls is already in the database"
    return
  } else {
    set type [string toupper [lindex $arg 1]]
    set type2 [sectionize $rls]
    if {$type2 != "CRAP"} { set type $type2 }
    set type [fixtype $rls $type]
    if {[rlsok $rls $type $nick] == 0} { return 0 }
    set weight [lindex $arg 3]
    set files [lindex $arg 2]
    set time [clock scan "[dur2 [lrange $arg 4 end]] ago"]
    set group [getgroup $rls]
    set result [mysqlexec $db2 "INSERT IGNORE INTO pre VALUES ('','$type','$rls','$time','','','','$weight','$files','$group','','')"]
    if {$result == 0} { return }
    putlog "$rls Added oldpre by $nick"
    putquick "PRIVMSG $chan :\[7OLDADD\] Pre $rls has been added to the database"
    preao $rls $type
  }
}

proc addoldpre {bot command arg} {
  global db2
  set rls [lindex $arg 0]
  set database [findpre $rls]
  if {$database != "error"} {
    return "$rls was found."
  } else {
    if {[lindex $arg 1] <= "315208800" || [lindex $arg 1] > [unixtime]} {
    	return
    }
    set type [string toupper [lindex $arg 2]]
    set type2 [sectionize $rls]
    if {$type2 != "CRAP"} { set type $type2 }
    set type [fixtype $rls $type]
    if {[rlsok $rls $type $bot] == 0} { return 0 }
    if {[lindex $arg 3] == "-"} { set nukersn ""} else { set nukersn [lindex $arg 3]}
    set group [getgroup $rls]
    set result [mysqlexec $db2 "INSERT IGNORE INTO pre VALUES ('','$type','[lindex $arg 0]','[lindex $arg 1]','','$nukersn','','[lindex $arg 5]','[lindex $arg 4]','$group','','')"]
    if {$result == 0} { return }
    putlog "$rls Added oldpre by $bot"
    preao $rls $type
  }
}

proc addoldpre3 {bot command arg} {
  global db2 missingchan
  set rls [lindex $arg 0]
  set database [findpre $rls]
  if {$database != "error"} {
    return "$rls was found."
  } else {
    if {[lindex $arg 2] <= 315208800 || [lindex $arg 2] > [unixtime]} {
    	return
    }
    set type [string toupper [lindex $arg 1]]
    set type2 [sectionize $rls]
    if {$type2 != "CRAP"} { set type $type2 }
    set type [fixtype $rls $type]
    if {[rlsok $rls $type $bot] == 0} { return 0 }
    if {[lindex $arg 6] == "-"} { set nukersn ""} else { set nukersn [lindex $arg 6]}
    if {[lindex $arg 3] == "-"} { set file "0"} else { set file [lindex $arg 3]}
    if {[lindex $arg 4] == "-"} { set size "0"} else { set size [lindex $arg 4]}
    if {[lindex $arg 5] == "-"} { set genre ""} else { set genre [lindex $arg 5]}
    set group [getgroup $rls]
    set result [mysqlexec $db2 "INSERT IGNORE INTO pre VALUES ('','$type','[lindex $arg 0]','[lindex $arg 2]','','$nukersn','$genre','$size','$file','$group','','')"]
    if {$result == 0} { return }
    putlog "$rls Added oldpre by $bot"
    preao $rls $type
  }
}

proc preao { rls type } {
	global db2 db toffset
	set ccode [typecolor $type]
	putnow "PRIVMSG #Announce-Old :\[$ccode\PRE-$type\] $rls ([clock format [expr [unixtime] + $toffset] -format "%Y/%m/%d %T CET" -gmt true])"
}

proc typecolor { type } {
	if {$type == "0DAY" || $type == "PDA"} {return "5"}
	if {$type == "APPS"} {return "4"}
	if {$type == "ANIME" || $type == "TV" || $type == "TV-XVID" || $type == "TV-X264" || $type == "TV-DVDR"} {return "7"}
	if {$type == "COVERS" || $type == "DOX" || $type == "TRAILER"} {return "12"}
	if {$type == "MOVIE-DVDR"} {return "2"}
	if {$type == "MOVIE-XVID" || $type == "MOVIE-X264"} {return "11"}
	if {$type == "MOVIE-VCD" || $type == "MOVIE-SVCD"} {return "10"}
	if {$type == "GAMES"} {return "12"}
	if {$type == "MP3" || $type == "MV" || $type == "MV-DVDR"} {return "3"}
	if {$type == "XXX"} {return "13"}
	if {$type == "NDS" || $type == "PS3"} {return "15"}
	if {$type == "GC" || $type == "GBA"} {return "6"}
	if {$type == "PS2" || $type == "PSP"} {return "14"}
	if {$type == "XBOX" || $type == "X360"} {return "9"}
	return "1"
}

proc get_old {arg} {
	global lastold
	if {$lastold == $arg} { return }
	if {[islinked leafBot]} { tmsg bot "!saypre #addold :" leafBot "!getold $arg" }
	set lastold $arg
}
