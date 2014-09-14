#!/usr/bin/tclsh
# Chew through a command log and feed it into ther muck

set input [open "test/commands"]
set address 192.168.1.202
set port 6666
set linecount 0

set delay 500
set characters(list) {null keeper}
set characters(null.pass) "null"
set characters(null.channel) [open "log/null.out" "w+"]
set characters(null.log) [open "log/null.log" "w"]
set characters(keeper.pass) "null"
set characters(keeper.channel) [open "log/keeper.out" "w+"]
set characters(keeper.log) [open "log/keeper.log" "w"]

proc sendline {name content} {
global characters
global linecount
set name [string tolower $name]

   puts "$name : $content"
   puts $characters($name.channel) $content
   puts $characters($name.log) "$linecount>$content"
}

proc openchar {name pass} {
# Handle connection to output.
global characters
global address
global port

   set characters($name.log) [open "log/$name.log" "w"]
   set characters($name.channel) [socket $address $port]
   fconfigure $characters($name.channel) -blocking false -buffering none
   wait
   sendline $name "connect $name $characters($name.pass)"
}

proc addchar {name pass} {
   global characters

   if {[lsearch -exact -nocase $characters(list) $name] >= 0} {
      puts "-- Attempt to create extant character ($name)"
   } {
      set name [string tolower $name]
      puts "-- Creating new character ($name) with password ($pass)"
      lappend characters(list) $name
      set characters($name.pass) $pass
      openchar $name $pass
   }
}

proc parseline {line} {
global linecount
# Main loop action. This dispatches other actions like character creation
# and other special actions that require updates on internal program stuff.
   set splitpoint [string first "  " $line]
   set content [string range $line [expr {$splitpoint + 2}] end]
   set nameend [expr {[string first "(" $line] - 1}]
   set namestart [expr {[string last " " $line $nameend] + 1}]
   set name [string range $line $namestart $nameend]
   incr linecount
   puts "$linecount >$name< >$content<"
   sendline $name $content
   # Since all we actually need to do is catch @pcreate
   # we test for them.
   if {[string equal -nocase -len 8 "@pcreate" $content]} {
      # We have @pcreate
      set newname [string range $content 9 [expr {[string first "=" $content] -1}]]
      set newpass [string range $content [expr {[string first "=" $content] + 1}] end]
      wait
      addchar $newname $newpass
      sendline one "give *$newname=10000"
   }
}

proc wait {} {
global delay
   after $delay
   emptyrecv
}

proc emptyrecv {} {
global characters

   foreach name $characters(list) {
      while {[gets $characters($name.channel) line] >= 0} {
         puts $characters($name.log) "<$line"
         puts "$name < $line"
      }
   }
}

addchar "one" "potrzebie"
# Starting main loop
gets $input line
emptyrecv
while {! [eof $input]} {
   parseline $line
   wait
   gets $input line
}
