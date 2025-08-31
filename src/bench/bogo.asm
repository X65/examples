
.p816       ; 65816 processor

.include "../ria.asm"
.include "../cgia.asm"
.include "../macros.asm"

.segment "INFO"
        .byte "speed test"

.segment "VECTORS"
        .word 0, 0, 0, 0, 0, nmi, 0, 0
        .word 0, 0, 0, 0, 0, 0, reset, 0

text_columns = 40
text_rows    = 8
text_offset  = $1000
chgen_offset = $1800
color_offset = $2000
bkgnd_offset = $2800

bg_color = 145
fg_color = 150

.define CGIA_PLANES_USED 1

.code
reset:
        sei                     ; disable IRQ

        ldx #$FF
        txs                     ; initialize stack pointer

        clc
        xce                     ; switch to native mode

        ; initialize counters
        stz $00
        stz $01
        stz $02
        stz $03
        store #60, $05

        ; disable all planes, so CGIA does not go haywire during reconfiguration
        stz CGIA::planes

        ; fetch character generator from RIA firmware
        phb
        pla
        sta RIA::stack          ; bank address
        lda #>chgen_offset      ; high byte
        sta RIA::stack
        lda #<chgen_offset      ; low byte
        sta RIA::stack
        lda #RIA_API_GET_CHARGEN
        sta RIA::op

        _i16

        ; clear CGIA registers
        stz CGIA::mode
        ldx CGIA::mode
        ldy CGIA::mode+1
        lda CGIA::plane0-1
        mvn 0,0
        ; set border/background color
        store #bg_color, CGIA::back_color
        store #bg_color, bkgnd_offset
        store #fg_color, color_offset
        ; clear text
        stz text_offset
        _a16
        ldx #text_offset
        ldy #text_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0
        ; fill background color
        ldx #bkgnd_offset
        ldy #bkgnd_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0
        ; fill foreground color
        ldx #color_offset
        ldy #color_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0

        ; now set plane registers
        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #(CGIA_PLANES_USED*CGIA_PLANE_REGS_NO)-1
        mvn 0,0

        ; configure plane display list offset
        store #display_list, CGIA::offset0

        _a8

        ; trigger NMI on VBL
        store #CGIA_REG_INT_FLAG_VBI, CGIA::int_enable

        ; --- activate background plane
        store #%00000001, CGIA::planes

        _a8
forever:
        inc $00
        bne forever
        inc $01
        bne forever
        inc $02
        bne forever
        inc $03
        bra forever

.macro  print_hex num, dest
        lda num
        and #$0F
        cmp #10
        bmi :+
        clc
        adc #'A'-10
        bra :++
:       clc
        adc #'0'
:       sta dest+1

        lda num
        lsrx 4
        cmp #10
        bmi :+
        clc
        adc #'A'-10
        bra :++
:       clc
        adc #'0'
:       sta dest
.endmacro

nmi:
        store #fg_color, CGIA::back_color

        dec $05
        beq :+
@exit_nmi:
        store #bg_color, CGIA::back_color
        stz CGIA::int_status    ; ack interrupts
        rti
:
        store #60, $05

        print_hex $00, text_offset+6
        print_hex $01, text_offset+4
        print_hex $02, text_offset+2
        print_hex $03, text_offset+0

        stz $00
        stz $01
        stz $02
        stz $03

        jmp @exit_nmi


cgia_planes:
.byte $00,4,7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   color_offset
.word   bkgnd_offset
.word   chgen_offset
.byte   $70, $70, $30           ; 2x 8 + 1x 4 of empty background lines
.repeat text_rows
.byte   CGIA_DL_MODE_TEXT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT ; JMP to begin of DL and wait for Vertical BLank
.word   display_list
