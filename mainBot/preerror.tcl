###############################
# Error Checker for PreScript #
###############################

putlog "Error Checker for PreScript Loaded"

bind bot - !error handleerror
bind disc - "*" senderr
bind link - "*" senderr2
bind pub - !prehelp pre_help
bind pub - !listsections valid_sections
bind pub - !listgenres valid_genres
bind dcc n rehash_all rehash_all
bind dcc n restart_all restart_all
bind dcc n push_update push_update

set debugmsg 1
set main_bots "leafBot"

proc push_update { handle idx arg } {
	global main_bots
	putlog "Pushing Update to Leaf Bots Standby..."
	set fp [open leaf_prebot.tcl "r"]
	set size [file size "leaf_prebot.tcl"]
	set data [split [read $fp $size] "\n"]
	close $fp
	foreach bot $main_bots {
		if {[islinked $bot]} { putbot $bot "!eupdate start" }
	}
	foreach line $data {
		foreach bot $main_bots {
			if {[islinked $bot]} { putbot $bot "!eupdate $line" }
		}
	}
	foreach bot $main_bots {
		if {[islinked $bot]} { putbot $bot "!eupdate stop" }
	}
	putlog "Update has been pushed to all bots!"
}

proc rehash_all { handle idx arg } {
  global main_bots
  foreach bot $main_bots {
   putbot $bot "!rehash"
  }
}

proc restart_all { handle idx arg } {
  global main_bots
  foreach bot $main_bots {
   putbot $bot "!restart"
  }
}

proc senderr { botname } {
  global debugmsg main_bots
  foreach bot $main_bots {
   if {$bot == $botname && $debugmsg == 1} {putquick "PRIVMSG owner :Bot $bot has delinked from the botnet. [clock format [unixtime]]"}
  }
}

proc senderr2 { botname viabot } {
  global debugmsg main_bots
  foreach bot $main_bots {
   if {$bot == $botname && $debugmsg == 1} {putquick "PRIVMSG owner :Bot $bot has linked to bot $viabot. [clock format [unixtime]]"}
  }
}

proc handleerror {frombot command args} { putquick "PRIVMSG owner :$args" }

proc check_link {} {
  global main_bots
  foreach bot $main_bots {
   if {![islinked $bot]} {
	link $bot
   }
  }
  check_database
  utimer 300 check_link
}

proc utreset {} {set timers [utimers]; foreach timer $timers {killutimer [lindex $timer 2]}}

proc pre_help {nick uhost hand chan more} {
	set db [open "help/prehelp.txt" r]; set entry [read $db]; set er [close $db]
	set entry [split $entry \n]; foreach line $entry { putnow "NOTICE $nick :$line" }
	set db ""
	if {[matchattr $nick K]} {set db [open "help/prehelp3.txt" r]} elseif {[matchattr $nick A]} {set db [open "help/prehelp2.txt" r]} elseif {[matchattr $nick C]} {set db [open "help/prehelp1.txt" r]}
	if {$db == ""} { return }
	putnow "NOTICE $nick : "
	set entry [read $db]
	set er [close $db]
	set entry [split $entry \n]
	foreach line $entry {putnow "NOTICE $nick :$line"}
}

proc valid_sections {nick uhost hand chan arg} {putnow "PRIVMSG $chan :\[7SECTIONS\] Valid sections are: 0DAY ANIME APPS BD COVERS DOX GAMES GBA GC HDDVD MOVIE MOVIE-DIVX MOVIE-DVDR MOVIE-SVCD MOVIE-VCD MOVIE-X264 MOVIE-XVID MP3 MV MV-DVDR NDS NULL PDA PS2 PS3 PSP TRAILER TV TV-DVDR TV-X264 TV-XVID WII X360 XBOX XXX"}
proc valid_genres {nick uhost hand chan arg} {putnow "PRIVMSG $chan :\[7GENRES\] Valid genres are: Acoustic Alternative Ambient Avantgarde Bass Beat Blues Classical Club Comedy Country Dance Drum Drum_&_Bass Electronic Ethnic Folk Gothic Hard_Rock Hardcore House Indie Industrial Funk Instrumental Jazz Latin Lo-Fi Metal Oldies Pop Psychadelic Punk R&B Rap Reggae Rock Soul Soundtrack Techno Top Trance Various"}
