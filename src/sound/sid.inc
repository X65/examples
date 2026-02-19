; SID -> SGU-1 registers converter
; (c) 2025 Tomasz "smokku" Sterna

.define WAVE_SINE 0
.define WAVE_TRIANGLE 1
.define WAVE_SAWTOOTH 2
.define WAVE_PULSE 3
.define WAVE_NOISE 4
.define WAVE_PERIODIC_NOISE 5
.define WAVE_XOR_SINE 6
.define WAVE_XOR_TRIANGLE 7

.a8
.i8

.code
prepare_filters:
		lda SID_Base,x
        asl A
        asl A
        asl A
        asl A
        asl A
        sta FILTER_FC           ; FC LO
        inx
        lda SID_Base,x
		lsr A
        sta FILTER_FC+1         ; FC HI
		lda FILTER_FC
		ror A
		sta FILTER_FC
		; clamp cutoff to $6D60 (28000) for SVF stability
		sec
		lda FILTER_FC
		sbc #$60
		lda FILTER_FC+1
		sbc #$6D
		bcc :+              ; < 28000 → no clamp
		lda #$60
		sta FILTER_FC
		lda #$6D
		sta FILTER_FC+1
:
        inx
        lda SID_Base,x
        and #$f0
        lsr A
        sta FILTER_RES
        lsr A
        lsr A
        lsr A
        lsr A
        ora FILTER_RES
        sta FILTER_RES

        stz FILTER_EN
        inx
        lda SID_Base,x
        and #%01000000          ; HP
		beq :+
		lda FILTER_EN
		ora #%01000000
		sta FILTER_EN
:       lda SID_Base,x
        and #%00100000          ; BP
		beq :+
		lda FILTER_EN
		ora #%10000000
		sta FILTER_EN
:	    lda SID_Base,x
        and #%00010000          ; LP
		beq :+
		lda FILTER_EN
		ora #%00100000
		sta FILTER_EN
:
        rts

convert_filter:
        beq :+                  ; filter off

        lda FILTER_RES
        sta SGU_base+32+9       ; set resonance

        lda FILTER_FC
        sta SGU_base+32+6       ; cutoff lo
        lda FILTER_FC+1
        sta SGU_base+32+7       ; cutoff hi

        lda SGU_base+32+4
		and #$1f
        ora FILTER_EN
        sta SGU_base+32+4       ; enable filters

		rts
:
        stz SGU_base+32+9       ; disable resonator
        stz SGU_base+32+6       ; cutoff lo
        stz SGU_base+32+7       ; cutoff hi

        lda SGU_base+32+4
		and #$1f
        sta SGU_base+32+4       ; disable filters

        rts

convert_ctl:
        lda SID_V1_Ctrl,x
		and #%10000000 ; noise wave? - dominates all, select first
		beq :+
		lda SGU_base+7
		and #$f8
		ora #WAVE_NOISE | $E0
		sta SGU_base+7
		rts
:       lda SID_V1_Ctrl,x
		and #%01000000 ; pulse wave? - if you picked pulse, you want duty cycle control
		beq :+
		lda SGU_base+7
		and #$f8
		ora #WAVE_PULSE | $E0
		sta SGU_base+7
		rts
:       lda SID_V1_Ctrl,x
        and #%00100000 ; sawtooth wave? - saw+tri still looks mostly like saw
		beq :+
		lda SGU_base+7
		and #$f8
		ora #WAVE_SAWTOOTH | $E0
		sta SGU_base+7
		rts
:		lda SID_V1_Ctrl,x
		and #%00010000 ; triangle wave?
		beq :+
		lda SGU_base+7
		and #$f8
		ora #WAVE_TRIANGLE | $E0
		sta SGU_base+7
		rts

; ===================================================================
; SID ADSR (4-bit) → OPN-style AR/DR/SL/SR/RR (5/5/4/5/4 bit)
; ===================================================================
; Lookup tables: SID 4-bit value → OPN 5-bit rate
; Log-mapped through actual SID timing: R = 31 - 2.506 * log2(T_sid / 2ms)
ar_table:
        .byte 31, 26, 23, 22, 20, 19, 18, 18   ; val 0-7
        .byte 17, 14, 11,  9,  9,  5,  3,  1   ; val 8-15
dr_table:
        .byte 27, 22, 20, 18, 16, 15, 14, 14   ; val 0-7
        .byte 13, 10,  7,  5,  5,  1,  1,  1   ; val 8-15
; SL (4-bit, 3dB/step): SL = floor(-20*log10(S/15) / 3), S=0 → 15
sl_table:
        .byte 15,7,5,4,3,3,2,2,1,1,1,0,0,0,0,0
; RR (4-bit): R = 15 - 1.253 * log2(T_decay / 6ms)
rr_table:
        .byte  15, 12, 11, 11, 10,  9,  9,  8   ; val 0-7
        .byte   8,  6,  5,  4,  4,  2,  1,  1   ; val 8-15
convert_adsr:
        lda SID_V1_AttDecay,x   ; attack
        lsrx 4
		tay
		lda ar_table,y
		aslx 4
		sta TEMP
		lda ar_table,y
		and #%00010000                ; handle AR_msb
		bne :+
		lda SGU_base+7
		and #%11101111
		sta SGU_base+7
		bra :++
:		lda SGU_base+7
		ora #%00010000
		sta SGU_base+7
:       lda SID_V1_AttDecay,x   ; decay
		and #$0f
		tay
		lda dr_table,y
		and #$0f
		ora TEMP
		sta SGU_base+2                ; store AR_lo4/DR_lo4
        lda dr_table,y
		and #%00010000                ; handle DR_msb
		bne :+
		lda SGU_base+7
		and #%11110111
		sta SGU_base+7
		bra :++
:		lda SGU_base+7
		ora #%00001000
		sta SGU_base+7
:
        lda SID_V1_SusRel,x    ; sustain
		lsrx 4
		tay
		lda sl_table,y
		aslx 4
		sta TEMP
        lda SID_V1_SusRel,x    ; release
		and #$0f
		tay
		lda rr_table,y
		ora TEMP
		sta SGU_base+3 		; store SL/RR

		stz SGU_base+4                ; set SR = 0

        rts

convert_3_off:
        and #%10000000
        beq :+
        stz SGU_base+32+2 ; volume off
		stz SGU_base+32+$16 ; slide amount
		stz SGU_base+32+$17 ; slide bound
:       rts

convert_gate:
        lda SID_V1_Ctrl,x
		and #%00000001
		beq :+
		lda SGU_base+32+4 ; set KEY bit
		ora #%00000001
		sta SGU_base+32+4 ; flags0
		rts
:
		lda SGU_base+32+4 ; clear KEY bit
		and #%11111110
		sta SGU_base+32+4 ; flags0
		rts

convert_sid_channel:
		; SGU-1 is tuned as a 1MHz SID, so according to datasheet formula
		; Fout = (Fn * Fclk/2^24) Hz
		; to get A-4 440Hz => Fn = 440 * 2^24 / 1MHz ~= 7382
		; but SID was running either
		; in an NTSC 60Hz C64, with clock 14.31818 MHz / 14 = 1022727.142857143 Hz
		; or a PAL 50Hz C64 with clock 17.734475 MHz / 18 = 985248.6(1) Hz
		; so the A-4 440Hz on NTSC => Fn = 440 * 2^24 / 1022727.142857143 Hz ~= 7218
		; and the A-4 440Hz on PAL => Fn = 440 * 2^24 / 985248.6(1) Hz ~= 7493
		; thus we need to scale C64 frequencies to match SGU-1's tuning by
		; PAL => 7382/7493 ~= 0.985248611 => ~252/256
		; NTSC => 7382/7218 ~= 1.022727143 => ~262/256
		; these ase so close, that you can just use C64 value as is, and be done with
		; but as an example and for completeness sake, we do the scaling ¯\_(ツ)_/¯
PAL_SID_SCALE = 252
NTSC_SID_SCALE = 262
        lda SID_V1_FreqL,x
        sta RIA::opera
        lda SID_V1_FreqH,x
        sta RIA::opera+1
        lda #<SID_SCALE
        sta RIA::operb
        lda #>SID_SCALE
        sta RIA::operb+1
        lda RIA::mulab+1
		sta SGU_base+32+0
        lda RIA::mulab+2
		sta SGU_base+32+1

		lda #1
        sta SGU_base+0                ; set x1 frequency multiplier

        ; convert duty cycle
		lda SID_V1_PulseL,x
		sta DUTY_shifter
		lda SID_V1_PulseH,x
		and #$0f
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

        ; convert ADSR
		jsr convert_adsr

		; convert gate
		jsr convert_gate

		; convert volume
		lda SID_VolFiltMode
		and #%00001110
		aslx 3
		sta TEMP
		lda SID_VolFiltMode
		and #$0f
		ora TEMP
		sta SGU_base+32+2

		bit SID_V1_Ctrl,x
		bpl :+    	  ; check if noise wave
		lda #$05 	  ; reduce total level of noise wave
		sta SGU_base+1
		rts
:       stz SGU_base+1
        rts
