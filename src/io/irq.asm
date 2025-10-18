.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "IRQ test"

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
.define text_rows    3
bg_color = 145
fg_color = 150

.code
        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

        _a8
mainloop:
        lda RIA::irq_status
        ldx #0
        jsr write_binary

        lda RIA::irq_status
        ldx #9
        jsr write_hex

        inc text_offset+text_columns
        jmp mainloop

.include "../util/write_binary.inc"
.include "../util/write_hex.inc"

.include "../cgia/cgia_init.inc"
