bind pub - "!fixtype" say:section

proc say:section {nick host hand chan arg} {
	global db2
	set section() [fixtype $arg [sectionize $arg]]
	set results [mysqlexec $db2 "UPDATE pre SET cat='$section()' WHERE title='$arg'"]
	if {$results != 0} { set line "Changed section for release $arg to $section()" } else { set line "Error occured in fixtype, try !cs" }
	putnow "PRIVMSG $chan :\[7UPDATE\] $line \[$results row(s) affected\]"
}

proc sectionize {arg} {
	global rls section rules
	set benchmark(sectionize) [clock clicks -milliseconds]
	set rls(pretime) [unixtime]

	# set sections and assign 10 points to each section
	#
	set sections(main) "ISO 0DAY MP3 CONSOLE HANDHELD DIVX XVID VCD SVCD DVDR OTHER"
	set sections(sub) "APPS GAMES DOX SAMPLECD EBOOK FONTS LIVE FOREIGN AUDIOBOOK TV MUSIC XXX TRAILERS PS2 XBOX X360 GCN PSX N64 PDA GBA GBC COVERS FAKE CRAP"
	foreach x "$sections(main) $sections(sub)" { set $x "10" }
	set UNKNOWN "11"

	set rls() $arg
	set rls(body) [string map {" " -} [join [lrange [split $rls() -] 0 end-1]]]
	if {$rls(body) == ""} { set rls(body) $rls() }
	set rls(group) [lindex [split $rls() -] end]
	if {[string match -nocase *_INT $rls(group)]} { set rls(group) [join [lrange [split $rls(group) _] 0 end-1]] }
	set rls(groupKnown) "0"

	# give/take points to sections based on keywords in the release name
	#
	foreach x "lib(groups) lib(wm) lib(crap)" {
		set y [open sections/$x.txt r]
		set z [read $y]
		close $y
		set $x [split $z \n]
	}

	set rules(sect) ""
	set rules(crap) ""
	foreach x $lib(wm) {
		if {[string match -nocase [lindex $x 0] $rls(body)-]} {
			foreach {i j} [lrange $x 1 end] {
				set $i [expr $$i $j]
				lappend rules(sect) "[lindex $x 0]:$i$j"
			}
		}
	}

	# give/take points to sections based on groupname (case sensitive)
	#
	set x [lindex $lib(groups) [lsearch [string toupper $lib(groups)] "[string toupper $rls(group)] *"]]
	if {$x != ""} {
		foreach {i j} [lrange $x 1 end] {
			incr $i $j
			lappend rules(sect) "*-[lindex $x 0]:$i+$j"
		}
		if {$rls(group) != [lindex $x 0]} {
			incr CRAP 1
			set rls(groupKnown) 2
		} else { set rls(groupKnown) 1 }
		if {[string match *_* $rls(group)]} { incr CRAP -20 }
	} else {
		incr CRAP 2
		lappend rules(crap) "CRAP#12 (group not in db (+2))"
	}

	# check through crap library for keywords in filtered release (no ._- and 0 -> o, etc.)
	#
	foreach x $lib(crap) {
		foreach {i j k} $x {
			if {[string match -nocase $i [string map {0 o 1 i 3 e . {} _ {} - {}} $rls()]]} {
				set $j [expr $$j $k]
				lappend rules(sect) "$i:$j$k"
			}
		}
	}

	if {[expr $FOREIGN >= 20]} {
		if {[expr $FOREIGN == 31]} { set language AT
		} elseif {[expr $FOREIGN == 32]} { set language AU
		} elseif {[expr $FOREIGN == 33]} { set language BE
		} elseif {[expr $FOREIGN == 34]} { set language BHANGRA
		} elseif {[expr $FOREIGN == 35]} { set language BR
		} elseif {[expr $FOREIGN == 36]} { set language CH
		} elseif {[expr $FOREIGN == 37]} { set language CN
		} elseif {[expr $FOREIGN == 38]} { set language CZ
		} elseif {[expr $FOREIGN == 39]} { set language DE
		} elseif {[expr $FOREIGN == 40]} { set language EE
		} elseif {[expr $FOREIGN == 41]} { set language ES
		} elseif {[expr $FOREIGN == 42]} { set language FI
		} elseif {[expr $FOREIGN == 43]} { set language FR
		} elseif {[expr $FOREIGN == 44]} { set language GR
		} elseif {[expr $FOREIGN == 45]} { set language HU
		} elseif {[expr $FOREIGN == 46]} { set language IL
		} elseif {[expr $FOREIGN == 47]} { set language IT
		} elseif {[expr $FOREIGN == 48]} { set language JP
		} elseif {[expr $FOREIGN == 49]} { set language LT
		} elseif {[expr $FOREIGN == 50]} { set language NL
		} elseif {[expr $FOREIGN == 51]} { set language NO
		} elseif {[expr $FOREIGN == 52]} { set language PL
		} elseif {[expr $FOREIGN == 53]} { set language RO
		} elseif {[expr $FOREIGN == 54]} { set language RU
		} elseif {[expr $FOREIGN == 55]} { set language SE
		} elseif {[expr $FOREIGN == 56]} { set language TR
		} elseif {[expr $FOREIGN == 60]} { set language NLSUB
		} elseif {[expr $FOREIGN == 61]} { set language SWESUB
		} elseif {[expr $FOREIGN == 62]} { set language DKSUB
		} elseif {[expr $FOREIGN == 63]} { set language NORDIC
		} elseif {[expr $FOREIGN == 64]} { set language FRSUB
		} else { set language FOREIGN }
		set FOREIGN 21
	} else { set language FOREIGN }


######## CRAPFILTER STUFF BLA BLA BLA ########

	# CRAP#1 no hyphen in release (+100)
	#
	if {$rls() == $rls(group)} {
		incr CRAP 100
		lappend rules(crap) "CRAP#1 (no hyphen (+100))"
		set rls(group) ""
	}

	# CRAP#2 first character is not a capital letter (A-Z) or a number (0-9) (+100)
	#
	#if {![regexp {[A-Z]} [lindex [split $rls() ""] 0]] && ![regexp {[0-9]} [lindex [split $rls() ""] 0 ]]} {
	#	incr CRAP 100
	#	lappend rules(crap) "CRAP#2 (first char no capital/number (+100))"
	#}

	# CRAP#3 release length under 10 characters (+(2^(15 - length)))
	#
	if {[string length $rls(body)] < 10} {
		incr CRAP [expr int(pow(2,10 - [string length $rls(body)]))]
		lappend rules(crap) "CRAP#3 (too short (+[expr int(pow(2,10 - [string length $rls(body)]))]))"
	}

	if {[string length [lindex [split $rls(body) ._-] 0]] > 30} {
		incr CRAP 100
		lappend rules(crap) "first part too long"
	}

	# CRAP#4 release length over 100 characters (+(length - 100))
	# if $EBOOK has 20 or more points, then allow 150 characters
	#
	if {[expr [string length $rls()] > 100]} {
		if {[expr $EBOOK < 20]} {
			incr CRAP [expr [string length $rls()] - 100]
			lappend rules(crap) "CRAP#4 (too long (+[expr [string length $rls()] - 100]))"
		} elseif {[expr [string length $rls()] > 150]} {
			incr CRAP [expr [string length $rls()] - 150]
			lappend rules(crap) "CRAP#4 (too long (+[expr [string length $rls()] - 150]))"
		}
	}

	### date in rls
	if {[string match [clock format [unixtime] -format %m%d]* $rls()]} {
		incr CRAP 100
		lappend rules(crap) "contains date"
	}
	if {[string match [clock format [expr [unixtime] - 86400] -format %m%d]* $rls()]} {
		incr CRAP 100
		lappend rules(crap) "contains date"
	}

	# CRAP#5 no alphabetical characters in the releasename (+100)
	#
	#

	# CRAP#6 unallowed characters in the releasename (+50 for each character)
	#
	#

	# CRAP#7 unallowed characters in the releasename (+50 for each character)
	#
	#

	# CRAP#8 signal-to-noise ratio over 33% (+(5*1%))
	#
	#

	# CRAP#9 bad start words (incomplete, nuked, etc.) or end words (CD1, covers, etc.) (+100)
	#
	foreach x {REQ* NUKED* APPROVED* INCOMPLETE* FILLED-* *CD1 *CD2 *CD3 *CD4 *CD5 *CD6 *CD7 *CD8 *CD9 *DISC1 *DISC2 *DISC3
*DISC4 *DVD1 *DVD2 *DVD3 *DVD4 *NONFO *NODIZ *Sample *Subs *Cover *Covers (no-nfo)* } {
 		if {[string match -nocase $x $rls()]} {
			incr CRAP 500
			lappend rules(crap) "CRAP#9 $x (+50)"
		}
	}

	# CRAP#10 look for *aaa*, *bbbb*, *ccccc*, etc. (+5, +20 or +50)
	#
	foreach x {a b c d e f g h i j k l m n o p q r s t u v w x y z . _ -} {
		if {[string match -nocase *[string repeat $x 3]* $rls(body)]} {
			incr CRAP 5
			if {[string match -nocase *[string repeat $x 4]* $rls(body)]} {
				incr CRAP 15
				if {[string match -nocase *[string repeat $x 5]* $rls(body)]} {
					incr CRAP 30
					lappend rules(crap) "CRAP#10 ([string repeat $x 5] (+50))"
				} else { lappend rules(crap) "CRAP#10 ([string repeat $x 4] (+20))" }
			} else { lappend rules(crap) "CRAP#10 ([string repeat $x 3](+5))" }
		}
	}

	if {[string match */* $rls(body)]} { incr CRAP 1200 }


######## ASSIGN SECTIONS AND SHIT ########

	# check which main section has most points, assign to variable $section1
	#
	set section(main) "UNKNOWN"
	foreach x $sections(main) {
		if {[expr $$x > $[lindex $section(main) 0]]} { set section(main) "$x"
		} elseif {[expr $$x == $[lindex $section(main) 0]]} { lappend section(main) "$x" }
	}
	if {[expr [llength $section(main)] > 1]} {
		foreach x {0DAY ISO VCD SVCD DVDR DIVX XVID CONSOLE HANDHELD MP3} {
			foreach y $section(main) {
				if {[string match $x $y]} {
					set section(main) $x
					break
				}
			}
		}
	}

	# check which sub section has most points, assign to variable $section2, and assign final section
	#
	if {$section(main) == "ISO"} { set sections(list) "APPS APPS GAMES GAMES DOX DOX SAMPLECD SAMPLECD"
	} elseif {$section(main) == "0DAY"} { set sections(list) "APPS 0DAY GAMES 0DAY-GAMES DOX 0DAY-DOX EBOOK EBOOK FONTS FONTS"
	} elseif {$section(main) == "MP3"} { set sections(list) "LIVE MP3-LIVE FOREIGN MP3-$language AUDIOBOOK AUDIOBOOK"
	} elseif {$section(main) == "DVDR"} { set sections(list) "TV DVDR-TV FOREIGN DVDR-$language MUSIC DVDR-MUSIC XXX DVDR-XXX"
	} elseif {$section(main) == "VCD"} { set sections(list) "TV TV-VCD FOREIGN VCD-$language TRAILERS TRAILERS MUSIC MVID XXX XXX-VCD"
	} elseif {$section(main) == "SVCD"} { set sections(list) "TV TV-SVCD FOREIGN SVCD-$language TRAILERS TRAILERS MUSIC MVID XXX XXX-SVCD"
	} elseif {$section(main) == "DIVX"} { set sections(list) "TV TV-DIVX FOREIGN DIVX-$language TRAILERS TRAILERS MUSIC MVID XXX XXX-DIVX"
	} elseif {$section(main) == "XVID"} { set sections(list) "TV TV-XVID FOREIGN XVID-$language TRAILERS TRAILERS MUSIC MVID XXX XXX-XVID"
	} elseif {$section(main) == "CONSOLE"} { set sections(list) "PS2 PS2 GCN GCN XBOX XBOX X360 X360 PSX PSX N64 N64"
	} elseif {$section(main) == "HANDHELD"} { set sections(list) "PDA PDA GBA GBA GBC GBC"
	} else { set sections(list) "APPS APPS GAMES GAMES DOX DOX SAMPLECD SAMPLECD EBOOK EBOOK FONTS FONTS LIVE MP3 AUDIOBOOK MP3-AUDIOBOOK TV TV MUSIC MUSIC XXX XXX TRAILERS TRAILERS PS2 PS2 XBOX XBOX X360 X360 GCN GCN PSX PSX N64 N64 PDA PDA GBC GBC COVERS COVERS FAKE FAKE CRAP CRAP" }

	set section() "UNKNOWN"
	set section(sub) "UNKNOWN"
	set section(temp) ""
	foreach {x y} $sections(list) {
		if {[expr $$x > $[lindex $section(sub) 0]]} {
			if {$x == "TV" && [expr $TV < 20]} { set section(temp) "TV"
			} elseif {$x == "EBOOK" && [expr $EBOOK < 20]} { set section(temp) "EBOOK"
			} elseif {$x == "DOX" && [expr $DOX < 20]} { set section(temp) "DOX"
			} elseif {$x == "MUSIC" && [expr $MUSIC < 20]} { set section(temp) "MUSIC"
			} else {
				set section(sub) $x
				set section() $y
			}
		} elseif {[expr $$x == $[lindex $section(sub) 0]]} { lappend section(sub) $x }
	}
	if {[expr [llength $section(sub)] > 1]} {
		foreach {x y} $sections(list) {
			foreach z {$section(sub)} {
				if {$x == $z} {
					set section(sub) $x
					set section() $y
					break
				}
			}
		}
	}

	# $sectionsMain ....... ISO 0DAY MP3 CONSOLE HANDHELD DIVX XVID VCD SVCD DVDR OTHER
	# $sectionsSub ........ APPS GAMES DOX SAMPLECD EBOOK FONTS LIVE FOREIGN AUDIOBOOK TV MUSIC
	#              ........ XXX TRAILERS PS2 XBOX X360 GCN PSX N64 PDA GBA GBC COVERS FAKE CRAP

	if {$section(sub) == "UNKNOWN" && $section(main) != "UNKNOWN"} { set section() $section(main)
	} elseif {$section(main) == "UNKNOWN" && $section(sub) != "UNKNOWN"} { set section() $section(sub) }
	if {$section() == "UNKNOWN" && $section(temp) != ""} { set section() $section(temp) }
	if {[expr $FAKE > $$section(main)]} { set section() "FAKE" }
	if {[expr $CRAP > $$section(main)]} { set section() "CRAP" }


	# set point distribution to variable $pointDistro (for debug purposes)
	#
	set rules(points) ""
	foreach x "$sections(main) $sections(sub)" {
		if {[expr $$x != 10]} { lappend rules(points) "$x:[expr $$x]" }
	}
	return $section()
}

proc nfm:sect {rls source} {
	# rls:    full releasename
	# source: sitenew/sitepre/addpre/override

	# declarations of:  $benchmark
	#                   $rls_body
	#                   $rls_group
	#                   $known_group

	set benchmark [clock clicks -milliseconds]
	set rls_body [lrange [split $rls ._-] 0 end-1]
	if {$rls_body == ""} { set rls_body $rls }
	set rls_group [lindex [split $rls -] end]
	if {[string match -nocase *_INT $rls_group]} { set rls_group [join [lrange [split $rls(group) _] 0 end-1]] }
	set known_group "0"


	# declarations of points(sections)
	# --------------------------------

	set sections(main) "ISO 0DAY MP3 CONSOLE HANDHELD DIVX XVID VCD SVCD DVDR OTHER"
	set sections(sub) "APPS GAMES DOX SAMPLECD EBOOK FONTS LIVE FOREIGN AUDIOBOOK TV MUSIC XXX TRAILERS PS2 XBOX X360 GCN PSX N64 PDA GBA GBC COVERS FAKE CRAP"

	foreach section "$sections(main) $sections(sub)" {
		set points(section) "10"
	}
	set points(unknown) "11"


	# sectionize and shit
	# -------------------

	if {}





	# crapfilter
	# ----------

	# no hyphen

	if {$rls == $rls_group} {
		incr points(crap) 100
		set rls_group ""
	}


	# first char no capital letter or number
	
	if {![regexp \[^A-Z\] [lindex [split $rls ""] 0]] && ![regexp \[^0-9\] [lindex [split $rls ""] 0]]} {
		incr points(crap) 100
	}


	# $rls_body length under 10 characters

	if {[string length $rls(body)] < 10} {
		incr points(crap) [expr int(pow(2,10 - [string length $rls_body]))]
	}


	# release length over 100 characters
	# allow more if section is ebook
	
	if {[expr [string length $rls] > 100]} {
		if {[expr $EBOOK < 20]} {
			incr CRAP [expr [string length $rls()] - 100]
			lappend rules(crap) "CRAP#4 (too long (+[expr [string length $rls()] - 100]))"
		} elseif {[expr [string length $rls()] > 150]} {
			incr CRAP [expr [string length $rls()] - 150]
			lappend rules(crap) "CRAP#4 (too long (+[expr [string length $rls()] - 150]))"
		}
	}

	foreach char {a b c d e f g h i j k l m n o p q r s t u v w x y z . _ -} {
		if {[string match -nocase *[string repeat $char 3]* $rls_body]} {
			incr points(crap) 5
			if {[string match -nocase *[string repeat $char 4]* $rls_body]} {
				incr points(crap) 15
				if {[string match -nocase *[string repeat $char 5]* $rls_body]} {
					incr points(crap) 30
					lappend rules [string repeat $char 5]
				} else {
					lappend rules [string repeat $char 4]
				}
			} else {
				lappend rules [string repeat $char 3]
			}
		}
	}
}
