.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "EXTernal devices test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, __NMI__, 0, 0
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

        clc
        xce                     ; switch to native mode

        _a16
        lda #$FC00              ; load base of EXT I/O area
        sta $00

        _a8
        lda #%10000000
        sta CGIA::int_enable    ; trigger NMI on VBL
forever:
        bra forever             ; do nothing more

__NMI__:
        _i16
        ldy $00                 ; load current pointer
        lda $0,y                ; read byte from memory
        ldx #6
        jsr write_hex           ; write byte as hex

        lda $00                 ; load low byte of pointer address
        ldx #2
        jsr write_hex           ; write low byte as hex
        lda $01                 ; load high byte of pointer address
        ldx #0
        jsr write_hex           ; write high byte as hex
        lda #':'
        sta text_offset+4

        ldx $00
        inx                     ; increment memory pointer
        stx $00
        lda $01                 ; load high byte of pointer
        cmp #$FE
        bne :+
        lda #$FC
        sta $01
:

        sta CGIA::int_status    ; ack interrupts
        rti                     ; return from interrupt

.include "../util/write_hex.inc"

.include "../cgia/cgia_init.inc"
