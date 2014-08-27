@program cmd-OOC.muf
1 99999 d
i
( OOC comsys. Link a command to this to create a channel )
( Should interpret quotes, colon, and hash roughly correct. )
()

$AUTHOR BlackDjinn at Gretna Green
$VERSION 0.0001

$DEF show me @ swap notify
$DEF }show me @ swap notify
$DEF defaultcolors "cyan"

: prependstring ( -- s )
   trigger @ "/comsys/displayname" getpropstr
   " "
   ME @ NAME
   STRCAT STRCAT
;

: printhelp
  "Stub Help. We know this should exist."
;

: doOption
   printhelp
;

: doPose
   "pose" show
;

: doSay
   "say" show
;

: main
   STRIP DUP 1 STRCUT SWAP (s -- s' s'2 s'1)
   dup ":" strcmp 0 = IF
      pop swap pop doPose
   ELSE DUP "#" STRCMP 0 = IF
      pop swap pop doOption
   ELSE DUP """ STRCMP 0 = IF
      pop swap pop doSay
   ELSE
      pop pop doSay
   THEN THEN THEN
;
.
c
q
