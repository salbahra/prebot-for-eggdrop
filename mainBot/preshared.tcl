#Offset for time calculation (Converts GMT to CET)
set toffset 3600

#Allows messages to be output based on input
proc tmsg {type form to arg} {
  switch $type {
    "bot" { putbot $to "$form$arg" }
    "pub" { putnow "$form $to :$arg" }
    "dcc" { putdcc $to "PHPCAP$form: $arg" }
    "dcc2" { putdcc $to "$arg$form" }
  }
}

#Alternative to puthelp/putserv that has no queue
proc putnow { arg } {
  global mcpskey
  set colonpos [ string first ":" $arg ]
  set partone [ string range $arg 0 [expr $colonpos - 1 ] ]
  set partone [ split $partone " " ]
  set prefixkeyword [lindex $partone 0]
  set dest [string tolower [lindex $partone 1]]
  set msg [ string range $arg [ expr $colonpos + 1 ] end ]
  set chankey ""
  if {[info exists mcpskey($dest)] != 0} {
    set chankey $mcpskey($dest)
    set msg "mcps [encrypt $chankey $msg]"
  }
  set newtext "$prefixkeyword $dest :$msg"
  append newtext "\n"
  putdccraw 0 [string length $newtext] $newtext
}

#Calculates percentage and returns only 2 decimal points
proc p {num total} { format %.2f%% [expr {$num * 100. / $total}] }

#Adds all elements of a list and returns their contents
proc ladd L {expr [join $L +]+0}

#Alias for array get
interp alias {} g {} array get

#Alias for array set
interp alias {} s {} array set
