;
; This program contains only code for the Four-Byte Burger demo.
; In order to have a working X65 ROM file, you need to merge it with
; image data.
; ../tools/converter.ts -c 1 -d 1 -r 1 ./4BB.png -o ./4BB_image.xex -x xex
; ../tools/xex-filter.pl -o 4BB_code.xex -a \$4000,\$fc00,\$ffe0 build/src/four_byte_burger.xex
; ../tools/xex-filter.pl -o 4BB.xex 4BB_image.xex 4BB_code.xex
;
; This demo showcases:
; - Editing the display list during vertical blank period
; - Scrolling the screen by editing image offset in display list
; - Line doubling using display list instructions
;
; Four-Byte Burger image courtesy of Senn (@senn_twt)
; https://x.com/senn_twt/status/1670246393095639041
;

.include "../ria.asm"
.include "../cgia.asm"
.include "../macros.asm"
.macpack generic

.segment "INFO"
    .byte "Four-Byte Burger demo"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, vbl_handler, 0, 0
    .word 0, 0, 0, 0, 0, 0, reset, 0

.p816       ; 65816 processor
.smart +    ; 8/16 smart mode

video_offset = $0000
color_offset = $5000
bkgnd_offset = $a000
dl_offset = $f000
table_offset = $f800

columns = 40
column_width = 8
cell_height = 1

display_list = $8000
display_lines = 120
picture_lines = 295

.zeropage

lms:    .res 2
lfs:    .res 2
lbs:    .res 2
dls:    .res 2

picture_offset:
.res   1
scroll_direction:
.res   1
scroll_delay:
.res   1
dl_start:
.res   2
dl_end:
.res   2
dl_bak:
.res   2

.code
.org $4000

cgia_regs:
.byte   $00  ; MODE bitmask - not used, should be 0
.byte   $00  ; bckgnd_bank
.byte   $00  ; sprite_bank
.byte   $00, $00, $00, $00, $00 ; not used
.byte   $00, $00, $00, $00, $00, $00, $00, $00 ; not used
.byte   $00, $00, $00, $00, $00, $00, $00, $00 ; RASTER unit
.byte   $00, $00, $00, $00, $00, $00, $00, $00 ; RASTER interrupts
.byte   $00, $00, $00, $00, $00, $00, $00, $00 ; PWM0, PWM1
.byte   $00, $00, $00, $00, $00, $00, $00, $00 ; not used
.byte   $00  ; PLANES bitmask: [TTTTEEEE] EEEE - enable bits, TTTT - type (0 bckgnd, 1 sprite)
.byte   $00  ; ORDER: [xxxOOOOO] OOOOO - plane order permutation
.byte   $00, $00 ; not used
.byte   $00  ; back_color
.byte   $00, $00, $00 ; not used
.word   display_list  ; PLANE0 DL offset
.word   $0000  ; PLANE1 DL offset
.word   $0000  ; PLANE2 DL offset
.word   $0000  ; PLANE3 DL offset
        ; --- plane 0
        ; --- background plane regs
.byte   PLANE_MASK_DOUBLE_WIDTH ; flags;
.byte   (384 - columns * column_width) / (2*8)  ; border_columns;
.byte   (cell_height - 1)  ; row_height;
.byte   $00  ; stride;
.byte   $00  ; scroll_x;
.byte   $00  ; offset_x;
.byte   $00  ; scroll_y;
.byte   $00  ; offset_y;
.byte   $00, $00  ; shared_color[0-1];
.byte   $00, $00, $00, $00, $00, $00  ; base_color[2-7];

.byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; plane 1
.byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; plane 2
.byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; plane 3

reset:
        sei                     ; disable IRQ

        clc
        xce                     ; switch to native mode

        _i16                    ; 16-bit index registers

        ; We need to move stack, because we have graphics data from $0000
        lda #$30
        xba
        lda #$00
        tcd                     ; transfer $3000 to direct page pointer
        lda #$ff
        tcs                     ; transfer $30ff to stack pointer

        ; First, disable all planes
        lda #0
        sta CGIA::planes
        ; Next, fill all registers
        ldx #127
cgia_init_loop:
        lda cgia_regs,x
        sta CGIA::mode,x
        dex
        bpl cgia_init_loop

        jsr create_display_list

        _a8
        ; set back color
        lda #178
        sta CGIA::back_color

        ; initial scroll params
        lda #5
        sta scroll_delay
        stz picture_offset
        stz scroll_direction

        ; now enable plane 0
        lda #$01
        sta CGIA::planes

        ; and enable VBL interrupt
        lda #%10000000
        sta CGIA::int_enable

self:   bra self

vbl_handler:
        _ai8
        ; delay scrolling every 5th frame
        dec scroll_delay
        bne vbl_exit
        lda #5
        sta scroll_delay

        lda scroll_direction
        beq vbl_scroll_up
vbl_scroll_down:
        lda picture_offset
        bne :+
        ; at 0 offset - change direction
        stz scroll_direction
        bra vbl_scroll_up
:       dec picture_offset
        bra vbl_update
vbl_scroll_up:
        lda picture_offset
        cmp #picture_lines - display_lines
        bne :+
        ; at last line - change direction
        inc scroll_direction
        bra vbl_scroll_down
:       inc picture_offset

vbl_update:
        jsr update_display_list

vbl_exit:
        _a8
        sta CGIA::int_status    ; ack interrupts
        rti

.a8
.i16
gen_mode_line:
        lda #CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN
        sta display_list,x
        inx
        lda lms
        sta display_list,x
        inx
        lda lms+1
        sta display_list,x
        inx
        lda lfs
        sta display_list,x
        inx
        lda lfs+1
        sta display_list,x
        inx
        lda lbs
        sta display_list,x
        inx
        lda lbs+1
        sta display_list,x
        inx

        ; copy two REG8 values for shared colors
        phy
        ldy #0
        lda (dls),y
        sta display_list,x
        inx
        iny
        lda (dls),y
        sta display_list,x
        inx
        iny
        lda (dls),y
        sta display_list,x
        inx
        iny
        lda (dls),y
        sta display_list,x
        inx
        ply

        lda #CGIA_DL_MODE_ATTRIBUTE_BITMAP | CGIA_DL_MULTICOLOR_BIT | CGIA_DL_DOUBLE_WIDTH_BIT
        sta display_list,x
        inx

        rts

create_display_list:
        _ai16
        store #video_offset, lms
        store #color_offset, lfs
        store #bkgnd_offset, lbs
        store #dl_offset+7, dls

        ldy #picture_lines
        ldx #0
        _a8
:
        jsr gen_mode_line
        jsr gen_mode_line

        _a16
        lda lms
        add #40
        sta lms
        lda lfs
        add #40
        sta lfs
        lda lbs
        add #40
        sta lbs
        lda dls
        add #5
        sta dls
        _a8

        dey
        bne :-

        lda #CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
        sta display_list,x
        inx
        lda #<display_list
        sta display_list,x
        lda #>display_list
        inx
        sta display_list,x

        rts


update_display_list:
        _a16
        _i8
        
        ; restore previous display list instruction
        ldy #0
        lda #CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN
        sta (dl_end),y
        iny
        lda dl_bak
        sta (dl_end),y

        ; each row takes 12 bytes in display list
        ; but we scroll by two lines, thus we skip 24 bytes for each line offset
        lda picture_offset
        and #$00FF
        sta RIA::opera
        lda #24
        sta RIA::operb

        lda RIA::mulab
        add #display_list

        sta CGIA::offset0
        sta dl_start

        ; now we need to skip `display_lines` lines
        ; and inject looping jump to end the display list
        lda #display_lines
        sta RIA::opera

        lda dl_start
        add RIA::mulab
        sta dl_end

        _ai8
        ldy #0
        lda #CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
        sta (dl_end),y
        iny
        _a16
        lda (dl_end),y
        sta dl_bak              ; backup old value
        lda dl_start
        sta (dl_end),y

        rts
