.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Controller test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

.define text_columns 40
.define text_rows    25
bg_color = 145
fg_color = 150

on_bg_color = bg_color+8
on_fg_color = 7

.define JOY0_RIGHT              5+2 + text_columns*2
.define JOY0_LEFT               5-2 + text_columns*2
.define JOY0_UP                 5   + text_columns*0
.define JOY0_DOWN               5   + text_columns*4
.define JOY0_BUTTON_A           10   + text_columns*1
.define JOY0_BUTTON_B           10+2 + text_columns*1
.define JOY0_BUTTON_X           10   + text_columns*3
.define JOY0_BUTTON_Y           10+2 + text_columns*3

.define JOY1_OFFSET             text_columns*10
.define JOY1_RIGHT              JOY1_OFFSET + JOY0_RIGHT
.define JOY1_LEFT               JOY1_OFFSET + JOY0_LEFT
.define JOY1_UP                 JOY1_OFFSET + JOY0_UP
.define JOY1_DOWN               JOY1_OFFSET + JOY0_DOWN
.define JOY1_BUTTON_A           JOY1_OFFSET + JOY0_BUTTON_A
.define JOY1_BUTTON_B           JOY1_OFFSET + JOY0_BUTTON_B
.define JOY1_BUTTON_X           JOY1_OFFSET + JOY0_BUTTON_X
.define JOY1_BUTTON_Y           JOY1_OFFSET + JOY0_BUTTON_Y

.code
        sei
        cld
        ldx #$ff
        txs

        jsr init_cgia

        lda #$10                ; 0
        sta text_offset
        lda #$11                ; 1
        sta text_offset + JOY1_OFFSET

        lda #$1c                ; ->
        sta text_offset + JOY0_RIGHT
        sta text_offset + JOY1_RIGHT
        lda #$1d                ; <-
        sta text_offset + JOY0_LEFT
        sta text_offset + JOY1_LEFT
        lda #$1e                ; ^
        sta text_offset + JOY0_UP
        sta text_offset + JOY1_UP
        lda #$1f                ; v
        sta text_offset + JOY0_DOWN
        sta text_offset + JOY1_DOWN

        lda #$41                ; A
        sta text_offset + JOY0_BUTTON_A
        sta text_offset + JOY1_BUTTON_A
        lda #$42                ; B
        sta text_offset + JOY0_BUTTON_B
        sta text_offset + JOY1_BUTTON_B
        lda #$58                ; X
        sta text_offset + JOY0_BUTTON_X
        sta text_offset + JOY1_BUTTON_X
        lda #$59                ; Y
        sta text_offset + JOY0_BUTTON_Y
        sta text_offset + JOY1_BUTTON_Y

.macro indicator offset, mask
        txa
        and #mask
        beq :+                  ; if pressed
        lda #bg_color
        sta bkgnd_offset + offset
        lda #fg_color
        sta color_offset + offset
        bra :++
:       lda #on_bg_color
        sta bkgnd_offset + offset
        lda #on_fg_color
        sta color_offset + offset
:
.endmacro

mainloop:
        ldx GPIO::in0
        indicator JOY0_UP,       %00000001
        indicator JOY0_DOWN,     %00000010
        indicator JOY0_LEFT,     %00000100
        indicator JOY0_RIGHT,    %00001000
        indicator JOY0_BUTTON_A, %00100000
        indicator JOY0_BUTTON_B, %10000000
        indicator JOY0_BUTTON_X, %00010000
        indicator JOY0_BUTTON_Y, %01000000

        ldx GPIO::in1
        indicator JOY1_UP,       %00000001
        indicator JOY1_DOWN,     %00000010
        indicator JOY1_LEFT,     %00000100
        indicator JOY1_RIGHT,    %00001000
        indicator JOY1_BUTTON_A, %00100000
        indicator JOY1_BUTTON_B, %10000000
        indicator JOY1_BUTTON_X, %00010000
        indicator JOY1_BUTTON_Y, %01000000

        jmp mainloop


; CGIA setup
text_offset  = $d000
chgen_offset = $d800
color_offset = $e000
bkgnd_offset = $e800

.define CGIA_PLANES_USED 1

init_cgia:
        clc
        xce                     ; switch to native mode

        stz CGIA::planes

        phb
        pla
        sta RIA::stack
        lda #>chgen_offset
        sta RIA::stack
        lda #<chgen_offset
        sta RIA::stack
        lda #RIA_API_GET_CHARGEN
        sta RIA::op

        _a8
        store #bg_color, bkgnd_offset
        store #fg_color, color_offset

        _ai16
        stz CGIA::mode
        ldx #CGIA::mode
        ldy #CGIA::mode+2
        lda #CGIA::plane0-CGIA::mode-2
        mvn 0,0

        stz text_offset
        ldx #text_offset
        ldy #text_offset+2
        lda #text_columns*text_rows-2
        mvn 0,0

        ldx #bkgnd_offset
        ldy #bkgnd_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0

        ldx #color_offset
        ldy #color_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0

        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #(CGIA_PLANES_USED*CGIA_PLANE_REGS_NO)-1
        mvn 0,0

        store #display_list, CGIA::offset0
        _ai8
        store #bg_color, CGIA::back_color

:       bit CGIA::raster
        bne :-
        store #%00000001, CGIA::planes

        sec
        xce                     ; switch to emulation mode

        rts

cgia_planes:
.byte $00,4,7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   color_offset
.word   bkgnd_offset
.word   chgen_offset
.byte   $70, $70, $30
.repeat text_rows
.byte   CGIA_DL_MODE_TEXT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list
