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

!main
    ;;; generate rA, a random printable character
    lod rA, [RAND]
    mod rA, rE
    add rA, '!'

    ;;; pick a random foreground color
    lod rB, [RAND]
    mod rB, 16
    str [SET_FG_COLOR], rB

    ;;; pick a random background color
    lod rB, [RAND]
    mod rB, 16
    str [SET_BG_COLOR], rB

    ;;; pick a random cursor X
    lod rB, [RAND]
    str [SET_X], rB

    ;;; pick a random cursor Y
    lod rB, [RAND]
    str [SET_Y], rB

    str [PRINT_CHAR], rA

    jmp !main
 