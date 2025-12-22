;
; This program contains only code for the demo.
; In order to have a working X65 ROM file, you need to merge it with
; image data blocks. See src/cgia/data/bins.c to generate it.
; Then do something like this:
; ../tools/xex-filter.pl -o build/mixed_modes_merged.xex -a \$B000,\$FC00,\$FFE0,\$A000 build/src/mixed_modes.xex ../emu/roms/parts/font_8px.xex
; ../tools/xex-filter.pl -o build/mixed_modes.xex build/mixed_modes_merged.xex src/cgia/data/mixed_mode_dl.xex src/cgia/data/mascot_bg.xex src/cgia/data/hud_layer.xex
;

; This demo showcases:
; - MODE7 affine transform
; - rotating the picture using sin() table lookup, 16bit math
;   and modifying Display-List for tear-free screen update
; - HUD overlay layer
; - split screen with graphics on the top of the screen and text mode on the bottom
;   using display-list features only, no raster interrupts
; - Vertical Blank Interrupt screen update and time tracking
; - prompt text using X65 font and blinking cursor
; - relocating the code, the stack and direct page to upper memory
; - filling the screen attributes memory using single MVN instruction


.p816       ; 65816 processor
.smart +    ; 8/16 smart mode

.include "../cgia.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Split screen display list demo"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, nmi, 0, 0
    .word 0, 0, 0, 0, 0, 0, reset, 0

dl0_offset = $F000
dl1_offset = $E000

text_columns = 40
text_rows    = 8
text_offset  = $EA00
color_offset = $EC00
bkgnd_offset = $EE00
code_offset  = $B000

bg_color = 145
fg_color = 150

.code
.org code_offset
reset:
    sei         ; disable IRQ

    clc
    xce         ; switch to native mode

    ; 0000-3fff is used for image data storage,
    ; so we need to move stack and direct page
    _a16
    lda #code_offset+$700
    tcd         ; set direct page pointer
    lda #code_offset+$7FF
    tcs         ; set stack pointer
    _a8

    ; disable all planes, so CGIA does not go haywire during reconfiguration
    store #0, CGIA::planes

    ; set border/background color
    store #bg_color, CGIA::back_color

    ; let's make sure we are in bank 00
    store #0, CGIA::bckgnd_bank

    ; now fill plane registers
    _a16
    _i16
    ldx #cgia_planes
    ldy #CGIA::plane0
    lda #(2*16)-1
    mvn 0,0
    ; configure plane display list offsets
    store #dl0_offset, CGIA::offset0
    store #dl1_offset, CGIA::offset1

    store #$0000, dl0_offset+10 ; u
    store #$0000, dl0_offset+13 ; v
    store sin_table+108 +256*2/4, dl0_offset+16 ; du
    store sin_table+108 , dl0_offset+19 ; dv
    store sin_table+108 +256*2/2, dl0_offset+22 ; dx
    store sin_table+108 +256*2/4, dl0_offset+25 ; dy

    _a8

    ; trigger NMI on VBL
    store #CGIA_REG_INT_FLAG_VBI, CGIA::int_enable

    ; --- activate 2 background planes
    store #%00000011, CGIA::planes

forever:
    jmp forever ; do nothing more

PF2 = PLANE_MASK_TRANSPARENT | PLANE_MASK_BORDER_TRANSPARENT
cgia_planes:
    .byte $00,0,0,$77,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bg1
    .byte PF2,4,0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bg2

; -----------------------------------------------------------------------------
nmi:
    rep #%00110000  ; 16-bit acc and idx
    pha             ; save accumulator
    phx             ; we use X for temporary storage
    sep #%00110000  ; 8-bit acc and idx

    lda #0
    xba             ; make sure B is 00 (needed for ASL later)

    lda $00
    inc A           ; run the frame counter
    sta $00

    ; move the rotation origin over time
    sta dl0_offset+10+1 ; u (high byte)
    sta dl0_offset+13+1 ; v (high byte)

    _a16
    asl A           ; compute sin table offset (x2 bytes per item)
    _i16
    tax

    lda sin_table, x
    sta dl0_offset+16 ; du
    txa
    clc
    adc #256*2/4
    bpl :+
    ora #$FE00
    bra :++
:   and #$01FF
:   tax
    lda sin_table, x
    sta dl0_offset+19 ; dv
    sta dl0_offset+22 ; dx
    txa
    clc
    adc #256*2/4
    bpl :+
    ora #$FE00
    bra :++
:   and #$01FF
:   tax
    tax
    lda sin_table, x
    sta dl0_offset+25 ; dy

    ; clean text area
    lda #bg_color
    stz text_offset
    ldx #text_offset
    ldy #text_offset+1
    lda #text_columns*text_rows-2
    mvn 0,0

    ; copy prompt
    ldx #prompt
    ldy #text_offset
    lda #4
    mvn 0,0

    ; fill background color
    lda #bg_color
    sta bkgnd_offset
    ldx #bkgnd_offset
    ldy #bkgnd_offset+1
    lda #text_columns*text_rows-2
    mvn 0,0
    ; fill foreground color
    lda #fg_color
    sta color_offset
    ldx #color_offset
    ldy #color_offset+1
    lda #text_columns*text_rows-2
    mvn 0,0

    ; blink cursor
    _a8
    lda $00
    and #$40
    cmp #$40
    bne :+
    _i8
    lda bkgnd_offset+text_columns
    ldx color_offset+text_columns
    sta color_offset+text_columns
    stx bkgnd_offset+text_columns
:
    rep #%00110000  ; 16-bit acc and idx
    plx             ; restore X
    pla             ; restore accumulator
    _a8
    sta CGIA::int_status    ; ack interrupts
    rti             ; return from interrupt

prompt:
    .byte "READY"

sin_table:
    .word $0000, $0006, $000C, $0012, $0019, $001F, $0025, $002B
    .word $0031, $0038, $003E, $0044, $004A, $0050, $0056, $005C
    .word $0061, $0067, $006D, $0073, $0078, $007E, $0083, $0088
    .word $008E, $0093, $0098, $009D, $00A2, $00A7, $00AB, $00B0
    .word $00B5, $00B9, $00BD, $00C1, $00C5, $00C9, $00CD, $00D1
    .word $00D4, $00D8, $00DB, $00DE, $00E1, $00E4, $00E7, $00EA
    .word $00EC, $00EE, $00F1, $00F3, $00F4, $00F6, $00F8, $00F9
    .word $00FB, $00FC, $00FD, $00FE, $00FE, $00FF, $00FF, $00FF
    .word $0100, $00FF, $00FF, $00FF, $00FE, $00FE, $00FD, $00FC
    .word $00FB, $00F9, $00F8, $00F6, $00F4, $00F3, $00F1, $00EE
    .word $00EC, $00EA, $00E7, $00E4, $00E1, $00DE, $00DB, $00D8
    .word $00D4, $00D1, $00CD, $00C9, $00C5, $00C1, $00BD, $00B9
    .word $00B5, $00B0, $00AB, $00A7, $00A2, $009D, $0098, $0093
    .word $008E, $0088, $0083, $007E, $0078, $0073, $006D, $0067
    .word $0061, $005C, $0056, $0050, $004A, $0044, $003E, $0038
    .word $0031, $002B, $0025, $001F, $0019, $0012, $000C, $0006
    .word $0000, $FFFA, $FFF4, $FFEE, $FFE7, $FFE1, $FFDB, $FFD5
    .word $FFCF, $FFC8, $FFC2, $FFBC, $FFB6, $FFB0, $FFAA, $FFA4
    .word $FF9F, $FF99, $FF93, $FF8D, $FF88, $FF82, $FF7D, $FF78
    .word $FF72, $FF6D, $FF68, $FF63, $FF5E, $FF59, $FF55, $FF50
    .word $FF4B, $FF47, $FF43, $FF3F, $FF3B, $FF37, $FF33, $FF2F
    .word $FF2C, $FF28, $FF25, $FF22, $FF1F, $FF1C, $FF19, $FF16
    .word $FF14, $FF12, $FF0F, $FF0D, $FF0C, $FF0A, $FF08, $FF07
    .word $FF05, $FF04, $FF03, $FF02, $FF02, $FF01, $FF01, $FF01
    .word $FF00, $FF01, $FF01, $FF01, $FF02, $FF02, $FF03, $FF04
    .word $FF05, $FF07, $FF08, $FF0A, $FF0C, $FF0D, $FF0F, $FF12
    .word $FF14, $FF16, $FF19, $FF1C, $FF1F, $FF22, $FF25, $FF28
    .word $FF2C, $FF2F, $FF33, $FF37, $FF3B, $FF3F, $FF43, $FF47
    .word $FF4B, $FF50, $FF55, $FF59, $FF5E, $FF63, $FF68, $FF6D
    .word $FF72, $FF78, $FF7D, $FF82, $FF88, $FF8D, $FF93, $FF99
    .word $FF9F, $FFA4, $FFAA, $FFB0, $FFB6, $FFBC, $FFC2, $FFC8
    .word $FFCF, $FFD5, $FFDB, $FFE1, $FFE7, $FFEE, $FFF4, $FFFA
