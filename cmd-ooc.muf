@program cmd-OOC.muf
1 99999 d
i
( OOC say/pose. Link an action called 'ooc' to it.)
( Should interpret quotes, colon, and hash roughly correct. )
()
( Todo: Configurable ANSI. Actual help. )

$AUTHOR BlackDjinn at Gretna Green
$VERSION 0.1000
$NOTE Fairly smart OOC formatting deal

: show
   me @ swap notify
;

: prependstring ( -- s )
   "[OOC]" "black,bg_cyan" TEXTATTR
   " "
   ME @ NAME
   STRCAT STRCAT
;

: printhelp
  "This should have something useful about help for OOC" show
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
