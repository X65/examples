.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Text Modes test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

; CGIA setup
text_offset  = $d000
chgen_offset = $d800
color_offset = $e000
bkgnd_offset = $e800
.define text_columns 40

.zeropage
src_ptr:    .res 2
dest_ptr:   .res 2

.code
.a8
.i8
        ; stop interrupts handling
        sei
        ; clear decimal mode
        cld
        ; stack pointer
        ldx #$ff
        txs

        ; go native mode
        clc
        xce

        ; stop all planes
        stz CGIA::planes

        ; load character generator from RIA
        phb
        pla
        sta RIA::stack
        lda #>chgen_offset
        sta RIA::stack
        lda #<chgen_offset
        sta RIA::stack
        lda #RIA_API_GET_CHARGEN
        sta RIA::op

        _ai16
        ; clear all CGIA registers
        stz CGIA::mode
        ldx #CGIA::mode
        ldy #CGIA::mode+2
        lda #.sizeof(CGIA)-3
        mvn 0,0

        ; setup text plane
        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #CGIA_PLANE_REGS_NO-1
        mvn 0,0
        store #display_list, CGIA::offset0

        store #mode0_text, src_ptr
        store #text_offset, dest_ptr
        jsr str_cpy
        store #mode0_dw_text, src_ptr
        store #text_offset+40, dest_ptr
        jsr str_cpy
        store #mode0_mc_text, src_ptr
        store #text_offset+40+20, dest_ptr
        jsr str_cpy
        store #mode0_dw_mc_text, src_ptr
        store #text_offset+40+20+80, dest_ptr
        jsr str_cpy

        store #mode0_text, src_ptr
        store #text_offset+180, dest_ptr
        jsr str_cpy
        store #mode0_dw_text, src_ptr
        store #text_offset+180+40, dest_ptr
        jsr str_cpy
        store #mode0_mc_text, src_ptr
        store #text_offset+180+40+20, dest_ptr
        jsr str_cpy
        store #mode0_dw_mc_text, src_ptr
        store #text_offset+180+40+20+80, dest_ptr
        jsr str_cpy

        ; sync to vblank
:       lda CGIA::raster
        bne :-
        ; enable text plane 0
        _ai8
        store #%00000001, CGIA::planes

loop:
        bra loop

cgia_planes:
.byte $00,(48-text_columns)/2,7,$00,$00,$00,$00,$00,$00,$16,$36,$56,$76,$96,$b6,$d6

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   color_offset
.word   bkgnd_offset
.word   chgen_offset

.byte   $70           ; top border

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_1BPP
.byte   CGIA_DL_MODE_PALETTE_TEXT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_MULTICOLOR_BIT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_DOUBLE_WIDTH_BIT | CGIA_DL_MULTICOLOR_BIT

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_4BPP
.byte   CGIA_DL_MODE_PALETTE_TEXT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_MULTICOLOR_BIT
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_DOUBLE_WIDTH_BIT | CGIA_DL_MULTICOLOR_BIT

.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list

.a16
.i16

.proc str_cpy
        _a8
        ldy #0
:       lda (src_ptr),y
        beq :+
        sta (dest_ptr),y
        iny
        bra :-
:       _a16
        rts
.endproc

mode0_text:
.byte $10,$1C, "012345ABCDEFGHijklmnopqrstuvwxyz", 248, 249, 252, 253, 254, 255, 0
mode0_dw_text:
.byte $10, " DOUBLE WIDTH ", 248, 252, 253, 254, 255, 0
mode0_mc_text:
.byte "0 MULTICOLOR: ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz", 252, 253, 254, 255, 0
mode0_dw_mc_text:
.byte "0 DW MC: ABCDEFGHijklmnopqrSTUVWXYZ", 248, 252, 253, 254, 255, 0
