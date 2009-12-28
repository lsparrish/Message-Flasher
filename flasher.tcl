#!/usr/bin/wish

proc WinIcon { } {
  set ico_text "Message Flasher"
  winico createfrom "./mf2.ico"
  variable hidden 0
  proc ShowHide {} {
    global hidden
    if {$hidden == 0 } {
      wm withdraw .
      set hidden 1
    } else {
      wm deiconify .
      set hidden 0
    }
  }

 proc winicoCallback {t {x 0} {y 0}} {
     if { $t == "WM_LBUTTONUP" } {
          ShowHide
        } elseif { $t == "WM_RBUTTONUP" } {
          StartStop
#		  ShowHide;ShowHide
#          .winicoPopup post $x $y  # Menu not yet implemented.
#          .winicoPopup activate 0
        }
   }

  winico taskbar add ico#1 -text $ico_text\
    -callback { winicoCallback %m %x %y } 

  proc Cleanup { } {
    winico taskbar delete ico#1
  }

  rename exit _exit
  proc exit {args} {
    if ![info exists $args] { set args 0 }
    if [info exists ico#1] { Cleanup }	
    Cleanup
    _exit $args
   
  }

}

proc Config { } {
  global showfor
  global hidefor
  set showfor 100
  set hidefor 8000
}


proc wait { delay } {
  # A more responsive alternative to "after".
  # Checks for user input every 10 miliseconds.
  global stop
  set remainder [expr $delay % 10 ]
  set delay [expr $delay / 10]
  for {set i 0} {$i<$delay} {incr i} {
	if {$stop} {continue}
    after 10
    update
  }
  if $remainder { after $remainder; update }
}

proc LoadAffs { } {
  global data
  set fp [open "aff.txt" r]
  set data [read -nonewline $fp]
  .affs delete 1.0 end
  .affs insert 1.0 $data
  update
  set data [split $data "\n"]
  close $fp
  StartStop
}

proc SaveAffs { } {
  set fp [open "aff.txt" w]
  puts -nonewline $fp [.affs get 1.0 end]
  close $fp
  StartStop
}

proc StartGUI { } {
  InitFlasher
  MakeWin
  .load invoke
  focus .
}

proc InitFlasher { } {
  toplevel .msg
  wm transient .msg
  wm overrideredirect .msg on
  wm withdraw .msg
  set fontsize "terminus-14"
  label .msg.output -text "Flasher not yet running." -font $fontsize
  pack .msg.output
  update
  variable x 0
  variable y 0
}

proc PickCorner { } {
  variable x
  variable y
  set x [expr int([rand 2])]
  set y [expr int([rand 2])]
}

proc StartStop { } {
  global stop
  global data
  if ![info exists stop] { set stop 0 }

  if { $stop == 0 } {
    set stop 1
    .start configure -text "Start"
	update
  } else {
    set stop 0
    .start configure -text "Stop"
	update
  }

  set data [.affs get 1.0 end]
  set data [split $data "\n"]
  global hidefor
  set hidefor [.hidefor get]
  global showfor
  set showfor [.showfor get]
  
  while (1) {
    if $stop break
    foreach line $data {
      if {$line == "."} { break }
      if {$line == ""} { continue }
      if {[string index $line "0"] == "#"} { continue }
      if !$stop {
        FlashMessage $line
      }
    }
  }
  wm withdraw .msg; update
}

proc PickCorner { } {
  set rand [expr {int(rand()*4) + 1}]
  switch -exact --$rand {
  --1 { wm geometry .msg +100-100 }
  --2 { wm geometry .msg +100+100 }
  --3 { wm geometry .msg -100+100 }
  --4 { wm geometry .msg -100-100 }
  }
}


proc FlashMessage { line } {
  global showfor; global hidefor; global stop
  PickCorner
  wm deiconify .msg
  if $stop { return 0 }
  .msg.output configure -text $line
  wm deiconify .msg; update
  wait $showfor

  wm withdraw .msg; update
  if $stop {return 0}
  wait $hidefor
}

proc MakeWin {} {
	wm geometry . +0+0
  button .start -text "Start" -command StartStop
#  button .stop -text "Stop" -command {global stop; set stop 1}
  button .load -text "Load" -command LoadAffs
  button .save -text "Save" -command SaveAffs
  button .exit -text "Exit" -command { exit} 
#  button .hide -text "Hide" -command {global hidden;wm withdraw .; set hidden 1} 

  text .affs -font "terminus-14"
  pack .affs -side bottom
  pack .start .load .save .exit -side left -ipadx 5
  
  global hidefor
  label .hf -text "Off:"
  entry .hidefor -width 5
  .hidefor delete 0 end
  .hidefor insert 0 $hidefor
  pack .hf .hidefor -side left

  global showfor
  label .sf -text "On:"
  entry .showfor -width 5
  .showfor delete 0 end
  .showfor insert 1 $showfor
  pack .sf .showfor -side left

  label .info -text "Welcome To The Message Flasher."
  pack .info -side left

  bind . <Escape> {exit}
  bind .affs <Key-Tab>       {focus [tk_focusNext %W];break}
  bind .affs <Shift-Key-Tab> {focus [tk_focusPrev %W];break}

  StartStop
   
  update
}
#WinIcon
Config
StartGUI
