# Pre Filter

#Bind commands
bind pub A !freload freload_chan
bind pub A !tflist tflist_list
bind bot - !tflist_add tflist_add
bind bot - !tflist_del tflist_del
bind pub A !tflist_add tflist_add_pub
bind pub A !tflist_del tflist_del_pub


proc freload_chan {nick hand uhost chan arg} { freload 1 }

proc tflist_add_pub { nick uhost handle chan arg } { tflist_add $nick "!tflist_add" $arg }

proc tflist_del_pub { nick uhost handle chan arg } { tflist_del $nick "!tflist_del" $arg }

proc freload {isChan} {
	global ::flist ::tflist
	set fid [open filterlist.tcl r]
	set list [split [read $fid] \n];
	close $fid
	set ::flist {}
	set ::tflist {}
	foreach filter $list {
		if {[regexp -- {^[#].+$} $filter]} {continue}
		if {[string length $filter] < 2} {continue}
		lappend ::flist $filter
	}
	if ($isChan) { putquick "PRIVMSG #repair :\[7FILTERS\] Filter list reloaded." }
}

proc tflist_add { frombot command arg } {
  global ::tflist
  set index [lsearch $::tflist $arg]
  if {$index == -1} {
    lappend ::tflist $arg
    timer 15 "tflist_del $frombot auto $arg"
    putquick "PRIVMSG #repair :\[4TEMPFILTER\] $arg added.  Removal scheduled for 15m. ([insert date [unixtime]])"
  } else {
    putquick "PRIVMSG #repair :\[4TEMPFILTER\] $arg already exists. (insert date [unixtime]])"
  }
}

proc tflist_del { frombot command arg } {
  global ::tflist
  set index [lsearch $::tflist $arg]
  if {$index != -1} {
    set ::tflist [lreplace $::tflist $index $index]
    putquick "PRIVMSG #repair :\[4TEMPFILTER\] $arg removed. ([insert date [unixtime]])"
  } else {
    putquick "PRIVMSG #repair :\[4TEMPFILTER\] $arg not found. ([insert date [unixtime]])"
  }
}

proc tflist_list { nick uhost handle chan arg } {
  global ::tflist
  set x 0
  foreach {filter} $::tflist {
    incr x
    putquick "PRIVMSG $chan :\[4TEMPFILTER\] Filter #$x $filter"
  }
  if {$x == 0} {
    putquick "PRIVMSG $chan :\[4TEMPFILTER\] No temp filters found. ([insert date [unixtime]])"
  } else {
    putquick "PRIVMSG $chan :\[4TEMPFILTER\] $x filters listed. ([insert date [unixtime]])"
  }
}

proc gnrok { rls genre } {
	set genre [string totitle $genre]
	if {$genre != "Acoustic" && $genre != "Alternative" && $genre != "Ambient" && $genre != "Avantgarde" && $genre != "Bass" && $genre != "Beat" && $genre != "Blues" && $genre != "Classical" && $genre != "Club" && $genre != "Comedy" && $genre != "Country" && $genre != "Dance" && $genre != "Drum" && $genre != "Drum_&_Bass" && $genre != "Electronic" && $genre != "Ethnic" && $genre != "Folk" && $genre != "Gothic" && $genre != "Hard_Rock" && $genre != "Hardcore" && $genre != "House" && $genre != "Indie" && $genre != "Industrial" && $genre != "Funk" && $genre != "Instrumental" && $genre != "Jazz" && $genre != "Latin" && $genre != "Lo-Fi" && $genre != "Metal" && $genre != "Oldies" && $genre != "Pop" && $genre != "Psychadelic" && $genre != "Punk" && $genre != "R&B" && $genre != "Rap" && $genre != "Reggae" && $genre != "Rock" && $genre != "Soul" && $genre != "Soundtrack" && $genre != "Techno" && $genre != "Top" && $genre != "Trance" && $genre != "Various"} {
	return 0
	}
	return 1
}

proc rlsok { rls section frombot } {
 global ::flist ::tflist db lastrls lastrlscur laststripped
 set x 1
 regsub -all {[\.\-\_\(\)]} $rls "" testrls
 # check for 4 or more repeated groups of chars or numbers
 if {[regexp -nocase {([a-z0-9]+)[-_\.]\1[-_\.]\1[-_\.]\1} $rls repchar]} {
   if {[findpre $rls] == "blocked"} { return 0 }
   putlog "Bad: $rls | Filter: Release name contains repeated chars $repchar | From: $frombot"
   set group [getgroup $rls]
   mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
   putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([insert date [unixtime]])"
   return 0
 }
 # check for 11 or more consonants in a row
 if {[regexp -nocase {[^aeiouy._()0-9-]{11,}} $rls repchar]} {
   if {[findpre $rls] == "blocked"} { return 0 }
   putlog "Bad: $rls | Filter: Release name contains 11+ consonants in a row $repchar | From: $frombot"
   set group [getgroup $rls]
   mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
   putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([insert date [unixtime]])"
   return 0
 }
 # check for unclosed brackets
 if {[regexp -all {\(} $rls] != [regexp -all {\)} $rls]} {
   if {[findpre $rls] == "blocked"} { return 0 }
   putlog "Bad: $rls | Filter: Release name contains unclosed brackets | From: $frombot"
   set group [getgroup $rls]
   mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
   putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([insert date [unixtime]])"
   return 0
 }
 for {set x 1} {$x <= 100} {incr x} {
   if {$testrls == $laststripped($x)} {
     if {[regexp -all {\(} $rls] == 0} {
       if {[findpre $rls] == "blocked"} { return 0 }
 	putlog "Bad: $rls | Filter: Incorrect Seperators | From: $frombot"
       set group [getgroup $rls]
       mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
       putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] \[Incorrect Seperators from: $lastrls($x)\] ([insert date [unixtime]])"
    	return 0
     } elseif {[regexp -all {\(} $rls] != 0 && [regexp -all {\(} $lastrls($x)] == 0} { delpre $frombot $lastrls($x); continue }
   }
   if {[string match *${testrls}* $laststripped($x)]} {
      if {[findpre $rls] == "blocked"} { return 0 }
      putlog "Bad: $rls |Filter: Partial Release Name | From: $frombot"
      set group [getgroup $rls]
      mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
      putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] \[Missing Letters from: $lastrls($x)\] ([insert date [unixtime]])"
      return 0
   }
 }
 foreach filter $::flist {
  if {[regexp -nocase -- $filter $rls]} {
   if {[findpre $rls] == "blocked"} { return 0 }
   putlog "Bad: $rls | Filter: $filter | From: $frombot"
   set group [getgroup $rls]
   mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
   putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([insert date [unixtime]])"
   return 0
  }
 }
 foreach filter $::tflist {
  if {[string match $filter $rls]} {
   if {[findpre $rls] == "blocked"} { return 0 }
   putlog "Bad: $rls | Filter: $filter | From: $frombot"
   set group [getgroup $rls]
   mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
   putnow "PRIVMSG #Repair :\[4BLOCKED\] \[$rls\] ([insert date [unixtime]])"
   return 0
  }
 }
 set laststripped($lastrlscur) $testrls
 set lastrls($lastrlscur) $rls
 incr lastrlscur
 if {$lastrlscur > 100} {
  set lastrlscur 1
 }
 return 1
}

proc fixgenre {rls genre} {
if {$genre == "SoundTrack"} { set genre "Soundtrack" }
if {$genre == "Hip_Hop"} { set genre "Rap" }
if {$genre == "Hip-Hop"} { set genre "Rap" }
if {$genre == "Gangsta"} { set genre "Rap" }
if {$genre == "Gangsta-Rap"} { set genre "Rap" }
if {$genre == "Gangsta_Rap"} { set genre "Rap" }
if {$genre == "Alt."} { set genre "Alternative" }
if {$genre == "Hard"} { set genre "Hard_Rock" }
if {$genre == "Folk_Rock"} { set genre "Folk" }
if {$genre == "Folk-Rock"} { set genre "Folk" }
if {$genre == "Top40"} { set genre "Top" }
if {$genre == "Top-40"} { set genre "Top" }
if {$genre == "BritPop"} { set genre "Pop" }
if {$genre == "R_n_B"} { set genre "R&B" }
if {$genre == "RnB"} { set genre "R&B" }
if {$genre == "Drum_n_Base"} { set genre "Drum_&_Base" }
if {$genre == "Disco"} { set genre "Dance" }
if {$genre == "Jazz+Funk"} { set genre "Jazz" }
if {$genre == "Bhangra"} { set genre "Ethnic" }
if {$genre == "Classic_Rock"} { set genre "Rock" }
if {$genre == "Classic"} { set genre "Classical" }
if {$genre == "Punk_Rock"} { set genre "Punk" }
if {$genre == "Alt.-Rock"} { set genre "Rock" }
return $genre
}

proc fixtype { rls type } {
  set rls [string toupper $rls]
  if {[string match "*0*DAY*" $type] || $type == "UTILS" || $type == "DAY_BOOKWARE" || $type == "DAY" || $type == "ODAY" || $type == "0DAYS" || $type == "ODAYS" || $type == "EBOOKS" || $type == "EBOOK" || $type == "BOOKWARE"} { set type "0DAY" }
  if {$type == "APP-ISO" || $type == "APPS"} { set type "APPS" }
  if {$type == "GAMECUBE"} { set type "GC" }
  if {[string first "MP3" $type] != -1 || $type == "VARIOUS" || $type == "MAXI" || $type == "CD" || $type == "RADIO" || $type == "CD-R"} { set type "MP3" }
  if {[string first "ANIME" $type] != -1} { set type "ANIME" }
  if {[string first "GAME" $type] != -1} { set type "GAMES" }
  if {$type == "MVID" || $type == "MVS" || $type == "MVIDS" || $type == "MUSICVIDEOS"} { set type "MV" }
  if {$type == "MP"} { set type "MP3" }
  if {$type == "ISO-DOCS"} { set type "DOX" }
  if {[string first "DVDR" $type] != -1 || [string first "DVD-R" $type] != -1 || $type == "DVD-NTSC" || $type == "PALCLASSIC" || $type == "DVD-PAL"} { set type "MOVIE-DVDR" }
  if {$type == "SERIES" || [string first "TV" $type] != -1 || [string first "SERIES" $type] != -1} { set type "TV" }
  if {$type == "UTIL" || $type == "ISO-UTIL"} { set type "APPS" }
  if {[string first ".LINUX" $rls] != -1} {set type "APPS"}
  if {[string first "_LINUX" $rls] != -1} {set type "APPS"}
  if {[string first "MAC.OSX" $rls] != -1} {set type "APPS"}
  if {[string first ".CRACKED" $rls] != -1} {set type "0DAY"}
  if {[string first ".INCL.KEYGEN" $rls] != -1} {set type "0DAY"}
  if {[string first "KEYMAKER" $rls] != -1} {set type "0DAY"}
  if {[string first ".REGGED" $rls] != -1} {set type "0DAY"}
  if {[string first ".WINALL" $rls] != -1} {set type "0DAY"}
  if {[string first ".EBOOK" $rls] != -1} {set type "0DAY"}
  if {[string first ".BOOKWARE" $rls] != -1} {set type "0DAY"}
  if {[string first "-AUDIOBOOK" $rls] != -1} {set type "0DAY"}
  if {[string first ".PRESSKIT" $rls] != -1} {set type "0DAY"}
  if {[string first ".PRESSBOOK" $rls] != -1} {set type "0DAY"}
  if {[string first ".PRESSTEXT" $rls] != -1} {set type "0DAY"}
  if {[string first ".IMAGESET" $rls] != -1} {set type "0DAY"}
  if {[string first ".IMGSET" $rls] != -1} {set type "0DAY"}
  if {[string first ".PHOTOSET" $rls] != -1} {set type "0DAY"}
  if {[string first ".FULL.IMG.SETS." $rls] != -1} {set type "0DAY"}
  if {[string first "STUDENT.GUIDE" $rls] != -1} {set type "0DAY"}
  if {[string first ".COVER" $rls] != -1} {set type "COVERS"}
  if {[string first ".DVDCOVER" $rls] != -1} {set type "COVERS"}
  if {[string first "_COVER" $rls] != -1} {set type "COVERS"}
  if {[string first "_DVDCOVER" $rls] != -1} {set type "COVERS"}
  if {[string first ".WIICOVER" $rls] != -1} {set type "COVERS"}
  if {[string first "_NOCD_" $rls] != -1} {set type "DOX"}
  if {[string first ".NOCD." $rls] != -1} {set type "DOX"}
  if {[string first "CHEAT_CODES" $rls] != -1} {set type "DOX"}
  if {[string first "SAVEGAME_EDITOR" $rls] != -1} {set type "DOX"}
  if {[string first "_TRAINER" $rls] != -1} {set type "DOX"}
  if {[string first ".TRAINER" $rls] != -1} {set type "DOX"}
  if {[string first ".ANIME." $rls] != -1} {set type "ANIME"}
  if {[string first "SAMPLER" $rls] != -1} {set type "MP3"}
  if {[string first "PROMO" $rls] != -1} {set type "MP3"}
  if {[string first "VINYL" $rls] != -1} {set type "MP3"}
  if {[string first "-VLS-" $rls] != -1} {set type "MP3"}
  if {[string first "(VLS)" $rls] != -1} {set type "MP3"}
  if {[string first "-RETAIL-199" $rls] != -1} {set type "MP3"}
  if {[string first "-RETAIL-200" $rls] != -1} {set type "MP3"}
  if {[string first "-(RETAIL)-" $rls] != -1} {set type "MP3"}
  if {[string first "_DAB_" $rls] != -1} {set type "MP3"}
  if {[string first "_SAT_" $rls] != -1} {set type "MP3"}
  if {[string first "_CAT_" $rls] != -1} {set type "MP3"}
  if {[string first "_DAT_" $rls] != -1} {set type "MP3"}
  if {[string first "_CABLE_" $rls] != -1} {set type "MP3"}
  if {[string first "-DAB-" $rls] != -1} {set type "MP3"}
  if {[string first "-SAT-" $rls] != -1} {set type "MP3"}
  if {[string first "-CAT-" $rls] != -1} {set type "MP3"}
  if {[string first "-DAT-" $rls] != -1} {set type "MP3"}
  if {[string first "-CABLE-" $rls] != -1} {set type "MP3"}
  if {[string first "-CD-" $rls] != -1} {set type "MP3"}
  if {[string first "OST-" $rls] != -1} {set type "MP3"}
  if {[string first "-EP-" $rls] != -1} {set type "MP3"}
  if {[string first "-LP-" $rls] != -1} {set type "MP3"}
  if {[string first "-2CD-"  $rls] != -1} {set type "MP3"}
  if {[string first "-CDS-" $rls] != -1} {set type "MP3"}
  if {[string first "-CDM-" $rls] != -1} {set type "MP3"}
  if {[string first "(2CD)" $rls] != -1} {set type "MP3"}
  if {[string first "(CDS)" $rls] != -1} {set type "MP3"}
  if {[string first "(CDM)" $rls] != -1} {set type "MP3"}
  if {[string first "-(DAB)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(SAT)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(CAT)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(DAT)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(CABLE)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(CD)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(EP)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(LP)-" $rls] != -1} {set type "MP3"}
  if {[string first "-(BONUS_DVD)-" $rls] != -1} {set type "MP3"}
  if {[string first "DVDR" $type] == 0} {set type "MOVIE-DVDR"}
  if {[string first "SVCD" $type] == 0} {set type "MOVIE-SVCD"}
  if {[string first "VCD" $type] == 0} {set type "MOVIE-VCD"}
  if {[string first "XVID" $type] == 0} {set type "MOVIE-XVID"}
  if {[string first "DIVX" $type] == 0} {set type "MOVIE-DIVX"}
  if {[string first ".DVDRRIP.SVCD" $rls] != -1} {set type "MOVIE-SVCD"}
  if {[string first ".DVDRIP.SVCD" $rls] != -1} {set type "MOVIE-SVCD"}
  if {[string first ".DVDR.PAL" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".FS.DVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".WS.DVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".DVDR.NTSC." $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".PAL.DVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".NTSC.DVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".NTSC.MDVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".PAL.MDVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string match {*.NTSC.R[0-9].DVDR*} $rls]} {set type "MOVIE-DVDR"}
  if {[string match {*.PAL.*.DVDR*} $rls]} {set type "MOVIE-DVDR"}
  if {[string match {*.NTSC.*.DVDR*} $rls]} {set type "MOVIE-DVDR"}
  if {[string first ".DVDR.PAL" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".DVDR-" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".NTSC.COMPLETE" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first ".PAL.COMPLETE" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first "DVDRIP.AC3.XVID" $rls] != -1} {set type "MOVIE-XVID"}
  if {[string first "DVB.XVID.MP3" $rls] != -1} {set type "MOVIE-XVID"}
  if {[string first "TELESYNC" $rls] != -1} {set type "MOVIE-VCD"}
  if {[string first "TELECINE" $rls] != -1} {set type "MOVIE-VCD"}
  if {[string first "TS.SVCD" $rls] != -1} {set type "MOVIE-VCD"}
  if {[string first "TC.SVCD" $rls] != -1} {set type "MOVIE-VCD"}
  if {[string first "TC.DVDR" $rls] != -1} {set type "MOVIE-DVDR"}
  if {[string first "BLURAY.X264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "BDRIP.X264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "1080P.HDTV.H264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "DVD5.720P.BLURAY.X264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "DVDRIP.X264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "DVDRIP.AC3.X264" $rls] != -1} {set type "MOVIE-X264"}
  if {[string first "_XBOX-" $rls] != -1} {set type "XBOX"}
  if {[string first "_PS2" $rls] != -1} {set type "PS2"}
  if {[string first "XBOX_DVD" $rls] != -1} {set type "XBOX"}
  if {[string first "DVD.XBOX" $rls] != -1} {set type "XBOX"}
  if {[string first "PS2_DVD" $rls] != -1} {set type "PS2"}
  if {[string first "XBOXDVD" $rls] != -1} {set type "XBOX"}
  if {[string first "PS2DVD" $rls] != -1} {set type "PS2"}
  if {[string first ".HDTV" $rls] != -1} {set type "TV"}
  if {[string first "_HDTV" $rls] != -1} {set type "TV"}
  if {[string match {*.[0-9]X[0-9][0-9]*DVB.XVID.MP3*ES*} $rls]} {set type "TV"}
  if {[string match {*.S[0-9][0-9]E[0-9][0-9]*} $rls]} {set type "TV"}
  if {[string match {*.S[0-9][0-9].*} $rls]} {set type "TV"}
  if {[string match {*.E[0-9][0-9].*} $rls]} {set type "TV"}
  if {[string match {*.[0-9]x[0-9][0-9].*} $rls]} {set type "TV"}
  if {[string first "TVRIP" $rls] != -1} {set type "TV"}
  if {[string match {*.EP.[0-9][0-9].*} $rls]} {set type "TV"}
  if {[string match {*.EP[0-9][0-9].*} $rls]} {set type "TV"}
  if {[string first ".DSR." $rls] != -1} {set type "TV"}
  if {[string first ".SATRIP." $rls] != -1} {set type "TV"}
  if {[string first "_DTV_" $rls] != -1} {set type "TV"}
  if {[string first ".DTV." $rls] != -1} {set type "TV"}
  if {[string first ".PDTV." $rls] != -1} {set type "TV"}
  if {[string match {*DSRIP.XVID-AAF} $rls]} {set type "TV"}
  if {$type == "TV" && [string first ".XVID" $rls] != -1} {set type "TV-XVID"}
  if {[regexp {SEASON(.|_)[0-9]+(.|_)DISC(.|_)[0-9]+(.|_)*(.|_)DVDR(.|_|-)} $rls] == 1} {set type "TV-DVDR"}
  if {[regexp {SEASON[0-9]+(.|_)DISC[0-9]+(.|_)*(.|_)DVDR(.|_|-)} $rls] == 1} {set type "TV-DVDR"}
  if {[regexp {S[0-9]+(.|_)D[0-9]+(.|_)*(.|_)DVDR(.|_|-)} $rls] == 1} {set type "TV-DVDR"}
  if {[regexp {S[0-9]+D[0-9]+(.|_)*(.|_)DVDR(.|_|-)} $rls] == 1} {set type "TV-DVDR"}
  if {[regexp {SET[0-9]+VOL[0-9]+(.|_)*(.|_)DVDR(.|_|-)} $rls] == 1} {set type "TV-DVDR"}
  if {$type == "TV" && ([string first ".X264" $rls] != -1 || [string first ".720P." $rls] != -1 || [string first ".1080P." $rls] != -1)} {set type "TV-X264"}
  if {[string first "XXX" $rls] != -1} {set type "XXX"}
  if {[string first ".JAV." $rls] != -1} {set type "XXX"}
  if {[string match {*_NDS-*} $rls]} {set type "NDS"}
  if {[string match {*_PSP-*} $rls]} {set type "PSP"}
  if {[string first "-PSPMV-" $rls] != -1} {set type "PSP"}
  if {[string first "PSP.MP4" $rls] != -1} {set type "PSP"}
  if {[string first "MP4.PSP" $rls] != -1} {set type "PSP"}
  if {[string first "JPN_PS3" $rls] != -1} {set type "PS3"}
  if {[string first "EUR.PS3" $rls] != -1} {set type "PS3"}
  if {[string first "PS3-EMiNENT" $rls] != -1} {set type "PS3"}
  if {[string first "USA_BLURAY" $rls] != -1} {set type "PS3"}
  if {[string first "NTSC_PS3BD" $rls] != -1} {set type "PS3"}
  if {[string first "JAP.BLURAY.PS3" $rls] != -1} {set type "PS3"}
  if {[string first "USA_BLUERAY_PS3" $rls] != -1} {set type "PS3"}
  if {[string first "USA_PS3" $rls] != -1} {set type "PS3"}
  if {[string first "JAP_PS3" $rls] != -1} {set type "PS3"}
  if {[string first "PS3.BD.USA" $rls] != -1} {set type "PS3"}
  if {[string first "WIICLONE" $rls] != -1} {set type "WII"}
  if {[string first "WII.PAL" $rls] != -1} {set type "WII"}
  if {[string first "WII_PAL" $rls] != -1} {set type "WII"}
  if {[string first "USA_WII" $rls] != -1} {set type "WII"}
  if {[string first "NTSC_WII" $rls] != -1} {set type "WII"}
  if {[string first "PAL_WII" $rls] != -1} {set type "WII"}
  if {[string first "WII-" $rls] != -1} {set type "WII"}
  if {[string first ".PPC-" $rls] != -1} {set type "PDA"}
  if {[string first ".PPC." $rls] != -1} {set type "PDA"}
  if {[string match {*-MV4U} $rls]} {set type "MV"}
  if {[string match {*FT.*-*SVCD*-*} $rls]} {set type "MV"}
  if {[string match {*FEAT.*-*SVCD*-*} $rls]} {set type "MV"}
  if {[string match {*-*LIVE*SVCD*-*} $rls]} {set type "MV"}
  if {[string match {*.MDVDR-*} $rls]} {set type "MV-DVDR"}
  if {[string match {*.MDVDR.*} $rls]} {set type "MV-DVDR"}
  if {[string match {*.MVDVDR.*} $rls]} {set type "MV-DVDR"}
  if {[string match {*.MVDVDR-*} $rls]} {set type "MV-DVDR"}
  if {[string first ".TRAILER." $rls] != -1} {set type "TRAILER"}
  if {[type_check $type]} {
    putlog "Unknown Type for $rls orginal section was $type"
    set type "-"
  }
  return $type
}

proc type_check { type } {
	set type [string toupper $type]
	if {$type != "0DAY" && $type != "ANIME" && $type != "APPS" && $type != "BD" && $type != "COVERS" && $type != "MOVIE-DIVX" && $type != "DOX" && $type != "MOVIE-DVDR" && $type != "GC" && $type != "GAMES" && $type != "GBA" && $type != "HDDVD" && $type != "MP3" && $type != "MV" && $type != "MV-DVDR" && $type != "NDS" && $type != "PDA" && $type != "PS2" && $type != "PS3" && $type != "PSP" && $type != "MOVIE-SVCD" && $type != "TV" && $type != "TV-XVID" && $type != "TV-DVDR" && $type != "TV-X264" && $type != "MOVIE-VCD" && $type != "WII" && $type != "XBOX" && $type != "X360" && $type != "XXX" && $type != "TRAILER" && $type != "MOVIE-XVID" && $type != "MOVIE-X264" && $type != "MOVIE"} {
		return 1
	}
	return 0
}

putlog "Prefilter for PreScript Loaded"
