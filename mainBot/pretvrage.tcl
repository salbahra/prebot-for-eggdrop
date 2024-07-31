bind pub - !today pub:tvrage.com.today
bind pub - !tomorrow pub:tvrage.com.tomorrow
bind pub - !showinfo pub:tvrage.com.showinfo
bind pub - !schedule pub:tvrage.com.schedule

package require http
setudef flag tv

proc pub:tvrage.com.schedule {nick uhost hand chan text} {
   set seconds [clock seconds]
   set days(sun) 0
   set days(mon) 1
   set days(tue) 2
   set days(wed) 3
   set days(thu) 4
   set days(fri) 5
   set days(sat) 6

   if ![info exist days([string tolower $text])] return

   set currDay [clock format $seconds -format "%w"]

   if {$currDay > $days([string tolower $text])} {
      parse:tvrage.com $nick $uhost $hand $chan $text [expr (7 - $currDay) + $days([string tolower $text])]
   } else {
      parse:tvrage.com $nick $uhost $hand $chan $text [expr $days([string tolower $text]) - $currDay]
   }
}


proc pub:tvrage.com.today {nick uhost hand chan text} {
   parse:tvrage.com $nick $uhost $hand $chan $text "0"
}

proc pub:tvrage.com.tomorrow {nick uhost hand chan text} {
   parse:tvrage.com $nick $uhost $hand $chan $text "1"
}

proc parse:tvrage.com.encodeURL {str} {
   set str [string map {" " +} $str]
   foreach c [split $str {}] {
      if {$c == "+" || [string is alnum $c]} {append x $c} {
         binary scan $c H2 c; append x %$c
      }
   }

   return $x
}

proc pub:tvrage.com.showinfo {nick uhost hand chan text} {
   if ![channel get $chan tv] return

   #set token [http::geturl [join [list "http://services.tvrage.com/tools/quickinfo.php?show=" [ncgi::encode [string trimleft $text]]] ""]]
   set token [http::geturl [join [list "http://services.tvrage.com/tools/quickinfo.php?show=" [parse:tvrage.com.encodeURL [string trimleft $text]]] ""]]
   set data [http::data $token]
   http::cleanup $token
   set show(title) ""

   foreach line [split $data \n] {
      if {[regexp {^No Show Results Were Found For \".*\"$} $line]} {
         putnow "PRIVMSG $chan :\00300$line\00315"
         return
      }
      if {[regexp {^Show Name@(.*)$} $line -> match]} { set show(title) $match }
      if {[regexp {^Show URL@(.*)$} $line -> match]} { set show(url) $match }
      if {[regexp {^Premiered@(.*)$} $line -> match]} { set show(premiered) $match }
      if {[regexp {^Latest Episode@(\d+)x(\d+)\^([\w\'\.\, \#\&\@\:\(\)\-]+)\^([\w\/]+)$} $line -> season episode eptitle epDate]} {
         set show(latest) [join [list "\00314$season" "x$episode - $eptitle ($epDate)\00300"] ""]
      }
     if {[regexp {^Next Episode@(\d+)x(\d+)\^([\w\'\.\, \#\@\&\:\(\)\-]+)\^([\w\/]+)$} $line -> season episode eptitle epDate]} {
         set show(next) [join [list "\00314$season" "x$episode - $eptitle ($epDate)\00300"] ""]
      }
      if {[regexp {^Country@(.*)$} $line -> match]} { set show(country) $match }
      if {[regexp {^Status@(.*)$} $line -> match]} { set show(status) $match }
      if {[regexp {^Classification@(.*)$} $line -> match]} { set show(class) $match }
   }

   if ![info exist show(next)] { set show(next) "N/A" }

   #putnow "PRIVMSG $chan :\00300Title ::\00315 \00300$show(title)\00315 \00300<>\00315 \00300URL ::\00315 \00300$show(url)\00315 \00300<>\00315 \00300Premiered ::\00315 \00300$show(premiered)\00315 \00300<>\00315 $show(latest) \00300<>\00315 $show(next) \00300<>\00315 \00300Country ::\00315 \00300$show(country)\00315 \00300<>\00315 \00300Status ::\00315 \00300$show(status)\00315"
putnow "PRIVMSG $chan :\00307\[\00314\002Title\002: $show(title)\00307\] \00307\[\00314\002Web\002: $show(url)\00307\] \[\00314\002Premiered\002: $show(premiered)\00307\] \[\00314\002Country\002: $show(country)\00307\] \[\00314\002Status\002: $show(status)\00307\]"
putnow "PRIVMSG $chan :\00307\[\00314\002Latest Ep\002: $show(latest)\00307\] \[\00314\002Next Ep\002: $show(next)\00307\]"
}

proc parse:tvrage.com {nick uhost hand chan text when} {
   if ![channel get $chan tv] return
   global db
   set token [http::geturl http://services.tvrage.com/tools/quickschedule.php]
   set data [http::data $token]
   http::cleanup $token
   set date ""
   set systemTime [clock seconds]
   set systemTime [expr $systemTime + 3600]
   set currentTime ""
   set parsing 0
   set currentOutput ""
   set gotTime 0
   set neededDate ""
   set neof 1

   set systemTime [expr "$systemTime + ($when * 86400)"]
   set neededDate [clock format $systemTime -format "%A, %d %b %Y"]
   foreach line [split $data \n] {
      if {[regexp {^\[DAY\]([\w\, ]+)\[\/DAY\]$} $line -> date]} {
         if {$parsing == 1} {
            break;
         }

         if {$date == $neededDate} {
            putnow "NOTICE $nick :New TV Shows for $date *All Times in EST/EDT*"
            set parsing 1
         }
      }

      if {$parsing} {
	  regexp {^\[TIME\]([\w\: ]+)\[\/TIME\]$} $line -> currentTime
         regsub -all {\x92} $line {'} line
         if {[regexp {^\[SHOW\]([ \w\&\!]+)\^([\-\(\)\#\w \'\`\:&\!\/]+)\^([\dx]+)\^([\w\\\/\:\.\-]+)\[\/SHOW\]$} $line -> network title epnum url]} {
            regsub -all { } $title {.} title
            regsub -all {[\!\'\)\(]} $title {} title
            regsub -all {&} $title {And} title
            regsub -all {/} $title {.} title
            regsub -all {x} $epnum {E} epnum
	     set title "$title.S$epnum"
	     set results [lindex [mysqlsel $db "SELECT `title`,`pretime` FROM `pre` WHERE `title` LIKE '$title%' LIMIT 1" -list] 0]
	     if {[lindex $results 0] != ""} { set title "[lindex $results 0] ([dur [expr [unixtime] - [lindex $results 1]]])" }
            putnow "NOTICE $nick :\002$currentTime:\002 \[7$network\] $title"
         }
      }
   }
}

putlog "TVRage.com Primetime Schedule v0.5"
