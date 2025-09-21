; PERIPHERAL CONSTANTS
    .const RAND           0x8010
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

; COLOR CONSTANTS
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

; KEY CONSTANTS 
    .const KEY_ENTER    1
    .const KEY_INSERT   2
    .const KEY_HOME     3
    .const KEY_PGUP     4
    .const KEY_DELETE   5
    .const KEY_END      6
    .const KEY_PGDOWN   7
    .const KEY_UP       14
    .const KEY_DOWN     15
    .const KEY_LEFT     16
    .const KEY_RIGHT    17
    .const KEY_F1       18
    .const KEY_F2       19
    .const KEY_F3       20
    .const KEY_F4       21
    .const KEY_F5       22
    .const KEY_F6       23
    .const KEY_F7       24
    .const KEY_F8       25
    .const KEY_F9       26
    .const KEY_F10      27
    .const KEY_F11      28
    .const KEY_F12      29
    .const KEY_NUMDEL   30
    .const KEY_NUMPAD0  31
    .const KEY_SPACE    32
    .const KEY_VIS_MIN  '~'
    .const KEY_VIS_MAX  '!'
    .const KEY_NUMPAD1  127
    .const KEY_NUMPAD2  128
    .const KEY_NUMPAD3  129
    .const KEY_NUMPAD4  130
    .const KEY_NUMPAD5  131
    .const KEY_NUMPAD6  132
    .const KEY_NUMPAD7  133
    .const KEY_NUMPAD8  134
    .const KEY_NUMPAD9  135

; Ideas
    ; Paint program
        ; Use WASD to move cursor
        ; "Pen-up" and "pen-down" buttons
        ; Adjustable parameters
            ; Foreground Color
            ; Foreground Intensity
                ; Will just pick from a list of characters that are more or less "intense"
            ; Background Color
            ; Brush size
                ; Square brush, maybe toggleable gradiant
            ; Texture
                ; Randomness is selection of intensity for each character

    ;;; rE = number of ASCII printable character
    set rE, '~'
    sub rE, '!'
    inc rE


; KEYBINDS
    .const KB_UP                'w'
    .const KB_LEFT              'a'
    .const KB_DOWN              's'
    .const KB_RIGHT             'd'
    .const KB_BRUSH_SINGLE      'j'
    .const KB_BRUSH_UP          'h'
    .const KB_BRUSH_PEN         'k'
    .const KB_BRUSH_RADIAL      'l'
    .const KB_BRUSH_FILL        ';'
    .const KB_PAINT_COL         'u'
    .const KB_PAINT_TEX_INTN    'i'
    .const KB_PAINT_TEX_RAND    'o'
    .const KB_PAINT_RAD_RADI    'm'


!prep
    cal !set_colors
    set rA, '#'
    str [paint_uniform_char], rA
    set rA, !mcb_up
    str [move_callback], rA
    jmp !main_loop


!main_loop
    lod rA, [GET_KEY]

    ; If no key, continue
    cmp rA, rZ
    jne !found_any_key
        dly 7
        jmp !main_loop
    !found_any_key

    ; Parse keybinds
        ; Uniform character change
            ; Delete to cancel character change
            cmp rA, KEY_DELETE
            jne !not_delete
                set rE, rZ
                jmp !main_loop
            !not_delete

            ; If changing character, store the next input in `paint_uniform_char`
            cmp rE, -1
            jne !not_changing_char
                set rE, rZ
                str [paint_uniform_char], rA
                jmp !main_loop
            !not_changing_char
            
            ; If space, change what character is being used
            cmp rA, KEY_SPACE
            jne !not_space
                str [SET_CURSOR_VIS], rA
                set rE, -1
                jmp !main_loop
            !not_space


        ; Movement
            cmp rA, KB_UP
            jne !not_UP
                set rB, 6
                jmp !move
            !not_UP

            cmp rA, KB_LEFT
            jne !not_LEFT
                set rB, 4
                jmp !move
            !not_LEFT

            cmp rA, KB_DOWN
            jne !not_DOWN
                set rB, 2
                jmp !move
            !not_DOWN

            cmp rA, KB_RIGHT
            jne !not_RIGHT
                set rB, 0
                jmp !move
            !not_RIGHT
        
        ; Brush mode
            ; Not actually a mode, just run the "pen" operation once
            cmp rA, KB_BRUSH_SINGLE
            jne !not_brush_single
                cal !mcb_pen
                jmp !keybinds_done
            !not_brush_single

            cmp rA, KB_BRUSH_UP
            jne !not_brush_up
                set rA, !mcb_up
                str [move_callback], rA
                cal !mcb_up
                jmp !keybinds_done
            !not_brush_up

            cmp rA, KB_BRUSH_PEN
            jne !not_brush_pen
                set rA, !mcb_pen
                str [move_callback], rA
                cal !mcb_pen
                jmp !keybinds_done
            !not_brush_pen

    !keybinds_done


    jmp !main_loop


!set_colors
    lod rA, [paint_fg_col]
    str [SET_FG_COLOR], rA
    lod rA, [paint_bg_col]
    str [SET_BG_COLOR], rA
    ret


; Expects rB to contain the movement direction
; Not to be called, use `jmp !move, jumps back to main_loop after
!move
    str [MOVE], rB
    lod rB, [move_callback]
    cal rB
    jmp !main_loop


!mcb_up
    ret


!mcb_pen
    lod rA, [paint_uniform_char]
    str [SET_CHAR], rA
    ret

    


; ARRAYS AND WHATNOT
    ; ; Up=0, Pen=1, Radial=2, Fill=3
    ; .var brush_mode 0
    .var move_callback  !mcb_pen

    ; Brush-mode settings:
        .var brush_radial_radius    3
        .var brush_fill_start_x     0
        .var brush_fill_start_y     0

    ; Uniform=0, Textured=1
    .var paint_mode     0
    .var paint_fg_col   WHITE
    .var paint_bg_col   BLACK

    ; Paint-mode settings:
        .var paint_uniform_char         '#'
        .var paint_textured_randomness  0
        .var paint_textured_intensity   7

    !charater_gradient ; Len=8
    .raw '.' '-' ':' '+' '%' '$' '&' '#'
    ;    ....----::::++++%%%%$$$$&&&&####