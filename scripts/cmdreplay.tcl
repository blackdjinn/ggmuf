#!/usr/bin/tclsh
# Chew through a command log and feed it into ther muck

set input [open "test/commands"]
set address 192.168.1.202
set port 6666

set delay 2000
set characters(list) {null keeper}
set characters(null.pass) "null"
set characters(null.channel) [open "log/null.out" "w+"]
set characters(null.log) [open "log/null.log" "w"]
set characters(keeper.pass) "null"
set characters(keeper.channel) [open "log/keeper.out" "w+"]
set characters(keeper.log) [open "log/keeper.log" "w"]

proc sendline {name content} {
global characters
set name [string tolower $name]

   puts "$name : $content"
   puts $characters($name.channel) $content
   puts $characters($name.log) ">$content"
}

proc openchar {name pass} {
# Handle connection to output.
global characters
global address
global port

puts 1111
   set characters($name.log) [open "log/$name.log" "w"]
puts 2222
   set characters($name.channel) [socket $address $port]
puts 3333
   fconfigure $characters($name.log) -blocking false -buffering none
puts 4444
   wait
puts 5555
   sendline $name "connect $name $characters($name.pass)"
puts 6666
   wait
puts 7777
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
puts xxx
      openchar $name $pass
puts yyy
   }
}

proc parseline {line} {
# Main loop action. This dispatches other actions like character creation
# and other special actions that require updates on internal program stuff.
   set splitpoint [string first "  " $line]
   set content [string range $line [expr {$splitpoint + 2}] end]
   set nameend [expr {[string first "(" $line] - 1}]
   set namestart [expr {[string last " " $line $nameend] + 1}]
   set name [string range $line $namestart $nameend]
puts ">$name< >$content<"
   # Since all we actually need to do is catch @pcreate
   # we test for them.
   if {[string equal -nocase -len 8 "@pcreate" $content]} {
      # We have @pcreate
      set newname [string range $content 9 [expr {[string first "=" $content] -1}]]
      set newpass [string range $content [expr {[string first "=" $content] + 1}] end]
      addchar $newname $newpass
   }
   sendline $name $content
}

proc wait {} {
global delay
   after $delay
   emptyrecv
}

proc emptyrecv {} {
global characters

puts aaa
   foreach name $characters(list) {
puts "bbb $name"
puts [eof $characters($name.channel)]
      set line [read $characters($name.channel)]
puts "ccc $name"
      puts $characters($name.log) "<$line"
      puts "$name < $line"
puts ddd
   }
}

addchar "one" "potrzebie"
# Starting main loop
gets $input line
emptyrecv
while {! [eof $input]} {
   parseline $line
   emptyrecv
   wait
   emptyrecv
   gets $input line
}
