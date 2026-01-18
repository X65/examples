.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Font CP test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

; CGIA setup
text_offset  = $d000
chgen_offset = $d800
.define text_columns 40
.define text_rows    21
bg_color = 145
fg_color = 150

.zeropage
src_ptr:    .res 2
dest_ptr:   .res 2

codepage:   .res 2
cp_index:   .res 1

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

        ; setup text plane
        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #CGIA_PLANE_REGS_NO-1
        mvn 0,0
        store #display_list, CGIA::offset0

        ; clear text buffer
        stz text_offset
        ldx #text_offset
        ldy #text_offset+2
        lda #text_columns*text_rows-3
        mvn 0,0

        ; print the ASCII table
        ldy #0
        ldx #0
:       tya
        sta text_offset+((text_columns-16)/2),x
        and #%00001111
        cmp #15
        bne :+
        txa
        clc
        adc #(text_columns - 16)
        tax
:       inx
        iny
        cpy #256
        bne :--

        store #cp_text, src_ptr
        store #text_offset+(18*40), dest_ptr
        jsr str_cpy
        store #prompt_text, src_ptr
        store #text_offset+(20*40), dest_ptr
        jsr str_cpy

        ; extended codes marker
        lda #'-'
        sta text_offset+(8*40)+9
        sta text_offset+(8*40)+10
        sta text_offset+(8*40)+29
        sta text_offset+(8*40)+30

        ; set CP to default
        stz codepage
        jsr load_chargen
        ; initialize next CP to load
        _a8
        stz cp_index

        ; set border color
        store #bg_color, CGIA::back_color

        ; sync to vblank
:       lda CGIA::raster
        bne :-
        ; enable text plane 0
        _ai8
        store #%00000001, CGIA::planes

        ; select keyboard device
        stz HID::d0

loop:
        _a8
        _i16
        ; display code page number
        lda codepage+1
        ldx #(18*40)+11
        jsr write_hex
        lda codepage
        ldx #(18*40)+13
        jsr write_hex
        lda #'h'
        sta text_offset+(18*40)+15

        ; wait for SPACE key press
:       lda HID::d5
        and #$10                ; SPACE id 44 bit - (USB scan code)
        beq :-
        ; wait for key release
:       lda HID::d5
        and #$10
        bne :-
        ; advance code page
        _a16
        _i8
        ldx cp_index
        lda code_pages,x
        sta codepage
        bne :+
        stz cp_index
        bra :++
:       inc cp_index
        inc cp_index
:       jsr load_chargen
        bra loop

code_pages:
        .word 437, 737, 771, 775, 850, 852, 855, 857, 860, 861, 862, 863, 864, 865, 866, 869, 0

cgia_planes:
.byte $00,(48-text_columns)/2,7,$00,$00,$00,$00,$00,bg_color,fg_color,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   chgen_offset

.byte   $70           ; top border

.repeat text_rows
.byte   CGIA_DL_MODE_PALETTE_TEXT
.endrep

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

; load character generator from RIA
.proc load_chargen
        php                     ; save register length
        _a8
        phb
        pla
        sta RIA::stack
        lda #>chgen_offset
        sta RIA::stack
        lda #<chgen_offset
        sta RIA::stack
        lda codepage+1
        sta RIA::stack
        lda codepage
        sta RIA::stack
        lda #RIA_API_GET_CHARGEN
        sta RIA::op
        plp                    ; restore register length
        rts
.endproc

cp_text:
.asciiz "Code Page:"
prompt_text:
.asciiz "Press SPACE to change"

.include "../util/write_hex.inc"
