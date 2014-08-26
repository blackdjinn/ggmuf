@program cmd-roll.muf
1 99999 d
i
( Roll some %iles and note matches. )
()

$AUTHOR BlackDjinn at Gretna Green
$VERSION 1.0000
$NOTE oh dear...

$DEF show me @ swap notify
$DEF showall loc @ #-1 rot notify_except

: main
   frand 100 * 1 + floor int dup
   me @ name
   "<DICE>" "green" TEXTATTR
   "%s %s rolled %i (1-100) " fmtstring
   swap dup 11 % not swap 100 = or
   IF "Match!" "bold" textattr strcat THEN
   showall
;
.
c
q
