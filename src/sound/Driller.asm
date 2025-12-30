.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

; PSID v2 player on SGU-1
; (c) 2025 Tomasz "smokku" Sterna

; You need to merge this code compiled to .xex with actual .sid file
; i.e.
; ../tools/xex-filter.pl -o ./build/Driller.sid.xex -a \$0882 -b src/sound/Driller.sid
; ../tools/xex-filter.pl -o ./build/Driller.xex ./build/src/Driller.sid.xex ./build/Driller.sid.xex

.segment "INFO"
    .byte "/MUSICIANS/G/Gray_Matt/Driller.sid"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

CLOCK = 1000000 ; 1 MHz timers clock

; CGIA setup
text_offset  = $8000
chgen_offset = $8800
color_offset = $9000
bkgnd_offset = $9800
.define text_columns 40
.define text_rows    4
bg_color = 145
fg_color = 150

LOADADDRESS = $900 - $7E ; adjust for PSID v2 header
INITMUSIC   = $15E0
PLAYMUSIC   = $0E46

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
DUTY_shifter = SID_Base-2
VOL_shifter = SID_Base-3

.code
.org $200

        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

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

        jsr INITMUSIC

        ; start timer A in continuous mode
        lda #$11
        sta TIMERS::cra

play:
        jsr PLAYMUSIC
        wai                     ; Is it time for another set of notes?
        lda TIMERS::icr         ; Acknowledge the interrupt
        jsr convert_sid_to_sgu
        jsr display_sid_registers
        jmp play

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

convert_ctl:
		lda SID_V1_Ctrl,x
		and #%00010000 ; triangle wave?
		beq :+
		lda #3
		sta SGU_base+32+4
:       lda SID_V1_Ctrl,x
        and #%00100000 ; sawtooth wave?
		beq :+
		lda #1
		sta SGU_base+32+4
:       lda SID_V1_Ctrl,x
		and #%01000000 ; pulse wave?
		beq :+
		lda #0
		sta SGU_base+32+4
:       lda SID_V1_Ctrl,x
		and #%10000000 ; noise wave?
		beq :+
		lda #4
		sta SGU_base+32+4
:       lda SID_V1_Ctrl,x
        and #%00000100 ; ring mod?
		beq :+
		lda SGU_base+32+4
		ora #$10
		sta SGU_base+32+4
:
		rts

convert_gate:
        lda SID_V1_Ctrl,x
		and #%00000001
		bne :+
		lda #$01
		sta SGU_base+32+$14 ; speed lo
		lda SID_V1_SusRel,x
		and #$0f
		sta SGU_base+32+$15 ; speed hi
		lda #$01
		sta SGU_base+32+$16 ; amount
		lda #$00
		sta SGU_base+32+$17 ; bound
		lda #%00100000 ; volume sweep
		sta SGU_base+32+5 ; flags1
		rts
:
		lda #0
		sta SGU_base+32+5 ; flags1
		rts

convert_sid_to_sgu:
        lda SID_VolFiltMode
		and #$0f
        asl A
		asl A
		sta VOL_shifter

		stz SGU_base+0                ; select channel 0
		ldx #0                        ; SID Voice 1 offset
		jsr convert_sid_channel
		inc SGU_base+0
		ldx #7                        ; SID Voice 2 offset
		jsr convert_sid_channel
		inc SGU_base+0
		ldx #14                       ; SID Voice 3 offset
		jsr convert_sid_channel
		rts

convert_sid_channel:
        lda SID_V1_FreqL,x
		sta SGU_base+32+0
        lda SID_V1_FreqH,x
		sta SGU_base+32+1

        ; convert duty cycle
		lda SID_V1_PulseL,x
		sta DUTY_shifter
		lda SID_V1_PulseH,x
		sta DUTY_shifter+1

        asl DUTY_shifter
		rol DUTY_shifter+1
		asl DUTY_shifter
		rol DUTY_shifter+1
		asl DUTY_shifter
		rol DUTY_shifter+1
		lda DUTY_shifter+1
		sta SGU_base+32+8

        ; convert wave form
		jsr convert_ctl

		; convert gate
		jsr convert_gate

		; convert volume
		lda SID_V1_SusRel,x
        lsr A
        lsr A
		clc
		adc VOL_shifter
		sta SGU_base+32+2

        rts

.include "../cgia/cgia_init.inc"
.include "../util/write_hex.inc"
