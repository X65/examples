.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "MODE0 test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

; CGIA setup
.define CGIA_PLANES_USED 1
text_offset  = $d000
chgen_offset = $d800
.define text_columns 40
.define text_rows    28
bg_color = 145

.code
        sei
        cld
        ldx #$ff
        txs

        clc
        xce

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

        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #(CGIA_PLANES_USED*CGIA_PLANE_REGS_NO)-1
        mvn 0,0

        store #display_list, CGIA::offset0

        _a8
        ldx #text_columns*text_rows
:       txa
        sta text_offset, x
        dex
        bpl :-

        _ai8
        store #bg_color, CGIA::back_color
        store #$00, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+0
        store #$15, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+1
        store #$35, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+2
        store #$55, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+3
        store #$75, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+4
        store #$95, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+5
        store #$b5, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+6
        store #$d5, CGIA::plane0 + CGIA_BCKGND_REGS::shared_color+7

        ; set bpp manually
        store #%00000000, CGIA::plane0 + CGIA_BCKGND_REGS::flags

        store #%00000001, CGIA::planes

loop:
        bra loop

cgia_planes:
.byte $00,(48-text_columns)/2,7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   chgen_offset
.byte   $70           ; top border
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), %00000000 ; 1bpp
.repeat 7
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), %00100000 ; 2bpp
.repeat 7
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), %01000000 ; 3bpp
.repeat 7
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::flags << 4), %01100000 ; 4bpp
.repeat 7
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list
