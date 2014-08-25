@program obvious-exits.muf
1 9999 d
i
( obvious-exits.muf, by Scotfox, 26-September-1993 )
( Originally by cknight@polyslo.calpoly.edu, jph@irie.ais.org, )
( pleiades@ucrmath.ucr.edu, and dragon@glia.biostr.washington.edu. )
 
( Usage: @succ here = @$exits optional-text-before-list )
 
( Example: @succ here = @$exits The sun is shining brightly. )
( When you look at the room, this gives: )
 
( Room Name )
( description )
( The sun is shining brightly. )
( [Obvious exits: north, south, east, west ] )
 
( @set an exit = Dark to hide it.  Only the first part of an exit's )
( name is used by this program -- 'one;two;three' appears as 'one'. )
( For mucks that don't allow players to set things dark, you can also )
( set a "dark" or a "_dark" property on the exit. )
 
$define tellme  me @ swap notify  $enddef
 
: list-exits ( first -- list-string )
    "" swap  ( list-string dbref )
    me @ "_prefs/obvexits/vertical" getpropstr if 
        trigger @ "exitlist_start" envpropstr swap pop
        dup strlen 0 = if pop "Obvious exits: " then
        rot strcat tellme
    then
    begin dup #-1 dbcmp not while
        dup "dark" flag? if next continue then  ( ignore it if it's dark )
        dup "dark" getpropstr if next continue then  ( allow "dark" prop too )
        dup "_dark" getpropstr if next continue then  ( also "_dark" prop )
        dup getlink dup ok? swap room? and not if
            next continue then  ( ignore it unless it goes somewhere )
 
        ( list-string dbref )
 
        dup name
        dup ";" instr dup if 1 - strcut pop else pop then  ( get 1st alias )

	me @ "_prefs/obvexits/vertical" getpropstr if
	  tellme next continue
	then
 
        ( list-string dbref exitname )
 
        rot  ( dbref exitname list-string )
        dup "" strcmp if ", " strcat then  ( add comma if not first exit )
 
        swap strcat  ( dbref list-string )
 
        swap next repeat
    pop  ( list-string )
;
: obvious-exits
    dup if tellme then  ( header to obvious exits list, if any )
 
    trigger @ exits list-exits
    ( exitstring )
 
    me @ "_prefs/obvexits/vertical" getpropstr if
      exit  ( exit if we've already shown exits in vertical format )
    then
  
    dup "" strcmp if
        trigger @ "exitlist_start" envpropstr swap pop
        dup strlen 0 = if pop "[ Obvious exits: " then
        swap strcat
 
        trigger @ "exitlist_end" envpropstr swap pop
        dup strlen 0 = if pop " ]" then
        strcat
 
        tellme 
    then
;
.
c
q
