#################################################################################
# Precheck Mod
################################################################################
bind bot - !eupdate eupdate
bind bot - !rehash do_rehash
bind bot - !restart do_restart
bind bot - !saypre bot:saypre
bind bot - !saypre2 bot:saypre2
bind bot - !saypre3 bot:saypre3
bind msg - !notify add_notify2
bind pub - !addold pub:addold
bind pub - !getold pub:getold
bind pub - !preplay pub:preplay
bind pub - !addpre pub:addpre
bind pub - !add pub:addpre
bind pub - !nuke pub:nuke
bind pub - !modnuke pub:modnuke
bind pub - !unnuke pub:unnuke
bind pub - !pre checkpre
bind pub - .pre checkpre2
bind pub - !total total
bind pub - !group total
bind pub - !topgroup topgroup
bind pub - !sections list_sections
bind pub - !genres list_genres
bind pub - !latest show_latest
bind pub - !nfo nfolookup
bind pub - !jpg jpglookup
bind pub - !getnfo nfolookup2
bind pub - !prehelp prehelp_proc
bind pub - !listsections valid_sections
bind pub - !listgenres valid_genres
bind pub - !notify add_notify
bind pub - !ndel ndel
bind pub - !nlist nlist
bind pub - !info add_info
bind pub - !gn add_genre
bind pub - !sitepre add_sitepre
bind pub - !delpre delpre
bind pub - !autodel delpre
bind pub - +filter filteradd
bind pub - -filter filterdel
bind pub - !time checktime
bind pub - !addnfo addnfo
bind pub - !addjpg addjpg
bind pub - !oldnfo addnfo
bind pubm - "% \[*DELETE*\] !delpre*" delpre2

# Variables
# Space seperated list
set infochans ""
set addchans ""
set addnfochans ""
set nukechans ""
set siteprechans ""
set addoldchans ""
set delchans ""
set filterchans ""
set prechans ""
set prechans2 ""

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
	global db databaseUser databasePassword databaseDB
	putlog "Presaver for Leaf Bot Loaded"
	if {![info exists db] || ![mysqlstate $db -numeric]} {
		catch {
			load /usr/lib/mysqltcl-3.052/libmysqltcl3.052.so
			set db [[mysqlconnect -host localhost -user $databaseUser -password $databasePassword -db $databaseDB]
      		if {[llength [utimers]] == 0} { utimer 30 mysql_ping }
		} err
	}
}

proc mysql_ping {} {
	global db databaseUser databasePassword databaseDB

	putlog "Checking database connection..."

	if {![::mysql::ping $db]} {
		putlog "MySQL connection lost. Restoring connection..."
		set db2 [mysqlconnect -host localhost -user $databaseUser -password $databasePassword -db $databaseDB]
	}

	utimer 30 mysql_ping
}

init

# Message Routines

proc bot:saypre { frombot command arg } {
	putnow "PRIVMSG $arg"
}

proc bot:saypre2 { frombot command arg} {
    set channel [lindex $arg 0]
    set rls [lindex $arg 1]
    set ago [lindex $arg 2]
    putnow "PRIVMSG $channel :\[\00314\002PRETIME\002\003\] + \002$rls\002 pred [format_duration $ago] ago"
}

proc bot:saypre3 { frombot command arg } {
    puthelp "NOTICE $arg"
}

# Add Pre and Info Routines

proc findpre {rls} {
  global db
  if {[mysqlsel $db "SELECT count(`title`) FROM `pre` WHERE `title`='$rls' AND `blocked`='1';" -list]} {
    return "blocked"
  } elseif {[mysqlsel $db "SELECT count(`title`) FROM `pre` WHERE `title`='$rls';" -list]} {
    return "pre"
  } else { return "error" }
}

proc getgroup {release} {
	# Handle special groups which break our regex
    set spgrps "SD-6 VH-PROD TEG-TV Cheetah-TV DVD-R CRN-TV FSN-EU ELPH-TV XeoN-VorTeX TEG-PSX TEG-VCD X-BRAIN LION-SVCD LION-XXX TEG-DVD Cheetah-DV THEORY-CLS"
    regsub -nocase {[._-]int$|\_internal$|_house$} $release {} release
    # EOSiNT is internal from EOS.. we have to fix that..
    regsub -- {-EOSiNT$} $release {-EOS} release
    foreach i $spgrps {if {[string match -noc *$i $release]} {return $i}}
    set t [split $release -]
    if {[llength $t] > 1} {return [lindex $t end]} else {return NOGRP}
}

proc addinfo_done {infot rls info} {
 global db
 if {$infot == "genre"} {
  set info [fixgenre $rls $info]
  if {$info == "" || [gnrok $rls $info] == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 6] != ""} { return }
  mysqlexec $db "UPDATE pre SET Genre='$info' WHERE title='$rls'"
 }
 if {$infot == "size"} {
  regsub -all {[^0-9\.]} $info "" info
  if {$info == "" || $info == 0 || $info > 10000} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 7] != "0"} { return }
  mysqlexec $db "UPDATE pre SET rlssize='$info' WHERE title='$rls'"
 }
 if {$infot == "files"} {
  regsub -all {[^0-9\.]} $info "" info
  if {$info == "" || $info == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$rls';" -list]
  set iCount [lindex $iCount 0]
  if {[lindex $iCount 8] != "0"} { return }
  mysqlexec $db "UPDATE pre SET files='$info' WHERE title='$rls'"
 }
 if {$infot == "fs2"} {
  set infot "fs"
 }
 if {$infot == "fs"} {
  set files [lindex $info 0]
  set size [lindex $info 1]
  regsub -all {[^0-9\.]} $files "" files
  regsub -all {[^0-9\.]} $size "" size
  if {$size == "" || $size == 0 || $size > 10000 || $files == "" || $files == 0} { return }
  if {[findpre $rls] == "error"} { return }
  set iCount [lindex [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$rls';" -list] 0]
  if {[lindex $iCount 7] != "0" && [lindex $iCount 8] != "0"} { return }
  mysqlexec $db "UPDATE pre SET rlssize='$size', files='$files' WHERE title='$rls'"
 }
  putlog "Pre info updated for release $rls. Now $infot is set to: $info"
}

proc gnrok { rls genre } {
	set genre [string totitle $genre]
	if {$genre != "Acoustic" &&
      $genre != "Alternative" &&
      $genre != "Ambient" &&
      $genre != "Avantgarde" &&
      $genre != "Bass" &&
      $genre != "Beat" &&
      $genre != "Blues" &&
      $genre != "Classical" &&
      $genre != "Club" &&
      $genre != "Comedy" &&
      $genre != "Country" &&
      $genre != "Dance" &&
      $genre != "Drum" &&
      $genre != "Drum_&_Bass" &&
      $genre != "Electronic" &&
      $genre != "Ethnic" &&
      $genre != "Folk" &&
      $genre != "Gothic" &&
      $genre != "Hard_Rock" &&
      $genre != "Hardcore" &&
      $genre != "House" &&
      $genre != "Indie" &&
      $genre != "Industrial" &&
      $genre != "Funk" &&
      $genre != "Instrumental" &&
      $genre != "Jazz" &&
      $genre != "Latin" &&
      $genre != "Lo-Fi" &&
      $genre != "Metal" &&
      $genre != "Oldies" &&
      $genre != "Pop" &&
      $genre != "Psychadelic" &&
      $genre != "Punk" &&
      $genre != "R&B" &&
      $genre != "Rap" &&
      $genre != "Reggae" &&
      $genre != "Rock" &&
      $genre != "Soul" &&
      $genre != "Soundtrack" &&
      $genre != "Techno" &&
      $genre != "Top" &&
      $genre != "Trance" &&
      $genre != "Various"} {
	return 0
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
  if {$type != "0DAY" &&
      $type != "ANIME" &&
      $type != "APPS" &&
      $type != "BD" &&
      $type != "COVERS" &&
      $type != "MOVIE-DIVX" &&
      $type != "DOX" &&
      $type != "MOVIE-DVDR" &&
      $type != "GC" &&
      $type != "GAMES" &&
      $type != "GBA" &&
      $type != "HDDVD" &&
      $type != "MP3" &&
      $type != "MV" &&
      $type != "MV-DVDR" &&
      $type != "NDS" &&
      $type != "PDA" &&
      $type != "PS2" &&
      $type != "PS3" &&
      $type != "PSP" &&
      $type != "MOVIE-SVCD" &&
      $type != "TV" &&
      $type != "TV-XVID" &&
      $type != "TV-DVDR" &&
      $type != "TV-X264" &&
      $type != "MOVIE-VCD" &&
      $type != "WII" &&
      $type != "XBOX" &&
      $type != "X360" &&
      $type != "XXX" &&
      $type != "TRAILER" &&
      $type != "MOVIE-XVID" &&
      $type != "MOVIE-X264" &&
      $type != "MOVIE"} {
    return 1
  }
  return 0
}

proc writeto_sql {rls type} {
	global db
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $rls "" rls2
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $type "" type
	if {$rls2 != $rls} {
		putlog "Bad: $rls | Filter: Release name contains shit chars | From: $frombot"
		set group [getgroup $rls]
		mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$section','$rls','[unixtime]','','','','','','$group','','1')"
		return 0
    }
	if {[findpre $rls] == "pre" || [findpre $rls] == "blocked"} { return }
	set type [string toupper $type]
	set iDate [unixtime]
	if {[regexp {^[a-zA-Z0-9(]+[_\(\)\.-]+[a-zA-Z0-9_\(\)\.-]+[a-zA-Z0-9]+$} "$rls"]} {
		if {[llength [split "$rls" "("]] == [llength [split "$rls" ")"]]} {
			set type [fixtype $rls $type]
			set group [getgroup $rls]
       		set result [mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$type','$rls','$iDate','','','','','','$group','','')"]
       		putlog "Added pre $rls in section $type for group $group"
      		if {$result == 0} { return 0 }
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

proc add_sitepre {nick uhost hand chan arg} {
	global siteprechans
	if {[string first [string tolower $chan] $siteprechans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!sitepre $arg"
	} else {
		writeto_sql [lindex $arg 0] [lindex $arg 1]
		addinfo_done fs2 [lindex $arg 0] "[lindex $arg 2] [lindex $arg 3]"
	}
}

proc add_sitepre2 {nick uhost hand chan arg} {
	global siteprechans
	if {[string first [string tolower $chan] $siteprechans] == -1} { return }
	set type [lindex [split [lindex [split [lindex $arg 0] "\[\]-"] end-2] ""] end]
	set rls [lindex $arg 4]
	set size [lindex $arg 7]
	set files [lindex $arg 9]
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $rls "" rls
	regsub -all {[^a-zA-Z\-\.\_\_()]} $type "" type
	regsub -all {[^0-9\.]} $size "" size
	regsub -all {[^0-9\.]} $files "" files
	if {$type == "DAY"} { set type "0DAY" }
	if {[islinked "mainBot"]} {
		putbot mainBot "!sitepre $rls $type $files $size"
	} else {
		writeto_sql $rls $type
		addinfo_done fs2 $rls "$files $size"
	}
}

proc add_sitepre3 {nick uhost hand chan arg} {
	global siteprechans
	if {[string first [string tolower $chan] $siteprechans] == -1} { return }
	set type [lindex $arg 16]
	set rls [lindex $arg 13]
	set temp [split [lindex $arg 17] "/"]
	set size [lindex $temp 1]
	set files [lindex $temp 0]
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $rls "" rls
	regsub -all {[^a-zA-Z\-\.\_\_()]} $type "" type
	regsub -all {[^0-9\.]} $size "" size
	regsub -all {[^0-9\.]} $files "" files
	if {[islinked "mainBot"]} {
		putbot mainBot "!sitepre $rls $type $files $size"
	} else {
		writeto_sql $rls $type
		addinfo_done fs2 $rls "$files $size"
	}
}

proc pub:addpre {nick uhost hand chan arg} {
	global addchans
	if {[string first [string tolower $chan] $addchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!addpre [lindex $arg 0] [lindex $arg 1]"
	} else {
		writeto_sql [lindex $arg 0] [lindex $arg 1]
		addinfo_done fs2 [lindex $arg 0] "[lindex $arg 2] [lindex $arg 3]"
	}
}

set lastaddnfo ""
proc addnfo {nick uhost hand chan arg} {
	global addnfochans db lastaddnfo
	if {[string first [string tolower $chan] $addnfochans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!addnfo [lindex $arg 0] [lindex $arg 1] [lindex $arg 2]"
	} else {
	    set rls [lindex $arg 0]
	    if { [string length $rls] < 5 || [string length [lindex $arg 1]] < 5 || [string length [lindex $arg 2]] < 4 } { return }
	    if {$lastaddnfo == $rls} { return }
	    set lastaddnfo $rls
	    set database [findpre $rls]
	    if {$database == "error"} { putlog "NFO added but pre [lindex $arg 0] not in database. Link: [lindex $arg 1]"; return }
	    set id [lindex [lindex [mysqlsel $db "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0] 0]
	    if {[mysqlsel $db "SELECT count(*) FROM `nfo` WHERE `id` = '$id';" -list]} { return }
	    exec /home/leafBot/insert [lindex $arg 0] [lindex $arg 1] [lindex $arg 2] &
	    putlog "NFO added for release [lindex $arg 0] Link: [lindex $arg 1]"
	}
}

set lastaddjpg ""
proc addjpg {nick uhost hand chan arg} {
	global addnfochans db lastaddjpg
	if {[string first [string tolower $chan] $addnfochans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!addjpg [lindex $arg 0] [lindex $arg 1] [lindex $arg 2]"
	} else {
	    set rls [lindex $arg 0]
	    if { [string length $rls] < 5 || [string length [lindex $arg 1]] < 5 || [string length [lindex $arg 2]] < 4 } { return }
	    if {$lastaddjpg == $rls} { return }
	    set lastaddjpg $rls
	    set database [findpre $rls]
	    if {$database == "error"} { putlog "JPG added but pre [lindex $arg 0] not in database. Link: [lindex $arg 1]"; return }
	    set id [lindex [lindex [mysqlsel $db "SELECT * FROM `pre` WHERE `title` = '$rls' ORDER BY `pretime` DESC LIMIT 0, 1;" -list] 0] 0]
	    if {[mysqlsel $db "SELECT count(*) FROM `samplejpg` WHERE `id` = '$id';" -list]} { return }
	    exec /home/leafBot/insert2 [lindex $arg 0] [lindex $arg 1] [lindex $arg 2] &
	    putlog "JPG added for release [lindex $arg 0] Link: [lindex $arg 1]"
	}
}

proc checktime {nick uhost hand chan arg} {
	global addoldchans
	if {[string first [string tolower $chan] $addoldchans] == -1} { return }
	putquick "PRIVMSG $chan :Current Time: [unixtime]"
}

proc pub:addold {nick uhost hand chan arg} {
	global addoldchans db
	if {[string first [string tolower $chan] $addoldchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!addold $arg"
	} else {
	  set rls [lindex $arg 0]
	  set database [findpre $rls]
	  if {$database != "error"} {
	    return "$rls was found."
	  } else {
	    if {[lindex $arg 2] <= 315208800 || [lindex $arg 2] > [unixtime]} { return }
	    set type [string toupper [lindex $arg 1]]
	    if {[lindex $arg 6] == "-"} { set nukersn ""} else { set nukersn [lindex $arg 6]}
	    if {[lindex $arg 3] == "-"} { set file "0"} else { set file [lindex $arg 3]}
	    if {[lindex $arg 4] == "-"} { set size "0"} else { set size [lindex $arg 4]}
	    if {[lindex $arg 5] == "-"} { set genre ""} else { set genre [lindex $arg 5]}
	    set group [getgroup $rls]
	    set result [mysqlexec $db "INSERT IGNORE INTO pre VALUES ('','$type','[lindex $arg 0]','[lindex $arg 2]','','$nukersn','$genre','$size','$file','$group','','')"]
	    if {$result == 0} { return }
	    putlog "$rls Added by oldpre"
	  }
	}
}

proc pub:getold {nick uhost hand chan arg} {
	global addoldchans
	if {[string first [string tolower $chan] $addoldchans] == -1} { return }
	if {[islinked "mainBot"]} { putbot mainBot "!getold $chan $arg" }
}

proc pub:preplay {nick uhost hand chan args} {
  global addoldchans
  if {[string first [string tolower $chan] $addoldchans] == -1} { return }
  if {[islinked "mainBot"]} { putbot mainBot "!preplay $chan $args" }
}

proc pub:nuke {nick uhost hand chan arg} {
	global nukechans
	if {[string first [string tolower $chan] $nukechans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!prenuke $nick $chan [lindex $arg 0] [lindex $arg 1]"
	} else {
		nukeproc [lindex $arg 1] [lindex $arg 0]
	}
}

proc pub:modnuke {nick uhost hand chan arg} {
	global nukechans
	if {[string first [string tolower $chan] $nukechans] == -1} { return }
	if {[islinked "mainBot"]} { putbot mainBot "!modnuke $nick $chan [lindex $arg 0] [lindex $arg 1]" }
}

proc pub:unnuke {nick uhost hand chan arg} {
	global nukechans
	if {[string first [string tolower $chan] $nukechans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!preunnuke $nick $chan [lindex $arg 0] [lindex $arg 1]"
	} else {
		unnukeproc [lindex $arg 1] [lindex $arg 0]
	}
}

proc nuke2 {nick uhost hand chan arg} {
	global nukechans
	if {[string first [string tolower $chan] $nukechans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!prenuke $nick $chan [lindex $arg 2] [lindex $arg 3]"
	} else {
		nukeproc [lindex $arg 3] [lindex $arg 2]
	}
}

proc unnuke2 {nick uhost hand chan arg} {
	global nukechans
	if {[string first [string tolower $chan] $nukechans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!preunnuke $nick $chan [lindex $arg 2] [lindex $arg 3]"
	} else {
		unnukeproc [lindex $arg 3] [lindex $arg 2]
	}
}

proc nukeproc {nukersn nukerls} {
	global db
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukerls "" nukerls
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukersn "" nukersn
	if {[string match {auto.nuke*} $nukersn] != 0} {return}
	if {[string match {satrip.is.forbidden.use.dtv.instead} $nukersn] != 0} {return}
	if {[string match {not.valid.with.hcr.rules.bad.dirname.bad.broadcast} $nukersn] != 0} {return}
	if {[string match {*autonuke(forbidden.word)*} $nukersn] != 0} {return}
	if {[string match {*Autonuke.Bad.Echo.Bad.Dir.Name.Sort.Your.Scripts*} $nukersn] != 0} {return}
	if {[string match {*autonuke.missing.letter(fix.your.scripts)*} $nukersn] != 0} {return}
	if {[string match {fake(autonuke.(v*)-*)*} $nukersn] != 0 || [string match {fake(rlz.must.be.*} $nukersn] != 0 || [string match {*fake(pre.spam)*} $nukersn] != 0 || [string match {*Auto.Nuke-Bad.Echo.Sort.Your.Damn.Scripts*} $nukersn] != 0 || [string match {**Autonuke.Possibility.Of.Nuke.First.Char.Must.Be.Upper**} $nukersn] != 0} {
	delpre "$nukerls"
	return
	}
	if {[findpre $nukerls] == "error"} { return }
	set iCount [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
	if {$iCount == "0"} { return }
	set next [mysqlnext $db]
	set nuketime [lindex $next 4]
	set pretime [lindex $next 3]
	set nukelock [lindex $next 10]
	mysqlendquery $db
	if { $nuketime != "0" || $nukelock == "1000"} { return }
	if {$nukelock > 4} {
	mysqlexec $db2 "UPDATE pre SET nukelock='1000' WHERE title='$nukerls'"
	putlog "$nukerls Auto Locked"
	return
	}
	mysqlexec $db "UPDATE pre SET nuketime='[unixtime]', nukereason='$nukersn', nukelock='[expr $nukelock + 1]' WHERE title='$nukerls'"
	putlog "$nukerls Nuked"
}

proc unnukeproc {nukersn nukerls} {
	global db
	if {[string match {*Someone.forgot.the.reason*} $nukersn] != 0} {return}
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukerls "" nukerls
	regsub -all {[^a-zA-Z0-9\-\.\_\_()]} $nukersn "" nukersn
	if {[findpre $nukerls] == "error"} { return }
	set iCount [mysqlsel $db "SELECT * FROM `pre` WHERE `title`='$nukerls';"]
	if {$iCount == "0"} { return }
	set next [mysqlnext $db]
	set nuketime [lindex $next 4]
	set pretime [lindex $next 3]
	set nukelock [lindex $next 10]
	set nukersn2 [lindex $next 5]
	mysqlendquery $db
	if { $nukersn == $nukersn2 || $nuketime == "0" || $nukelock == "1000"} { return }
	if { [expr [unixtime] - $nuketime] < 10 } { putlog "$nukerls attempted Unnuke too soon."; return }
	mysqlexec $db "UPDATE pre SET nuketime='0', nukereason='', nukelock='[expr $nukelock + 1]' WHERE title='$nukerls'"
	putlog "$nukerls Unnuked by $nick in $chan"
}

proc delpre {nick uhost hand chan arg} {
	global delchans
	if {[string first [string tolower $chan] $delchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!predel [lindex $arg 0]"
	} else {
		delpre [lindex $arg 0]
	}
}

proc delpre2 {nick uhost hand chan arg} {
	global delchans
	if {[string first [string tolower $chan] $delchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!predel [lindex $arg 2]"
	} else {
		delpre [lindex $arg 2]
	}
}

proc delpre {arg} {
	global db
	set release [mysqlsel $db "SELECT * FROM `pre` WHERE `title` = '$arg' AND `blocked`='0' ORDER BY `pretime` DESC LIMIT 0, 1;" -list]
	mysqlendquery $db
	set release [lindex $release 0]
	set id [lindex $release 0]
	if {$id == ""} { return }
	mysqlexec $db "UPDATE `pre` SET `blocked`=1 WHERE `id`='$id' LIMIT 1"
	mysqlendquery $db
	putlog "$arg Deleted"
}

proc add_info {nick uhost hand chan arg} {
  global infochans
  if {[string first [string tolower $chan] $infochans] == -1} { return }
  if {[islinked "mainBot"]} {
	  putbot mainBot "!info $arg"
  } else {
	  addinfo_done [lindex $arg 1] [lindex $arg 0] [lindex $arg 2]
  }
}

proc add_genre {nick uhost hand chan arg} {
	global infochans
	if {[string first [string tolower $chan] $infochans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!addinfo [lindex $arg 0] genre [lindex $arg 1]"
	} else {
		addinfo_done genre [lindex $arg 0] [lindex $arg 1]
	}
}

#Notify Proc
proc add_notify {nick uhost hand chan arg} {
  set mode "[lindex $arg 0]"
  if {[string tolower [lindex $arg 0]] == "privmsg"} { set mode "bot:$nick:privmsg" }
  if {[string tolower [lindex $arg 0]] == "notice"} { set mode "bot:$nick:notice" }
  set arg "$mode [lrange $arg 1 end]"
  if {[islinked "mainBot"]} { putbot mainBot "!notify $nick $arg" }
}

proc add_notify2 {nick uhost hand arg} {
  set mode "[lindex $arg 0]"
  if {[string tolower [lindex $arg 0]] == "privmsg"} { set mode "bot:$nick:privmsg" }
  if {[string tolower [lindex $arg 0]] == "notice"} { set mode "bot:$nick:notice" }
  set arg "$mode [lrange $arg 1 end]"
  if {[islinked "mainBot"]} { putbot mainBot "!notify $nick $arg" }
}

proc ndel {nick uhost hand chan arg} {
  if {[islinked "mainBot"]} { putbot mainBot "!ndel $nick [lindex $arg 0]" }
}

proc nlist {nick uhost hand chan arg} {
  if {[islinked "mainBot"]} { putbot mainBot "!nlist $nick" }
}

proc filteradd {nick uhost hand chan arg} {
	global filterchans
	if {[string first [string tolower $chan] $filterchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!tflist_add [lindex $arg 0]"
		putserv "PRIVMSG $chan :String filter [lindex $arg 0] added for 30m."
	}
}

proc filterdel {nick uhost hand chan arg} {
	global filterchans
	if {[string first [string toilterchans] == -1} { return }
	if {[islinked "mainBot"]} {
		putbot mainBot "!tflist_del [lindex $arg 0]"
		putserv "PRIVMSG $chan :String filter [lindex $arg 0] deleted."
	}
}

#Pre Help Routine

proc prehelp_proc {nick uhost hand chan more } {
    set db [open "help/prehelp.txt" r]
    set entry [read $db]
    set er [close $db]
    set entry [split $entry \n]
    foreach line $entry {
        putserv "PRIVMSG $nick :$line"
    }
}

# Pre Check Routine

proc autochk {nick uhost hand chan arg} {
    set rls [string tolower [lindex $arg $schar]]
    putlog "auto: $chan & $rls"
    regsub -all {[^a-zA-Z0-9\/\-\.\_\_()]} $rls "" rls
	if {[string first "/" $rls] != -1} {
	set rls [split $rls "/"]
	set testrls [lrange $rls 0 end-1]
	if {[string first "private" $testrls] != -1 || [string first "_pre" $testrls] != -1} { return }
	    set rls [lindex $rls end]
	}
	if {$rls != "vobsub" && $rls != "cover" && $rls != "covers" && $rls != "sample" && [string first "cd" $rls] == -1 && [string first "disc" $rls] == -1 && [string length $rls] > 5 } {
	if {[islinked "mainBot"]} { putbot mainBot "!precheck {-w -Z -h $rls} 1 1800 $chan" }
	}
}

proc checkpre {nick uhost hand chan args} {
    if {$args == ""} { return }
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!precheck $args 1 28800 $chan $nick" }
}

proc checkpre2 {nick uhost hand chan args} {
    if {$args == ""} { return }
    global prechans2
    if {[string first [string tolower $chan] $prechans2] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!precheck $args 1 28800 $chan $nick" }
}

proc total {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!total $chan $args" }
}

proc topgroup {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!topgroup $chan $args" }
}

proc list_sections {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!sections $chan $args" }
}

proc list_genres {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!genres $chan $args" }
}

proc show_latest {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!latest $chan $args" }
}

proc nfolookup {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!nfo $chan $args" }
}

proc jpglookup {nick uhost hand chan args} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!jpg $chan $args" }
}

proc nfolookup2 {nick uhost hand chan args} {
    global addnfochans
    if {[string first [string tolower $chan] $addnfochans] == -1} { return }
    if {[islinked "mainBot"]} { putbot mainBot "!getnfo $chan $args" }
}

proc valid_sections {nick uhost hand chan arg} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    putnow "PRIVMSG $chan :\[7SECTIONS\] Valid sections are: 0DAY ANIME APPS BD COVERS MOVIE-DIVX DOX MOVIE-DVDR GC GAMES GBA HDDVD MP3 MV NDS NULL PDA PS2 PS3 PSP MOVIE-SVCD TRAILER TV TV-DVDR TV-XVID TV-X264 MOVIE-VCD WII XBOX X360 MOVIE-XVID MOVIE-X264 XXX"
}

proc valid_genres {nick uhost hand chan arg} {
    global prechans
    if {[string first [string tolower $chan] $prechans] == -1} { return }
    putnow "PRIVMSG $chan :\[7GENRES\] Valid genres are: Acoustic Alternative Ambient Avantgarde Bass Beat Blues Classical Club Comedy Country Dance Drum Drum_&_Bass Electronic Ethnic Folk Gothic Hard_Rock Hardcore House Indie Industrial Funk Instrumental Jazz Latin Lo-Fi Metal Oldies Pop Psychadelic Punk R&B Rap Reggae Rock Soul Soundtrack Techno Top Trance Various"
}

#Auto Update
proc eupdate {frombot command arg} {
	global eupdatebot updatefile
	if {![string match -nocase $frombot mainBot]} {
		putlog "Update: WARNING $frombot is trying to update your bot and is not recognized as an update bot. ABORTING!"
		return 0
	}
	if {$arg == "start"} {
		set updatefile [open prebot.tcl "w"]
	} elseif {$arg == "stop"} {
		close $updatefile
		putlog "Update: Script updated successfully. Rehashing..."
		rehash
	} else {
		puts $updatefile $arg
	}
}

#Extra Procs

proc dur {time} {
    set time [duration $time]
    return [string map {" years" y " year" y " weeks" w " week" w " hours" h " hour" h " days" d " day" d " minutes" m " minute" m " seconds" s " second" s} $time]
}

proc format_duration {secs} {
	set duration ""
	foreach div {31536000 604800 86400 3600 60 1} unit {y w d h m s} {
		set num [expr {$secs / $div}]
		if {$num > 0} {lappend duration "\002$num\002$unit"}
		set secs [expr {$secs % $div}]
	}
	if {[llength $duration]} {return [join $duration]} else {return "\0020\002s"}
}

proc putnow { arg } {
	putserv $arg
}

proc do_rehash { frombot command arg } {
    rehash
}

proc do_restart { frombot command arg } {
    restart
}

proc tmsg {type form to arg} {
	if {$type == "bot"} {
		putbot $to "$form$arg"
	}
	if {$type == "pub"} {
		putnow "$form $to :$arg"
	}
}

