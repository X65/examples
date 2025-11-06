; Written by https://github.com/karmic64/64vgmplay
; ca64 port for X65 by smoku

; # 64vgmplay
; OPL1/2 VGM converter/player for SFX Sound Expander/FM-YAM.
;
; Making a C64 executable is a multi-step process:
; - First, run the "convert" utility, which will create an `.include`able file from a VGM file for use with the assembler. `convert vgmname outname`
; - Now, take a look at the bottom of the assembly file, and change the filename after `.include` to the name of the file you just exported. Assemble the file with 64tass.
; - You should probably crunch it now with Exomizer or something else. Start address is $080d.
;
; Your VGM file must use at least one OPL1 or OPL2 to be usable. If more than one chip fits these qualifications, you will be given a choice of which one to log. Any other chips' commands will simply be ignored.
;
; Remember to have an SFX Sound Expander/FM-YAM enabled in your emulator/plugged into your machine when you run the file.
;
; Remember that there is only 64k of space available to the C64- if the assembler warns you about processor program counter overflow, your VGM is too large. There is no compression per se, but the data format used by the player will result in data that is about 3/4 the size of the VGM, for any standard single-chip VGM. So, be careful with any files above around 70kb.
;
; This play routine is only intended to generate standalone executables, not for demos. If you want to use FM-enhanced music in a production, consider the Edlib D00 player by Mr. Mouse.
;

.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

HAS_LOOP = 2

.segment "INFO"
    .byte "VGM player demo"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.struct
.org $f0
waitcnt     .res 1
dataptr     .res 2
waitptr     .res 2

irqa    .res 1
irqy    .res 1
irq1    .res 1
.endstruct

OPL2_ADDR = $FC00
OPL2_DATA = $FC01
OPL3_ADDR = $FC02
OPL3_DATA = $FC03

SCREEN    = $D000

.setcpu "65816"

;CLOCK = 985248  ;PAL
;CLOCK = 1022727 ;NTSC
CLOCK = 1000000 ;X65

.code
            sei
            cld
            ldx #$ff
            txs
            
            lda #$7f
            sta TIMERS::icr
            lda #$01
            sta RIA::irq_enable
            lda #<nmi
            sta $fffa
            lda #>nmi
            sta $fffb
            lda #<irq
            sta $fffe
            lda #>irq
            sta $ffff
            
            ; enable EXTIO bank0 (OPL3)
            ldx #1
            stx RIA::extio
            
            ldx #0
            txa
:           stx OPL2_ADDR
            nop
            nop
            sta OPL2_DATA
            php
            plp
            php
            plp
            php
            plp
            php
            plp
            inx
            bne :-
            
            jsr init_cgia
            
            lda #<regdata
            sta dataptr
            lda #>regdata
            sta dataptr+1
            lda #<waitdata+4
            sta waitptr
            lda #>waitdata+4
            sta waitptr+1
            lda #1
            sta waitcnt
            
            lda #<(CLOCK/44100) * 2
            sta TIMERS::ta_lo
            lda #>(CLOCK/44100) * 2
            sta TIMERS::ta_hi
            lda waitdata
            sta TIMERS::tb_lo
            lda waitdata+1
            sta TIMERS::tb_hi
            lda #$11 ;tma runs every cycle
            sta TIMERS::cra
            lda #$51 ;tmb runs every xx samples
            sta TIMERS::crb
            lda waitdata+2 ;set wait period for next cycle
            sta TIMERS::tb_lo
            lda waitdata+3
            sta TIMERS::tb_hi
            
            lda TIMERS::icr
            lda #$82
            sta TIMERS::icr
            cli
            
            
mainloop:   lda #0
            sta CGIA::back_color
            
            lda dataptr
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$03
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$02
            lda dataptr+1
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$01
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$00
            
            
            lda waitptr
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$09
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$08
            lda waitptr+1
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$07
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$06
            
            
            
:           lda TIMERS::tb_lo
            pha
            lda TIMERS::tb_hi
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$25
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$24
            pla
            tax
            and #$0f
            tay
            lda conv,y
            sta SCREEN+$27
            txa
            lsr
            lsr
            lsr
            lsr
            tay
            lda conv,y
            sta SCREEN+$26
            
            
            lda waitcnt
            beq :-
            dec waitcnt
            lda #$0f
            sta CGIA::back_color
            
getloop:    ldy #$00
            lda (dataptr),y
            cmp #$fe
            bcs next
            sta OPL2_ADDR
            iny
            lda (dataptr),y
            sta OPL2_DATA
            tya
            sec
            adc dataptr
            sta dataptr
            bcc getloop
            inc dataptr+1
            bcs getloop
            
next:       .if HAS_LOOP
                bne loopdata
            .else
                bne *
            .endif
            inc dataptr
            bne :+
            inc dataptr+1
:           beq :+
            jmp mainloop
:
loopdata:   .if HAS_LOOP
                lda #<regdata_loop
                sta dataptr
                lda #>regdata_loop
                sta dataptr+1
                beq :+
                jmp mainloop
:
            .endif
            
            
irq:        sta irqa
            sty irqy
            ldy #0
            lda (waitptr),y
            iny
            ora (waitptr),y
            beq _loop
            lda (waitptr),y
            sta TIMERS::tb_hi
            dey
            lda (waitptr),y
            sta TIMERS::tb_lo
            lda #2
            clc
            adc waitptr
            sta waitptr
            bcc _end
            inc waitptr+1
            bcs _end
_loop:      .if HAS_LOOP
                lda waitdata_loop
                sta TIMERS::tb_lo
                lda waitdata_loop+1
                sta TIMERS::tb_hi
                lda #<waitdata_loop+2
                sta waitptr
                lda #>waitdata_loop+2
                sta waitptr+1
                ;bne _end
            .else
                lda #$7f
                sta TIMERS::icr
                ;bpl _end
            .endif
_end:       inc waitcnt
            lda TIMERS::icr
            lda irqa
            ldy irqy
            sta RIA::irq_status
nmi:        rti

text_columns = 40
text_rows    = 1
text_offset  = $d000
chgen_offset = $d800
color_offset = $e000
bkgnd_offset = $e800

bg_color = 145
fg_color = 150

.define CGIA_PLANES_USED 1

init_cgia:
        clc
        xce                     ; switch to native mode

        stz CGIA::planes

        phb
        pla
        sta RIA::stack
        lda #>chgen_offset
        sta RIA::stack
        lda #<chgen_offset
        sta RIA::stack
        lda #RIA_API_GET_CHARGEN
        sta RIA::op

        _i16
        stz CGIA::mode
        ldx #CGIA::mode
        ldy #CGIA::mode+1
        lda #CGIA::plane0-CGIA::mode-1
        mvn 0,0
        store #bg_color, CGIA::back_color
        store #bg_color, bkgnd_offset
        store #fg_color, color_offset

        stz text_offset
        ldx #text_offset
        ldy #text_offset+1
        _a16
        lda #text_columns*text_rows-1
        mvn 0,0

        ldx #bkgnd_offset
        ldy #bkgnd_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0

        ldx #color_offset
        ldy #color_offset+1
        lda #text_columns*text_rows-1
        mvn 0,0

        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #(CGIA_PLANES_USED*CGIA_PLANE_REGS_NO)-1
        mvn 0,0

        store #display_list, CGIA::offset0
        _ai8
        store #%00000001, CGIA::planes

        sec
        xce                     ; switch to emulation mode

        rts

cgia_planes:
.byte $00,4,7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   color_offset
.word   bkgnd_offset
.word   chgen_offset
.byte   $70, $70, $30
.repeat text_rows
.byte   CGIA_DL_MODE_ATTRIBUTE_TEXT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list

            
conv:   .byte "0123456789ABCDEF"
            
            ;insert your music data here
            .include "data/tune.asm"
