.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Bitmap Modes test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

; CGIA setup
text_offset  = $d000
color_offset = $e000
bkgnd_offset = $e800
.define text_columns 40
.define TEST_PATTERN_LENGTH 10*8

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

        ; setup background plane
        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #CGIA_PLANE_REGS_NO-1
        mvn 0,0
        store #display_list, CGIA::offset0

        _a8
        ldy #TEST_PATTERN_LENGTH-1
:       lda test_pattern,y
        sta text_offset,y
        dey
        bpl :-

        _ai16
        ldx #text_offset
        ldy #text_offset+TEST_PATTERN_LENGTH
        lda #180*3*8-TEST_PATTERN_LENGTH-1
        mvn 0,0

        _a8
        ldy #0
        ldx #40+20+80+40 - 1
:       tya
        sta color_offset, y
        txa
        sta bkgnd_offset, y
        iny
        dex
        bpl :-

        ; sync to vblank
:       lda CGIA::raster
        bne :-
        ; enable background plane 0
        _ai8
        store #%00000001, CGIA::planes

loop:
        bra loop

cgia_planes:
.byte $00,(48-text_columns)/2,0,$00,$00,$00,$00,$00,$00,$16,$36,$56,$76,$96,$b6,$d6

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN
.word   text_offset
.word   color_offset
.word   bkgnd_offset

.byte   $70           ; top border

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_1BPP
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 0
.byte   CGIA_DL_MODE_PALETTE_BITMAP
.byte   $00
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 1
.byte   CGIA_DL_MODE_PALETTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   $10

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_2BPP
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 0
.byte   CGIA_DL_MODE_PALETTE_BITMAP
.byte   $00
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 1
.byte   CGIA_DL_MODE_PALETTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   $10

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_3BPP
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 0
.byte   CGIA_DL_MODE_PALETTE_BITMAP
.byte   $00
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 1
.byte   CGIA_DL_MODE_PALETTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   $10

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), PLANE_BITS_4BPP
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 0
.byte   CGIA_DL_MODE_PALETTE_BITMAP
.byte   $00
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 1
.byte   CGIA_DL_MODE_PALETTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT

.byte   $70           ; some space

.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::row_height << 4), 7
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), $00
.byte   CGIA_DL_MODE_ATTRIBUTE_BITMAP
.byte   CGIA_DL_MODE_ATTRIBUTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT
.byte   CGIA_DL_MODE_ATTRIBUTE_BITMAP | CGIA_DL_MULTICOLOR_BIT
.byte   CGIA_DL_MODE_ATTRIBUTE_BITMAP | CGIA_DL_DOUBLE_WIDTH_BIT | CGIA_DL_MULTICOLOR_BIT

.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list

test_pattern:
.byte   %00001111
.byte   %00001111
.byte   %00001111
.byte   %00001111
.byte   %11110000
.byte   %11110000
.byte   %11110000
.byte   %11110000

.byte   %00000000
.byte   %11111111
.byte   %00000000
.byte   %11111111
.byte   %00000000
.byte   %11111111
.byte   %00000000
.byte   %11111111

.byte   %01010101
.byte   %01010101
.byte   %01010101
.byte   %01010101
.byte   %01010101
.byte   %01010101
.byte   %01010101
.byte   %01010101

.byte   %10101010
.byte   %10101010
.byte   %10101010
.byte   %10101010
.byte   %10101010
.byte   %10101010
.byte   %10101010
.byte   %10101010

.byte   %01010101
.byte   %10101010
.byte   %01010101
.byte   %10101010
.byte   %01010101
.byte   %10101010
.byte   %01010101
.byte   %10101010

.byte   %10101010
.byte   %01010101
.byte   %10101010
.byte   %01010101
.byte   %10101010
.byte   %01010101
.byte   %10101010
.byte   %01010101

.byte   %11111010
.byte   %11111010
.byte   %11111010
.byte   %11111010
.byte   %01010000
.byte   %01010000
.byte   %01010000
.byte   %01010000

.byte   %00000000
.byte   %00000000
.byte   %01010101
.byte   %01010101
.byte   %10101010
.byte   %10101010
.byte   %11111111
.byte   %11111111

.byte   %00011011
.byte   %00011011
.byte   %00011011
.byte   %00011011
.byte   %00011011
.byte   %00011011
.byte   %00011011
.byte   %00011011

.byte   %11000110
.byte   %11000110
.byte   %11000110
.byte   %11000110
.byte   %11000110
.byte   %11000110
.byte   %11000110
.byte   %11000110
