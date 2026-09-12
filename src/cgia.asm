.define CGIA_COLUMN_PX 8

.define CGIA_PLANE_REGS_NO 16

.struct CGIA_PLANE_REGS
    regs            .byte CGIA_PLANE_REGS_NO
.endstruct
.struct CGIA_BCKGND_REGS
    flags           .byte
    border_columns  .byte
    row_height      .byte
    stride          .byte
    scroll_x        .byte
    offset_x        .byte
    scroll_y        .byte
    offset_y        .byte
    shared_color    .byte 8
.endstruct
.struct CGIA_HAM_REGS
    flags           .byte
    border_columns  .byte
    row_height      .byte
    reserved        .byte 5
    base_color      .byte 8
.endstruct
.struct CGIA_AFFINE_REGS
    flags           .byte
    border_columns  .byte
    row_height      .byte
    texture_bits    .byte       ; 2-0 width_bits-1, 6-4 height_bits-1; 0..7 => 2..256 px
    u               .word
    v               .word
    du              .word
    dv              .word
    dx              .word
    dy              .word
.endstruct
.struct CGIA_SPRITE_REGS
    active          .byte       ; bitmask for active sprites
    border_columns  .byte
    start_y         .byte
    stop_y          .byte
    reserved        .byte 4
    color           .byte 8     ; shared by every sprite on the plane (palette entries 4..11)
.endstruct

.define CGIA_PLANES                 4
.define CGIA_AFFINE_FRACTIONAL_BITS 8
.define CGIA_MAX_DL_INSTR_PER_LINE  32

; plane flags:
; 0 - color 0 is transparent
; 1-2 - [RESERVED]
; 3 - border is transparent
; 4 - double-width pixel
; 5 - multicolor-pixel
; 6,7 - pixel bits: 00 - 1bit, 2 colors; 01 - 2bit, 4 colors;
;                   10 - 3bit, 8 colors; 11 - 4bit, 8 colors + half-bright
.define PLANE_MASK_TRANSPARENT        %00000001
.define PLANE_MASK_BORDER_TRANSPARENT %00001000
.define PLANE_MASK_DOUBLE_WIDTH       %00010000
.define PLANE_MASK_MULTICOLOR         %00100000
.define PLANE_MASK_PIXEL_BITS         %11000000

.define PLANE_MASK_FROM_DL PLANE_MASK_DOUBLE_WIDTH | PLANE_MASK_MULTICOLOR

.define PLANE_BITS_1BPP %00 << 6
.define PLANE_BITS_2BPP %01 << 6
.define PLANE_BITS_3BPP %10 << 6
.define PLANE_BITS_4BPP %11 << 6

.struct CGIA_PWM
    freq    .word
    duty    .byte
            .byte
.endstruct

.define CGIA_PWMS 2

.struct CGIA
                .org    $FF00

    mode        .byte
    bckgnd_bank .byte
    sprite_bank .byte
                .byte (16-3)    ; reserved

    raster      .word
                .byte (8-2)     ; reserved
    int_raster  .word
    int_enable  .byte
    int_status  .byte
                .byte (8-4)     ; reserved

                .byte (16)      ; reserved

    planes      .byte           ; [TTTTEEEE] EEEE - enable bits, TTTT - type (0 bckgnd, 1 sprite)
    order       .byte           ; [xxxOOOOO] OOOOO - plane order permutation
                .byte (4-2)     ; reserved
    back_color  .byte
                .byte (4-1)     ; reserved
    offset0     .word           ; DisplayList or SpriteDescriptor table start
    offset1     .word
    offset2     .word
    offset3     .word
    plane0      .tag CGIA_PLANE_REGS
    plane1      .tag CGIA_PLANE_REGS
    plane2      .tag CGIA_PLANE_REGS
    plane3      .tag CGIA_PLANE_REGS
.endstruct

.define CGIA_MODE_HIRES_BIT     %00000001
.define CGIA_MODE_INTERLACE_BIT %00000010

.define CGIA_REG_INT_FLAG_VBI %10000000
.define CGIA_REG_INT_FLAG_DLI %01000000
.define CGIA_REG_INT_FLAG_RSI %00100000

; --- DISPLAY LIST INSTRUCTIONS ---
.define CGIA_DL_INS_EMPTY_LINES         $00
.define CGIA_DL_INS_RESERVED_1          $01
.define CGIA_DL_INS_JUMP                $02
.define CGIA_DL_INS_DL_INTERRUPT            %10000000
.define CGIA_DL_INS_LOAD_MEMORY         $03
.define CGIA_DL_INS_LM_MEMORY_SCAN          %00010000
.define CGIA_DL_INS_LM_FOREGROUND_SCAN      %00100000
.define CGIA_DL_INS_LM_BACKGROUND_SCAN      %01000000
.define CGIA_DL_INS_LM_CHARACTER_GENERATOR  %10000000
.define CGIA_DL_INS_LOAD_REG8           $04
.define CGIA_DL_INS_LOAD_REG16          $05
.define CGIA_DL_INS_RESERVED_6          $06
.define CGIA_DL_INS_RESERVED_7          $07

.define CGIA_DL_MODE_PALETTE_TEXT       $08
.define CGIA_DL_MODE_PALETTE_BITMAP     $09
.define CGIA_DL_MODE_ATTRIBUTE_TEXT     $0A
.define CGIA_DL_MODE_ATTRIBUTE_BITMAP   $0B
.define CGIA_DL_MODE_HOLD_AND_MODIFY    $0E
.define CGIA_DL_MODE_AFFINE_TRANSFORM   $0F

.define CGIA_DL_MODE_BIT         %00001000
.define CGIA_DL_DOUBLE_WIDTH_BIT %00010000
.define CGIA_DL_MULTICOLOR_BIT   %00100000
.define CGIA_DL_RESERVED_BIT     %01000000
.define CGIA_DL_DLI_BIT          %10000000

; --- SPRITE DESCRIPTOR --- (16 bytes) ---
.define CGIA_SPRITE_DESC_LEN 16
.struct CGIA_SPRITE
    pos_x   .word
    pos_y   .word
    lines_y .word
    flags   .byte
            .byte           ; reserved
    color   .byte 4
    data_offset     .word
    next_dsc_offset .word   ; after passing lines_y, reload sprite descriptor data
                            ; this is a built-in sprite multiplexer
.endstruct

.define CGIA_SPRITES     8
.define SPRITE_MAX_WIDTH 8

; sprite flags:
; 0-2 - width in 8 pixel columns, minus one (1..8 columns, 8..64 px)
; 3 - double-width
; 4-5 - pixel bits: 00 - 1bit, 01 - 2bit, 10 - 3bit, 11 - 4bit
;       (same encoding as the plane's PLANE_MASK_PIXEL_BITS)
; 6 - mirror X
; 7 - mirror Y
.define SPRITE_MASK_WIDTH        %00000111
.define SPRITE_MASK_DOUBLE_WIDTH %00001000
.define SPRITE_MASK_PIXEL_BITS   %00110000
.define SPRITE_MASK_MIRROR_X     %01000000
.define SPRITE_MASK_MIRROR_Y     %10000000

.define SPRITE_PIXEL_BITS_SHIFT 4
.define SPRITE_BITS_1BPP %00 << SPRITE_PIXEL_BITS_SHIFT
.define SPRITE_BITS_2BPP %01 << SPRITE_PIXEL_BITS_SHIFT
.define SPRITE_BITS_3BPP %10 << SPRITE_PIXEL_BITS_SHIFT
.define SPRITE_BITS_4BPP %11 << SPRITE_PIXEL_BITS_SHIFT
; the old name for 2bpp sprites
.define SPRITE_MASK_MULTICOLOR SPRITE_BITS_2BPP

; Sprite pixel data uses the MODE1 packing at every depth: a column of
; 8 pixels takes `bpp` bytes, most significant pixel first, so a line is
; `bpp * columns` bytes long.
;
; Pixel values index one 16 entry palette per sprite, and a deeper sprite
; simply reaches further into it:
;
;   bits 3:2 | bits 1:0 | draws
;   ---------+----------+--------------------------------------------
;     00     |   cc     | descriptor color[cc]     (0000 is transparent)
;     01     |   cc     | plane color[cc]
;     10     |   cc     | plane color[4+cc]
;     11     |   cc     | descriptor color[cc], half-bright (index ^ 4)
;
; 1bpp sees entry 1, 2bpp entries 1..3, 3bpp entries 1..7 (bit 3 dropped),
; 4bpp all of them. Entry 0 is always transparent, so descriptor color[0]
; is only ever drawn through entry 12, half-bright.

; a palette index is hue * 8 + level; toggling level bit 2 moves four levels
.define CGIA_COLOR_HALF_BRIGHT %00000100
