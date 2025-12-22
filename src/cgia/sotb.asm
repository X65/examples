;
; This program contains only code for SOTB demo.
; In order to have a working X65 ROM file, you need to merge it with
; image data blocks. See src/cgia/data/bins.c to generate it.
; Then do something like this:
; ../tools/xex-filter.pl -o build/SOTB.xex build/src/sotb.xex src/cgia/data/sotb_layers.xex src/cgia/data/sotb_sprite.xex
;
; This demo showcases:
; - 65816 Native mode programming
; - Dealing with 16-bit numbers and registers
; - VBI (Vertical Blank Interrupt) screen update (the main_loop equivalent)
; - RSI (RaSter Interrupt) screen splits - the meat of parallax scroller
; - how to distinguish the source of NMI interrupt and how to ACK interrupts
; - configuring separate background bank and sprite bank
;   (the scrolling background layers take so much memory, that sprites cannot fit-in)
; - four graphics planes configured: 3 background planes and one sprite plane
; - background planes are configured with separate display list each
; - a sprite-descriptors array is created in bank 1 and configured in sprite plane
; - 9.7 and 8.8 fixed point number handling using 16bit operations
; - byte mangling using A/B register swap
; - fine scrolling using 16bit numbers unfolded to scroll_x and offset_x registers
; - use of math accelerator to do complex 16 bit multiplication (to get sprite frame offset)
; - XEX loader feature allowing to load data to any given bank.
;   (writing a 1-byte block to $FFFE changes the load-bank)

.p816       ; 65816 processor
.smart +    ; 8/16 smart mode

.include "../cgia.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Shadow Of The Beast demo"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, nmi, 0, 0
    .word 0, 0, 0, 0, 0, 0, reset, 0

.zeropage
.define SCROLL_MAX      $2580   ; 9600
.define SCROLL_SPEED    3       ; 3
.define Y_OFFS          20
.define FP_SCALE        128
.define SPRITE_X        180
sprite_y = 125+Y_OFFS
.define SPRITE_Y        sprite_y
.define SPRITE_HEIGHT   52

offset_clouds_01:   .res 2
offset_clouds_02:   .res 2
offset_clouds_03:   .res 2
offset_clouds_04:   .res 2
offset_clouds_05:   .res 2
offset_hills_06:    .res 2
offset_grass_07:    .res 2
offset_trees_08:    .res 2
offset_grass_09:    .res 2
offset_grass_10:    .res 2
offset_grass_11:    .res 2
offset_fence_12:    .res 2
sprite_frame:       .res 2

video_offset_1 = $1000
color_offset_1 = $5000
bkgnd_offset_1 = $5800
dl_offset_1 = $4F00
video_offset_2 = $6000
color_offset_2 = $A000
bkgnd_offset_2 = $A800
dl_offset_2 = $9F00
video_offset_3 = $B000
color_offset_3 = $F000
bkgnd_offset_3 = $F800
dl_offset_3 = $EF00

spr_0_data = $A000
spr_1_data = $8000
spr_desc = $010000  ; sprite descriptors address in sprite bank

.code
reset:
    sei         ; disable IRQ

    ldx #$FF
    txs         ; initialize stack pointer

    clc
    xce         ; switch to native mode

    _ai8

    ; disable all planes, so CGIA does not go haywire during reconfiguration
    store #0, CGIA::planes

    ; set border/background color
    store #145, CGIA::back_color

    ; backgrounds are in bank 00
    lda #0
    sta CGIA::bckgnd_bank
    ; sprites are in bank 01
    lda #1
    sta CGIA::sprite_bank

    ; configure plane display lists
    lda #<dl_offset_1
    sta CGIA::offset0
    lda #>dl_offset_1
    sta CGIA::offset0 + 1
    lda #<dl_offset_2
    sta CGIA::offset1
    lda #>dl_offset_2
    sta CGIA::offset1 + 1
    lda #<dl_offset_3
    sta CGIA::offset2
    lda #>dl_offset_3
    sta CGIA::offset2 + 1
    ; now fill plane registers
    ldx #(4*16)-1
pl_loop:
    lda cgia_planes, x
    sta CGIA::plane0, x
    dex
    bpl pl_loop
    ; set sprite descriptors address
    lda #0
    sta CGIA::offset3
    sta CGIA::offset3 + 1
    ; copy sprite descriptors
    ldx #(2*16)-1
sp_loop:
    lda sprite_descriptors, x
    sta spr_desc, x
    dex
    bpl sp_loop
    stz sprite_frame
    stz sprite_frame+1

    ; --- setup CGIA interrupts
    lda #Y_OFFS
    sta CGIA::int_raster    ; set interrupt raster line

    lda #(CGIA_REG_INT_FLAG_VBI|CGIA_REG_INT_FLAG_RSI)
    sta CGIA::int_enable    ; trigger NMI on VBL and raster line

    ; --- activate planes
    store #%10001111, CGIA::planes

forever:
    jmp forever ; do nothing more

PF1 = PLANE_MASK_DOUBLE_WIDTH | PLANE_MASK_TRANSPARENT | PLANE_MASK_BORDER_TRANSPARENT
PF2 = PLANE_MASK_DOUBLE_WIDTH | PLANE_MASK_TRANSPARENT
cgia_planes:
    .byte PF1,4,7,80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bg1
    .byte PF1,4,7,80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bg2
    .byte PF2,4,7,80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bg3
    .byte $03,$00,$00,(SPRITE_Y+SPRITE_HEIGHT-1),$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; sprites
sprite_descriptors:
    .byte <SPRITE_X,>SPRITE_X,<SPRITE_Y,>SPRITE_Y,<SPRITE_HEIGHT,>SPRITE_HEIGHT,7|SPRITE_MASK_MULTICOLOR,$00
    .byte $0A,$6A,$06,$00,<spr_0_data,>spr_0_data,$00,$00
    .byte <SPRITE_X,>SPRITE_X,<SPRITE_Y,>SPRITE_Y,<SPRITE_HEIGHT,>SPRITE_HEIGHT,7|SPRITE_MASK_MULTICOLOR,$00
    .byte $99,$9A,$9B,$00,<spr_1_data,>spr_1_data,$10,$00

; -----------------------------------------------------------------------------
nmi:
    rep #%00110000  ; 16-bit acc and idx
    pha             ; save accumulator
    phx             ; we use X for temporary storage
    sep #%00110000  ; 8-bit acc and idx

    lda #CGIA_REG_INT_FLAG_VBI
    bit CGIA::int_status    ; check for Vertical Blank Interrupt
    beq :+                  ; skip to RSI if not active
    jsr vbi_handler
:
    lda #CGIA_REG_INT_FLAG_RSI
    bit CGIA::int_status    ; check for RaSter Interrupt
    beq :+                  ; skip to end if not active
    jsr rsi_handler
:
    rep #%00110000  ; 16-bit acc and idx
    plx             ; restore X
    pla             ; restore accumulator
    _a8
    sta CGIA::int_status    ; ack interrupts
    rti             ; return from interrupt

.macro update_offset offset, width
    lda offset
    clc
    adc #(width * SCROLL_SPEED * FP_SCALE / SCROLL_MAX)
    cmp #(320 * FP_SCALE)
    bcc :+
    sec
    sbc #(320 * FP_SCALE)
:   sta offset
.endmacro

vbi_handler:
    ; restart background color
    lda #$8b
    sta CGIA::back_color

    ; wait for first line of RSI
    store #Y_OFFS+0, CGIA::int_raster

    _a16
    update_offset offset_clouds_01, 3300
    update_offset offset_clouds_02, 2700
    update_offset offset_clouds_03, 2500
    update_offset offset_clouds_04, 2200
    update_offset offset_clouds_05, 2000
    update_offset offset_hills_06, 2700
    update_offset offset_grass_07, 3400
    update_offset offset_trees_08, 4500
    update_offset offset_grass_09, 5400
    update_offset offset_grass_10, 6800
    update_offset offset_grass_11, 8200
    update_offset offset_fence_12, 9600

    ; update_sprite_frame
    lda sprite_frame
    clc
    adc #((SCROLL_MAX / 20) * SCROLL_SPEED * 256 / SCROLL_MAX)
    cmp #(6 * 256)
    bcc :+
    sec
    sbc #(6 * 256)
:   sta sprite_frame
    xba
    and #$FF
    ; multiply
    sta $FFC0   ; store in OPERA of math accelerator
    lda #8*SPRITE_HEIGHT ; 8 bytes per sprite line
    sta $FFC2   ; store in OPERB of math accelerator
    lda $FFC4   ; get MULAB result from math accelerator
    clc
    adc #spr_0_data
    sta spr_desc+12 ; set frame address to sprite 0 data pointer
    lda $FFC4   ; get MULAB result again
    clc
    adc #spr_1_data
    sta spr_desc+$10+12 ; set frame address to sprite 1 data pointer

    _a8
    rts

.macro apply_plane_offset offset, plane
    _a16
    lda offset
    xba     ; we need to divide by FP_SCALE, but instead of shifting right 7 times, we swap the bytes
    asl A   ; and shift left 1 time
    adc #0  ; add the shifted left bit back
    tax     ; store low byte of acc (X is 8 bit) for later
    lsr A   ; shift right 1 time - we fit in 8 bits now
    _a8     ; go acc 8 bit
    lsr A   ; shift two more times
    lsr A   ; to divide by 8 and get the plane column offset
    sta plane+CGIA_BCKGND_REGS::offset_x
    txa     ; now we need to compute negative fine scroll
    and #%00000111  ; clamp the value to 0-7
    eor #$FF; negate
    inc     ; do 2-complement
    sta plane+CGIA_BCKGND_REGS::scroll_x
    _a8
.endmacro

rsi_handler:
    lda CGIA::raster
    cmp #Y_OFFS+0
    bne :+
        _a16
        store #0, CGIA::plane0+CGIA_BCKGND_REGS::scroll_x ; moon does not move
        apply_plane_offset offset_clouds_01, CGIA::plane1
        apply_plane_offset offset_trees_08, CGIA::plane2
        store #Y_OFFS+21, CGIA::int_raster
        rts
:   cmp #Y_OFFS+21
    bne :+
        apply_plane_offset offset_clouds_02, CGIA::plane1
        store #Y_OFFS+61, CGIA::int_raster
        rts
:   cmp #Y_OFFS+61
    bne :+
        apply_plane_offset offset_clouds_03, CGIA::plane1
        store #Y_OFFS+72, CGIA::int_raster
        rts
:   cmp #Y_OFFS+72
    bne :+
        apply_plane_offset offset_hills_06, CGIA::plane0
        store #Y_OFFS+76, CGIA::int_raster
        rts
:   cmp #Y_OFFS+76
    bne :+
        store #$9b, CGIA::back_color
        store #Y_OFFS+80, CGIA::int_raster
        rts
:   cmp #Y_OFFS+80
    bne :+
        apply_plane_offset offset_clouds_04, CGIA::plane1
        store #Y_OFFS+89, CGIA::int_raster
        rts
:   cmp #Y_OFFS+89
    bne :+
        apply_plane_offset offset_clouds_05, CGIA::plane1
        store #Y_OFFS+96, CGIA::int_raster
        rts
:   cmp #Y_OFFS+96
    bne :+
        apply_plane_offset offset_grass_07, CGIA::plane1
        store #Y_OFFS+103, CGIA::int_raster
        rts
:   cmp #Y_OFFS+103
    bne :+
        store #$a4, CGIA::back_color
        store #Y_OFFS+117, CGIA::int_raster
        rts
:   cmp #Y_OFFS+117
    bne :+
        store #$b4, CGIA::back_color
        store #Y_OFFS+127, CGIA::int_raster
        rts
:   cmp #Y_OFFS+127
    bne :+
        store #$c4, CGIA::back_color
        store #Y_OFFS+135, CGIA::int_raster
        rts
:   cmp #Y_OFFS+135
    bne :+
        store #$cd, CGIA::back_color
        store #Y_OFFS+142, CGIA::int_raster
        rts
:   cmp #Y_OFFS+142
    bne :+
        store #$dd, CGIA::back_color
        store #Y_OFFS+148, CGIA::int_raster
        rts
:   cmp #Y_OFFS+148
    bne :+
        store #$ed, CGIA::back_color
        store #Y_OFFS+154, CGIA::int_raster
        rts
:   cmp #Y_OFFS+154
    bne :+
        store #$f6, CGIA::back_color
        store #Y_OFFS+158, CGIA::int_raster
        rts
:   cmp #Y_OFFS+158
    bne :+
        store #$0e, CGIA::back_color
        store #Y_OFFS+170, CGIA::int_raster
        rts
:   cmp #Y_OFFS+170
    bne :+
        store #$41, CGIA::back_color
        store #Y_OFFS+175, CGIA::int_raster
        rts
:   cmp #Y_OFFS+175
    bne :+
        apply_plane_offset offset_grass_09, CGIA::plane0
        store #Y_OFFS+178, CGIA::int_raster
        rts
:   cmp #Y_OFFS+178
    bne :+
        apply_plane_offset offset_fence_12, CGIA::plane1
        store #Y_OFFS+182, CGIA::int_raster
        rts
:   cmp #Y_OFFS+182
    bne :+
        apply_plane_offset offset_grass_10, CGIA::plane0
        store #Y_OFFS+185, CGIA::int_raster
        rts
:   cmp #Y_OFFS+185
    bne :+
        store #$40, CGIA::back_color
        store #Y_OFFS+189, CGIA::int_raster
        rts
:   cmp #Y_OFFS+189
    bne :+
        apply_plane_offset offset_grass_11, CGIA::plane0
        rts
:
    rts
