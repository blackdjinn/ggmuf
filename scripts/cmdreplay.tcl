#!/usr/bin/tclsh
# Chew through a command log and feed it into ther muck

#set input [open "commands"]
set address 192.168.1.202
set port 6666

set delay 2
set characters(list) {one}
set characters(one.pass) "Potrzebie"
set connections(list) {}

proc addchar {name pass} {
   global characters

   if {[lsearch -exact -nocase $characters(list) $name] >= 0} {
      puts "-- Attempt to create extant character ($name)"
   } {
      set name [string tolower $name]
      puts "-- Creating new character ($name)"
      lappend characters(list) $name
      set characters($name.pass) $pass
   }
}

proc parseline {line} {
   set splitpoint [string "  " $line]
   
}

proc sendline {linelist} {
}

proc wait {} {
}

addchar "Able" "baker"
addchar "Able" "baker"
