.define CGIA_PLANES_USED 1

cgia_init_text:
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
        stz RIA::stack
        stz RIA::stack
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
.byte $00,(48-text_columns)/2,7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   color_offset
.word   bkgnd_offset
.word   chgen_offset
.byte   $70, $70, $30
.repeat text_rows
.byte   CGIA_DL_MODE_ATTRIBUTE_TEXT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list
