jmp !prep

; PERIPHERAL CONSTANTS
    .const RAND_POS       0x8010
    .const RAND_BITS      0x8011
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


; KEYBINDS
    .const KB_UP                    'w'
    .const KB_LEFT                  'a'
    .const KB_DOWN                  's'
    .const KB_RIGHT                 'd'
    .const KB_BRUSH_SINGLE          'j'
    .const KB_BRUSH_ERASE           'J'
    .const KB_BRUSH_UP              'h'
    .const KB_BRUSH_PEN             'k'
    .const KB_BRUSH_RADIAL          'l'
    .const KB_BRUSH_FILL            ';'
    .const KB_PAINT_MODE_UNI        'g'
    .const KB_PAINT_MODE_TEX        'b'
    .const KB_PAINT_BG_COL          'y'
    .const KB_PAINT_FG_COL          'u'
    .const KB_PAINT_TEX_INTEN_UP    'i'
    .const KB_PAINT_TEX_INTEN_DN    'I'
    .const KB_PAINT_TEX_RAND_UP     'o'
    .const KB_PAINT_TEX_RAND_DN     'O'
    .const KB_PAINT_RAD_RADI        'm'


; ARRAYS AND WHATNOT
    .var move_callback

    ; Brush-mode settings:
        .var brush_radial_radius    3
        .var brush_fill_start_x     0
        .var brush_fill_start_y     0

    .var paint_callback

    ; Paint-mode settings:
        .var paint_fg_col   WHITE
        .var paint_bg_col   BLACK
        .var paint_uniform_char         '#'
        .var paint_textured_randomness  0
        .var paint_textured_true_rand   0
        .var paint_textured_intensity   7

    !charater_gradient ; Len=8
    .raw '.' '-' ':' '+' '%' '$' '&' '#' 'E'
    ;    ....----::::++++%%%%$$$$&&&&#### ERROR
    .const MAX_INTENSITY 7


!prep
    cal !set_colors
    set rA, !mcb_up
    str [move_callback], rA     ; Use "do-nothing" as the default movement callback (no painting)
    set rA, !pcb_uniform
    str [paint_callback], rA    ; Use "uniform-pain" as the default paint type
    
    str [CLEAR_SCREEN], rZ
    
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

            ; Not actually a mode, just set the space character
            cmp rA, KB_BRUSH_ERASE
            jne !not_brush_erase
                set rA, ' '
                str [SET_CHAR], rA
                jmp !keybinds_done
            !not_brush_erase

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
        

        ; Paint mode
            cmp rA, KB_PAINT_MODE_UNI
            jne !not_paint_mode_uni
                set rA, !pcb_uniform
                str [paint_callback], rA
                jmp !keybinds_done
            !not_paint_mode_uni

            cmp rA, KB_PAINT_MODE_TEX
            jne !not_paint_mode_tex
                set rA, !pcb_textured
                str [paint_callback], rA
                jmp !keybinds_done
            !not_paint_mode_tex



        ; Paint settings
            cmp rA, KB_PAINT_BG_COL
            jne !not_paint_bg_color
                lod rA, [paint_bg_col]
                inc rA
                and rA, 0x7
                str [paint_bg_col], rA
                cal !set_colors
                jmp !keybinds_done
            !not_paint_bg_color

            cmp rA, KB_PAINT_FG_COL
            jne !not_paint_fg_color
                lod rA, [paint_fg_col]
                inc rA
                and rA, 0xF
                str [paint_fg_col], rA
                cal !set_colors
                jmp !keybinds_done
            !not_paint_fg_color

            cmp rA, KB_PAINT_TEX_INTEN_UP
            jne !not_paint_tex_inten_up
                lod rA, [paint_textured_intensity]
                cmp rA, MAX_INTENSITY
                jg !paint_tex_inten_too_high

                ; if at max, ignore
                je !keybinds_done
            
                ; if not at max, increase intensity
                    inc rA
                    str [paint_textured_intensity], rA
                    cal !fix_random
                    jmp !keybinds_done

                ; if above max, set to max
                !paint_tex_inten_too_high
                    set rA, MAX_INTENSITY
                    str [paint_textured_intensity], rA
                    cal !fix_random
                    jmp !keybinds_done
            !not_paint_tex_inten_up

            cmp rA, KB_PAINT_TEX_INTEN_DN
            jne !not_paint_tex_inten_dn
                lod rA, [paint_textured_intensity]
                cmp rA, rZ
                jl !paint_tex_inten_too_low

                ; if at min, ignore
                je !keybinds_done
            
                ; if not at min, decrease intensity
                    dec rA
                    str [paint_textured_intensity], rA
                    cal !fix_random
                    jmp !keybinds_done

                ; if below min, set to min
                !paint_tex_inten_too_low
                    str [paint_textured_intensity], rZ
                    cal !fix_random
                    jmp !keybinds_done
            !not_paint_tex_inten_dn

            cmp rA, KB_PAINT_TEX_RAND_UP
            jne !not_paint_tex_rand_up
                lod rA, [paint_textured_randomness]
                cmp rA, MAX_INTENSITY
                jg !paint_tex_rand_too_high

                ; if at max, ignore
                je !keybinds_done
            
                ; if not at max, increase randomness
                    inc rA
                    str [paint_textured_randomness], rA
                    cal !fix_random
                    jmp !keybinds_done

                ; if above max, set to max
                !paint_tex_rand_too_high
                    set rA, MAX_INTENSITY
                    str [paint_textured_randomness], rA
                    cal !fix_random
                    jmp !keybinds_done
            !not_paint_tex_rand_up

            cmp rA, KB_PAINT_TEX_RAND_DN
            jne !not_paint_tex_rand_dn
                lod rA, [paint_textured_randomness]
                cmp rA, rZ
                jl !paint_tex_rand_too_low

                ; if at min, ignore
                je !keybinds_done
            
                ; if not at min, decrease randomness
                    dec rA
                    str [paint_textured_randomness], rA
                    cal !fix_random
                    jmp !keybinds_done

                ; if below min, set to min
                !paint_tex_rand_too_low
                    str [paint_textured_randomness], rZ
                    cal !fix_random
                    jmp !keybinds_done
            !not_paint_tex_rand_dn

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


; Brush-up, meaning do nothing
!mcb_up
    ret


; Brush=Pen, so draw a single character
!mcb_pen
    lod rA, [paint_callback]
    cal rA
    ret


; Paint is uniform, so just draw the specified character
!pcb_uniform
    lod rA, [paint_uniform_char]
    str [SET_CHAR], rA
    ret


; Paint is textured, so take random characters using intensity
!pcb_textured
    lod rA, [paint_textured_intensity]
    lod rB, [paint_textured_true_rand]
    
    cmp rB, rZ
    jle !skip_rand
        ; Add random value to intensity
        inc rB
        lod rC, [RAND_POS]
        mod rC, rB
        add rA, rC
    !skip_rand

    set rC, !charater_gradient
    add rC, rA
    lod rC, [rC]
    str [SET_CHAR], rC
    ret


!fix_random
    lod rA, [paint_textured_intensity]
    lod rB, [paint_textured_randomness]
    set rC, MAX_INTENSITY
    sub rC, rA
    cmp rB, rC
    jle !random_is_fine
        set rB, rC
    !random_is_fine
    str [paint_textured_true_rand], rB
    ret