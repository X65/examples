; SID -> SGU-1 registers converter
; (c) 2025 Tomasz "smokku" Sterna

.a8
.i8

.code
prepare_vol_shifter:
		lda SID_Base,x
		and #$0f
        asl A
		asl A
		sta VOL_shifter
        rts

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
        sta FILTER_FC+1         ; FC HI

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

        lda FILTER_EN
        ora SGU_base+32+4
        sta SGU_base+32+4       ; enable filters

        rts
:
        stz SGU_base+32+9       ; disable resonator
        stz SGU_base+32+6       ; cutoff lo
        stz SGU_base+32+7       ; cutoff hi

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
		ora #%00010000
		sta SGU_base+32+4
:       lda SID_V1_Ctrl,x
        and #%00000010 ; sync?
		beq :+
		lda #%00000011
        sta SGU_base+32+5
        rts

:       stz SGU_base+32+5
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
		bne :+
		lda SID_V1_SusRel,x
		and #$0f
		asl A
		sta SGU_base+32+$15 ; speed hi
		lda #$01
		sta SGU_base+32+$14 ; speed lo
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

convert_sid_channel:
        lda SID_V1_FreqL,x
		sta SGU_base+32+0
        lda SID_V1_FreqH,x
		sta SGU_base+32+1

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

		; convert gate
		jsr convert_gate

		; convert volume
		lda SID_V1_Ctrl,x
		and #%00000001
		beq :+
		lda SID_V1_SusRel,x
        lsr A
        lsr A
		clc
		adc VOL_shifter
		sta SGU_base+32+2
:
        rts
