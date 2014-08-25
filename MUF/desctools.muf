@program DescTools.muf
1 9999 d
i
( DescTools.muf    v1.3    Jessy @ FurryMUCK    9/96, 4/97
  
  A morphing program for storing and changing descs. Descs may have
  automatically set species and sex props associated with them. Users
  may also set an MPI string to be parsed when changing to specific
  descs.
  
  Installation:
  
  Create an action and link it to this program. DescTools.muf requires
  Mucker level 3 and the editor libraries lib-lmgr, lib-editor, and
  lib-strings, which should be available on any established MUCK, and
  lib-mucktools, which holds code shared by the MuckTools programs.
  The program uses no macros.
  
  The help screen uses the first alias of the command name in formatting
  output: name the action with the most common or intuitive alias first.
  Additional aliases are listed on the help screen.
  
  Use:
  
    <cmd> <string>      Wear desc <string>.
    <cmd> #list         List your currently stored descs.
    <cmd> #add          Add a desc.
    <cmd> #edit         Edit a stored desc.
    <cmd> #delete       Delete a stored desc.
    <cmd> #format       Edit your look-notify formats.
    <cmd> #restore      Restore desc worn before using this program.
 
  Functions which require additional input will supply prompts. You may
  talk and pose while at a prompt line. The argument strings listed
  above need not be entered completely: typing the # octothorpe followed 
  by the first one or several characters will select the appropriate 
  function. DescTools data is stored in your '_descs/' directory.
 
  DescTools.muf may be freely ported. Please comment any changes.
)
  
$define Tell me @ swap notify $enddef
  
lvar ourString   (* These three variables are swapped around as needed,  *)
lvar ourBoolean  (* but in general ourString holds input from keyboard,  *)
lvar counter     (* counter controls loops, and ourBoolean does IF tests *)
    
(***************************lsedit functions******************************)
  
$include $lib/lmgr
$include $lib/editor
$include $lib/strings
$include $lib/mucktools
 
$def LMGRgetcount lmgr-getcount
$def LMGRgetrange lmgr-getrange
$def LMGRputrange lmgr-putrange
$def LMGRdeleterange lmgr-deleterange
  
: LMGRdeletelist
    over over LMGRgetcount
    1 4 rotate 4 rotate LMGRdeleterange
;
  
: LMGRgetlist
    over over LMGRgetcount
    rot rot 1 rot rot
    LMGRgetrange
; 
  
: lsedit-loop            (* listname dbref {rng} mask currline cmdstr -- *)
    EDITORloop
    dup "save" stringcmp not if
        pop pop pop pop
        3 pick 3 + -1 * rotate
        over 3 + -1 * rotate
        dup 5 + pick over 5 + pick
        over over LMGRdeletelist
        1 rot rot LMGRputrange
        4 pick 4 pick LMGRgetlist
        dup 3 + rotate over 3 + rotate
        "< List saved. >" .tell
        "" lsedit-loop exit
    then
    dup "abort" stringcmp not if
        "< list not saved. >" .tell
        pop pop pop pop pop pop pop pop pop exit
    then
    dup "end" stringcmp not if
        pop pop pop pop pop pop
        dup 3 + rotate over 3 + rotate
        over over LMGRdeletelist
        1 rot rot LMGRputrange
        "< list saved. >" .tell exit
    then
;
    
: ThisEditList  ( s --  )                       (* edit list s on player *)
    
    me @
                                                         (* enter editor *)
"<    Welcome to the list editor.  You can get help by entering '.h'     >"
    Tell
"< '.end' will exit and save the list.  '.abort' will abort any changes. >"
    Tell
"<    To save changes to the list, and continue editing, use '.save'     >"
    Tell
    over over LMGRgetlist
    "save" 1 ".i $" lsedit-loop
;
   
(*************************Internal Functions******************************)
  
: ClearStack  (  --  )                   (* pop everything off the stack *)
    
    begin
        depth while pop
    repeat
;
  
: ListNames  (  -- s i )(* return trig aliases in comma-separeted string *)
                                          (* i is true if there are alia *)
   
           (* return null string and false if no addtional command names *)
   trig name ";" explode dup 1 = if
       pop "" 0 exit
       else
           counter !
   then
                                        (* make a string showing aliases *)
   "" ourBoolean !
   begin
       counter @ 1 = if
           pop break
       then
       swap ", " strcat ourBoolean @ swap strcat ourBoolean !
       counter @ 1 - counter !
   repeat
                                               (* return string and true *)
   ourBoolean @ dup strlen 2 - strcut pop 1
;
      
: DoInit  (  --  )                                (* set DescTools props *)
    
    me @ "_/de" getpropstr
    me @ "_descs/prefs/prev" getpropstr not and if
        me @ "_descs/prefs/prev"
        me @ "_/de" getpropstr 
        setprop
        ">>  Moving your current desc to prop '_descs/prefs/prev'." Tell
    then
    
    me @ "{my-desc}" setdesc
    
    me @ "_msgmacs/my-desc"
    "{if:{prop:_descs/{prop:_descs/prefs/current}#},"
    "{eval:{list:_descs/{prop:_descs/prefs/current}#}}"
    "{eval:{prop:_descs/prefs/lformat}}{eval:{prop:_descs/prefs/olformat}},"
    "{name:this} doesn't have a valid desc selected."
    "{null:{tell:[ {name:me} looked at you\\, but you don't have a valid "
    "desc selected. ],this}}}"
    strcat strcat strcat strcat strcat setprop
    
                              (* set a look-notify format if not present *)
    me @ "_descs/prefs/lformat" over over
    getpropstr not if
        "{null:{tell:[ {name:me} looked at you. ],this}}" setprop
        me @ me @ "_descs/prefs/olformat" "{null}" setprop
        else
            pop pop
    then
                              (* set a look-notify format if not present *)
    me @ "_descs/prefs/olformat" over over
    getpropstr not if
        "{null:{tell:[ {name:me} looked at you. ],this}}" setprop
        me @ me @ "_descs/prefs/olformat" 
        "{null:{tell:[ {name:this} sees you looking. ],me}}"  setprop
        else
            pop pop
    then
    
    me @ "_descs/prefs/ver" "1.3" setprop
;
  
: CheckInit  (  --  )                     (* initialize player if needed *)
   
    me @ "_descs/prefs/ver" getpropstr dup if
        "1.3" instr not if
            DoInit
        then
    then    
;  
  
: GrabADesc  (  --  )        (* set 'current' to first desc in directory, 
                                        or warn if user now has no descs *)
    
          (* find a desc list. ourBoolean stores true if a desc is found *)
    0 ourBoolean !
    me @ "_descs/" nextprop counter !
    begin
        counter @ while
        me @ counter @ "/1" strcat getpropstr if
  
                                              (* found one! set and exit *)
            1 ourBoolean !
            me @ "_descs/prefs/current"
            counter @ 7 strcut swap pop dup strlen 1 - strcut pop 
            dup ourString !
            setprop
            break
        then
        me @ counter @ nextprop counter !
    repeat
    
                                            (* no descs found; warn user *)
    ourBoolean @ not if
        ">>  Warning: You currently have no descs stored." Tell
        else
            ">>  Current desc is now invalid. Changing to your '"
            ourString @ strcat
            "' desc." strcat Tell
    then
;
  
: DescCheck  ( --  )               (* check: 'current' desc still valid? 
                                              grab and set a desc if not *)
    me @ "_descs/prefs/current" getpropstr dup not if
        pop GrabADesc
        else
        "_descs/" swap strcat "#/1" strcat me @ swap getpropstr not if
            GrabADesc
        then
    then 
;
  
: MiscProps  (  --  )       (* set additional props associated with desc *)
    
              (* see if user wants to reset species or sex for this desc *)
    begin
     ">>  Do you want to reset your species prop when changing to this desc?"
        Tell
        ">> [Enter 'yes', 'no', or .q to quit]" Tell
        SayPose strip
    
        dup ".quit" swap stringpfx if
             DescCheck exit
        then
        
        dup "yes" swap stringpfx if
            ">>  What species is associated with this desc?" Tell
            ">> [Enter species, or .q to quit]" Tell
            SayPose strip
            
            dup ".quit" swap stringpfx if
                DescCheck exit
            then
            
            me @ "_descs/" ourString @ strcat "/spec" strcat rot setprop
            ">>  Set." ClearStack break
        then
        
        "no" swap stringpfx if
            me @ "_descs/" ourString @ strcat "/spec" strcat remove_prop
            break
            else
                ">>  Command not understood." Tell continue
        then
    repeat 
            
    begin
        ">>  Do you want to reset your sex prop when changing to this desc?"
        Tell
        ">> [Enter 'yes', 'no', or .q to quit]" Tell
        SayPose strip
    
        dup ".quit" swap stringpfx if
             DescCheck exit
        then
        
        dup "yes" swap stringpfx if
            ">>  What sex is associated with this desc?" Tell
            ">> [Enter species, or .q to quit]" Tell
            SayPose strip
            
            dup ".quit" swap stringpfx if
                DescCheck Tell exit
            then
            
            me @ "_descs/" ourString @ strcat "/sex" strcat rot setprop
            ">>  Set." ClearStack break
        then
        
        "no" swap stringpfx if
            me @ "_descs/" ourString @ strcat "/sex" strcat remove_prop
            break
            else
                ">>  Command not understood." Tell continue
        then
    repeat 
    
     begin
        ">>  Do you want to run an MPI string when changing to this desc?"
        Tell
        ">> [Enter 'yes', 'no', or .q to quit]" Tell
        SayPose strip
    
        dup ".quit" swap stringpfx if
             DescCheck Tell exit
        then
        
        dup "yes" swap stringpfx if
            ">>  What MPI should be parsed when you change to this desc?"
             Tell
            ">> [Enter MPI string, or .q to quit]" Tell
            SayPose strip
            
            dup ".quit" swap stringpfx if
                DescCheck Tell exit
            then
            
            dup
            me @ "_descs/" ourString @ strcat "/mpi" strcat rot setprop
            ">>  Set to " Tell " " Tell
            "       " swap strcat Tell " " Tell
            break
        then
        
        "no" swap stringpfx if
            me @ "_descs/" ourString @ strcat "/mpi" strcat remove_prop
            break
            else
                ">>  Command not understood." Tell continue
        then
    repeat 
;
  
(*************************************************************************)
  
: DoHelp  ( s --  )                                  (* show help screen *)
    
    " " Tell "DescTools.muf, v1.3" 
    prog "L" flag? if
        " (program #" prog intostr strcat ")" strcat strcat
    then
    Tell " " Tell
    
    trig name MainName " <string>" 20 Pad "Wear desc <string>." 
    strcat strcat Tell
    trig name MainName " #list" 20 Pad "List your currently stored descs." 
    strcat strcat Tell
    trig name MainName " #add" 20 Pad "Add a desc." 
    strcat strcat Tell
    trig name MainName " #edit" 20 Pad "Edit a stored desc." 
    strcat strcat Tell
    trig name MainName " #delete" 20 Pad "Delete a stored desc." 
    strcat strcat Tell
    trig name MainName " #format" 20 Pad "Edit your look-notify formats." 
    strcat strcat Tell
    trig name MainName " #restore" 20 Pad "Restore desc worn before using this "
    "program." strcat strcat strcat Tell " " Tell
    ListNames if
        "Command aliases: " swap strcat Tell " " Tell
    then
    "Functions which require additional input will supply prompts. You may "
    "talk and pose while at a prompt line. The argument strings listed "
    "above need not be entered completely: typing the # octothorpe followed " 
    "by the first one or several characters will select the appropriate "
    "function. DescTools data is stored in your '_descs/' directory." 
    strcat strcat strcat strcat
    Tell " " Tell
;
  
: DoList  ( s --  )                         (* show list of stored descs *)
    
    pop CheckInit
    " " Tell "Currently stored descs:" Tell " " Tell
    me @ "_descs/" nextprop counter !
    begin
        counter @ while
        counter @ "*#" smatch if
            "  " counter @ 7 strcut swap pop 
            dup strlen 1 - strcut pop strcat
            Tell
        then
        me @ counter @ nextprop counter !
    repeat
    " " Tell 
;
  
: DoWear  ( s --  )  (* set prop '_descs/current' to user-specified desc *)
    
                                     (* check: have a desc by that name? *)
    pop CheckInit 
    me @ "_descs/" ourString @ strcat "#/1" strcat getpropstr not if
        ">>  You don't have a desc called '" 
        ourString @ strcat
        "'." strcat  Tell exit
    then
                                                               (* set it *)
    me @ "_descs/prefs/current" ourString @ setprop
    me @ "_descs/" ourString @ strcat "/spec" strcat getpropstr dup if
        me @ "species" rot setprop
        else
            pop
    then
    me @ "_descs/" ourString @ strcat "/sex" strcat getpropstr dup if
        me @ "sex" rot setprop
        else
            pop
    then
    me @ "_descs/" ourString @ strcat "/mpi" strcat getpropstr if
        me @ "_descs/" ourString @ strcat "/mpi" strcat ParseThis
    then
    
    ">>  You are now wearing your '" ourString @ strcat "' desc." strcat
    Tell
;
  
: DoAdd  ( s --  )           (* add a desc to user's '_descs/' directory *)
    
              (* check: does user have a non-DescTools desc? Store if so *)
    pop CheckInit
                                        (* set DescTools props if needed *)
    me @ "_descs/prefs/ver" getpropstr dup if
        "1.1" smatch not if
             DoInit
         then
         else
             DoInit
    then
                                              (* get desc name from user *)
    ">>  What is the name of this description?" Tell
    ">> [Enter a name, or .q to quit]" Tell
    SayPose strip ourString !
    
    ourString @ ".quit" swap stringpfx if 
        DescCheck ">>  Done." Tell exit
    then
                            (* check: would desc name create a wiz prop? *)
    ourString @ "@*" smatch if
">>  That name would cause the program to place the desc in a wizard-only"
    Tell
"    directory. Please choose a different name."
    Tell
        DescCheck ">>  Done." Tell exit
    then
                (* check: would desc name be interpreted as an argument? *)
    ourString @ "#*" smatch if
">>  A desc name beginning with an # octothorpe would be mis-interpreted by"
    Tell
"    the program as a command-line argument. Please choose a different name."
    Tell
        DescCheck ">>  Done." Tell exit
    then
                             (* check: already have a desc by that name? *)
    me @ "_descs/" ourString @ strcat "#/1" strcat getpropstr if
        ">>  You already have a desc by that name." Tell
        DescCheck ">>  Done." Tell exit
    then
    
    " " Tell
"*************Entering lsedit. Type your new description here. ***********"
    Tell
"***********The description can modified with the #edit command***********"
    Tell " " Tell
                                             (* use editor to enter desc *)
    "_descs/" ourString @ strcat ThisEditList
    
    MiscProps     
   
      (* set new desc to current if user has no current DescTools desc set *)
    me @ "_descs/prefs/current" over over getpropstr not if 
        ourString @ setprop
        else
            pop pop
    then
    
    DescCheck ">>  Done." Tell
;
  
: DoEdit  ( s --  )                                  (* edit stored desc *)
     
    pop CheckInit
                                        (* set DescTools props if needed *)
    me @ "_descs/prefs/ver" getpropstr dup if
        "1.1" smatch not if
             DoInit
         then
         else
             DoInit
    then
                                                        (* get desc name *)
    ">>  Which desc do you want to edit?" Tell
    ">> [Enter a desc name, or .q to quit]" Tell
    SayPose strip ourString !
    
    ourString @ ".quit" swap stringpfx if
        DescCheck ">>  Done." Tell exit
    then
                                      (* check: user has indicated desc? *)
    me @ "_descs/" ourString @ strcat "#/1" strcat getpropstr not if
        ">>  You don't have a desc called '"
        ourString @ strcat
        "'." strcat Tell 
        DescCheck ">>  Done." Tell exit
    then
                                                              (* edit it *)
    "_descs/" ourString @ strcat ThisEditList
    
    MiscProps
    
    DescCheck ">>  Done." Tell
;
  
: DoDelete  ( s --  )                              (* delete stored desc *)
    
                                                        (* get desc name *)
    pop CheckInit
    ">>  Which desc do you want to delete?" Tell
    ">> [Enter a desc name, or .q to quit]" Tell
    SayPose strip ourString !
    
    ourString @ ".quit" swap stringpfx if
        DescCheck ">>  Done." Tell exit
    then
                                      (* check: user has indicated desc? *)
    me @ "_descs/" ourString @ strcat "#/1" strcat getpropstr not if
        ">>  You don't have a desc by that name." Tell exit
    then
                                                            (* delete it *)
    "_descs/" ourString @ strcat me @ swap RemoveList
    me @ "_descs/" ourString @ strcat "/spec" strcat remove_prop
    me @ "_descs/" ourString @ strcat "/sex"  strcat remove_prop
    me @ "_descs/" ourString @ strcat "/mpi"  strcat remove_prop
    
        (* check: 'current' desc still valid? grab and set a desc if not *)    
    DescCheck ">>  Done." Tell
;
  
: DoFormat  ( s --  )                     (* reformat look-notify string *)
    
                         (* set one to be reformated if there isn't one! *)
    pop CheckInit
    me @ "_descs/prefs/ver" getpropstr dup if
        "1.1" smatch not if
             DoInit
         then
         else
             pop
    then
    
    0 ourBoolean !
    begin
        ">>  Do you want to be told when someone looks at you?"
        Tell
        ">> [Enter 'yes', 'no', or .q to quit]" Tell
        SayPose strip
    
        dup ".quit" swap stringpfx if
             DescCheck ">>  Done." Tell exit
        then
        
        dup "yes" swap stringpfx if
            pop
            ">>  Your current MPI look-notify string is: " Tell " " Tell
            me @ "_descs/prefs/lformat" getpropstr Tell " " Tell
    
                                             (* show how it looks parsed *)
            ">>  If you were the 'looker', this would parse to: " 
            Tell " " Tell
            me @ "_descs/prefs/lformat" ParseThis ClearStack
            " " Tell
    
                                                      (* get new version *)
            ">>  What do you want to set your MPI look-notify string to?" 
            Tell
">> [Enter MPI for your look-notify, .d to return to the default setting, "
            Tell
"    .n for no change, or .q to quit]" Tell
    
            Saypose strip ourString !
    
            ourString @ ".quit" swap stringpfx if
                DescCheck ">>  Done." Tell exit
            then
                                             (* check: reset to default? *)
            ourString @ ".d" smatch if
                me @ "_descs/prefs/lformat"
                "{null:{tell:[ {name:me} looked at you. ],this}}" 
                setprop
                ">>  Set." Tell 1 ourBoolean !
            then
            
            ourBoolean @ not if
                ourString @ ".n" smatch not if
                                                      (* set new version *)
                    me @ "_descs/prefs/lformat" ourString @ setprop
                                               (* show what was just set *)
                    ">>  Format set to:" Tell " " Tell
                    ourString @ Tell " " Tell
                                             (* show how it looks parsed *)
                    ">>  If you were the 'looker', this would parse to: " 
                    Tell " " Tell
                    me @ "_descs/prefs/lformat" ParseThis ClearStack
                    " " Tell
                then
            then
            
            begin
">>  Do you want the player who looks at you to be told that you were "
                Tell
                "    notified?" Tell
                ">> [Enter 'yes', 'no', or .q to quit]" Tell
                SayPose strip ourString !
    
                ourString @ ".quit" swap stringpfx if
                    DescCheck ">>  Done." Tell exit
                then
        
                ourString @ "yes" swap stringpfx if
                    ">>  Your current MPI o-look-notify string is: " 
                    Tell " " Tell
                    me @ "_descs/prefs/olformat" getpropstr Tell " " Tell
   
                                             (* show how it looks parsed *)
                   ">>  If you were the 'looker', this would parse to: " 
                   Tell " " Tell
                    me @ "_descs/prefs/olformat" ParseThis ClearStack
                    " " Tell
    
                                                      (* get new version *)
                   ">>  What do you want to set your MPI "
                   "o-look-notify string to?" strcat Tell
">> [Enter MPI for your look-notify, .d to return to the default setting, "
                   Tell
                   "   .n for no change, or .q to quit]" Tell
    
                   Saypose strip ourString !
    
                   ourString @ ".quit" swap stringpfx if
                       DescCheck ">>  Done." Tell exit
                   then
                                             (* check: reset to default? *)
                   ourString @ ".d" smatch if
                       me @ "_descs/prefs/olformat"
                       "{null:{tell:[ {name:this} sees you looking. ],me}}" 
                       setprop
                       ">>  Set." Tell 
                       DescCheck ">>  Done." Tell exit
                   then
                   
                   ourString @ ".n" smatch if
                       DescCheck ">>  Done." Tell exit
                   then
                                                      (* set new version *)
                   me @ "_descs/prefs/olformat" ourString @ setprop
                                               (* show what was just set *)
                   ">>  Format set to:" Tell " " Tell
                    ourString @ Tell " " Tell
                                             (* show how it looks parsed *)
                   ">>  This parses to: " Tell " " Tell
                   me @ "_descs/prefs/olformat" ParseThis ClearStack
                   " " Tell
                   DescCheck ">>  Done." Tell exit
                then
                
                ourString @ "no" swap stringpfx if
                    me @ "_descs/prefs/olformat" "{null}" setprop
                    ">>  Set." Tell
                    DescCheck ">>  Done." Tell exit
                    else
                        ">>  Command not understood." Tell continue
                then
                break
            repeat
       then
                
       ourString @ "no" swap stringpfx if
           me @ "_descs/prefs/lformat" "{null}" setprop
           ">>  Set." Tell
           DescCheck ">>  Done." Tell exit
           else
               ">>  Command not understood." Tell continue
       then
       break
    repeat 
                                                 (* show current version *)    
    DescCheck ">>  Done." Tell
;
  
: DoRestore  ( s --  )                    (* restore old desc if present *)
    
                                    (* check: do we have one to restore? *)
    pop
    me @ "_descs/prefs/prev" getpropstr not if
        ">>  No previous desc to restore!" Tell
        ">>  If you want to stop using this program, erasing all data, type:"
        Tell " " Tell
        "       @set me = _descs/:" Tell " " Tell
        ">>  To erase only the DescTools props, saving your descs, type:"
        Tell " " Tell
        "       @set me = _descs/prefs/:" Tell " " Tell
        ">>  Your descs will remain in your '_descs/' directory, "
        "stored as lists." strcat Tell exit
    then
                                                              (* restore *)
    me @ dup "_descs/prefs/prev" getpropstr setdesc
                                                (* remove DescTools data *)
    me @ "_descs/prefs/lformat" remove_prop
    me @ "_descs/prefs/olformat" remove_prop
    me @ "_descs/prefs/prev" remove_prop
    me @ "_descs/prefs/current" remove_prop
    me @ "_descs/prefs/ver" remove_prop
    ">>  Restored." Tell
           (* notify if user still has descs stored in _descs/ directory *)
    me @ "_descs/" nextprop if
        ">>  Descs set with DescTools are still in your '_descs/' directory."
        Tell
    then
;
  
: main
    
    "me" match me !
    strip dup ourString !
    
                                                       (* set docs prop *)
    prog "_docs" "@list #" prog intostr strcat "=1-36" strcat setprop
    
    ourString @ not if
        DoHelp exit
    then
    
    dup if
        dup "#*" smatch if
            dup "#help"    swap stringpfx if DoHelp    else
            dup "#list"    swap stringpfx if DoList    else
            dup "#add"     swap stringpfx if DoAdd     else
            dup "#edit"    swap stringpfx if DoEdit    else
            dup "#delete"  swap stringpfx if DoDelete  else
            dup "#format"  swap stringpfx if DoFormat  else
            dup "#restore" swap stringpfx if DoRestore else
                ">>  Command not understood." Tell
            then then then then then then then
            exit
        then
    then
                                            (* screen for wiz-prop stuff *)
    ourString @ "@*" smatch if
        ">>  You don't have a desc called '"
        ourString @ strcat
        "'." strcat Tell exit
    then
        
    DoWear
;
.
c
q

