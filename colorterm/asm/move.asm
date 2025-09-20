.const RAND         0x8010

.const SET_FG_COLOR   0x9000
.const SET_BG_COLOR   0x9001
.const CLEAR_SCREEN   0x9002
.const SET_CHAR       0x9003
.const PRINT_CHAR     0x9004
.const SET_CURSOR_VIS 0x9005
.const SET_TITLE      0x9006
.const SET_X          0x9007
.const SET_Y          0x9008
.const KEY_CNT        0x9009
.const GET_KEY        0x900A
.const MOVE_E         0x9010
.const MOVE_SE        0x9011
.const MOVE_S         0x9012
.const MOVE_SW        0x9013
.const MOVE_W         0x9014
.const MOVE_NW        0x9015
.const MOVE_N         0x9016
.const MOVE_NE        0x9017
.const MOVE           0x9020

.const BLACK          0
.const BLUE           1
.const GREEN          2
.const CYAN           3
.const RED            4
.const MAGENTA        5
.const BROWN          6
.const GREY           7
.const DARKGREY       8
.const LIGHTBLUE      9
.const LIGHTGREEN     10
.const LIGHTCYAN      11
.const LIGHTRED       12
.const LIGHTMAGENTA   13
.const YELLOW         14
.const WHITE          15

.const KEY_SPACE      32


!prep
    ;;; rE = number of ASCII printable character
    set rE, '~'
    sub rE, '!'
    inc rE

    set rA, BLACK
    str [SET_BG_COLOR], rA
    set rA, WHITE
    str [SET_FG_COLOR], rA
    str [CLEAR_SCREEN], rZ
    str [SET_CURSOR_VIS], rZ

    str [SET_X], rZ
    str [SET_Y], rZ

    set rD, '@'

    cal !clear_current
    str [CLEAR_SCREEN], rZ
    cal !set_current

    jmp !main


; Delays by N milliseconds, where N is stored in rA
!delay_ms
    cmp rA, rZ
    jg !delay_loop
    ret

    !delay_loop
        dly 997
        dec rA
        cmp rA, rZ
        jg !delay_loop
    ret


!clear_current
    set rA, BLACK
    str [SET_BG_COLOR], rA
    set rA, WHITE
    str [SET_FG_COLOR], rA
    set rA, ' '
    str [SET_CHAR], rA
    ret


!set_current
    set rA, DARKGREY
    str [SET_BG_COLOR], rA
    set rA, LIGHTCYAN
    str [SET_FG_COLOR], rA
    str [SET_CHAR], rD
    ret



; Stores the caputred key in rA
; Stores the corresponding move direction in rB
!get_dir_from_key
    lod rA, [GET_KEY]

    ; Loop back if no key was found
    cmp rA, rZ
    jne !found_any_key
        dly 5
        jmp !get_dir_from_key
    !found_any_key

    cmp rA, KEY_SPACE
    jne !not_space
        ; Draw an empty character, then clear the character, and make cursor visible
        set rD, ' '
        cal !set_current
        set rD, rZ
        str [SET_CURSOR_VIS], SP

        jmp !get_dir_from_key
    !not_space

    cmp rD, rZ
    jne !key_already_set
        ; Keep looking for new character if not a visible character
        cmp rA, '!'
        jl !get_dir_from_key
        cmp rA, '~'
        jg !get_dir_from_key

        ; Set and draw the new character
        set rD, rA
        cal !set_current
        str [SET_CURSOR_VIS], rZ

        ; Keep looping
        jmp !get_dir_from_key
    !key_already_set


    cmp rA, 'w'
    jne !not_W
        set rB, 6
        ret
    !not_W

    cmp rA, 'a'
    jne !not_A
        set rB, 4
        ret
    !not_A

    cmp rA, 's'
    jne !not_S
        set rB, 2
        ret
    !not_S

    cmp rA, 'd'
    jne !main
        set rB, 0
        ret
    ; not_D

    jmp !get_dir_from_key



!main
    ; Stores movement direction in rB
    cal !get_dir_from_key

    ; Set rC to negative of movement
    set rC, rB + 4
    and rC, 0x7

    ; Move character
        ; Move and set new character
        str [MOVE], rB
        cal !set_current

        ; Backtrack and clear old character
        str [MOVE], rC
        cal !clear_current

        ; Move back to current spot
        str [MOVE], rB
    ; End move charater
    ; The above seems stupid
    ; Why not clear, move, then set?
    ; Because for some reason that ends up leaving traling keyboard inputs in the terminal



    set rA, 33
    ; cal !delay_ms
    jmp !main


!END