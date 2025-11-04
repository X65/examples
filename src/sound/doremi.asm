.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.macpack generic

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
.define text_columns 48
.define text_rows    10
bg_color = 145
fg_color = 150

SD1_base = $FEC0
SD1_registers = (4*16)

note_idx = $00
note_hi = $01
note_lo = $02

.code
        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

        clc
        xce                     ; switch to native mode

        _ai8

        ; wait until SD-1 startup
        jsr sleep_sec

        ; prepare SD-1 header
        ldx #0
:       lda sd1_header,x
        bze :+
        sta text_offset+text_columns*3,x
        inx
        bra :-
:
        store #$10, text_offset+text_columns*4
        store #$11, text_offset+text_columns*5
        store #$12, text_offset+text_columns*6
        store #$13, text_offset+text_columns*7

        store #'S', text_offset+text_columns*2+0
        store #'D', text_offset+text_columns*2+1
        store #'-', text_offset+text_columns*2+2
        store #'1', text_offset+text_columns*2+3
        store #':', text_offset+text_columns*2+4


        store #':', text_offset+2
        store #',', text_offset+6

        jsr aud_fm_configure
        jsr aud_fm_set_tone
        jsr aud_fm_set_ch

        stz note_idx

mainloop:
        lda note_idx
        ldx #0
        jsr write_hex

        ldy note_idx
        lda doremi_fm,y
        sta note_hi
        inc note_idx
        ldx #4
        jsr write_hex

        ldy note_idx
        lda doremi_fm,y
        sta note_lo
        inc note_idx
        ldx #7
        jsr write_hex

        jsr fm_keyon

        lda note_idx
        cmp #$0A
        bne :+
        stz note_idx
:

; dump SD-1 registers
        _i16
.repeat SD1_registers, I
        lda SD1_base+I
        ldx #text_columns*4+1 + I*3
        jsr write_hex
.endrep
        _i8

        jsr sleep_sec

        jmp mainloop

sleep_sec:
        ; wait for a second (60 frames)
        ldx #60
:       lda CGIA::raster
        bnz :-
:       lda CGIA::raster
        bze :-
        dex
        bnz :--
        rts

sleep_some:
        ; Wait a bit
        ldx #0
:       dex
        bnz :-
        rts

.feature string_escapes
sd1_header:
.byte " .\x10 .\x11 .\x12 .\x13 .\x14 .\x15 .\x16 .\x17"
.byte " .\x18 .\x19 .A .B .C .D .E .F", 0

fm_keyon:
        store #$00, SD1_base+$0B        ; voice num
        store #$54, SD1_base+$0C        ; vovol
        store note_hi, SD1_base+$0D     ; fnumh
        store note_lo, SD1_base+$0E     ; fnuml
        store #$40, SD1_base+$0F        ; keyon = 1
        rts

doremi_fm:
  ; fnumh, fnuml
.byte $14, $65
.byte $1c, $11
.byte $1c, $42
.byte $1c, $5d
.byte $24, $17

aud_fm_configure:
        ; Configure playback
        ; Set MASTER_VOL to +9dB
        store #%11110000, SD1_base+$19
        ; Enable mute interpolation
        store #%00111111, SD1_base+$1B
        ; Turn on interpolation
        store #$00, SD1_base+$14
        ; Set speaker amplifier gain to 6.5dB (reset value)
        store #$01, SD1_base+$03

        ; Reset sequencer
        store #%11110110, SD1_base+$08
        jsr sleep_some
        store #$00, SD1_base+$08

        ; Set sequencer volume
        store #%11111000, SD1_base+$09
        ; Set sequence SIZE
        store #$00, SD1_base+$0A

        ; Set sequencer time unit - MS_S
        store #$40, SD1_base+$17
        store #$00, SD1_base+$18
        rts

aud_fm_set_ch:
        store #$00, SD1_base+$0B    ; voice num
        store #$30, SD1_base+$0F    ; keyon = 0
        store #$71, SD1_base+$10    ; chvol
        store #$00, SD1_base+$11    ; XVB
        store #$08, SD1_base+$12    ; FRAC
        store #$00, SD1_base+$13    ; FRAC
        rts

aud_fm_set_tone:
        ; Reset sequencer
        store #$F6, SD1_base+$08
        jsr sleep_some
        store #$00, SD1_base+$08

        ldx #0
:       lda tone_data,x
        sta SD1_base+$07
        inx
        cpx #35
        bne :-
        rts

tone_data:
.byte   $81 ; header
        ; T_ADR 0
.byte   $01, $85
.byte   $00, $7F, $F4, $BB, $00, $10, $40
.byte   $00, $AF, $A0, $0E, $03, $10, $40
.byte   $00, $2F, $F3, $9B, $00, $20, $41
.byte   $00, $AF, $A0, $0E, $01, $10, $40
.byte   $80, $03, $81, $80


.include "../util/write_hex.inc"

.include "../cgia/cgia_init.inc"
