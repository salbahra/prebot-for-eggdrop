# Precheck

#Bind all text starting with an exclamation point in all channels to be proccessed by get_trigger
bind pubm - "% !*" get_trigger

#Bind all bot commands to primary bot interpreter
foreach trigger {!precheck !getnfo !nfo !jpg !topgroup !latest !total !sections !genres} {
  bind bot - $trigger bot_get_trigger
}

#Other triggers
bind pub - !pconvert pconvert

#Start a connection to the database only if connection is not present and active
if {![info exists db] || ![::mysql::state $db -numeric]} { set db [::mysql::connect -host localhost -user user -password password -db db] }

#Filters for language, crap and quality checks
set lfilters "\[.\]lt\[.\]|\[.\]sk\[-\]|\[-\]sp\[-\]|\[-\]de\[-\]|\[-\]jp\[-\]|\[-\]nl\[-\]|\[-\]es\[-\]|\[-\]pt\[-\]|\[-\]gr\[-\]|\[-\]fi\[-\]|\[-\]cn\[-\]|\[-\]se\[-\]|flemish|valencian|vietnamese|slovenian|nordic|persian|azerbaijani|arabic|cz|portuguese|chinese|bulgarian|norwegian|slovak|uzbek|albanian|bosnian|catalan|croatian|finnish|galician|greek|hebrew|japanese|korean|lithuanian|macedonian|polish|romanian|serbian|cyrillic|latin|turkish|thai|ukrainian|hungarian|french|german|custom|czech|spanish|swedish|danish|rus|dutch|italian|\[.\]es\[.\]|\[.\]es\[-\]|\[.\]it\[.\]|\[.\]fr\[.\]|\[.\]sk\[.\]|\[.\]subbed\[.\]|\[.\]nlsub\[.\]|\[.\]nlsubbed\[.\]|\[.\]dub\[.\]|\[.\]pl\[.\]|\[.\]hun\[.\]|heb\[.\]sub|\[.\]multi|subs"
set cfilters "mp4\[.\]psp|ppc\[.\]xvid|ebook|unlocker|extras|trailer|cover|keygen|bonus|crack|cheat|demo|patch|nfofix|cdkey|\[.\]mini\[.\]image|\[.\]manual\[.\]discs|\[.\]keychanger|fix|\[.\]gameguide|\[.\]nocd|\[.\]trainer|\[.\]custom|\[.\]java|\[.\]solaris|\[.\]pda|\[.\]psp\[.\]mp4|\[.\]int"
set qtypes "{\[-_.\]\[iI\]\[nN\]\[tT\]\[._-\]|\[-_.\]\[iI\]\[nN\]\[tT\]\[eE\]\[rR\]\[nN\]\[aA\]\[lL\]\[._-\]} {\[-_.\]\[dD\]\[iI\]\[rR\]\[fF\]\[iI\]\[xX\]\[._-\]} {\[-_.\]\[nN\]\[fF\]\[oO\]\[fF\]\[iI\]\[xX\]\[._-\]} {\[-_.\]\[rR\]\[eE\]\[pP\]\[aA\]\[cC\]\[kK\]\[._-\]|\[-_.\]\[rR\]\[eE\]\[rR\]\[iI\]\[pP\]\[._-\]|\[-_.\]\[rR\]\[eE\]\[-\]\[rR\]\[iI\]\[pP\]\[._-\]}"

#Forward binds to primary trigger handler
proc get_trigger { nick uhost hand chan arg } { do_trigger $nick $chan privmsg pub $chan $arg }

proc dcc_nfolookup {hand idx arg} { do_trigger phpbot $idx [lindex $arg 0] dcc "" "!nfo [lindex [lrange $arg 1 end] 0]" }

proc dcc_precheck { hand idx arg } { do_trigger phpbot $idx [lindex $arg 0] dcc "" "!precheck [lindex [lrange $arg 1 end] 0]" }

proc bot_get_trigger { frombot command arg } {

  #Match precheck against all other queries since syntax differs
  switch $command {
    !precheck { do_trigger [lindex $arg 4] $frombot "!saypre [lindex $arg 3] :" bot [lindex $arg 3] "$command [lindex $arg 0]" }
    default { do_trigger "" $frombot "!saypre [lindex $arg 0] :" bot [lindex $arg 0] "$command [lindex $arg 1]" }
  }

}

proc do_trigger { nick to form type chan arg } {
#Proccess trigger and query then redirects to destination call

  #Set the trigger to the first word passed from pubm minus the !
  set trigger [string range [lindex $arg 0] 1 end]

  #Check if trigger is supported
  if {[lsearch {topgroup nfo jpg getnfo nukes precheck pre latest sections genres total} $trigger] == -1} { return }

  #Set the argument as everything minus the trigger
  set arg [lrange $arg 1 end]

  #Log query
  putlog "Trigger: $trigger From: $to Type: $type Form: $form Nick: $nick Channel: $chan Query: $arg"

  #Sets the default send/recieve information
  s parms "chan {$chan} type {$type} to {$to} form {$form} query {$arg} nick {$nick} colord column col {} filter {} days 0 negsec = results 4 prefix {} section {} blocked 0 regexp {} genre {} grp {} exclude % nrsn {} dupechk 0 nnuke 0 nfo 0 jpg 0 startat 0 endat 0 binary {} hideextra 0 skin 0 order DESC"
  s parms [parseargs $parms(query)]

  #Check fors errors from arguments
  if {[array names parms -exact error] != ""} { tmsg $parms(type) $parms(form) $parms(to)  [errorout $parms(error)]; return }

  #Compare the trigger with accepted endpoints and if matched redirect
  switch $trigger {
    sections { s parms "col {cat} title {SECTION}"; list_column parms; return }
    genres { s parms "col {genre} title {GENRE}"; list_column parms; return }
    total { total parms; return }
  }

  if { $arg == "" } { tmsg $parms(type) $parms(form) $parms(to)  [errorout 7]; return }

  switch $trigger {
    topgroup { topgroup parms }
    nfo { s parms "old 0"; nfolookup parms }
    jpg { jpglookup parms }
    getnfo { s parms "old 1"; nfolookup parms }
    nukes { s parms "query {-N $arg}"; prelookup parms }
    precheck -
    pre { prelookup parms }
    latest { latest parms }
    default { return }
  }

}

proc latest { arr } {

  #Intialize variables
  global db
  upvar 1 $arr latest

  #Convert an acceptable query into the section for makequery
  if {![type_check $latest(query)] || ![type_check [string range $latest(query) 1 end]]} { array set latest [parseargs "-s $latest(query)" 0] }

  #Query database
  set top10 [::mysql::sel $db [makequery latest latest] -list]

  #Output results
  foreach rls $top10 { tmsg $latest(type) $latest(form) $latest(to) "\[12LATEST\] [lindex $rls 0] [expr {([lindex $rls 1] != "") ? "(NFO)":""}]" }

}

proc list_column { arr } {

  #Intialize variables
  global db
  upvar 1 $arr col

  #Query database
  set i 1; set rows [::mysql::sel $db [makequery col col] -list]

  #Loop through sections
  foreach row $rows {

    #Append this section to the current line
    append line "\[[lindex $row 0]3 [lindex $row 1]\] "

    #If this is the 4th section on this line then begin new line
    if {![expr {fmod($i,4)}]} { lappend lines $line; set line "" }
    incr i
  }

  #Grab the final line if it exists
  if {$line != ""} { lappend lines $line }

  #Iterate through lines and return them in an alphabetically sorted fashion.
  #Note: Sort is preformed since the lines are stored in reverse order. Simply changing the SQL query would result in the first line of
  #          output to be less then the cut off of 4. lreverse function did not seem to work either.

  foreach line [lsort -dictionary $lines] { tmsg $col(type) $col(form) $col(to) "\[12$col(title)\] $line" }

}

proc topgroup { arr } {

  #Intialize variables
  global db
  upvar 1 $arr top; set x 1

  #Convert an acceptable query into the section for makequery
  if {![type_check $top(query)] || ![type_check [string range $top(query) 1 end]]} { array set top [parseargs "-s $top(query)" 0] }

  #Query the database
  set top5 [::mysql::sel $db [makequery top topgroup] -list]

  #Iterate through and return results
  foreach rls $top5 {
    tmsg $top(type) $top(form) $top(to) "\[8TOPGROUP\] #$x [lindex $rls 0] ([lindex $rls 1] pres and [expr [lindex $rls 1] - [lindex $rls 2]] nukes)"
    incr x
  }
  return

}

proc nfolookup { arr } {

  #Intializes variables
  global db
  upvar 1 $arr nfo

  #Query database for NFO
  set nfo(exist) [::mysql::sel $db [makequery nfo nfo]]

  #Proccess result and output result if found or error message if not
  if {$nfo(exist)} {
    set nfo(result) [::mysql::fetch $db]; set nfo(url) "http://nfo.prewebsite.net/?[regsub -all "=" [::base64::encode -maxlen 100 "[lindex $nfo(result) 0]:[md5 "SEED[expr [unixtime] + 600]"]:[expr [unixtime] + 600]"] ""]"
    tmsg $nfo(type) $nfo(form) $nfo(to) [expr {(!$nfo(old) && $nfo(type) != "dcc") ? "\[8INFO\] NFO for $nfo(query) at ":""}][expr {($nfo(old)) ? "!oldnfo $nfo(query) ":""}]$nfo(url)[expr {($nfo(old)) ? "=download [lindex $nfo(result) 2]":""}]
  } else { if {!$nfo(old) && $nfo(type) != "dcc"} { tmsg $nfo(type) $nfo(form) $nfo(to) "\[8INFO\] NFO for $nfo(query) not found" } }

  #End query
  ::mysql::endquery $db
  if {$nfo(type) == "dcc"} { tmsg "dcc2" $nfo(form) $nfo(to) "PHPDONE" }

}

proc jpglookup { arr } {

  #Intializes variables
  global db
  upvar 1 $arr jpg

  #Query database for JPG
  set jpg(exist) [::mysql::sel $db [makequery jpg jpg]]

  #Proccess result and output result if found or error message if not
  if {$jpg(exist)} {
    set jpg(result) [::mysql::fetch $db]; set jpg(url) "http://nfo.prewebsite.net/jpgview.php?[regsub -all "=" [::base64::encode -maxlen 100 "[lindex $jpg(result) 0]:[md5 "SEED[expr [unixtime] + 600]"]:[expr [unixtime] + 600]"] ""]OmltYWdlOjA="
    tmsg $jpg(type) $jpg(form) $jpg(to) "\[8INFO\] JPG for $jpg(query) at $jpg(url)"
  } else { tmsg $jpg(type) $jpg(form) $jpg(to) "\[8INFO\] JPG for $jpg(query) not found" }

  #End query
  ::mysql::endquery $db
}

proc total { arr } {

  #Intialize variables
  global db
  upvar 1 $arr total

  #Checks if query contains a valid group name, if so moving the variable into the group variable
  if {[llength $total(query)] == 1 && [isgrp $total(query)]} { set total(grp) $total(query); set total(query) "" }

  #Identify if query matches against any known index
  set noindex [expr {($total(grp) == "" && $total(section) == "" && $total(query) == "") ? 1:0}]

  #Notify user if expected wait time will be longer then 10 seconds (benched)
  if { $total(grp) == "" && $total(section) == "" && $total(query) != ""} { tmsg $total(type) $total(form) $total(to) "\[7WARNING\] Your request did not match an index. Your query may take up to a minute." }

  #If no index use table status to get total pre/nfo/jpg rows
  if {$noindex} {

    #Query database
    set tb_status [::mysql::sel $db [makequery total status] -list]

    #For each table with returned status set the 'tablename'num and size variables to their respective values
    foreach table $tb_status { set [lindex $table 0]num [lindex $table 4]; set [lindex $table 0]size [expr {([lindex $table 6] + [lindex $table 8]) / 1073741824}] }
  } else {

    #Query database for the total number of rows in nfo, jpg, and pre
    set totals [lindex [::mysql::sel $db [makequery total total] -list] 0]

    #Set the values returned from the list to keep them uniform with noindex based results
    set nfonum [lindex $totals 0]; set samplejpgnum [lindex $totals 1]; set prenum [lindex $totals 2]

    #Quality check results for internal, dirfix, nfofix, and repacks
    set qindex [::mysql::sel $db [check_quality [g total]] -list]
    lassign $qindex int dirfix nfofix repack
  }

  #Query database for the first and last pre
  set flpre [::mysql::sel $db [makequery total flpre] -list]

  #Query the database for the first and last nuke
  set flnuke [::mysql::sel $db [makequery total flnuke] -list]

  #Set the request column to nuke and query for all matching nuked release count
  set total(col) "nuked"; set nukenum  [::mysql::sel $db [makequery total count] -list]

  #Set the request column to blocked and query for all matching blocked release count
  set total(col) "blocked"; set blocknum  [::mysql::sel $db [makequery total count] -list]

  #Set the request column to type and query for list of sections matching and number of releases total per section
  set total(col) "cat"; set total(colord) "total"; set sections [::mysql::sel $db [makequery total col] -list]

  #Prepare output
  lappend lines "\[8STATS\] \[Total Releases: $prenum Nukes: $nukenum ([p $nukenum $prenum]) Blocked: $blocknum ([p $blocknum $prenum])\]"
  lappend lines "\[8STATS\] \[NFOs: $nfonum ([p $nfonum $prenum]) JPGs: $samplejpgnum ([p $samplejpgnum $prenum])\] \[Favorite section: [lindex [lindex $sections end] 0] ([p [lindex [lindex $sections end] 1] $prenum])\]"
  if {!$noindex} { lappend lines "\[8STATS\] \[Internals: $int ([p $int $prenum]) Dirfixes: $dirfix ([p $dirfix $prenum]) NFOfixs: $nfofix ([p $nfofix $prenum]) Repacks: $repack ([p $repack $prenum])\] \[Quality: [p [expr $prenum-($nukenum+[ladd $qindex])] $prenum]\]" }
  if {$flpre != ""} { lappend lines "\[8STATS\] \[First pre was [lindex [lindex $flpre 1] 0] ([dur [expr [unixtime] - [lindex [lindex $flpre 1] 1]]])\] \[Latest pre is [lindex [lindex $flpre 0] 0] ([dur [expr [unixtime] - [lindex [lindex $flpre 0] 1]]])\]" }
  if {$flnuke != ""} { lappend lines "\[8STATS\] \[First nuke was [lindex [lindex $flnuke 1] 0] ([dur [expr [unixtime] - [lindex [lindex $flnuke 1] 1]]]) reason: [lindex [lindex $flnuke 1] 2]\] \[Latest nuke is [lindex [lindex $flnuke 0] 0] ([dur [expr [unixtime] - [lindex [lindex $flnuke 0] 1]]]) reason: [lindex [lindex $flnuke 0] 2]\]" }
  if {$noindex} { lappend lines "\[8STATS\] \[Database Size: [expr {$presize + $nfosize + $samplejpgsize}] GB\]" }

  #Cycle through and display output
  foreach line $lines { tmsg $total(type) $total(form) $total(to) $line }

}

proc prelookup { arr } {

  #Intializes variables
  global db
  upvar 1 $arr preinfo

  #Start timer
  set preinfo(timestart) [clock clicks -milliseconds]

  #Check fors errors from arguments
  if {$preinfo(results) > 50} { tmsg $preinfo(type) $preinfo(form) $preinfo(to) [errorout 8] ; set preinfo(results) 50 }

  #Change some variables if results are going to a bot
  if {$preinfo(type) == "bot" && $preinfo(results) != 4} { set preinfo(form) "!saypre3 $preinfo(nick) :" } elseif {$preinfo(type) != "dcc" && $preinfo(results) != 4} { set preinfo(form) "NOTICE" ; set preinfo(to) $preinfo(nick) }
  if {$preinfo(type) == "bot" && $preinfo(skin) == 1} { set preinfo(form) "!saypre2 $preinfo(chan) " }

  #Debug
  #putlog "Query: [makequery preinfo pre]\n Array: [array get preinfo]"

  #Query the database and requery blocked/deleted queries if no results found. If still no results then request an addold when possible then terminate.
  set numreleases [::mysql::sel $db [makequery preinfo pre]]
  if { !$numreleases && !$preinfo(blocked)} {
    set preinfo(blocked) 1
    set numreleases [::mysql::sel $db [makequery preinfo pre]]
    if {!$numreleases} {
      set timeend "[expr [clock clicks -milliseconds] - $preinfo(timestart)]ms"; set checkmore ""
      if {$preinfo(dupechk) && [string first "*" $preinfo(query)] == -1} {set checkmore ", now checking other bots."; get_old $preinfo(query) }
      if {$preinfo(type) == "dcc"} { tmsg "dcc2" $preinfo(form) $preinfo(to) "PHPDONE" }
      if {![regexp "^!saypre2$" [lindex $preinfo(form) 0]]} { tmsg $preinfo(type) $preinfo(form) $preinfo(to) "$preinfo(query) [insert nrsn $preinfo(nnuke) $preinfo(nrsn)][insert exclude $preinfo(exclude)]was not found in pred database$checkmore \[$timeend\]" }
      ::mysql::endquery $db
      return
    }
  }

  #Parse results
  if {$preinfo(startat) >= $numreleases} { set preinfo(startat) 0 }
  if {$preinfo(endat) != $preinfo(startat) && [expr $preinfo(endat) - $preinfo(startat)] > 50} { set preinfo(results) [expr $preinfo(endat) - $preinfo(startat)] }
  if {$numreleases < $preinfo(results)} { set preinfo(results) $numreleases }
  ::mysql::seek $db $preinfo(startat)

  #End query time and proccess results
  set timeend "[expr [clock clicks -milliseconds] - $preinfo(timestart)]ms"; set rshown 1
  if {$numreleases < [expr $preinfo(results) + $preinfo(startat)]} { set preinfo(results) [expr $numreleases - $preinfo(startat)] }
  if {$numreleases > 1} { if {$preinfo(type) == "dcc"} {tmsg $preinfo(type) $preinfo(form) $preinfo(to) "$numreleases [expr $preinfo(startat) + $rshown] [expr $preinfo(startat) + $preinfo(results)] $timeend" } else { tmsg $preinfo(type) $preinfo(form) $preinfo(to) "\[9RESULTS\] Sending you results [expr $preinfo(startat) + $rshown]-[expr $preinfo(startat) + $preinfo(results)] of $numreleases for $preinfo(query)[insert nrsn $preinfo(nnuke) $preinfo(nrsn)][insert exclude $preinfo(exclude)]. \[$timeend\]"}}
  while { $rshown <= $preinfo(results) } {
    lassign [::mysql::fetch $db] id type title time nuketime nrsn genre weight files grp nlock blocked nfound sfound
    set ago [expr [unixtime] - $time]; set extradata ""; fixvar nfound; fixvar sfound; fixvar genre
    if {!$preinfo(hideextra)} { append extradata [insert type $type][insert genre $genre][insert weight $weight][insert files $files][insert nfound $nfound][insert sfound $sfound] }
    if {$preinfo(skin) == 1} {
	if {$preinfo(type) == "dcc"} { tmsg $preinfo(type) $preinfo(form) $preinfo(to) "$title $ago $type $genre $weight $files $nfound $sfound $nuketime $nrsn" } else { tmsg $preinfo(type) $preinfo(form) $preinfo(to) "$title $ago" }
    } else {
    	tmsg $preinfo(type) $preinfo(form) $preinfo(to) "\[12CHECK\] [insert blocked $preinfo(blocked)][insert nlock $nlock][insert nuked $nuketime $nrsn]$title was pred [dur $ago] ago$extradata ([insert date $time])"
    }
    incr rshown
  }
  if {$preinfo(type) == "dcc"} { tmsg "dcc2" $preinfo(form) $preinfo(to) "PHPDONE" }
  mysqlendquery $db
  return

}

proc parseargs { arg } {
#Parse arguments from a query and return an array representation of query

  #Intialize variables. The loop cycles through item by item and if a switch is found it is parsed and set. If a match occurs AFTER some text has been found then a syntax error is thrown. All switches go before query
  global lfilters cfilters
  set args [split $arg]; set ardone 0; set posit 0; set lastword 0; set totalar [llength $args]; array set results {}

  #Begin loop
  while { $ardone <= $totalar } {

    #Grab the value of a switch
    set tmpvar [lrange $args [expr 0 + $ardone] [expr 1 + $ardone]]

    #Advance the position in the list
    set ardone [expr $ardone + 1]; set lastpos $posit

    #Match against possible switches. Glob is used for the nuke reason search
    switch -glob [lindex $tmpvar 0] {
      "-c" { if {![info exists results(exclude)]} { set results(exclude) "$cfilters" } else { set results(exclude) "$results(exclude)|$cfilters" }; incr posit }
      "-l" { if {![info exists results(exclude)]} { set results(exclude) "$lfilters" } else { set results(exclude) "$results(exclude)|$lfilters" }; incr posit }
      "-e" { if {![info exists results(exclude)]} { set results(exclude) [lindex $tmpvar 1] } else { set results(exclude) "$results(exclude)|[lindex $tmpvar 1]" }; incr ardone; incr posit 2 }
      "-S" { if {[lindex $tmpvar 1] <= 0} { return {"error" 3} }; set results(startat) [expr [lindex $tmpvar 1] - 1]; incr ardone; incr posit 2 }
      "-E" { if {[lindex $tmpvar 1] <= 0} { return {"error" 4} }; set results(endat) [lindex $tmpvar 1]; incr ardone; incr posit 2 }
      "-g" { set results(genre) [lindex $tmpvar 1]; incr ardone; incr posit 2 }
      "-r" { set results(results) [regsub -all {[^0-9\.]} [lindex $tmpvar 1] ""]; incr ardone; incr posit 2 }
      "-R" { set results(regexp) [lindex [lindex $tmpvar 1] 0]; incr ardone; incr posit 2 }
      "-t" { set results(days) [lindex $tmpvar 1]; incr ardone; incr posit 2 }
      "-G" { set results(grp) [lindex $tmpvar 1]; incr ardone; incr posit 2 }
      "-C" { set results(binary) "BINARY"; incr posit }
      "-o" { set results(order) "ASC"; incr posit }
      "-b" { set results(blocked) 1; incr posit }
      "-h" { set results(hideextra) 1; incr posit }
      "-Z" { set results(skin) 1; incr posit }
      "-B" { set results(skin) 1; incr posit }
      "-w" { set results(dupechk) 1; incr posit }
      "-i" { set results(nfo) 1; incr posit }
      "-I" { set results(nfo) 2; incr posit }
      "-j" { set results(jpg) 1; incr posit }
      "-J" { set results(jpg) 2; incr posit }
      "-n" { set results(nnuke) 1; incr posit }
      "-N" { set results(nnuke) 2; incr posit }
      "-N:*" { set results(nnuke) 3; set results(nrsn) [string map {\. %} [lindex [split [lindex $tmpvar 0] ":"] 1]]; incr posit }
      "-s" {
        set results(section) [string toupper [lindex $tmpvar 1]]

	#If a ! is supplied before the section then inverse the requirment for the section
        if {[string range $results(section) 0 0] == "!"} { set results(section) [string range $results(section) 1 end]; set results(negsec) "!=" }

	#If the section is not valid generate an error
        if {[type_check $results(section)]} { return {"error" 2} }

	#If a valid wildcard section has been detected subsitute the valid section
        switch $results(section) {"NULL" {set results(section) "-" } "MOVIE" {set results(section) "MOVIE-%"} "TV" {set results(section) "TV-%"}}; incr ardone; incr posit 2
      }
    }

    #If the current position has advanced (means a switch was found) and we skipped a non-switch before finding the current switch return a syntax error
    if {$posit > $lastpos} { if {[expr $ardone - $lastword] > [expr $posit - $lastpos]} { return {"error" 5} }; set lastword $ardone }
  }

  #Assemble query into array then return the array
  set results(query) [lrange $args $posit end]; return [g results]
}

proc tosql { arr type } {
#Converts true/false strings in array to SQL based on type

  #Link array from parent proc
  upvar 1 $arr results

  #Match type and return SQL
  switch $type {
    exclude { if {$results(exclude) != ""} { return "AND $results(prefix)`title` NOT REGEXP '$results(exclude)'" } }
    section { if {$results(section) != ""} { return "$results(prefix)`cat` [expr {([string first "%" $results(section)] != -1) ? [string map {"=" "like" "!=" "not like"} $results(negsec)]:$results(negsec)}] '$results(section)' AND" } }
    blocked { return "$results(prefix)`blocked` = $results(blocked) AND" }
    group { if {$results(grp) != ""} { return "$results(prefix)`grp` = '$results(grp)' AND" } }
    nfo { if {$results(nfo) == 1} { return "$results(prefix)`nfo`.`id`!='' AND" } elseif {$results(nfo) == 2} { return "$results(prefix)`nfo`.`id` is NULL AND" } }
    jpg { if {$results(jpg) == 1} { return "$results(prefix)`samplejpg`.`id`!='' AND" } elseif {$results(jpg) == 2} { return "$results(prefix)`samplejpg`.`id` is NULL AND" } }
    nuke { if {$results(nnuke) == 1} { return "$results(prefix)`nukereason`='' AND" } elseif {$results(nnuke) == 2} { return "$results(prefix)`nukereason`!='' AND" } elseif {$results(nnuke) == 3 } { return "$results(prefix)`nukereason` like '%$results(nrsn)%' AND" } }
    genre { if {[gnrok "" $results(genre)]} { return "$results(prefix)`genre` = '$results(genre)' AND" } }
    regexp { if {$results(regexp) != ""} { return "AND `$results(prefix)title` REGEXP '$results(regexp)'" } }
    query { return "$results(prefix)`title` LIKE $results(binary) '[if {!$results(dupechk)} {format %s "%"}][regsub -all {[^a-zA-Z0-9\%\?\-\.\_()\\]} [string map {_ \\_ ? _ * % " " %} $results(query)] ""][if {!$results(dupechk)} {format %s "%"}]'" }
    days { if {$results(days) != 0} { return "AND $results(prefix)`pretime`>[clock scan [clock format [expr [unixtime] + $::toffset - ($results(days) * 86400)] -format %D -gmt true]]" } }
    order { return "ORDER BY `pretime` $results(order)" }
    default { return "" }
  }
}

proc makequery { arr type } {
#Generates the query based on type

  #Link array from parent proc
  upvar 1 $arr results

  #Match against type and return query
  switch $type {
    status { return "SHOW TABLE STATUS;" }
    nfo { return "SELECT `id`,`release`,`filename`,`time` FROM `nfo` WHERE `release`='$results(query)';" }
    jpg { return "SELECT `id`,`release`,`filename`,`time` FROM `samplejpg` WHERE `release`='$results(query)';" }
    total { return "SELECT COUNT(`nfo`.`id`),COUNT(`samplejpg`.`id`),COUNT(*) FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"];" }
    pre { return "SELECT HIGH_PRIORITY `pre`.*,`nfo`.`id`,`samplejpg`.`id` FROM `pre` LEFT JOIN (`nfo`) USING (`id`) LEFT JOIN (`samplejpg`) USING (`id`) WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nfo"] [tosql results "jpg"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] [tosql results "order"];" }
    topgroup { set results(prefix) "P1."; return "SELECT P1.`grp`, COUNT(P1.`id`) AS 'total', COUNT(P2.`id`) AS 'good' FROM `pre` AS P1 LEFT JOIN `pre` AS P2 ON ([tosql results "nuke"] [tosql results "blocked"] P1.`id` = P2.`id` ) WHERE [tosql results "group"] [tosql results "genre"] [tosql results "section"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] GROUP BY P1.`grp` ORDER BY good DESC LIMIT 5;" }
    latest { return "SELECT pre.`title`,nfo.`id` FROM pre LEFT JOIN (nfo) USING (id) WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nfo"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] [tosql results "order"] LIMIT 10;" }
    col { return "SELECT `$results(col)` AS 'column', COUNT(*) AS 'total' FROM `pre` WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] GROUP BY `$results(col)` order by `$results(colord)` asc;" }
    flpre { return "(SELECT `title`,`pretime` FROM `pre` WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] [tosql results "order"] LIMIT 1) UNION (SELECT `title`,`pretime` FROM `pre` WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] [tosql results "nuke"] [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] ORDER BY `pretime` ASC LIMIT 1);" }
    flnuke { return "(SELECT `title`,`nuketime`,`nukereason` FROM `pre` WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] `nukereason`!='' AND [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] [tosql results "order"] LIMIT 1) UNION (SELECT `title`,`nuketime`,`nukereason` FROM `pre` WHERE [tosql results "section"] [tosql results "group"] [tosql results "genre"] [tosql results "blocked"] `nukereason`!='' AND [tosql results "query"] [tosql results "days"] [tosql results "exclude"] [tosql results "regexp"] ORDER BY `pretime` ASC LIMIT 1);" }
    count {
      #Since we're using upvar we must prevent changes to the variable by using a temporary variable
      array set tmp [g results]; col_select tmp $results(col)
      return "SELECT COUNT(*) FROM `pre` WHERE [tosql tmp "section"] [tosql tmp "group"] [tosql tmp "genre"] [tosql tmp "blocked"] [tosql tmp "nuke"] [tosql tmp "query"] [tosql tmp "days"] [tosql tmp "exclude"] [tosql tmp "regexp"]" }
    }
}

proc insert { type args } {
#Allows quick access for inline string creation
  global lfilters cfilters
  #Cycle against type supplied by call
  switch $type {
    blocked { if {$args} { format %s "\[4Blocked\] " } }
    nlock { if {$args == 1000} { format %s "\[7Nuke Locked\]" } }
    nuked { if {[lindex $args 0]} { format %s "\[4Nuked [dur [expr [unixtime] - [lindex $args 0]]] ago Reason: [lindex $args 1]\] " } }
    type { if {$args != ""} { format %s " in [string toupper $args]" } }
    genre { if { $args != "-"} { format %s " as $args" } }
    weight { if {$args} { format %s " weighing in at $argsMB" } }
    files { if {$args} { format %s " with $argsF" } }
    nfound { if {$args} { format %s " with NFO Available" } }
    sfound { if {$args} { format %s " and with JPG Available" } }
    date { format %s [clock format [expr $args + $::toffset] -format "%Y/%m/%d %T CET" -gmt true] }
    nrsn { if {[lindex $args 0] == 3} { format %s " where nuke reason is *[lindex $args 1]* " } }
    exclude { if {$args != "%"} { format %s " excluding [lindex [string map "$lfilters non-english $cfilters crap" $args] 0]" } }
    default { format %s "" }
  }
}

proc fixvar { varname } {
#Modifies a variable based pre-set rules matched against filename

  #Promotes the variable (varname) from the caller namespace to the current local namespace (var)
  upvar 1 $varname var

  #Cycle against variable names
  switch $varname {

    #MySQL returns NULL on any values from a left join that do not exist. TCL does not handle NULL but mysqltcl does
    nfound { if {[::mysql::isnull $var]} { set var 0 } }
    sfound { if {[::mysql::isnull $var]} { set var 0 } }

    #Oddly, genre returns an empty list instead of an empty string when truly empty. This allows us to fix that
    genre { if {[lindex $var 0]== ""} { set var "-" } }
  }
}

proc col_select { arr col } {

  #When creating a query for a count change the desired column to true
  upvar 1 $arr results

  #Cycle through column selection
  switch $col {
    blocked { set results(blocked) 1; }
    nuked { set results(nnuke) 2; }
  }

}

proc check_quality { arr } {
#Generates a SELECT query for all quality filters

  #Intialize variables
  s results $arr; set results(col) "all"

  #Cycle through quality checks and generate UNION ALL aggregate of all filters
  foreach results(regexp) $::qtypes {
    append query "([makequery results count]) UNION ALL "
  }

  #Chop off the last UNION ALL from the query and return it
  return "[string range $query 0 end-11];"
}

proc isgrp { grp } {
#Checks if argument is a valid group

  set result [::mysql::sel $::db "SELECT count(*) FROM pre WHERE grp='$grp'" -list]
  if {$result == 0} { return 0 }
  return 1

}

proc errorout { error } {
#Identifies error messages and displays output

  set p "\[4ERROR\]"
  switch $error {
    2 {return "$p Invalid section please refer to !listsections for valid sections."}
    3 {return "$p Start value cannot be a negative value."}
    4 {return "$p End value cannot be a negative value."}
    5 {return "$p All switches must be used before the search query."}
    6 {return "$p Start value cannot be greater than the end value."}
    7 {return "$p No search parameters detected, request will not be proccesed."}
    8 {return "$p Requested number of results exceed the maxiumum. Changing number of results to 50."}
  }; return ""

}

#Calculate and output duration of time from difference in unix time
proc dur {time} { set time [duration $time]; return [string map {" years" y " year" y " weeks" w " week" w " hours" h " hour" h " days" d  " day" d " minutes" m  " minute" m " seconds" s " second" s} $time] }
proc dur2 {time} { return [string map {"y" year "w" week "h" hour "d" day "m" min "s" sec} $time] }

#Converts a time difference into unixtime
proc pconvert { nick uhost hand chan arg } { putquick "PRIVMSG $chan :[clock scan "[dur2 $arg] ago"]" }

#Notify the script is loaded
putlog "Prechecker for PreScript Loaded"
