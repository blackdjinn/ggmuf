@program cmd-OOC.muf
1 99999 d
i
( OOC say/pose. Link an action called 'ooc' to it.)
( Should interpret quotes, colon, and hash roughly correct. )
()

$AUTHOR BlackDjinn at Gretna Green
$VERSION 1.0000
$NOTE Fairly smart OOC formatting deal

$DEF show me @ swap notify
$DEF defaultcolors "cyan"

: prependstring ( -- s )
   "[OOC]"
   me @ "/ooc/colors" getpropstr
   dup not IF
      pop defaultcolors
   THEN
   TEXTATTR
   " "
   ME @ NAME
   STRCAT STRCAT
;

: printhelp
  "Help for OOC" show
  "------------" show
  "Usage:" show
  "  Say ooc:   ooc stuff" show
  "  Say ooc:   ooc \"stuff" show
  "  Pose ooc:  ooc :stuff" show
  "  Show this: ooc #help" show
  "" show
  "Propeties:" show
  "  @set me=/ooc/colors:colorist" show
  "    where 'colorlist' is a comma seperated list of ANSI attributes." show
  "------------" show
;

: main
   STRIP DUP 1 STRCUT SWAP (s -- s' s'2 s'1)
   dup ":" strcmp 0 = IF
      pop SWAP pop " " SWAP STRCAT
   ELSE dup "\"" strcmp 0 = IF
      pop SWAP pop " says \"" SWAP STRCAT "\"" STRCAT
   ELSE DUP "#" STRCMP 0 = IF
      printhelp EXIT
   ELSE
      pop pop
      " says \"" SWAP STRCAT "\"" STRCAT
   THEN THEN THEN (s)
   prependstring SWAP STRCAT
   loc @ #-1 rot notify_except
;
.
c
q
