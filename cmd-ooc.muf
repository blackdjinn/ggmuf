@program cmd-OOC.muf
1 99999 d
i
( OOC say/pose. Link an action called 'ooc' to it.)
( Should interpret quotes, colon, and hash roughly correct. )
$AUTHOR BlackDjinn at Gretna Green
$VERSION 0.0001
$NOTE Fairly smart OOC formatting deal

: tell
   me @ swap notify
;

: prependstring ( -- s )
   "[OOC]" "black,bg_cyan" TEXTATTR
   " "
   ME @ NAME
   STRCAT STRCAT
;

: printhelp
  "This should have something useful about help for OOC" tell
;

: main
   STRIP DUP STRCUT SWAP (s -- s' s'2 s'1)
   dup ":" strcmp 0 = IF
      DROP SWAP DROP " " SWAP STRCAT
   ELSE dup "\"" strcmp 0 = IF
      DROP SWAP DROP " says \"" SWAP STRCAT "\"" STRCAT
   ELSE DUP "#" STRCMP 0 = IF
      printhelp EXIT
   THEN THEN THEN (s)
   prependstring SWAP STRCAT
   here @ #-1 rot notify-except
;
.
c
q
