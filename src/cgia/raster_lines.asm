.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Raster Lines test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

text_offset  = $d000

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

        _ai16
        ; clear all CGIA registers
        stz CGIA::mode
        ldx #CGIA::mode
        ldy #CGIA::mode+2
        lda #.sizeof(CGIA)-3
        mvn 0,0

        ; clear memory buffer
        stz text_offset
        ldx #text_offset
        ldy #text_offset+2
        lda #2048-3
        mvn 0,0

        ; setup plane
        store #display_list, CGIA::offset0

        ; sync to vblank
:       lda CGIA::raster
        bne :-
        ; enable plane 0
        _ai8
        store #%00000001, CGIA::planes

loop:
        bra loop

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   text_offset

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4), $07
.byte   CGIA_DL_MODE_PALETTE_TEXT
.repeat 119
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4), $00
.byte   CGIA_DL_MODE_PALETTE_TEXT
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4), $04
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4), $07
.byte   CGIA_DL_MODE_PALETTE_TEXT

.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list
