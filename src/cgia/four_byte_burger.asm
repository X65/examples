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

display_lines = 120
picture_lines = 295

.segment "CODE"

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
.word   live_display_list1  ; PLANE0 DL offset
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
        tcs                     ; transfer $3000 to stack pointer

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

        jsr create_color_table

        ; set back color
        lda #178
        sta CGIA::back_color

        ; now enable plane 0
        lda #$01
        sta CGIA::planes

        ; and enable VBL interrupt
        lda #%10000000
        sta CGIA::int_enable

self:   bra self

picture_offset:
.byte   0
scroll_direction:
.byte   1
scroll_delay:
.byte   1

vbl_handler:
        ; set display list for this frame
        ldx live_dl_offset
        stx CGIA::offset0

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

        lda live_dl
        bne :+
        inc live_dl
        ldy #live_display_list2
        bra :++
:       stz live_dl
        ldy #live_display_list1
:       sty live_dl_offset
        sty display_list_jmp

        ; copy generated DL to Live
        ldx #display_list
        _a16
        lda #(display_list_end - display_list)
        mvn 0,0
        _a8

vbl_exit:
        sta CGIA::int_status    ; ack interrupts
        rti

create_color_table:
        ldy #0
        ldx #0
create_color_table_loop:
        lda dl_offset+7,y
        cmp #CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4)
        beq :+
        rts
:       iny                     ; skip over LOAD_REG8 instruction
        lda dl_offset+7,y       ; load shared color 0
        sta table_offset,x
        inx
        iny
        iny                     ; skip over next LOAD_REG8 instruction
        lda dl_offset+7,y       ; load shared color 0
        sta table_offset,x
        inx
        iny
        iny                     ; skip over MODE5 instruction
        bra create_color_table_loop


update_display_list_counter:
.res    1

update_display_list:
        ; update memory scans with start line address
        _a16
        ; multiply row offset by columns in row
        lda picture_offset
        and #$00FF
        sta RIA::opera
        ; offset in colors table (each row has two colors)
        asl A
        tay

        lda #columns
        sta RIA::operb

        ; add to each memory scan
        lda RIA::mulab
        clc
        adc #video_offset
        sta display_list_lms
        lda RIA::mulab
        clc
        adc #color_offset
        sta display_list_lfs
        lda RIA::mulab
        clc
        adc #bkgnd_offset
        sta display_list_lbs
        _a8

        ; copy the needed number of REG8 values
        lda #display_lines
        sta update_display_list_counter
        ldx #0
update_display_list_loop:
        lda table_offset,y
        iny
        inx                     ; REG8
        sta display_list_start,x
        inx                     ; REG8 value
        lda table_offset,y
        iny
        inx                     ; REG8
        sta display_list_start,x
        inx                     ; REG8 value
        inx                     ; MODE5
        inx                     ; DUPL
        dec update_display_list_counter
        bne update_display_list_loop

        rts


display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_FOREGROUND_SCAN|CGIA_DL_INS_LM_BACKGROUND_SCAN
display_list_lms:
.word   video_offset
display_list_lfs:
.word   color_offset
display_list_lbs:
.word   bkgnd_offset
display_list_start:
.repeat display_lines
.byte   CGIA_DL_INS_LOAD_REG8 | (CGIA_BCKGND_REGS::shared_color << 4), $00
.byte   CGIA_DL_INS_LOAD_REG8 | ((CGIA_BCKGND_REGS::shared_color + 1) << 4), $00
.byte   CGIA_DL_MODE_ATTRIBUTE_BITMAP | CGIA_DL_MULTICOLOR_BIT
.byte   CGIA_DL_INS_EMPTY_LINES    ; duplicate each line one time
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT ; JMP to begin of DL and wait for Vertical BLank
display_list_jmp:
.word   display_list
display_list_end:

live_dl:
.byte 0
live_dl_offset:
.word live_display_list1

live_display_list1:
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   live_display_list1
.res    display_list_end - display_list

live_display_list2:
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   live_display_list2
.res    display_list_end - display_list
