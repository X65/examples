
.p816       ; 65816 processor

.include "../ria.asm"
.include "../cgia.asm"
.include "../macros.asm"

.segment "INFO"
        .byte "speed test"

.import __MAIN_START__
.segment "VECTORS"
        .word 0, 0, 0, 0, 0, __NMI__, 0, 0
        .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

text_columns = 40
text_rows    = 8
text_offset  = $1000
chgen_offset = $1800
color_offset = $2000
bkgnd_offset = $2800

bg_color = 145
fg_color = 150

.code
        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

        clc
        xce                     ; switch to native mode

        .a8
        .i8
        ; initialize counters
        stz $00
        stz $01
        stz $02
        stz $03
        store #60, $05

        ; trigger NMI on VBL
        store #CGIA_REG_INT_FLAG_VBI, CGIA::int_enable

forever:
        inc $00
        bne forever
        inc $01
        bne forever
        inc $02
        bne forever
        inc $03
        bra forever

.macro print_hex num, dest
        lda num
        ldx dest
        jsr write_hex
.endmacro

__NMI__:
        store #fg_color, CGIA::back_color

        dec $05
        beq :+
@exit_nmi:
        store #bg_color, CGIA::back_color
        stz CGIA::int_status    ; ack interrupts
        rti
:
        store #60, $05

        print_hex $00, #6
        print_hex $01, #4
        print_hex $02, #2
        print_hex $03, #0

        stz $00
        stz $01
        stz $02
        stz $03

        bra @exit_nmi


.include "../util/write_hex.inc"

.include "../cgia/cgia_init.inc"
