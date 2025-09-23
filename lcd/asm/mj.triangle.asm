jmp !main

; TeenyAT Constants
.const PORT_A_DIR   0x8000
.const PORT_B_DIR   0x8001
.const PORT_A       0x8002
.const PORT_B       0x8003
.const RAND         0x8010
.const RAND_BITS    0x8011

; LCD Peripherals
.const LIVESCREEN 0x9000
.const UPDATESCREEN 0xA000
.const X1 0xD000
.const Y1 0xD001
.const X2 0xD002
.const Y2 0xD003
.const STROKE 0xD010
.const FILL 0xD011
.const DRAWFILL 0xD012
.const DRAWSTROKE 0xD013
.const UPDATE 0xE000
.const RECT 0xE010
.const LINE 0xE011
.const POINT 0xE012
.const MOUSEX 0xFFFC
.const MOUSEY 0xFFFD
.const TERM 0xFFFF
.const KEY 0xFFFE

.const DATABASE_FABULOUS 2689  ; the default screen color

; ### DATA STRUCTURES ###

    ; Current model structure
    ;   [0] = Verts begin (location of first vertex)
    ;   [1] = Verts end (earliest location past last vertex)
    ;   [2] = Faces begin (location of first face)
    ;   [3] = Faces end (earliest location past last face)
    ;   [4] = Barycentric data address (just a single barycentric struct)
    .const MM_STRIDE    4
        .const MM_V_BEGIN   0
        .const MM_V_END     1
        .const MM_F_BEGIN   2
        .const MM_F_END     3

    ; Current vert structure:
    ;   [0] = X | 8 bit unsigned int stored in 16 bits
    ;   [1] = Y
    ;   Size = 2 words
    .const VERT_STRIDE  2
        .const V_X          0
        .const V_Y          1

    ; Current face structure:
    ;   [0,1,2] = A, B, C respectively
    ;   Size = 3 words
    .const FACE_STRIDE  3
        .const F_A          0
        .const F_B          1
        .const F_C          2

    ; Line dat structure
    ;   [0] = dx  | 8 bit signed int stored in 16 bits
    ;   [1] = dy  | ^
    ;   [2] = c   | 16 bit signed integer
    ;   [4] = div | 16 bit signed integer (cull if negative), used to rescale the equation
    ;       Prop: Rescale using division by sum of all barycentric values instead
    ;             of having a divisor in the line eq
    ;   Size = 5 words
    .const LINE_STRIDE  4
        .const L_DX         0
        .const L_DY         1
        .const L_C          2
        .const L_DIV        3

    ;
    ; Current barycentric data structure:
    ;   3 Vertices (min/max corners, avg)
    ;   3 Lines
    ; Size = 18 words
    .const BARY_STRIDE  18
    !barycentric_corners
        .var B_V_MIN_X   ; Lower corner of bounding box
        .var B_V_MIN_Y
        .var B_V_MAX_X   ; Upper corner of bounding box
        .var B_V_MAX_Y
        ; These constants are here so that we can use the lone "corners" address
        ; to grab all vertex data of cornes, no need to load multiple addresses
        .const OFF_B_V_MIN_X    0   ; Lower corner of bounding box
        .const OFF_B_V_MIN_Y    1
        .const OFF_B_V_MAX_X    2   ; Upper corner of bounding box
        .const OFF_B_V_MAX_Y    3
    !barycentric_center
        .var B_V_CNT_X   ; Center of bounding box (might not need this, could just add above two and bitshift)
        .var B_V_CNT_Y
    !barycentric_line_AB
        .var B_L_AB_DX   ; Line AB
        .var B_L_AB_DY
        .var B_L_AB_C
        .var B_L_AB_DIV
    !barycentric_line_BC
        .var B_L_BC_DX   ; Line BC
        .var B_L_BC_DY
        .var B_L_BC_C
        .var B_L_BC_DIV
    !barycentric_line_CB
        .var B_L_CA_DX   ; Line CA
        .var B_L_CA_DY
        .var B_L_CA_C
        .var B_L_CA_DIV
        

; ### END DATA STRUCTURES ###



; Stores a model containing a single triangle
; Not intended to be called; this is where the program starts, i.e. a preprocessing step
!main

    set rE, !END

    set rD, rE       ; Get address after barycentric
    add rD, MM_STRIDE


    ; BEGIN: VERTEX ARRAY
    
        str [rE + MM_V_BEGIN], rD   ; STORE IN META: VERT_BEGIN
        
        set rA,  18          ; Set X
        set rB,  52         ; Set Y
        str [rD + V_X], rA  ; Store X
        str [rD + V_Y], rB  ; Store Y
        add rD, VERT_STRIDE ; Increment to next vertex
        
        set rA,   8         ; Set X
        set rB,  13         ; Set Y
        str [rD + V_X], rA  ; Store X
        str [rD + V_Y], rB  ; Store Y
        add rD, VERT_STRIDE ; Increment to next vertex
        
        set rA,  39         ; Set X
        set rB,  24         ; Set Y
        str [rD + V_X], rA  ; Store X
        str [rD + V_Y], rB  ; Store Y
        add rD, VERT_STRIDE ; Increment to next vertex
        
        set rA,  55         ; Set X
        set rB,  28         ; Set Y
        str [rD + V_X], rA  ; Store X
        str [rD + V_Y], rB  ; Store Y
        add rD, VERT_STRIDE ; Increment to next vertex
        
        set rA,  44         ; Set X
        set rB,  60         ; Set Y
        str [rD + V_X], rA  ; Store X
        str [rD + V_Y], rB  ; Store Y
        add rD, VERT_STRIDE ; Increment to next vertex

        str [rE + MM_V_END], rD   ; STORE IN META: VERT_END
    
    ; #END#: VERTEX ARRAY


    ; BEGIN: FACE ARRAY
    
        ; rD is now after vertices
        str [rE + MM_F_BEGIN], rD   ; STORE IN META: FACE_BEGIN

        set rA,  0          ; Set index A
        set rB,  1          ; Set index B
        set rC,  2          ; Set index C
        str [rD + F_A], rA  ; Store index A
        str [rD + F_B], rB  ; Store index B
        str [rD + F_C], rC  ; Store index C
        add rD, FACE_STRIDE ; Increment to next face

        set rA,  2          ; Set index A
        set rB,  3          ; Set index B
        set rC,  4          ; Set index C
        str [rD + F_A], rA  ; Store index A
        str [rD + F_B], rB  ; Store index B
        str [rD + F_C], rC  ; Store index C
        add rD, FACE_STRIDE ; Increment to next face

        str [rE + MM_F_END], rD   ; STORE IN META: FACE_END
    
    ; #END#: FACE ARRAY

    ; Clear all registers
        set rA, rZ
        set rB, rZ
        set rC, rZ
        set rD, rZ
        set rE, rZ

    set rC, rZ
    str [DRAWSTROKE], rZ

    jmp !loop


; Creates a line equation from two points
; Parameters:
;   B.y
;   B.x
;   A.y
;   A.x
;   Memory address to write line equation to
!makeline
    ; Placeholder
    ret


; Create a single barycentric data object
; Parameters:
;   Memory address of vertices
;   Memory address of face to contruct barycentric from
;   [Mut] Memory address to store barycentric in
;       If the triangle is culled, this address is left unchanged.
;       If the triangle is kept, it increments by BARY_STRIDE
!makebary

    lod rE, [SP + 2]    ; rE = Vertices
    lod rD, [SP + 3]    ; rD = Face (gets overwritten at some point, remember to reload from stack)

    lod rC, [rD + F_A]  ; Load first index of face
    mpy rC, VERT_STRIDE ; Get location of vertex relative to vertex array
    add rC, rE          ; Get absolute location of vertex
    lod rA, [rC + V_X]  ; Load X into rA
    lod rB, [rC + V_Y]  ; Load Y into rB
    psh rA              ; Push vertex to stack
    psh rB

    lod rC, [rD + F_B]  ; Load second index of face
    mpy rC, VERT_STRIDE ; Get location of vertex relative to vertex array
    add rC, rE          ; Get absolute location of vertex
    lod rA, [rC + V_X]  ; Load X into rA
    lod rB, [rC + V_Y]  ; Load Y into rB
    psh rA              ; Push vertex to stack
    psh rB

    lod rC, [rD + F_C]  ; Load third index of face
    mpy rC, VERT_STRIDE ; Get location of vertex relative to vertex array
    add rC, rE          ; Get absolute location of vertex
    lod rD, [rC + V_Y]  ; Load Y into rD ; Yes, these two instructions are swapped from the other two loads
    lod rC, [rC + V_X]  ; Load X into rC
    psh rC              ; Push vertex to stack
    psh rD

    ; Vertices are now loaded in stack like:
        ; Top
        ; C.y
        ; C.x
        ; ...
        ; A.x
    ; There are almost certainly more optimal ways to do this,
    ; but this is probably all gooing to be redone anyways.
    ; Also, B.x/B.y are already in rA/rB, C.x/C.y in rC/rD
    ; Store mins in rA/rB, store maxes in rC/rD, use rE for temp values
    
    cmp rA, rC          ; Compare X's, swap if need be
    jle !mb_BX_min
        set rE, rA
        set rA, rC
        set rC, rE
    !mb_BX_min
    
    cmp rB, rD          ; Compare Y's, swap if need be
    jle !mb_BY_min
        set rE, rB
        set rB, rD
        set rD, rE
    !mb_BY_min


    lod rE, [SP + 6]    ; Load A.x into rE
    cmp rE, rA          ; Compare to min_x
    jge !mb_AX_not_min  ; Don't set new min if >= old min
        set rA, rE
        jmp !mb_AX_not_max ; The min can't be greater than the max, so skip max compare
    !mb_AX_not_min

    cmp rE, rC          ; Compare to max_x
    jle !mb_AX_not_max  ; Don't set new max if <= old max
        set rC, rE
    !mb_AX_not_max


    lod rE, [SP + 5]    ; Load A.y into rE
    cmp rE, rB          ; Compare to min_y
    jge !mb_AY_not_min  ; Don't set new min if >= old min
        set rB, rE
        jmp !mb_AY_not_max ; The min can't be greater than the max, so skip max compare
    !mb_AY_not_min

    cmp rE, rD          ; Compare to max_y
    jle !mb_AY_not_max  ; Don't set new max if <= old max
        set rD, rE
    !mb_AY_not_max


    set rE, !barycentric_corners

    str [rE + OFF_B_V_MIN_X], rA    ; Store min_x
    str [rE + OFF_B_V_MIN_Y], rB    ; Store min_y
    str [rE + OFF_B_V_MAX_X], rC    ; Store max_x
    str [rE + OFF_B_V_MAX_Y], rD    ; Store max_y

    add rA, rC
    add rB, rD
    shr rA, 1
    shr rB, 1
    set rE, !barycentric_center
    str [rE + V_X], rA    ; Store center_x
    str [rE + V_Y], rB    ; Store center_y

    ; Compute line equations...

    add SP, 6       ; "Pop" the 3 vertices we added earlier

    ret




; Draws to the screen using barycentric data
; Uses registers rD, rE
; Eventually should also look at a depth map of some kind, 
;  but for now just overwrites the given pixels
; Parameters:
;   Memory address of barycentric object to read from
; For now, just draws the bounding box, not a triangle
!drawbary
    set rE, !barycentric_corners

    lod rD, [rE + OFF_B_V_MIN_X]    ; Load min_x of bounding box
    str [X1], rD

    lod rD, [rE + OFF_B_V_MIN_Y]    ; Load min_y of bounding box
    str [Y1], rD

    lod rD, [rE + OFF_B_V_MAX_X]    ; Load max_x of bounding box
    str [X2], rD

    lod rD, [rE + OFF_B_V_MAX_Y]    ; Load max_x of bounding box
    str [Y2], rD

    lod rD, [RAND_BITS]         ; Get random color
    str [FILL], rD

    str [RECT], rZ              ; Draw to screen

    ret


; Renders all objects of a model to the screen
; Does not clear/update screen
; Uses all registers
; Parameters:
;   Memory address of model metadata
!render
    
    lod rE, [SP + 2]            ; Model addr
    lod rB, [rE + MM_F_BEGIN]   ; Face addr
    lod rC, [rE + MM_V_BEGIN]   ; Vert addr
    lod rD, [rE + MM_F_END]     ; Face end addr

    !r_cal_makebary

        psh rD ; Push face end (not a parameter of !makebary)

        psh rB ; Push faces
        psh rC ; Push vertices
        cal !makebary
        pop rC ; Grab vertices
        pop rB ; Grab faces

        pop rD ; Grab face end


        psh rD ; Save face end address
        cal !drawbary
        pop rD ; Grab face end address

        ; Check if more faces. If more, continue looping, else break
        add rB, FACE_STRIDE     ; Increment to next face
        cmp rB, rD              ; Compare face address and end address
        jl  !r_cal_makebary     ; Loop back if face_addr < face_end_addr
    
    ; #END#: r_cal_makebary
    
    ret


; Uses rA
!clearscreen
    set rA, DATABASE_FABULOUS
    str [FILL], rA

    str [X1], rZ
    str [Y1], rZ
    set rA, 63
    str [X2], rA
    str [Y2], rA
    str [RECT], rZ
    ret


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



!loop
    cal !clearscreen

    str [TERM], rC
    psh rC ; Save color

    set rA, !END ; Set rA to model data location and push
    psh rA
    cal !render
    pop rA

    pop rC ; Get color back


    str [UPDATE], rZ     ; swap the display buffers
    add rC, 0x1          ; increase color value

    set rA, 300
    cal !delay_ms

    jmp !loop



!ERROR
    str [FILL], rZ
    str [X1], rZ
    str [Y1], rZ
    set rB, 63
    str [X2], rB
    str [Y2], rB
    str [RECT], rZ
    str [UPDATE], rZ      ; swap the display buffers
    set rC, 50

    set rE, !ERR_STR

!ERR_LOOP
    set rA, rC
    cal !delay_ms
    lod rB, [rE]
    cmp rB, rZ
    je !END

    str [TERM], rB
    inc rE
    jmp !ERR_LOOP
!ERR_STR
    .raw 'E' 'R' 'R' 'O' 'R' 0

!END