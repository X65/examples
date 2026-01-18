.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

; PSID v2 player on SGU-1
; (c) 2025 Tomasz "smokku" Sterna

; You need to merge this code compiled to .xex with actual .sid file
; i.e.
; ../tools/xex-filter.pl -o ./build/Pokeymania.sid.xex -a \$1E82 -b src/sound/Orbtraxx2-Pokeymania.sid
; ../tools/xex-filter.pl -o ./build/Pokeymania.xex ./build/src/Pokeymania.sid.xex ./build/Pokeymania.sid.xex

.segment "INFO"
    .byte "Orbtraxx2-Pokeymania.sid by 4mat"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

CLOCK = 1000000 ; 1 MHz timers clock

; CGIA setup
text_offset  = $3000
chgen_offset = $3800
color_offset = $4000
bkgnd_offset = $4800
.define text_columns 40
.define text_rows    5
bg_color = 145
fg_color = 150

LOADADDRESS = $1F00 - $7E ; adjust for PSID v3 header
INITMUSIC   = $8000
PLAYMUSIC   = $8003
DEFSONG     = 3
SONGS_COUNT = 4

PLAYING_OFFSET = text_columns + text_columns/2

SID_Base        = $D400

SID_V1_FreqL    = SID_Base + $0
SID_V1_FreqH    = SID_Base + $1
SID_V1_PulseL   = SID_Base + $2
SID_V1_PulseH   = SID_Base + $3
SID_V1_Ctrl     = SID_Base + $4
SID_V1_AttDecay = SID_Base + $5
SID_V1_SusRel   = SID_Base + $6

SID_Filter0_2   = SID_Base + $15
SID_Filter3_10  = SID_Base + $16
SID_FilterCtrl  = SID_Base + $17
SID_VolFiltMode = SID_Base + $18
SID_PadX        = SID_Base + $19
SID_PadY        = SID_Base + $1A
SID_V3_WaveOut  = SID_Base + $1B
SID_V3_ADSROut  = SID_Base + $1C

SGU_base = $FEC0

.zeropage
DUTY_shifter: .res 2
VOL_shifter:  .res 1
FILTER_FC:    .res 2
FILTER_RES:   .res 1
FILTER_EN:    .res 1

TUNE:       .res 1

str:        .res 2

was_key_pressed:
            .res 1

.code
.org $200

        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

		; Tune 01 hangs if zero page is not clear
		ldx #0
:		stz $00,x
		inx
		bne :-

		lda #<str_playing
		sta str
		lda #>str_playing
		sta str+1
		ldx #PLAYING_OFFSET
		jsr print_str

		lda #<str_press_key
		sta str
		lda #>str_press_key
		sta str+1
		ldx #PLAYING_OFFSET + text_columns*3 - 3
		jsr print_str

		ldx #$1C
:		stz SID_Base, x
		dex
		bpl :-

; Assumes 1Mhz system clock.
Setup50HzTimer:
        lda #<(CLOCK/50)
        sta TIMERS::ta_lo
        lda #>(CLOCK/50)
        sta TIMERS::ta_hi
		; enable interrupts
        lda #$7f                ; Clear all IRQ flags
        sta TIMERS::icr
        lda #$81                ; Enable Timer A IRQ
        sta TIMERS::icr
        lda #$01
        sta RIA::irq_enable

		stz HID::d0 		 ; activate keyboard mapping
		stz was_key_pressed

        lda #DEFSONG
		sta TUNE

        ; start timer A in continuous mode
        lda #$11
        sta TIMERS::cra

start_play:
		lda TUNE
        jsr INITMUSIC
		lda TUNE
		inc A
		ldx #PLAYING_OFFSET + 13
        jsr write_hex

		jsr reset_sgu

play:
        jsr PLAYMUSIC
        jsr convert_sid_to_sgu
        jsr display_sid_registers
        wai                     ; Is it time for another set of notes?
        lda TIMERS::icr         ; Acknowledge the interrupt

        lda HID::d0
		and #1
		bne no_keypress
		inc A
		sta was_key_pressed
		bra play

no_keypress:
        lda was_key_pressed
		beq play
		; key was pressed and released now
		stz was_key_pressed
		; advance to next tune
		lda TUNE
		inc A
		cmp #SONGS_COUNT
		bne :+
		lda #0
:		sta TUNE

        jmp start_play

display_sid_registers:
        lda SID_Base+1
        ldx #0
        jsr write_hex
		lda SID_Base+0
		ldx #2
		jsr write_hex
        lda SID_Base+3
        ldx #5
        jsr write_hex
		lda SID_Base+2
		ldx #7
		jsr write_hex
		lda SID_Base+4
		ldx #10
		jsr write_hex
		lda SID_Base+5
		ldx #13
		jsr write_hex
		lda SID_Base+6
		ldx #15
		jsr write_hex

        lda SID_Base+7+1
        ldx #40+0
        jsr write_hex
		lda SID_Base+7+0
		ldx #40+2
		jsr write_hex
        lda SID_Base+7+3
        ldx #40+5
        jsr write_hex
		lda SID_Base+7+2
		ldx #40+7
		jsr write_hex
		lda SID_Base+7+4
		ldx #40+10
		jsr write_hex
		lda SID_Base+7+5
		ldx #40+13
		jsr write_hex
		lda SID_Base+7+6
		ldx #40+15
		jsr write_hex

        lda SID_Base+14+1
        ldx #80+0
        jsr write_hex
		lda SID_Base+14+0
		ldx #80+2
		jsr write_hex
        lda SID_Base+14+3
        ldx #80+5
        jsr write_hex
		lda SID_Base+14+2
		ldx #80+7
		jsr write_hex
		lda SID_Base+14+4
		ldx #80+10
		jsr write_hex
		lda SID_Base+14+5
		ldx #80+13
		jsr write_hex
		lda SID_Base+14+6
		ldx #80+15
		jsr write_hex

        lda SID_Base+21+1
        ldx #120+0
        jsr write_hex
		lda SID_Base+21+0
		ldx #120+2
		jsr write_hex
        lda SID_Base+21+2
        ldx #120+5
        jsr write_hex
		lda SID_Base+21+3
		ldx #120+8
		jsr write_hex
		rts

convert_sid_to_sgu:
        ldx #24
		jsr prepare_vol_shifter
		ldx #21
		jsr prepare_filters

		stz SGU_base+0                ; select channel 0
		ldx #0                        ; SID Voice 1 offset
		jsr convert_sid_channel
		lda SID_FilterCtrl
		and #%00000001
		jsr convert_filter

		inc SGU_base+0
		ldx #7                        ; SID Voice 2 offset
		jsr convert_sid_channel
		lda SID_FilterCtrl
		and #%00000010
		jsr convert_filter

		inc SGU_base+0
		ldx #14                       ; SID Voice 3 offset
		jsr convert_sid_channel
		lda SID_FilterCtrl
		and #%00000100
		jsr convert_filter
		lda SID_FilterCtrl
		jsr convert_3_off

		rts

reset_sgu:
		stz SGU_base
		ldx #0
:		stz SGU_base+32,x
		inx
		cpx #32
		bne :-
		rts

.proc print_str
        ldy #0
loop:	lda (str),y
		bne :+
		rts
:		sta text_offset,x
        iny
		inx
		bra loop
.endproc

str_playing:
        .asciiz "Playing tune 00/04"
str_press_key:
        .asciiz "Press any key to change"

.include "./sid.inc"

.include "../cgia/cgia_init.inc"
.include "../util/write_hex.inc"

