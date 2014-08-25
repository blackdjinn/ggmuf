@q
@program jboard.muf
1 99999 d
i
( jboard.muf    v1.1    Jessy @ FurryMUCK    7/99
  
  A global bulletin board program: a single action runs multiple
  boards. Features include controlled access to specific boards,
  search capabilities, and navigation aids for viewing `new' and
  `next' posts.
  
  INSTALLATION:
  
  Create a global action named 
    
    read;write;editmsg;delete;next;board 
     
  and link it to this program. JBoard.muf requires M3, but setting
  it Wizard is recommended. The program also requires lib-editor,
  lib-lmgr, lib-reflist, and lib-strings, all of which should be
  installed on any established MUCK.
  
  IMPORTANT NOTE: If you wish to use other command names, DO NOT
  manually rename the command... Instead, use the built-in aliasing 
  and renaming #options.
  
    <cmd> #alias <alias name>
    <cmd> #rename <new name>
  
  Examples:
  
  To add `del' as an alias for `delete': 
    
    delete #alias del
  
  To rename the `read' command to `+read':
  
    read #rename +read
    
  USE:
  
  Some user commands include:
  
    read ........................... Display list of boards
    read <board> ................... List posts on <board>
    read <board>/<post> ............ Display <post> from <board>
    read #search <string> .......... Search all boards for <string>
    read #search <board>/<string> .. Search <board> for <string>
    read #new <board> .............. Display new posts on <board>
    write <board>/<subject> ........ Write post <subject> on <board>
    write #noname <board>/<subject>  Write an anonymous post on <board>
    edit <board>/<post> ............ Edit <post> on <board>
    delete <board>/<post> .......... Delete <post> on <board>
    next ........................... Show next post in <board|search>
    board #window <number> <units> . Set `new posts' window
    
  Administrative commands include:
  
    board #create .................. Create a new board
    board #destroy .................. Delete an existing board
    board #private <board> ......... Set <board> private
    board #open <board> ............ Set <board> open
    board #include <board>/<player>  Give <player> access to <board>
    board #exclude <board>/<player>  Remove <player>'s access to <board>
    board #noname <board> .......... Toggle <board>'s nonames allowed
    board #staff <board> ........... Set <board> staff-only
    board #general <board> ......... Set <board> general public
    board #add <player> ............ Add <player> to admin list
    board #remove <player> ......... Remove <player> from admin list
  
  #Help is available for each command. 
  
  Boards and posts can be specified by name or number.
  
  #Argument strings do not have to be typed completely: typing the
  first one or several characters will produce the same result. For
  example, typing `read #s rosebud' will produce the same result as
  `read #search rosebud'.
  
  Next displays either then post immediately following the one you last
  read, or -- if you issued a #search and have not issued a standard
  read since then -- the next match in your last #search.
  
  Edit and delete permission is given to the author of a post, the
  owner of the program or trigger, wizards, and anyone included in the
  admin list.
  
  Private boards are visible only to #included players and admins.
  Because some players will not see some boards, board numbering can
  be different for different players.
  
  Staff-only boards can be read by anyone, but only written to by 
  admins... intended for policy postings and the like.
  CHANGES:
  1.1  Fixed counting errors that arose with #private boards. Fixed
       a crasher bug in #exclude.
  
  JBoard.muf may be freely ported. Please comment any changes.
)
  
$include $lib/reflist
$include $lib/lmgr
$include $lib/editor
$include $lib/strings
   
$define Tell me @ swap notify $enddef
  
lvar ourArg               (* str: user's #arg string; may be modified *)
lvar ourCom                  (* str: unchanged copy of lvar `command' *)
lvar ourCounter                   (* str or int: flow-control counter *)
lvar ourCounter2                  (* str or int: flow-control counter *)
lvar ourPostCounter               (* str or int: flow-control counter *)
lvar ourBoard                        (* str: propdir of current board *)
lvar ourSubject                        (* str: formatted post subject *)
lvar ourPost                          (* str: propdir of current post *)
lvar ourString                                  (* str: workspace var *)
lvar ourTime                                   (* int: time-check var *)
lvar ourBoolean                              (* int: flow-control var *)
lvar listString                            (* str: list-handling vars *)
lvar listCounter
lvar listScratch
   
: AddListLine  ( s s' --  )       (* add line s' to list s on library *)
  
  over prog LMGR-GetCount 1 + 3 pick prog LMGR-PutElem pop
;
  
: EditLoop  ( listname dbref {rng} mask currline cmdstring  --  )
                                        (* read input for list editor *)
  EDITORloop
  dup "save" stringcmp not if
    pop pop pop pop
    3 pick 3 + -1 * rotate
    over 3 + -1 * rotate
    dup 5 + pick over 5 pick
    over over LMGR-DeleteList
    1 rot rot LMGR-PutRange
    4 pick 4 pick LMGR-GetList
    dup 3 + rotate over 3 + rotate
    ">>  Post saved." Tell
    "" EditLoop exit
  then
  dup "abort" stringcmp not if
    ">>  Post not saved." Tell
    pop pop pop pop pop pop pop pop pop exit
  then
  dup "end" stringcmp not if
    pop pop pop pop pop pop 
    dup 3 + rotate over 3 + rotate
    over over LMGR-DeleteList
    1 rot rot LMGR-PutRange
    ">>  Post saved." Tell exit
  then
;
  
: EditList  ( d s --  )                           (* edit list s on d *)
  
  swap
">>  Welcome to the post editor. You can get help by entering `.h' on"
Tell
">>  a line by itself. `.end' will save and exit. `.abort' will abort"
Tell
">>  any changes. To save changes and continue editing, use `.save'."
Tell
  over over LMGR-GetList
  "save" 1 ".i $" EditLoop
;
  
: ShowList  ( d s --  )                 (* display list s on object d *)
  
  swap LMGR-GetList
  begin                                    (* begin line-listing loop *)
    dup while
    dup 1 + rotate Tell
    1 -
  repeat                                     (* end line-listing loop *)
  pop
;
  
: RemoveDir   ( d s --  )       (* remove dir s from d; leave subdirs *)
    
  dup "*/" smatch not if          (* add a trailing / slash if needed *)
    "/" strcat
  then
                              (* loop through and remove props in dir *)
  over over nextprop swap pop
  begin                                   (* begin prop-removing loop *)
    dup while
    over over nextprop
    3 pick rot remove_prop
  repeat                                    (* end prop-removing loop *)
  pop pop
;  
   
: ParseTimeString  ( s -- i1 i2 )  
  
(* convert string s to number of seconds i1. i2 is true if successful *)
  (* format of s is `<num> <units>', eg `3 hours', `1 day', `2 weeks' *)
  
                                                   (* tokenize string *)
  " " explode dup 2 = if       (* check syntax and bail out if needed *)
    pop                 
  else
    begin
      dup while
      swap pop
      1 -
    repeat
    pop
    ">>  Entry not understood." Tell 0 exit
  then
                                    (* parse units and convert amount *)
  swap strip 
  "seconds" over stringpfx if 1        else
  "minutes" over stringpfx if 60       else
  "hours"   over stringpfx if 3600     else
  "days"    over stringpfx if 86400    else
  "weeks"   over stringpfx if 604800   else
  "months"  over stringpfx if 1036800  else
  "years"   over stringpfx if 12441600 else
  pop pop 0 exit
  then then then then then then then 
  swap pop swap atoi * 
  dup 0 < if
    ">>  ERROR: Result out of range." Tell pid kill
  else
    1
  then
;  
  
: CheckAdminPerm  (  --  )     (* return true if user has admin perms *)
  
  me @ "W" flag?                                           (* wizard? *)
  prog owner me @ dbcmp                                (* prog owner? *)
  trig owner me @ dbcmp                                (* trig owner? *)
  prog "_admin" me @ REF-inlist? or or or if     (* configured admin? *)
    1                                         (* any of those qualify *)
  else
    0                                                (* otherwise, no *)
  then
;
   
: CheckBoardPerm ( s -- i ) (* return true if user is allowed board s *)
   
  CheckAdminPerm if
    pop 1 exit
  then
  
                                           (* see if board is private *)
  prog "_closed/" 3 pick 
  dup "*/" smatch if dup strlen 1 - strcut pop then
  strcat getpropstr
  if 
                             (* see if user is auth for private board *)
    prog "_closed/" rot strcat "/" strcat me @ intostr strcat
    getprop if
      1
    else
      0
    then
  else
    pop 1
  then
;
 
: CheckPostPerm    ( s -- i )(* return true if user can delete post s *)
  
  prog swap "/auth" strcat getprop me @ dbcmp              (* author? *)
  CheckAdminPerm or if                              (* administrator? *)
    1                                                (* if either, ok *)
  else
    0
  then
;
  
: CheckOldPost  ( s -- i )   (* return true if post is `old' for user *)
   
     (* `old' is outside window, if set, or older than last read post *)
  dup "." rinstr 1 - strcut pop
  dup "/" rinstr strcut swap pop
  atoi 
  me @ "_prefs/news/lastpost" getpropstr if       (* older than last? *)
    dup me @ "_prefs/news/lastpost" getpropstr
    dup "." rinstr 1 - strcut pop
    dup "/" rinstr strcut swap pop
    atoi <= if
      pop 1 exit
    then
  then
  me @ "_prefs/news/window" getprop dup if         (* outside window? *)
    systime swap - <= if
      1
    else
      0
    then
  else
    pop pop 0
  then
;
   
: SetNew  (  --  )            (* strip #n from arg and set ourBoolean *)
  
  ourArg @ " " instr dup if           (* strip `#new' from arg string *)
    ourArg @ swap strcut swap pop strip ourArg !
  else
    pop
  then
  1 ourBoolean !     (* this will tell DisplayPostList to exclude old *)
;
    
: UpdateLast  (  --  )           (* update `last read' tracking props *)
  
  me @ "_prefs/news/lastpost" ourPost @ setprop
  ourPost @ dup "." rinstr 1 - strcut pop
  dup "/" rinstr strcut swap pop
  atoi me @ "_prefs/news/lasttime" rot setprop
;
  
: GetCurrentCommandName  ( s -- s' )  (* return current name of com s *)
  
  prog "_orign/" 3 pick strcat getpropstr dup if
    swap pop
  else
    pop
  then
;
  
: GetOtherCommandNames  ( s -- s' ) 
          (* return formatted string of all jboard com names except s *)
  
  dup "read" smatch if
    pop
    "write"  GetCurrentCommandName ", "     strcat 
    "edit"   GetCurrentCommandName ", "     strcat strcat
    "delete" GetCurrentCommandName ", "     strcat strcat
    "next"   GetCurrentCommandName ", and " strcat strcat
    "board"  GetCurrentCommandName strcat
  else
  dup "write" smatch if
    pop
    "read"   GetCurrentCommandName ", "     strcat 
    "edit"   GetCurrentCommandName ", "     strcat strcat
    "delete" GetCurrentCommandName ", "     strcat strcat
    "next"   GetCurrentCommandName ", and " strcat strcat
    "board"  GetCurrentCommandName strcat
  else
  dup "edit" smatch if
    pop
    "read"   GetCurrentCommandName ", "     strcat 
    "write"  GetCurrentCommandName ", "     strcat strcat
    "delete" GetCurrentCommandName ", "     strcat strcat
    "next"   GetCurrentCommandName ", and " strcat strcat
    "board"  GetCurrentCommandName strcat
  else
  dup "delete" smatch if
    pop
    "read"   GetCurrentCommandName ", "     strcat 
    "write"  GetCurrentCommandName ", "     strcat strcat
    "edit"   GetCurrentCommandName ", "     strcat strcat
    "next"   GetCurrentCommandName ", and " strcat strcat
    "board"  GetCurrentCommandName strcat
  else
  dup "next" smatch if    
    pop
    "read"   GetCurrentCommandName ", "     strcat 
    "write"  GetCurrentCommandName ", "     strcat strcat
    "edit"   GetCurrentCommandName ", "     strcat strcat
    "delete" GetCurrentCommandName ", and " strcat strcat
    "board"  GetCurrentCommandName          strcat 
  dup "board" smatch if
    pop
    "read"   GetCurrentCommandName ", "     strcat strcat
    "write"  GetCurrentCommandName ", "     strcat strcat
    "edit"   GetCurrentCommandName ", "     strcat strcat
    "delete" GetCurrentCommandName ", and " strcat strcat
    "next"   GetCurrentCommandName          strcat 
  then then then then then then
;
  
: GetBoardName  ( s -- s' )        (* return name of board for prop s *)
  
  "" "_boards/" subst                        (* remove propdir string *)
  "" "/" subst                                   (* remove trailing / *)
;
  
: GetNumPosts  ( s -- s' )       (* return number of posts on board s *)
  
  0                                     (* put a counter int on stack *)
  prog rot "/" strcat nextprop
  begin                                   (* begin post-counting loop *)
    dup while
    swap 1 + swap                  (* bump counter for each post prop *)
    prog swap nextprop
  repeat
  pop
  intostr                                       (* return total found *)
;
  
: GetNumNewPosts  ( s -- s' )    (* return number of posts on board s *)
  
  0 ourPostCounter !
  0                                     (* put a counter int on stack *)
  prog rot "/" strcat nextprop
  begin                                   (* begin post-counting loop *)
    dup while
    dup CheckOldPost not if 
      ourPostCounter @ 1 + ourPostCounter !
    then
    swap 1 + swap                  (* bump counter for each post prop *)
    prog swap nextprop
  repeat
  pop pop
  ourPostCounter @ intostr                      (* return total found *)
;
  
: GetPostNumber ( s -- s' )                (* return number of post s *)
  
  0 ourCounter !
  dup dup "/" rinstr strcut pop
  prog swap nextprop
  begin                                   (* begin post-counting loop *)
    dup while
    ourCounter @ 1 + ourCounter !
    over over smatch if 
      pop pop ourCounter @ intostr exit             (* found it... go *)
    then
    prog swap nextprop
  repeat                                    (* end post-counting loop *)
  pop "X"       (* if post not found, return harmless, inaccurate `X' *)
;
  
: GetBoardNumber  (  -- s' )       (* return number of board ourBoard *)
  
  0 ourCounter !
  prog "_boards/" nextprop
  begin                                  (* begin board-counting loop *)
    dup while
    dup CheckBoardPerm not if            (* skip ones users can't see *)
      prog swap nextprop
      continue
    then
    ourCounter @ 1 + ourCounter !
    dup ourBoard @ dup strlen 1 - strcut pop smatch if
      pop ourCounter @ intostr exit                 (* found it... go *)
    then
    prog swap nextprop
  repeat                                   (* end board-counting loop *)
  pop "X"      (* if board not found, return harmless, inaccurate `X' *)
;
  
: GetBoardHeader  ( s -- s' )  (* return formatted header for board s *)
  
  "" "_boards/" subst "" "/" subst toupper
  "-- " swap strcat
  " ( Board #" strcat GetBoardNumber strcat
  " ) -----------------------------------------------------------------"
  strcat 72 strcut pop 
;
 
: GetPostHeader  (  -- s )     (* return formatted header for ourPost *)
  
  prog ourPost @ "/subj" strcat getprop dup not if     (* get subject *)
    pop "<unknown>"
  then
   
  "  ( " strcat
  prog ourPost @ "/auth" strcat getprop dup if          (* get author *)
    dup ok? if
      dup player? if
        prog "_anon/" ourBoard @ dup strlen 1 - strcut pop strcat getprop
        prog ourPost @ "/anon" strcat getprop and if
          pop "<anon>"
        else
          name
        then
      else
        pop "<unknown>"
      then
    else
      pop "<unknown>"
    then
  else
    pop "<unknown>" 
  then
  
  strcat ", " strcat
  prog ourPost @ "/time" strcat getprop if                (* get time *)
    "%D"
  else
    "<unknown>" 
  then
  strcat " )" strcat
  prog ourPost @ "/time" strcat getprop timefmt  (* format and return *)
;
  
: ShowPost  (  --  )                             (* show post ourPost *)
  
                                                          (* line sep *)
 "---------------------------------------------------------------------"
  Tell
  GetBoardNumber ":" strcat                           (* board number *)
  ourPost @ GetPostNumber strcat "  " strcat           (* post number *)
  GetPostHeader strcat Tell               (* header: subj, auth, time *)
  " " Tell                                                (* line sep *)
  prog ourPost @ ShowList                                  (* content *)
                                                          (* line sep *)
 "---------------------------------------------------------------------"
  Tell
  UpdateLast                              (* update `last read' props *)
;
   
: FindBoardByNumber  (  -- i )           (* find board by #arg number *)
            (* store result in ourBoard and return true if successful *)
          
  ourArg @ atoi 0               (* put board num and counter on stack *)
  prog "_boards/" nextprop
  begin                                  (* begin board-counting loop *)
    dup while
    dup CheckBoardPerm not if           (* skip boards user can't see *)
      prog swap nextprop
      continue
    then
    3 pick 3 pick 1 + = if       (* when found, store ourBoard and go *)
      "/" strcat ourBoard ! pop pop 1 exit          (* found it... go *)
    else
      swap 1 + swap
      prog swap nextprop
    then
  repeat
  pop pop pop 0         (* if not found, clean up stack, return false *)
;
  
: FindBoardByTitle   (  -- i )                (* find board by #title *)
            (* store result in ourBoard and return true if successful *)
  
                     (* do we have a propdir that matches #title arg? *)
  "_boards/" ourArg @ strcat dup prog swap getprop if
    "/" strcat dup CheckBoardPerm if 
      ourBoard ! 1
    else
      pop 0
    then
  else
    pop 0 
  then
;
  
: FindPostByNumber  (  -- i )            (* find post by #arg number *)
            (* store result in ourPost and return true if successful *)
  0
  prog ourBoard @ nextprop
  begin                                  (* begin post-counting loop *)
    dup while
    over 1 + ourPost @ atoi = if
      ourPost ! pop 1 exit                         (* found it... go *)
    then
    swap 1 + swap
    prog swap nextprop
  repeat                                   (* end post-counting loop *)
  pop pop 0            (* if not found, clean up stack, return false *)
;
  
: FindPostByTitle  (  -- i )              (* find post by #title arg *)
            (* store result in ourPost and return true if successful *)
            
        (* full path of post prop not known; have to iterate through *)
  prog ourBoard @ nextprop
  begin                                 (* begin post-searching loop *)
    dup while
    prog over "/subj" strcat getpropstr
    dup if
      ourPost @ smatch if
        ourPost ! 1 exit                           (* found it... go *)
      then
    else
      pop
    then
    prog swap nextprop
  repeat                                  (* end post-searching loop *) 
  pop 0                (* if not found, clean up stack, return false *)
;
  
: ParsePostPath  (  --  )                     (* find <board>/<post> *)
  
  ourArg @ dup "/" instr strcut strip                       (* parse *)
  dup if
    ourPost !    (* store raw post arg; leave raw board arg on stack *)
  else
    pop ">>  Syntax:  "                            (* or show syntax *)
    ourCom @ strcat
    " <board> / <post>" strcat Tell 0 exit
  then
            (* raw board arg is on stack: trim trailing /, then find *)
  dup strlen 1 - strcut pop strip
  dup if
    dup ourArg !
    number? if               (* this way if board arg is a number... *)
      FindBoardByNumber not if
        ">>  Sorry, board number " 
        ourArg @ strcat 
        " not found." strcat Tell pid kill
      then
    else
      FindBoardByTitle not if    (* .. or this way if arg is a title *)
        ">>  Sorry, board `" 
        ourArg @ strcat
        "' not found." strcat Tell pid kill
      then
    then
  else
    ">>  Syntax:  "                  (* improper #arg... show syntax *)
    ourCom @ strcat
    " <board> / <post>" strcat Tell pid kill
  then
  1
;
  
: MakePostProp  (  --  )     (* format and store a prop for new post *)
                         
     (* props are stored by systime, padded with leading zeros and 
        stringified so alphabetic ordering will be correct, and 
        catted with a random 3-digit number to avoid overwrites when 
        two or more players write during same second... not foolproof
        but quite safe, and makes prop-parsing routines a bit cleaner 
        than they would be if we padded by dbref *)
  
  systime intostr                                 (* get current time *)
  12 over strlen -   (* pad with leading zeros to 12 character string *)
  begin
    dup while
    "0" rot strcat swap
    1 -
  repeat
  pop
  "." strcat           (* cat on random number string from 000 to 999 *)
  random 1000 % intostr 
  3 over strlen -
  begin
    dup while
    "0" rot strcat swap
    1 -
  repeat
  pop strcat
  ourPost !                                       (* store in ourPost *)
;
 
: WritePostStamps  (  --  ) (* add time/auth/subj stamps for new post *)
  
  prog ourBoard @ dup strlen 1 - strcut pop systime setprop
  prog ourBoard @ ourPost @ strcat "#/auth" strcat me @ setprop
  prog ourBoard @ ourPost @ strcat "#/time" strcat systime setprop
  prog ourBoard @ ourPost @ strcat "#/subj" strcat ourSubject @ setprop
  ourBoolean @ if
    prog ourBoard @ ourPost @ strcat "#/anon" strcat "yes" setprop
  then
;
  
: WritePost  (  --  )             (* write new post on board ourBoard *)
  
  ourBoolean @ if
    prog "_anon/" ourBoard @ dup strlen 1 - strcut pop strcat getprop 
    not if
      ">>  Sorry, no-name posts are not allowed on this board."
      Tell exit
    then
  then
  prog "_staff/" ourBoard @ dup strlen 1 - strcut pop strcat getprop
  CheckAdminPerm not and if
    ">>  Sorry, this board is read-only." Tell exit
  then
  prog ourBoard @ MakePostProp ourPost @ strcat EditList
  prog ourBoard @ ourPost @ strcat "#/" strcat nextprop if
    WritePostStamps
  then
; 
  
: EditPost  (  --  )           (* edit post ourPost on board ourBoard *)
  
  ourPost @ CheckPostPerm not if  (* check: user has edit permission? *)
    ">>  Permission denied." Tell exit
  then
  "_temp/" me @ intostr strcat ourCounter !
                                     (* store post stamps in temp dir *)
  prog ourCounter @ "/auth" strcat prog ourPost @ "/auth" strcat 
  getprop setprop
  prog ourCounter @ "/time" strcat prog ourPost @ "/time" strcat
  getprop setprop
  prog ourCounter @ "/subj" strcat prog ourPost @ "/subj" strcat
  getprop setprop
  prog ourCounter @ "/anon" strcat prog ourPost @ "/anon" strcat
  getprop setprop
  prog ourPost @ "" "#" subst EditList                (* go edit post *)
                                 (* move post stamps back to post dir *)
  prog ourPost @ "/auth" strcat prog ourCounter @ "/auth" strcat
  getprop setprop 
  prog ourPost @ "/time" strcat prog ourCounter @ "/time" strcat
  getprop setprop 
  prog ourPost @ "/subj" strcat prog ourCounter @ "/subj" strcat
  getprop setprop
  prog ourPost @ "/anon" strcat prog ourCounter @ "/anon" strcat
  getprop setprop
  prog ourCounter @ RemoveDir 
;
  
: DeletePost  (  --  )     (* delete post ourPost from board ourBoard *)
  
  ourPost @ CheckPostPerm not if (* check: user has delete permission *)
    ">>  Permission denied." Tell exit
  then
  
  prog ourPost @ RemoveDir 
  prog ourPost @ remove_prop
  ">>  Post deleted." Tell
;
   
: ShowWindowSyntax  (  --  )      (* show syntax for #window settings *)
  
  ">>  Syntax:  "
  ourCom @ strcat
  " #window <number> <time units>" strcat Tell
  ">>  Example:  "
  ourCom @ strcat
  " #window 6 weeks." strcat Tell
;
   
: SetPostWindow  (  --  )              (* set prop for user's #window *)
  
  ourArg @ " " instr dup if                             (* parse #arg *)
    ourArg @ swap strcut swap pop strip          (* strip #window arg *)
    ParseTimeString if                                  (* parse time *)
      me @ "_prefs/news/window" rot setprop        (* set window prop *)
      ">>  Window set." Tell
    else
      ShowWindowSyntax           (* or show syntax if unable to parse *)
    then
  else                    (* or clear window if no time was specified *)
    me @ "_prefs/news/window" remove_prop
    ">>  Window cleared." Tell pop
  then
;
  
: SetBoardStaff  (  --  )           (* set specified board staff-only *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ " " instr dup if                      (* find board to set *)
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ number? if
      FindBoardByNumber if          (* this way if arg is a number... *)
        prog "_staff/" ourBoard @ strcat dup strlen 1 - strcut pop
        "yes" setprop
        ">>  Board set `staff' (only admins can post to it)." Tell
      else
        ">>  Board number "                (* or say we couldn't find *)
        ourArg @ strcat
        " not found." strcat Tell exit
      then
    else                   (* or find this way if arg is a board name *)
      FindBoardByTitle if 
        prog "_staff/" ourBoard @ strcat dup strlen 1 - strcut pop
        "yes" setprop
        ">>  Board set `staff' (only admins can post to it)." Tell
      else
        ">>  Board `"
        ourArg @ strcat
        "' not found." strcat Tell exit
      then
    then
  else
    pop ">>  Syntax:  "
    ourCom @ strcat
    " #staff <board>" strcat Tell
  then
;
  
: SetBoardGeneral  (  --  )         (* set specified board staff-only *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ " " instr dup if                      (* find board to set *)
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ number? if
      FindBoardByNumber if          (* this way if arg is a number... *)
        prog "_staff/" ourBoard @ strcat dup strlen 1 - strcut pop
        remove_prop
        ">>  Board set `general' (anyone can post to it)." Tell
      else
        ">>  Board number "                (* or say we couldn't find *)
        ourArg @ strcat
        " not found." strcat Tell exit
      then
    else                   (* or find this way if arg is a board name *)
      FindBoardByTitle if 
        prog "_staff/" ourBoard @ strcat dup strlen 1 - strcut pop
        "yes" setprop
        ">>  Board set `general' (anyone can post to it)." Tell
      else
        ">>  Board `"
        ourArg @ strcat
        "' not found." strcat Tell exit
      then
    then
  else
    pop ">>  Syntax:  "
    ourCom @ strcat
    " #general <board>" strcat Tell
  then
;
  
: SetBoardPrivate  (  --  )            (* set specified board private *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
    
  ourArg @ " " instr dup if                      (* find board to set *)
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ number? if
      FindBoardByNumber if          (* this way if arg is a number... *)
        prog "_closed/" ourBoard @ strcat dup strlen 1 - strcut pop 
        "yes" setprop                                       (* set it *)
        ">>  Board set `private'." Tell
      else
        ">>  Board number "                (* or say we couldn't find *)
        ourArg @ strcat
        " not found." strcat Tell
      then
    else                   (* of find this way if arg is a board name *)
      FindBoardByTitle if
        prog "_closed/" ourBoard @ strcat dup strlen 1 - strcut pop 
        "yes" setprop                                       (* set it *)
        ">>  Board set `private'." Tell
      else
        ">>  Board `"                      (* or say we couldn't find *)
        ourArg @ strcat 
        "' not found." strcat Tell
      then
    then
  else                            (* show syntax if we couldn't parse *)
    pop ">>  Syntax:  "
    ourCom @ strcat 
    " #close <board>" strcat Tell 
  then
;
  
: SetBoardOpen  (  --  )                  (* set specified board open *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
    
  ourArg @ " " instr dup if                      (* find board to set *)
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ number? if        (* find this way if arg is a number... *)
      FindBoardByNumber if
        prog "_closed/" ourBoard @ strcat dup strlen 1 - strcut pop
        remove_prop                                         (* set it *)
        ">>  Board set `open'." Tell
      else
        ">>  Board number "                (* or say we couldn't find *)
        ourArg @ strcat
        " not found." strcat Tell
      then
    else                   (* or find this way if arg is a board name *)
      FindBoardByTitle if
        prog "_closed/" ourBoard @ strcat dup strlen 1 - strcut pop 
        remove_prop                                         (* set it *)
        ">>  Board set `open'." Tell
      else
        ">>  Board `"                      (* or say we couldn't find *)
        ourArg @ strcat 
        "' not found." strcat Tell
      then
    then
  else                            (* show syntax if we couldn't parse *)
    pop ">>  Syntax:  "
    ourCom @ strcat 
    " #open <board>" strcat Tell 
  then
;
  
: SetSearchTariff  (  --  )          (* set penny tariff for searches *)
  
  "set search tariff" .tell
;
 
: ShowAddPlayerSyntax  (  --  )      (* show syntax for boad #include *)
  
  ">>  Syntax:  "
  ourCom @ strcat
  " #include <board> / <player>" strcat Tell
;
    
: IncPlayerClosed  (  --  )  (* add specified player to private board *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ "/" instr not if                              (* parsable? *)
    ShowAddPlayerSyntax exit
  then
  
  ourArg @ " " instr dup if                             (* then parse *)
    ourArg @ swap strcut swap pop strip
    dup "/" instr dup if
      strcut strip
      .pmatch dup not if                               (* find player *)
        ">>  Sorry, player not found." Tell pop exit
      then
      swap strip dup if
        dup strlen 1 = if
          pop ShowAddPlayerSyntax
        else
          dup strlen 1 - strcut pop strip               (* find board *)
          ourArg ! ourArg @ number? if
            FindBoardByNumber if                 (* set if found both *)
              prog "_closed/" ourBoard @ strcat 
              3 pick intostr strcat "yes" setprop
              ">>  " swap name " added to board authorization list."
              strcat Tell
            else
              ">>  Sorry, board number "   (* or say we couldn't find *)
              ourArg @ strcat
              " not found." strcat Tell pop pid kill
            then
          else
            FindBoardByTitle if                  (* set if found both *)
              prog "_closed/" ourBoard @ strcat 
              3 pick intostr strcat "yes" setprop
              ">>  " swap name " added to board authorization list."
              strcat Tell
            else
              ">>  Sorry, board `"         (* or say we couldn't find *)
              ourArg @ strcat
              " not found." strcat Tell pop pid kill
            then
          then
        then
      else
        pop ShowAddPlayerSyntax   (* show syntax if we couldn't parse *)
      then
    else
      pop pop ShowAddPlayerSyntax
    then
  else
    pop ShowAddPlayerSyntax
  then
;
 
: ShowRemPlayerSyntax  (  --  )     (* show syntax for board #exclude *)
  
  ">>  Syntax:  "
  ourCom @ strcat
  " #exclude <board> / <player>" strcat Tell
;
 
: ExcPlayerClosed  (  --  )       (* remove player from private board *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ "/" instr not if                             (* parseable? *)
    ShowRemPlayerSyntax exit
  then
  
  ourArg @ " " instr dup if                             (* then parse *)
    ourArg @ swap strcut swap pop strip
    dup "/" instr dup if
      strcut strip
      .pmatch dup not if                               (* find player *)
        ">>  Sorry, player not found." Tell pop exit
      then
      swap strip dup if
        dup strlen 1 = if
          pop ShowRemPlayerSyntax
        else       (* find board; set if found both; otherwise notify *)
          dup strlen 1 - strcut pop strip
          ourArg ! ourArg @ number? if
            FindBoardByNumber if
              prog "_closed/" ourBoard @ strcat
              3 pick intostr strcat remove_prop
              ">>  " swap name strcat " removed from board authorization list."
              strcat Tell
            else
              ">>  Sorry, board number "
              ourArg @ strcat
              " not found." strcat Tell pop pid kill
            then
          else
            FindBoardByTitle if
              prog "_closed/" ourBoard @ strcat
              3 pick intostr strcat remove_prop
              ">>  " swap name " removed from board authorization list."
              strcat Tell
            else
              ">>  Sorry, board '"
              ourArg @ strcat
              " not found." strcat Tell pop pid kill
            then
          then
        then
      else
        pop ShowRemPlayerSyntax   (* show syntax if we couldn't parse *)
      then
    else
      pop pop ShowRemPlayerSyntax
    then
  else
    pop ShowRemPlayerSyntax
  then
;
   
: ShowAddAdminSyntax  (  --  )                (* show syntax for #add *)
  
  ">>  Syntax:  " ourCom @ strcat " #add <player>" strcat Tell
;
   
: AddAdministrator  (  --  )        (* make specified player an admin *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
                             (* parse and add player to admin reflist *)
  ourArg @ " " instr dup if
    ourArg @ swap strcut swap pop strip dup if
      .pmatch dup if
        prog "_admin" 3 pick REF-add
        ">>  " swap name strcat
        " added to board administrator list." strcat Tell
      else
        ">>  Sorry, player not found." Tell
      then
    else
      pop ShowAddAdminSyntax      (* or show syntax if couldn't parse *)
    then
  else
    pop ShowAddAdminSyntax
  then
;
  
: ShowRemAdminSyntax  (  --  )       (* show syntax for board #remove *)
  
  ">>  Syntax:  " ourCom @ strcat " #remove <player>" strcat Tell
;
   
: RemAdministrator  (  --  )      (* remove player's admin privileges *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
                        (* parse and remove player from admin reflist *)
  ourArg @ " " instr dup if
    ourArg @ swap strcut swap pop strip dup if
      .pmatch dup if
        prog "_admin" 3 pick REF-delete
        ">>  " swap name strcat
        " removed from board administrator list." strcat Tell
      else
        ">>  Sorry, player not found." Tell
      then
    else
      pop ShowRemAdminSyntax   (* or show syntax if we couldn't parse *)
    then
  else
    pop ShowRemAdminSyntax
  then
;
 
: CreateNewBoard  (  --  )             (* create a new bulletin board *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ " " instr dup if                                  (* parse *)
    ourArg @ swap strcut swap pop strip
  else
    pop ">>  Syntax:  "                    (* show syntax if we can't *)
    ourCom @ strcat
    " #create <name>" strcat Tell exit
  then                                     (* start propdir for board *)
  prog "_boards/" 3 pick strcat systime intostr setprop 
  ">>  Board `" swap strcat "' created." strcat Tell
;
 
: DeleteBoard   (  --  )                  (* delete an existing board *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
  
  ourArg @ " " instr dup if          (* parse or notify that we can't *)
    ourArg @ swap strcut swap pop strip
  else
    pop ">>  Syntax:  "
    ourCom @ strcat
    " #destroy <name>" strcat Tell exit
  then
  
  dup ourArg ! number? if
    FindBoardByNumber not if
      ">>  Sorry, board number "
      ourArg @ strcat
      " not found." strcat Tell exit
    then
  else
    FindBoardByTitle not if
      ">>  Sorry, board `"
      ourArg @ strcat
      "' not found" strcat Tell exit
    then
  then  
          (* this will blow away all posts on board: get confirmation *)
  ">>  Please confirm: You wish to delete board "
  ourBoard @ GetBoardName strcat
  ", and all its posts?" strcat Tell
  ">> [Enter `yes' to confirm]" Tell
  read "yes" smatch if           (* if confirmed, remove all propdirs *)
    prog ourBoard @ RemoveDir
    prog ourBoard @ dup strlen 1 - strcut pop remove_prop
    prog "_closed/" ourBoard @ strcat RemoveDir
    ">>  Board deleted." Tell
  else
    ">>  Aborted." Tell
  then
;
    
: HelpHeader  (  --  )     (* show standard first line for help pages *)
  
  " " Tell "JBoard.muf (#" prog intostr strcat ")" strcat Tell " " Tell
;
  
: DPad35  ( s --  )   (* pad s with trailing dots and cut to 35 chars *)
  
  " .............................." strcat 35 strcut pop
; 
  
: ComNameHelp  (  --  )   (* show standard #alias and #rem help lines *)
  
  "  " ourCom @ strcat " #alias <alias name>" strcat DPad35
  " Set an alias for `" ourCom @ strcat "' (admin only)" 
  ourBoolean @ if "" "(admin only)" subst then strcat strcat Tell
  "  " ourCom @ strcat " #rename <new name>" strcat DPad35
  " Rename the `" ourCom @ strcat "' command (admin only)" 
  ourBoolean @ if "" "(admin only)" subst then strcat strcat Tell
;
  
: DoReadHelp  (  --  )            (* show help scren for read command *)
  
  HelpHeader
  
  "JBoard.muf is a global bulletin board program, with `search', `new',"
  " and `next' features." strcat Tell " " Tell
  
  "  " ourCom @ strcat DPad35 
  " List all boards" strcat Tell
  "  " ourCom @ strcat " <board>" strcat DPad35
  " List posts on <board>" strcat Tell
  "  " ourCom @ strcat " <board>/<post>" strcat DPad35
  " Display <post> from <board>" strcat Tell
  "  " ourCom @ strcat " #search <string>" strcat DPad35
  " Search all boards for <string>" strcat Tell
  "  " ourCom @ strcat " #search <board>/<string>" strcat DPad35
  " Search <board> for <string>" strcat Tell
  "  " ourCom @ strcat " #new" strcat DPad35
  " List number of new posts on all boards" strcat Tell
  "  " ourCom @ strcat " #new <board>" strcat DPad35
  " List all new posts on <board>" strcat Tell
  "  " ourCom @ strcat " #last <time>" strcat DPad35
  " Display all posts since <time>" strcat Tell
  "  " ourCom @ strcat " #last <board>/<time>" strcat DPad35
  " Display all posts on <board> since <time>" strcat Tell
  CheckAdminPerm if ComNameHelp then
  " " Tell
  
  "Boards and posts may be specified by either number or name." 
  Tell " " Tell
  
  "#Argument strings do not have to be typed completely: entering `"
  ourCom @ strcat " #s rosebud' will produce the same result as `"
  ourCom @ strcat " #search rosebud'. Posts are considered new if "
  "they are more recent than the last post you read, and -- if you "
  "have a `window' set -- within your specified window (see "
  "board" GetCurrentCommandName strcat
  " #help). The <time> parameter for #last can be any positive "
  "number and standard time unit: `1 month', `12 hours', `6 months'." 
  strcat strcat strcat strcat strcat strcat Tell " " Tell
  
  "See also #help for " "read" GetOtherCommandNames strcat Tell
;
 
: DoWriteHelp  (  --  )         (* show help screen for write command *)
  
  HelpHeader
  
  "The " ourCom @ strcat " command allows you to add a post to an "
  "existing bulletin board." strcat strcat Tell " " Tell
  
  "  " ourCom @ strcat " <board>/<subject>" strcat DPad35
  " Add a post about <subject> to <board>" strcat Tell 
  "  " ourCom @ strcat " #noname <board>/<subject>" strcat DPad35
  " Add an anonymous post to <board>" strcat Tell
  CheckAdminPerm if ComNameHelp then
  " " Tell
  
  "The board may be specified by either name or number." Tell " " Tell
  
  "See also #help for " "write" GetOtherCommandNames strcat Tell
;
  
: DoEditHelp  (  --  )           (* show help screen for edit command *)
  
  HelpHeader
  
  "The " ourCom @ strcat " command allows you to edit a post for "
  "which you have edit permission (that is, you are either the author "
  "of the post, or have admin permission for the bulletin boards.)"
  strcat strcat strcat Tell " " Tell
  
  "  " ourCom @ strcat " <board>/<post>" strcat DPad35
  " Edit an existing post" strcat Tell
  CheckAdminPerm if ComNameHelp then
  " " Tell
  
  "The board and post may be specified by either name or number."
  Tell " " Tell
  
  "See also #help for " "edit" GetOtherCommandNames strcat Tell
;
  
: DoDeleteHelp  (  --  )       (* show help screen for delete command *)
  
  HelpHeader
  
  "The " ourCom @ strcat " command allows you to delete a post for "
  "which you have delete permission (that is, you are either the "
  "author of the post, or have admin permission for the bulletin "
  "boards" strcat strcat strcat strcat Tell " " Tell
  
  "  " ourCom @ strcat " <board>/<post>" strcat DPad35
  " Delete an existing post." strcat Tell
  CheckAdminPerm if ComNameHelp then
  " " Tell
  
  "The board and post may be specified by either name or number."
  Tell " " Tell
  
  "See also #help for " "delete" GetOtherCommandNames strcat Tell
;
  
: DoNextHelp  (  --  )           (* show help screen for next command *)
  
  HelpHeader
   
  "The " ourCom @ strcat " command allows you to page through either "
  "the posts of a board or the results of a #search." strcat strcat 
  Tell " " Tell
  
  "  " ourCom @ strcat DPad35
  " Display next post from <board|search>" strcat Tell
  CheckAdminPerm if ComNameHelp then
  " " Tell
  
  "If you have done a standard " "read" GetCurrentCommandName strcat
  " more recently, then the next post frim the same board will be "
  "displayed. If you have done a #search more recently, then the first "
  "or next post containing your search string will be displayed."
  strcat strcat strcat Tell " " Tell
  
  "See also #help for " "next" GetOtherCommandNames strcat Tell
;
 
: DoBoardHelp  (  --  )         (* show help screen for board command *)
  
  1 ourBoolean !
  HelpHeader
                                      (* show this version for admins *)
  CheckAdminPerm if
    "The " ourCom @ " command is used to administer the bulletin "
    "boards. All options listed are admin-only, except for #window."
    strcat strcat strcat Tell " " Tell
  
    "  " ourCom @ strcat " #create <name>" strcat DPad35
    " Create new board named <name>" strcat Tell
    "  " ourCom @ strcat " #destroy <board>" strcat DPad35
    " Delete board <board>" strcat Tell
    "  " ourCom @ strcat " #private <board>" strcat DPad35
    " Set <board> private" strcat Tell
    "  " ourCom @ strcat " #open <board>" strcat DPad35
    " Set <board> open" strcat Tell
    "  " ourCom @ strcat " #include <board>/<player>" strcat DPad35
    " Include <player> in private <board>" strcat Tell
    "  " ourCom @ strcat " #exclude <board>/<player>" strcat DPad35
    " Exclude <player> from private <board>" strcat Tell
    "  " ourCom @ strcat " #noname <board>" strcat DPad35
    " Toggle nonames-allowed for <board>" strcat Tell
    "  " ourCom @ strcat " #add <player>" strcat DPad35
    " Add <player> to admin list" strcat Tell
    "  " ourCom @ strcat " #remove <player>" strcat DPad35
    " Remove <player> from admin list" strcat Tell
    "  " ourCom @ strcat " #staff <board>" strcat DPad35
    " Set <board> writable by staff only" strcat Tell
    "  " ourCom @ strcat " #general <board>" strcat DPad35
    " Set <board> writable by general public" strcat Tell
    "  " ourCom @ strcat " #window <number> <units>" strcat DPad35
    " Set window to <time>" strcat Tell 
    "  " ourCom @ strcat " #window" strcat DPad35
    " Clear window setting" strcat Tell
    ComNameHelp " " Tell
  
    "Private boards are only visible to admins and players included "
    "in the board's authorization list. Admins are wizards, the owner "
    "of this program and action, or players included in the admin "
    "list. A `window' is the time after which a post is considered "
    "`old', and will not appear in `" "read" GetCurrentCommandName
    strcat
    " #new <board>'. Its <time> pair can be any positive "
    "number and standard time unit. Examples: `300 hours', `1 day', "
    "`3 months'. The #noname option is not allowed by default. `"
    ourCom @ " #noname' toggles this option on and off."
    strcat strcat strcat strcat strcat strcat strcat strcat strcat
    Tell 
                                  (* show this version for non admins *)
  else
    "The " ourCom @ " command is primarily used by the MUCK's "
    "administrators to configure bulletin boards. It does though "
    "have one purpose for non-admin users: Setting your `new' "
    "window." strcat strcat strcat strcat strcat Tell " " Tell
  
    "Your window is time beyond which posts are considered `old', "
    "and will no longer appear when you do `" "read"
    GetCurrentCommandName strcat " #new <board>'." strcat
    "For example, if you set your window to `six weeks', then "
    "posts older than six weeks will not appear on the #new lists."
    strcat strcat strcat Tell " " Tell
  
    "  " ourCom @ strcat " #window <time>" strcat DPad35
    " Set window to <time>" strcat Tell 
    "  " ourCom @ strcat " #window" strcat DPad35
    " Clear window setting" strcat Tell
    " " Tell
  
    "The <time> parameter can be any positive number and "
    "standard time unit. Examples: '300 hours', '1 day', '2 months'."
    strcat Tell " " Tell
    
    "See also #help for " "board" GetOtherCommandNames strcat Tell
  then
;
   
: DoCommandAlias  (  --  )      (* set an alias for specified command *)
        (* or, if called from DoCommandRename, replace a command name *)
  
  CheckAdminPerm not if                           (* check admin perm *)
    ">>  Permission denied." Tell exit
  then
                                    (* check for illegal action names *)
  ourArg @ " " instr dup if
    ourArg @ swap strcut swap pop strip ourString !
    ourString @ "home" smatch 
    ourString @ "here" smatch
    ourString @ "me"   smatch
    ourString @ "#*"   smatch
    or or or if
      ">>  Sorry, invalid exit name." Tell
    else        (* keep track of original names... may be re-aliasing *)
      ourCom @ ourCounter !
      prog "_alias/" command @ strcat getpropstr dup if
        command ! 
      else
        pop
      then
    then (* ourBoolean is true if we're renaming rather than aliasing *)
    ourBoolean @ if          (* find com name and substitute new name *)
      trig name ";" ourCom @ strcat ";" strcat over over instr if
        "" swap subst trig swap setname
      else
        pop pop
        trig name ";" ourCom @ strcat over over instr if
          "" swap subst trig swap setname
        else
          pop pop trig name ourCom @ ";" strcat over over instr if
            "" swap subst trig swap setname
          else
            pop pop
            ">>  ERROR: Unable to rename." Tell 
            pid kill
          then
        then
      then
      trig name ";" strcat ourString @ strcat trig swap setname
      prog "_alias/" ourString @ strcat command @ setprop
      prog "_orign/" command @ strcat ourString @ setprop
      ">>  Command renamed." Tell
    else
      trig name ";" ourString @ ";" strcat strcat instr
      trig name ";" ourString @ strcat instr
      trig name ourString @ ";" strcat instr or or not if
        trig name ";" strcat ourString @ strcat trig swap setname
      then
      prog "_alias/" ourString @ strcat command @ setprop 
      ">>  Alias created." Tell
    then
  else
    ">>  Syntax:  "
    ourCom @ strcat
    " #alias <alias name>" strcat Tell
  then
;
       
: DoCommandRename  (  --  )                         (* rename command *)
         (* many routines are shared with DoCommandAlias, so do it by
            setting ourBoolean true and calling DoCommandAlias.       *)
  
  ourArg @ " " instr dup if
    1 ourBoolean !
    DoCommandAlias
  else
    pop ">>  Syntax:  "
    ourCom @ strcat
    " #rename <new name>" strcat Tell
  then
;
  
: ShowNoNameSyntax  (  --  )         (* show syntax for board #noname *)
  
  ">>  Syntax:  "
  ourCom @ strcat 
  " #noname <board>" strcat Tell
;
  
: ToggleNoNames  (  --  )      (* toggle #nonames allowed for a board *)
  
  ourArg @ " " instr dup if
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ number? if
      FindBoardByNumber not if
        ">>  Sorry, board number "
        ourArg @ strcat
        " not found." strcat Tell pid kill
      then
    else
      FindBoardByTitle not if
        ">>  Sorry, board `"
        ourArg @ strcat
        " not found." strcat Tell pid kill
      then
    then
    prog "_anon/" ourBoard @ dup strlen 1 - strcut pop strcat
    over over getprop if
      remove_prop
      ">>  No-name posts are now *not* allowed for board "
      ourBoard @ GetBoardName strcat "." strcat Tell
    else
      "yes" setprop
      ">>  No-name posts are now allowed for board "
      ourBoard @ GetBoardName strcat "." strcat Tell
    then
  else
    pop ShowNoNameSyntax
  then
;
   
: DoNextSearch  (  --  )          (* show next post in search results *)
  
                    (* protect prop keeps search results for one read *)
                              (* we're searching now so can delete it *)
  me @ "_prefs/news/protect" remove_prop 
  me @ over "/" strcat nextprop                      (* get next post *)
  dup "" "_prefs/news/search/" subst ourPost !
  ourPost @ dup "/" rinstr strcut pop ourBoard !
  ShowPost                                               (* show post *)
  me @ swap remove_prop                          (* update search set *)
  me @ "_prefs/news/search/" nextprop not if
    " " Tell ">>  End of #search results." Tell 
  then
; 
  
: DoNextRead  (  --  )             (* show next post on current board *)
  
  pop
  me @ "_prefs/news/lastpost" getpropstr dup if
    prog swap nextprop dup if
      dup dup "/" rinstr strcut pop ourBoard !
      ourPost ! ShowPost
      UpdateLast
    else
      ">>  No more posts on this board." Tell
    then
  else
    ">>  Sorry, no `last read' post currently recorded for you." Tell
  then
;
 
: DoNext (  --  )(* show next post in search results or current board *)
    
  ourArg @ if
    ourArg @ "#" stringpfx if
      ourArg @ "#h" stringpfx if DoNextHelp exit      else
      ourArg @ "#a" stringpfx if DoCommandAlias exit  else
      ourArg @ "#r" stringpfx if DoCommandRename exit else
      ">>  #Argument not understood." Tell exit
      then then then
    then 
  then
  
  me @ "_prefs/news/search/_boards/" nextprop dup if
    DoNextSearch                     (* this way if we're in a search *)
  else
    DoNextRead                            (* or this way if we're not *)
  then
;
   
: DoPostList  (  --  )               (* list posts on specified board *)
  
  0 ourCounter !
  " " Tell
  ourBoard @ GetBoardHeader Tell                 (* show board header *)
  0 ourCounter !
  prog ourBoard @ nextprop dup if                        (* get posts *)
    begin                                  (* begin post-showing loop *)
      dup while
      ourBoolean @ if                             (* skip `old' posts *)
        dup CheckOldPost if
          prog swap nextprop continue
        then
      then
      dup ourPost !    (* store current in ourPost, for GetPostHeader *)
      dup GetPostNumber                                (* number post *)
      ") " strcat dup strlen 3 = if
        " " strcat
      then
      GetPostHeader strcat Tell    (* cat number and formatted header *)
      prog swap nextprop
    repeat                                   (* end post-showing loop *)
    pop
  else
    pop ">>  Sorry, there are no posts on this board yet." Tell
  then
;
  
: SearchBoard  (  --  )   (* search ourBoard for posts with ourSubject *)
  
  0 ourBoolean  !
  0 ourCounter2 !
  prog swap nextprop
  begin                                  (* begin post-searching loop *)
    dup while
    ourCounter2 @ 1 + ourCounter2 !
    dup
    prog over "/" strcat nextprop
    begin                                (* begin line-searching loop *)
      dup while          (* for a hit, format and display post, break *)
      prog over getpropstr tolower ourString @ tolower instr if
        me @ "_prefs/news/search/" 3 pick strcat "1" setprop
              1 ourBoolean !
        dup "" "_boards/" subst
        dup "/" instr 1 - strcut pop "/" strcat 
        ourCounter2 @ intostr strcat 
        " ..................................................."
        strcat 24 strcut pop " " strcat ourSubject !
        pop prog over "/subj" strcat getpropstr
        ourSubject @ swap strcat " ( " strcat ourSubject !
        prog over "/auth" strcat getprop 
        dup ok? if
          name
        else
          pop "<unknown>" 
        then
        ourSubject @ swap strcat ", %D )" strcat ourSubject !
        prog over "/time" strcat getprop
        ourSubject @ swap timefmt Tell
        break
      then
      prog swap nextprop
    repeat                                 (* end line-searching loop *)
    pop 
    prog swap nextprop
  repeat                                   (* end post-searching loop *)
  pop 
                           (* if we got a hit, protect search results *)
  ourBoolean @ if
    me @ "_prefs/news/protect" "yes" setprop
  then
;
  
: DoBoardList  (  --  )                 (* display list of all boards *)
  
  background
  " " Tell "BULLETIN BOARDS:" Tell " " Tell
  0 ourCounter !
  prog "_boards/" nextprop dup if    (* check: do we have any boards? *)
    1 ourCounter !                       (* init board-number counter *)
    begin                                 (* begin board-listing loop *)
      dup while
                     (* skip private boards user isn't authorized for *)
      dup CheckBoardPerm not if
        prog swap nextprop continue
      then
      
      ourCounter @ intostr                     (* format board number *)
      ") " strcat
      dup strlen 2 = if " " strcat then
       
      over GetBoardName strcat                (* go format board name *)
       
      " (" strcat                   (* go get number of posts; format *)
      over GetNumPosts 
      dup "1" smatch if
        " post)"
      else
        " posts)"
      then
      strcat strcat
       
      Tell                           (* display string for this board *)
       
      ourCounter @ 1 + ourCounter !                      (* increment *)
      prog swap nextprop
    repeat                                  (* end board-listing loop *)
    pop
  else
    ">>  Sorry, no boards have been created." Tell
  then
;
  
: DoNewBoardList  (  --  )              (* display list of all boards *)
  
  background
  " " Tell "BULLETIN BOARDS:" Tell " " Tell
  0 ourCounter !
  prog "_boards/" nextprop dup if    (* check: do we have any boards? *)
    1 ourCounter !                       (* init board-number counter *)
    begin                                 (* begin board-listing loop *)
      dup while
                     (* skip private boards user isn't authorized for *)
      dup CheckBoardPerm not if
        prog swap nextprop continue
      then
      
      ourCounter @ intostr                     (* format board number *)
      ") " strcat
      dup strlen 2 = if " " strcat then
       
      over GetBoardName strcat                (* go format board name *)
       
      " (" strcat                   (* go get number of posts; format *)
      over GetNumNewPosts 
      dup "1" smatch if
        " new post)"
      else
        " new posts)"
      then
      strcat strcat
       
      Tell                           (* display string for this board *)
       
      ourCounter @ 1 + ourCounter !                      (* increment *)
      prog swap nextprop
    repeat                                  (* end board-listing loop *)
    pop
  else
    ">>  Sorry, no boards have been created." Tell
  then
;
 
: GetLastFromBoard  (  --  )(* show posts from ourBoard since ourTime *)
  
  0 ourBoolean !                              (* true if we got a hit *)
  ourBoard @ GetBoardHeader Tell                 (* show board header *)
  1 ourPostCounter !          (* start a counter for posts this board *)
  begin                                   (* begin post-checking loop *)
    ourPostCounter @ intostr ourPost ! FindPostByNumber while
    ourPost @ dup "." rinstr 1 - strcut pop             (* check time *)
    dup "/" rinstr strcut swap pop
    atoi ourTime @ > if                      (* show if recent enough *)
      1 ourBoolean !
      GetPostHeader Tell
      GetBoardNumber ":" strcat                       (* board number *)
      ourPost @ GetPostNumber strcat "  " strcat       (* post number *)
      GetPostHeader strcat Tell           (* header: subj, auth, time *)
      " " Tell                                            (* line sep *)
      prog ourPost @ ShowList                              (* content *)
 "---------------------------------------------------------------------"
      Tell
    then
    ourPost @ CheckOldPost not if
      me @ "_prefs/news/lastpost" ourPost @ setprop
    then
    ourPostCounter @ 1 + ourPostCounter !
  repeat
  
  ourBoolean @ not if
    "  <none>" Tell
  then
;
   
: ShowReadLastSyntax  (  --  )          (* show syntax for read #last *)
  
  ">>  Syntax:   " ourCom @ " #last [<board>/]<number> <units>"
  strcat strcat Tell
  ">>  Examples: " ourCom @ " #last 6 weeks" strcat strcat Tell
  "              " ourCom @ " #last 3/10 days" strcat strcat Tell
  "              " ourCom @ " #last policy/1 month" strcat strcat Tell
;
   
: DoReadLast  (  --  )   (* setup display of all posts in last <time> *)
  
  ourArg @ " " instr dup if
    ourArg @ swap strcut swap pop strip ourArg !
    ourArg @ "/" instr dup if
      ourArg @ swap strcut strip ourCounter !
      dup strlen 1 - strcut pop strip ourArg !
      ourCounter @ ParseTimeString if
        systime swap - dup 0 <= if
          ">>  Sorry, MU*'s weren't even around then, so no posts."
          Tell exit
        else
          ourTime !
        then
      else
        ShowReadLastSyntax exit
      then
      ourArg @ number? if
        FindBoardByNumber not if
          ">>  Sorry, board number "
          ourArg @ strcat 
          " not found." strcat Tell exit
        then
      else
        FindBoardByTitle not if
          ">>  Sorry, board `"
          ourArg @ strcat 
          "' not found." strcat Tell exit
        then
      then
    else
      pop ourArg @ ParseTimeString if
        systime swap - dup 0 <= if
          ">>  Sorry, MU*'s weren't even around then, so no posts."
          Tell exit
        else
          ourTime !
        then
      else
        ShowReadLastSyntax exit
      then
    then
  else
    pop ShowReadLastSyntax exit
  then
  
  ourBoard @ if
    GetLastFromBoard
  else
    1 ourCounter2 !
    begin
      ourCounter2 @ intostr ourArg ! FindBoardByNumber while
      GetLastFromBoard
      ourCounter2 @ 1 + ourCounter2 !
    repeat
    depth if pop then
  then
;
   
: DoParseSearch  (  --  )           (* parse search request; dispatch *)
  
  begin depth while pop repeat    (* clear stack to keep things tidy! *)
  ourArg @ dup " " instr dup if                          (* parse arg *)
    strcut swap pop
    dup "/" instr dup if
      strcut strip dup if
        ourString !
      else
        pop ">>  Syntax:  " 
        ourCom @ strcat
        " #search <string> [/<board>]" strcat Tell exit
      then
      dup strlen 1 - strcut pop 
      strip dup if
        ourArg ! 1 ourBoolean !
      else
        pop ">>  Syntax:  "
        ourCom @ strcat
        " #search <string> [/<board>]" strcat Tell exit
      then
    else
      pop ourString !
    then
  else
    pop pop ">>  Syntax:  " ourCom @ strcat 
    " #search <string> [/<board>]" strcat Tell exit
  then
                        (* if a board to search is specified, find it *)
  ourBoolean @ if
    ourArg @ number? if
      FindBoardByNumber not if
        ">>  Sorry, board number "
        ourArg @ strcat
        " not found." strcat Tell exit
      then
    else
      FindBoardByTitle not if
        ">>  Sorry, board `"
        ourArg @ strcat
        "' not found." strcat Tell exit
      then
    then
  then
     
  ">>  Searching for $string..." 
  ourString @ "$string" subst Tell
  ourBoard @ if          (* if we have a specific board, search it... *)
    ourBoard @ SearchBoard
  else                                 (* otherwise search all boards *)
    1 
    begin                                 (* begin board-getting loop *)
      dup intostr ourArg !
      FindBoardByNumber if
        ourBoard @ SearchBoard                 (* go search one board *)
      else
        break
      then
      begin
        dup int? not while
              pop
              depth not if break then
      repeat
      1 +
    repeat                                  (* end board-getting loop *)
  then
  begin depth while pop repeat
  ">>  Done." Tell
;
 
: SetNew  (  --  )            (* strip #n from arg and set ourBoolean *)
  
  ourArg @ " " instr dup if           (* strip `#new' from arg string *)
    ourArg @ swap strcut swap pop strip ourArg !
  else
    pop 1 ourBoolean ! DoNewBoardList pid kill
  then
  1 ourBoolean !     (* this will tell DisplayPostList to exclude old *)
;
 
: DoParseRead (  --  )(* find board to display; default is board list *)
  
  me @ "_prefs/news/protect" getpropstr not if
    me @ "_prefs/news/search/" RemoveDir
  then
  ourArg @ if
    ourArg @ "#" stringpfx if
      ourArg @ "#h" stringpfx if DoReadHelp exit      else
      ourArg @ "#a" stringpfx if DoCommandAlias exit  else
      ourArg @ "#r" stringpfx if DoCommandRename exit else
      ourArg @ "#s" stringpfx if DoParseSearch exit   else
      ourArg @ "#l" stringpfx if DoReadLast exit      else
      ourArg @ "#n" stringpfx if SetNew               else
      ">>  #Argument not understood." Tell exit
      then then then then then then
    then
    ourArg @ "/" instr if             (* check: board/post specified? *)
      ParsePostPath not if                    (* ... if so, find path *)
        exit
      then
      ourPost @ number? if
        FindPostByNumber not if
          ">>  Sorry, post number "
          ourPost @ strcat 
          " not found." strcat Tell pid kill
        then
      else
        FindPostByTitle not if
          ">>  Sorry, post `"
          ourPost @ strcat
          "' not found." strcat Tell pid kill
        then
      then
      ShowPost
    else
      ourArg @ number? if           (* check: board number specified? *)
        FindBoardByNumber if             (* ... if so, find by number *)
          DoPostList
        else
          ">>  Sorry, board number "
          ourArg @ strcat
          " not found." strcat Tell pid kill
        then
      else                            (* check: board title specified *)
        FindBoardByTitle if                   (* if so, find by title *)
          DoPostList
        else
          ">>  Sorry, board `"
          ourArg @ strcat
          "' not found." strcat Tell pid kill
        then
      then
    then
  else                          (* ... otherwise, show list of boards *)
    ourBoolean @ if
      DoNewBoardList                         (* either in #new format *)
    else
      DoBoardList                               (* or in `all' format *)
    then
  then
;
  
: DoParseWrite  (  --  )                       (* parse write command *)
 
  ourArg @ if                                          (* check #args *)
    ourArg @ "#n" stringpfx
    ourArg @ " "  instr and if
      ourArg @ dup " " instr strcut swap pop strip ourArg !
      1 ourBoolean !
    then
    ourArg @ "#" stringpfx if
      ourArg @ "#h" stringpfx if DoWriteHelp     exit else
      ourArg @ "#a" stringpfx if DoCommandAlias  exit else
      ourArg @ "#r" stringpfx if DoCommandRename exit else
      ">>  #Argument not understood." Tell exit
      then then then 
    else
      ourArg @ "/" instr dup if                 (* parse post subject *)
        ourArg @ swap strcut strip 
        dup "/" instr if  (* subjects with /'s would mess up propdirs *)
          ">>  Sorry, post subjects cannot include `/' slashes."
          Tell pop pop pid kill
        else
          dup 45 strcut pop ourSubject !   (* limit subjs to 45 chars *)
          dup strlen 1 - strcut pop strip ourArg !
        then
        strip dup strlen 1 - strcut pop ourArg !
      else
        DoWriteHelp exit            (* show help if we couldn't parse *)
      then
     
      ourArg @ number? if                    (* find board to post on *)
        FindBoardByNumber if
          WritePost                                  (* go write post *)
        else
          ">>  Sorry, board number "
          ourArg @ strcat 
          " not found." strcat Tell pid kill
        then
      else
        FindBoardByTitle if
          WritePost                                  (* go write post *)
        else
          ">>  Sorry, board `"
          ourArg @ strcat
          " not found." strcat Tell pid kill
        then
      then
    then
  else
    DoWriteHelp                     (* show help if we couldn't parse *)
  then
;
  
: DoParseEdit  (  --  )                         (* parse edit command *)
  
  ourArg @ if                                          (* check #args *)
    ourArg @ "#" stringpfx if
      ourArg @ "#h" stringpfx if DoEditHelp      exit else
      ourArg @ "#a" stringpfx if DoCommandAlias  exit else
      ourArg @ "#r" stringpfx if DoCommandRename exit else
      ">>  #Argument not understood." Tell exit
      then then then
    else                                                     (* parse *)
      ourArg @ "/" instr dup if
        ourArg @ swap strcut strip dup if
          ourPost !
        else
          pop DoEditHelp exit
        then
        dup strlen 1 - strcut pop strip dup if
          ourArg !
        else
          pop DoEditHelp exit
        then
        ourArg @ number? if                          (* find board... *)
          FindBoardByNumber not if
            ">>  Sorry, board number "
            ourArg @ strcat
            " not found." strcat Tell pid kill
          then
        else
          FindBoardByTitle not if
            ">>  Sorry, board `" 
            ourArg @ strcat 
            "' not found." strcat Tell pid kill
          then
        then
        ourPost @ number? if                    (* ... then find post *)
          FindPostByNumber not if
            ">>  Sorry, post number "
            ourPost @ strcat 
            " not found." strcat Tell pid kill
          then
        else
          FindPostByTitle not if
            ">>  Sorry, post `"
            ourPost @ strcat
            "' not found." strcat Tell pid kill
          then
        then
        EditPost                                      (* go edit post *)
      else
        pop DoEditHelp
      then
    then
  else
    DoEditHelp
  then
;
  
: DoParseDelete  (  --  )                     (* parse delete command *)
  
  ourArg @ if                                          (* check #args *)
    ourArg @ "#" stringpfx if
      ourArg @ "#h" stringpfx if DoDeleteHelp    exit else
      ourArg @ "#a" stringpfx if DoCommandAlias  exit else
      ourArg @ "#r" stringpfx if DoCommandRename exit else
      ">>  #Argument not understood." Tell exit
      then then then
    else                                                     (* parse *)
      ourArg @ "/" instr dup if
        ourArg @ swap strcut strip dup if
          ourPost !
        else
          pop DoDeleteHelp exit
        then
        dup strlen 1 - strcut pop strip dup if
          ourArg !
        else
          pop DoDeleteHelp exit
        then
        ourArg @ number? if                          (* find board... *)
          FindBoardByNumber not if
            ">>  Sorry, board number "
            ourArg @ strcat
            " not found." strcat Tell pid kill
          then
        else
          FindBoardByTitle not if
            ">>  Sorry, board `" 
            ourArg @ strcat 
            "' not found." strcat Tell pid kill
          then
        then
        ourPost @ number? if                    (* ... then find post *)
          FindPostByNumber not if
            ">>  Sorry, post number "
            ourPost @ strcat 
            " not found." strcat Tell pid kill
          then
        else
          FindPostByTitle not if
            ">>  Sorry, post `"
            ourPost @ strcat
            "' not found." strcat Tell pid kill
          then
        then
        DeletePost                                  (* go delete post *)
      else
        pop DoDeleteHelp
      then
    then
  else
    DoDeleteHelp
  then
;
  
: DoParseBoard  (  --  )                       (* parse board command *)
  
  ourArg @ if            (* everything is an #arg; we're just routing *)
    ourArg @ "#ren" stringpfx if DoCommandRename  else
    ourArg @ "#ali" stringpfx if DoCommandAlias   else
    ourArg @ "#h"   stringpfx if DoBoardHelp      else
    ourArg @ "#c"   stringpfx if CreateNewBoard   else
    ourArg @ "#n"   stringpfx if ToggleNoNames    else
    ourArg @ "#d"   stringpfx if DeleteBoard      else
    ourArg @ "#w"   stringpfx if SetPostWindow    else
    ourArg @ "#p"   stringpfx if SetBoardPrivate  else
    ourArg @ "#o"   stringpfx if SetBoardOpen     else
    ourArg @ "#s"   stringpfx if SetBoardStaff    else
    ourArg @ "#g"   stringpfx if SetBoardGeneral  else
    ourArg @ "#i"   stringpfx if IncPlayerClosed  else
    ourArg @ "#e"   stringpfx if ExcPlayerClosed  else
    ourArg @ "#a"   stringpfx if AddAdministrator else
    ourArg @ "#r"   stringpfx if RemAdministrator else
    ourArg @ "#t"   stringpfx if SetSearchTariff  else
    ">>  #Argument not understood." Tell
    then then then then then then then then
    then then then then then then then then
  else
    DoBoardHelp
  then
;
  
: main
  
  "me" match me !                                    (* no imposters! *)
  strip ourArg !                               (* store orig argument *)
  command @ ourCom !                       (* store orig command name *)
  
  ourArg @ "#" stringpfx if
    ourArg @ " " instr if
      ourArg @ dup " " instr strcut pop strip ourString !
    else
      ourArg @ ourString !
    then                            (* filter out invalid #args early *)
    "#install" ourString @ stringpfx
    "#help"    ourString @ stringpfx  
    "#search"  ourString @ stringpfx
    "#new"     ourString @ stringpfx
    "#last"    ourString @ stringpfx
    "#window"  ourString @ stringpfx
    "#noname"  ourString @ stringpfx
    "#private" ourString @ stringpfx
    "#open"    ourString @ stringpfx
    "#include" ourString @ stringpfx
    "#exclude" ourString @ stringpfx
    "#add"     ourString @ stringpfx
    "#remove"  ourString @ stringpfx
    "#create"  ourString @ stringpfx
    "#destroy" ourString @ stringpfx
    "#alias"   ourString @ stringpfx
    "#rename"  ourString @ stringpfx
    "#staff"   ourString @ stringpfx
    "#general" ourString @ stringpfx
    "#tarrif"  ourString @ stringpfx
    or or or or or or or or or or or or or or or or or or or not if
      ">>  #Argument not understood." Tell exit
    then
  then
                       (* command may be aliased; get `official' name *)
  prog "_alias/" command @ strcat getpropstr dup if
    command !
  else
    pop
  then
                                         (* go to appropriate command *)
  command @ "read"    smatch if DoParseRead   else
  command @ "write"   smatch if DoParseWrite  else
  command @ "editmsg" smatch if DoParseEdit   else
  command @ "delete"  smatch if DoParseDelete else
  command @ "board"   smatch if DoParseBoard  else
  command @ "next"    smatch if DoNext        else
  ">>  Command not understood. Please contact "
  prog owner name strcat
  " or a staff member." strcat Tell
  then then then then then then
;
.
c
q
