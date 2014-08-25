@program Dice.muf
1 9999 d
i
( DicePack.muf  v1.0    Jessy @ FurryMUCK    12/96
  
  A dice-rolling utility. The program lets players roll X number of
  Y-sided dice, modified +/- Z, with the results shown to the room
  or a specified group of players.
  
  Installation:
  
  Link an action to this program. DicePack.muf requires Mucker level
  2 and the .pmatch macro.
  
  Use:
  
  Syntax: 
 
  roll [<number of dice>] <sides per die> [+|-<modifier] [to <player/s>]
 
  Examples:
 
  roll 6                      Roll 1 six-sided die
  roll 3 6                    Roll 3 six-sided dice
  roll 3 6 +2                 Roll 3 six-sided dice, with a +2 modifier
  roll 20 to Glumilan         Roll 1 twenty-sided die, showing the result
                              only to you and Glumilan.
 
  Multiple players can be included in the 'to' group; if no players are 
  specified, the results are shown to the room.
  Any number of any-sided dice can be rolled, but riduculously large
  numbers will result in errors, the exact error depeding on the program's
  Mucker level.
  
  DicePack.muf may be freely ported or copied. Please comment any changes.
)
  
$define Tell me @ swap notify $enddef
  
lvar counter                                   (* loop controlling counter *)
lvar ourString          (* input from keyboard or figured string to output *)
lvar tellPlayers                             (* players to be told results *)
lvar dice                                  (* sides per dice; type of dice *)
lvar times   (* number of dice to roll; used as loop control in ParseNames *)
lvar modifier                            (* modider to apply to total roll *)
lvar total                                         (* total rolled on dice *)
lvar ourFlag
  
: Pad  ( s i --  )                     (* pad string s with i spaces right *)
    
    "                                                             "
    rot swap strcat swap strcut pop
;
  
: Ltell  ( s --  )                     (* notify players at loc with s *)
   
    loc @ swap 0 swap notify_exclude
;
 
: DoHelp  (  --  )                    (* you guessed it: show help screen *)
    
    " " Tell
    "DicePack.muf  v1.0" Tell
    " " Tell
    "Syntax: " Tell
    " " Tell
    "  " command @ strcat
    " [<number of dice>] <sides per die> [+|-<modifier>] [to <player/s>]"
    strcat Tell
    " " Tell
    "Examples:" Tell
    " " Tell
    "  " command @ strcat
    " 6" strcat 30 pad
    "Roll 1 six-sided die" strcat Tell
    
    "  " command @ strcat
    " 3 6" strcat 30 pad
    "Roll 3 six-sided dice" strcat Tell
        
    "  " command @ strcat
    " 3 6 +2" strcat 30 pad
    "Roll 3 six-sided dice, with a +2 modifier" strcat Tell
    
    "  " command @ strcat
    " 20 to Glumilan" strcat 30 pad
    "Roll 1 twenty-sided die, showing the result" strcat Tell
    " " 30 pad
    "only to you and Glumilan." strcat Tell
    
    " " Tell
    "Multiple players can be included in the 'to' group; if no players "
    "are specified, the results are shown to the room. Any number of "
    "any-sided dice may be rolled, but extremely large numbers will "
    "result in errors." strcat strcat strcat Tell
    " " Tell
;
  
: ParseNames  (  --  )               (* convert string of names to tell
                                        results to into a string of dbrefs *)
    
                        (* get rid of 'and', just in case they included it *)
    tellPlayers @ "* and *" smatch if
        tellPlayers @ "and" explode pop 
        " " swap strcat strcat strip
        tellPlayers !
    then
                    (* build concatted string of dbrefs of players to tell *)
                   (* ourFlag will control whether a 'tell' loop is needed *)
    tellPlayers @ "* *" smatch if
        tellPlayers @ " " explode counter !
        "" tellPlayers !
        begin
            counter @ not if 
                break
            then
            dup strip .pmatch dup not if
                 pop
                 ">>  Player " swap strcat
                 " not found." strcat Tell
                 else
                     dup awake? not if
                         ">>  " swap name strcat
                         " is not online." strcat Tell
                         counter @ 1 - counter !
                         pop
                         continue
                     then
                     dup location loc @ dbcmp not if
                         ">>  " swap name strcat
                         " is not here." strcat Tell
                         counter @ 1 - counter !
                         pop
                         continue
                     then
                     ourFlag @ 1 + ourFlag !
                     ourFlag @ 2 >= if
                         intostr " " swap strcat 
                         tellPlayers @ swap strcat tellPlayers !
                         else
                             intostr tellPlayers @ swap strcat 
                             tellPlayers !
                     then
                     pop
             then
             counter @ 1 - counter !
        repeat
        else
            tellPlayers @ .pmatch dup not if
                ">>  Player " tellPlayers @ strcat
                " not found." strcat Tell 
                else
                    dup awake? not if
                        ">>  " swap name strcat
                        " is not online." strcat Tell
                        else
                            intostr tellPlayers ! 1 ourFlag !
                    then
            then
    then
;
  
: DoTell  (  --  )                              (* display results of roll *)
    
                                       (* get original 'times' number back *)
    ourString @ times !
                                                 (* make the output string *)
    ">>  " me @ name strcat
    " rolls " strcat
    total @ intostr strcat
    " on " strcat
    times @ intostr strcat
    " " strcat
    dice @ intostr strcat
    "-sided " strcat
    times @ 1 = if
        "die"
        else
            "dice"
    then
    strcat 
    modifier @ if
        ", with a " strcat
        modifier @ atoi 0 > if
            "+" strcat
        then
        modifier @ strcat
        " modifier" strcat
    then
    "." strcat
    ourString !
                                           (* this is the to-room version *)
    tellPlayers @ not if
        loc @ #-1 ourString @ notify_except exit
    then
                                     (* this is the 'to-somebody' version *)
    ParseNames
    ourFlag @ if
                                    (* first make the 'to' part of string *)
    tellPlayers @ if
        tellPlayers @ " " explode 
        dup 1 = not if
            ourString @ " \(to " strcat ourString !
            counter !
            begin
                counter @ not if
                    break
                then
                atoi dbref name
                counter @ 1 = if
                    "and " swap strcat
                then
                counter @ 3 >= if
                    "," strcat
                then
                counter @ 1 > if
                    " " strcat
                then
                ourString @ swap strcat ourString !
                counter @ 1 - counter !
            repeat
            ourString @ "\)" strcat
            else
                pop
                tellPlayers @ atoi dbref ourString @ " \(to you\)" strcat
                notify      
                ourString @ " \(to " strcat swap atoi dbref name strcat
                "\)" strcat dup Tell pop exit
        then
    then
    
    ourString !                                (* store built string... *)
                                                             (* notify! *)
    tellPlayers @ if
        tellPlayers @ " " explode counter !
        begin
            counter @ not if 
                break
            then
            atoi dbref ourString @ notify
            counter @ 1 - counter !
        repeat
        then
        ourString @ Tell
        else
            ourString @ Ltell
    then
;
  
: DoRoll  (  --  )                                     (* roll those dice! *)
    
    0 total !
    begin
        random dice @ % 1 + 
        total @ + total !
        times @ 1 - times !
        times @ not if
            break
        then
    repeat
    
    total @ modifier @ atoi + total !
    
    DoTell
;
  
: DoParse  (  --  )     (* parse arg string into dice, sides, mod, players *)
    
                                                   (* check: 'to' players? *)
    ourString @ "* to *" smatch if
       ourString @ " to " explode pop strip ourString !
       strip tellPlayers !
    then
                                                  (* check: plus modifier? *)
    ourString @ "+" rinstr dup if
        ourString @ swap strcut strip modifier !
        dup strlen 1 - strcut pop strip ourString ! 
        else
            pop
    then
                                                 (* check: minus modifier? *)
    ourString @ "-" rinstr dup if
        ourString @ swap strcut strip 
        atoi 0 swap - intostr modifier !
        dup strlen 1 - strcut pop strip ourString ! 
        else
            pop
    then
                                                            (* get numbers *)
    ourString @ " " explode
    
    dup 1 = if
        pop 
        dup number? not if
            pop DoHelp exit
        then
        atoi dice !
        else
            2 = if
                dup number? not if
                    pop DoHelp exit
                then
                atoi times ! 
                dup number? not if
                    pop DoHelp exit
                then
                atoi dice !
                else
                     DoHelp exit
        then
    then
                                          (* stick a 1 in times if omitted *)
    times @ not if
        1 times !
    then
                               (* save 'times' in 'ourstring', since 'times'
                                           will be modified in DoRoll loop *)
    times @ ourString !
    
    DoRoll
;
  
: main
    
    "me" match me !
    dup ourString !
    
    dup if
        dup "#help" swap stringpfx if 
            DoHelp exit
        then
        else
            DoHelp exit
    then
    
    DoParse
;
.
c
q

