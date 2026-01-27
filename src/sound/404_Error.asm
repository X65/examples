.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

; PSID v2 player on SGU-1
; (c) 2025 Tomasz "smokku" Sterna

; You need to merge this code compiled to .xex with actual .sap file
; i.e.
; ../tools/xex-filter.pl -o ./build/Mystery_Cannon.xex ./build/src/Mystery_Cannon.sid.xex ./build/Mystery_Cannon.sid.xex

.segment "INFO"
    .byte "Groups/Grayscale/404_Error.sap"

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

INITMUSIC   = $04E5
PLAYMUSIC   = $04F6
DEFSONG     = 0

POKEY_Base        = $D200
POKEY2_Base       = $D210
POKEY2_offset     = POKEY2_Base - POKEY_Base

POKEY_AUDF1       = POKEY_Base + $0
POKEY_AUDC1       = POKEY_Base + $1
POKEY_AUDF2       = POKEY_Base + $2
POKEY_AUDC2       = POKEY_Base + $3
POKEY_AUDF3       = POKEY_Base + $4
POKEY_AUDC3       = POKEY_Base + $5
POKEY_AUDF4       = POKEY_Base + $6
POKEY_AUDC4       = POKEY_Base + $7
POKEY_AUDCTL      = POKEY_Base + $8

POKEY2_AUDF1 	  = POKEY_AUDF1 + POKEY2_offset
POKEY2_AUDC1 	  = POKEY_AUDC1 + POKEY2_offset
POKEY2_AUDF2 	  = POKEY_AUDF2 + POKEY2_offset
POKEY2_AUDC2 	  = POKEY_AUDC2 + POKEY2_offset
POKEY2_AUDF3 	  = POKEY_AUDF3 + POKEY2_offset
POKEY2_AUDC3 	  = POKEY_AUDC3 + POKEY2_offset
POKEY2_AUDF4 	  = POKEY_AUDF4 + POKEY2_offset
POKEY2_AUDC4 	  = POKEY_AUDC4 + POKEY2_offset
POKEY2_AUDCTL 	  = POKEY_AUDCTL + POKEY2_offset

SGU_base   = $FEC0
SGU_select = SGU_base + $3F

.zeropage
DUTY_shifter: .res 2
VOL_shifter:  .res 1
FILTER_FC:    .res 2
FILTER_RES:   .res 1
FILTER_EN:    .res 1

.code
.org $200

        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text

		ldx #$1C
:		stz POKEY_Base, x
		dex
		bpl :-

; Assumes 1Mhz system clock.
Setup150HzTimer:
        lda #<(CLOCK/150)
        sta TIMERS::ta_lo
        lda #>(CLOCK/150)
        sta TIMERS::ta_hi
		; enable interrupts
        lda #$7f                ; Clear all IRQ flags
        sta TIMERS::icr
        lda #$81                ; Enable Timer A IRQ
        sta TIMERS::icr
        lda #$01
        sta RIA::irq_enable

        lda #DEFSONG
        jsr INITMUSIC

        ; start timer A in continuous mode
        lda #$11
        sta TIMERS::cra

		; prepare hardware multiplier
		stz RIA::opera+1
		stz RIA::operb+1
		lda #66   ; 64 kHz
		sta RIA::operb

play:
        jsr PLAYMUSIC
        jsr convert_pokey_to_sgu
        ; jsr display_POKEY_registers
        wai                     ; Is it time for another set of notes?
        lda TIMERS::icr         ; Acknowledge the interrupt
        jmp play

.macro pokey_to_sgu REG
		lda #255
		sec
		sbc REG
		sta RIA::opera
		lda RIA::mulab
		sta SGU_base+32
		lda RIA::mulab+1
		sta SGU_base+32+1

		lda REG+1
		aslx 3
		and #%01111111
		sta SGU_base+32+2

		lda #$40
		sta SGU_base+32+8
.endmacro

convert_pokey_to_sgu:
		stz SGU_select                ; select channel 0
		pokey_to_sgu POKEY_AUDF1
        inc SGU_select
		pokey_to_sgu POKEY_AUDF2
		inc SGU_select
		pokey_to_sgu POKEY_AUDF3
		inc SGU_select
		pokey_to_sgu POKEY_AUDF4

		inc SGU_select
		pokey_to_sgu POKEY2_AUDF1
        inc SGU_select
		pokey_to_sgu POKEY2_AUDF2
		inc SGU_select
		pokey_to_sgu POKEY2_AUDF3
		inc SGU_select
		pokey_to_sgu POKEY2_AUDF4


		rts


.include "../cgia/cgia_init.inc"

