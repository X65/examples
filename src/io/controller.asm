.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "Controller test"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

.define text_columns 40
.define text_rows    25
bg_color = 145
fg_color = 150

on_bg_color = bg_color+8
on_fg_color = 7

.define JOY0_RIGHT              5+2 + text_columns*2
.define JOY0_LEFT               5-2 + text_columns*2
.define JOY0_UP                 5   + text_columns*0
.define JOY0_DOWN               5   + text_columns*4
.define JOY0_BUTTON_A           10   + text_columns*1
.define JOY0_BUTTON_B           10+2 + text_columns*1
.define JOY0_BUTTON_C           10+4 + text_columns*1
.define JOY0_BUTTON_X           10   + text_columns*3
.define JOY0_BUTTON_Y           10+2 + text_columns*3
.define JOY0_BUTTON_Z           10+4 + text_columns*3
.define JOY0_BUTTON_L           17   + text_columns*1
.define JOY0_BUTTON_R           17+2 + text_columns*1
.define JOY0_BUTTON_L2          17   + text_columns*2
.define JOY0_BUTTON_R2          17+2 + text_columns*2
.define JOY0_BUTTON_L3          17   + text_columns*3
.define JOY0_BUTTON_R3          17+2 + text_columns*3
.define JOY0_BUTTON_SELECT      10+1 + text_columns*5
.define JOY0_BUTTON_START       10+3 + text_columns*5
.define JOY0_BUTTON_HOME        10+5 + text_columns*5

.define JOY1_OFFSET             text_columns*8
.define JOY1_RIGHT              JOY1_OFFSET + JOY0_RIGHT
.define JOY1_LEFT               JOY1_OFFSET + JOY0_LEFT
.define JOY1_UP                 JOY1_OFFSET + JOY0_UP
.define JOY1_DOWN               JOY1_OFFSET + JOY0_DOWN
.define JOY1_BUTTON_A           JOY1_OFFSET + JOY0_BUTTON_A
.define JOY1_BUTTON_B           JOY1_OFFSET + JOY0_BUTTON_B
.define JOY1_BUTTON_X           JOY1_OFFSET + JOY0_BUTTON_X
.define JOY1_BUTTON_Y           JOY1_OFFSET + JOY0_BUTTON_Y

.define JOYH_OFFSET             text_columns/2
.define JOYH_RIGHT              JOYH_OFFSET + JOY0_RIGHT
.define JOYH_LEFT               JOYH_OFFSET + JOY0_LEFT
.define JOYH_UP                 JOYH_OFFSET + JOY0_UP
.define JOYH_DOWN               JOYH_OFFSET + JOY0_DOWN
.define JOYH_BUTTON_A           JOYH_OFFSET + JOY0_BUTTON_A
.define JOYH_BUTTON_B           JOYH_OFFSET + JOY0_BUTTON_B
.define JOYH_BUTTON_C           JOYH_OFFSET + JOY0_BUTTON_C
.define JOYH_BUTTON_X           JOYH_OFFSET + JOY0_BUTTON_X
.define JOYH_BUTTON_Y           JOYH_OFFSET + JOY0_BUTTON_Y
.define JOYH_BUTTON_Z           JOYH_OFFSET + JOY0_BUTTON_Z
.define JOYH_BUTTON_L           JOYH_OFFSET + JOY0_BUTTON_L
.define JOYH_BUTTON_R           JOYH_OFFSET + JOY0_BUTTON_R
.define JOYH_BUTTON_L2          JOYH_OFFSET + JOY0_BUTTON_L2
.define JOYH_BUTTON_R2          JOYH_OFFSET + JOY0_BUTTON_R2
.define JOYH_BUTTON_L3          JOYH_OFFSET + JOY0_BUTTON_L3
.define JOYH_BUTTON_R3          JOYH_OFFSET + JOY0_BUTTON_R3
.define JOYH_BUTTON_SELECT      JOYH_OFFSET + JOY0_BUTTON_SELECT
.define JOYH_BUTTON_START       JOYH_OFFSET + JOY0_BUTTON_START
.define JOYH_BUTTON_HOME        JOYH_OFFSET + JOY0_BUTTON_HOME

.define KBD_OFFSET              text_columns*18
.define KBD_ROW                 text_columns-2

.code
        sei
        cld
        ldx #$ff
        txs

        jsr cgia_init_text
        clc
        xce                     ; switch to native mode
        .a8
        .i8

        lda #$10                ; 0
        sta text_offset
        lda #$11                ; 1
        sta text_offset + JOY1_OFFSET
        lda #'H'
        sta text_offset + JOYH_OFFSET - 1
        lda #'I'
        sta text_offset + JOYH_OFFSET
        lda #'D'
        sta text_offset + JOYH_OFFSET + 1

        lda #'K'
        sta text_offset + KBD_OFFSET
        lda #'B'
        sta text_offset + KBD_OFFSET + 1
        lda #'D'
        sta text_offset + KBD_OFFSET + 2
        lda #$10                ; 0
        sta text_offset + KBD_OFFSET + KBD_ROW
        lda #$11                ; 1
        sta text_offset + KBD_OFFSET + KBD_ROW - 2
        lda #$12                ; 2
        sta text_offset + KBD_OFFSET + KBD_ROW - 5
        lda #$14                ; 4
        sta text_offset + KBD_OFFSET + KBD_ROW - 5*2
        lda #$18                ; 8
        sta text_offset + KBD_OFFSET + KBD_ROW - 5*4

        lda #$1c                ; ->
        sta text_offset + JOY0_RIGHT
        sta text_offset + JOY1_RIGHT
        sta text_offset + JOYH_RIGHT
        lda #$1d                ; <-
        sta text_offset + JOY0_LEFT
        sta text_offset + JOY1_LEFT
        sta text_offset + JOYH_LEFT
        lda #$1e                ; ^
        sta text_offset + JOY0_UP
        sta text_offset + JOY1_UP
        sta text_offset + JOYH_UP
        lda #$1f                ; v
        sta text_offset + JOY0_DOWN
        sta text_offset + JOY1_DOWN
        sta text_offset + JOYH_DOWN

        lda #'A'
        sta text_offset + JOY0_BUTTON_A
        sta text_offset + JOY1_BUTTON_A
        sta text_offset + JOYH_BUTTON_A
        lda #'B'
        sta text_offset + JOY0_BUTTON_B
        sta text_offset + JOY1_BUTTON_B
        sta text_offset + JOYH_BUTTON_B
        lda #'X'
        sta text_offset + JOY0_BUTTON_X
        sta text_offset + JOY1_BUTTON_X
        sta text_offset + JOYH_BUTTON_X
        lda #'Y'
        sta text_offset + JOY0_BUTTON_Y
        sta text_offset + JOY1_BUTTON_Y
        sta text_offset + JOYH_BUTTON_Y
        lda #'C'
        sta text_offset + JOYH_BUTTON_C
        lda #'Z'
        sta text_offset + JOYH_BUTTON_Z
        lda #'L'
        sta text_offset + JOYH_BUTTON_L
        sta text_offset + JOYH_BUTTON_L2
        sta text_offset + JOYH_BUTTON_L3
        lda #'R'
        sta text_offset + JOYH_BUTTON_R
        sta text_offset + JOYH_BUTTON_R2
        sta text_offset + JOYH_BUTTON_R3
        lda #'2'
        sta text_offset + JOYH_BUTTON_R2 - 1
        lda #'3'
        sta text_offset + JOYH_BUTTON_R3 - 1
        lda #$08                ; <>
        sta text_offset + JOYH_BUTTON_SELECT
        lda #$09                ; =>
        sta text_offset + JOYH_BUTTON_START
        lda #$B2                ; <>
        sta text_offset + JOYH_BUTTON_HOME

.macro indicator_0 offset, mask
        txa
        and #mask
        beq :+                  ; if pressed
        lda #bg_color
        sta bkgnd_offset + offset
        lda #fg_color
        sta color_offset + offset
        bra :++
:       lda #on_bg_color
        sta bkgnd_offset + offset
        lda #on_fg_color
        sta color_offset + offset
:
.endmacro
.macro indicator_1 offset, mask
        txa
        and #mask
        bne :+                  ; if pressed
        lda #bg_color
        sta bkgnd_offset + offset
        lda #fg_color
        sta color_offset + offset
        bra :++
:       lda #on_bg_color
        sta bkgnd_offset + offset
        lda #on_fg_color
        sta color_offset + offset
:
.endmacro

.macro  write_hex_char
        ora #$30                ; '0'..'9' or ':'..'?'
        cmp #$3A                ; ':' = '9'+1
        bcc :+                  ; 0..9 done
        adc #$06                ; carry=1 from CMP -> add 7 => 'A'..'F'
:       sta text_offset,x
        inx
.endmacro

mainloop:
        ldx GPIO::in0
        indicator_0 JOY0_UP,       %00000001
        indicator_0 JOY0_DOWN,     %00000010
        indicator_0 JOY0_LEFT,     %00000100
        indicator_0 JOY0_RIGHT,    %00001000
        indicator_0 JOY0_BUTTON_A, %00100000
        indicator_0 JOY0_BUTTON_B, %10000000
        indicator_0 JOY0_BUTTON_X, %00010000
        indicator_0 JOY0_BUTTON_Y, %01000000

        ldx GPIO::in1
        indicator_0 JOY1_UP,       %00000001
        indicator_0 JOY1_DOWN,     %00000010
        indicator_0 JOY1_LEFT,     %00000100
        indicator_0 JOY1_RIGHT,    %00001000
        indicator_0 JOY1_BUTTON_A, %00100000
        indicator_0 JOY1_BUTTON_B, %10000000
        indicator_0 JOY1_BUTTON_X, %00010000
        indicator_0 JOY1_BUTTON_Y, %01000000

        ; select gamepad HID device
        store #RIA_HID_DEV_GAMEPAD, HID::d0
        lda HID::d0
        bmi :+
        ; no gamepad connected
        ; TODO: print message
        jmp kbd

:       ; gamepad 0 (merged) is active - at least one pad connected
        and #$0F                ; mask direction pad
        ora HID::d1             ; merge with sticks
        tax
        indicator_1 JOYH_UP,       %00000001
        indicator_1 JOYH_DOWN,     %00000010
        indicator_1 JOYH_LEFT,     %00000100
        indicator_1 JOYH_RIGHT,    %00001000
        ldx HID::d2
        indicator_1 JOYH_BUTTON_A, %00000001
        indicator_1 JOYH_BUTTON_B, %00000010
        indicator_1 JOYH_BUTTON_C, %00000100
        indicator_1 JOYH_BUTTON_X, %00001000
        indicator_1 JOYH_BUTTON_Y, %00010000
        indicator_1 JOYH_BUTTON_Z, %00100000
        indicator_1 JOYH_BUTTON_L, %01000000
        indicator_1 JOYH_BUTTON_R, %10000000
        ldx HID::d3
        indicator_1 JOYH_BUTTON_L2,     %00000001
        indicator_1 JOYH_BUTTON_R2,     %00000010
        indicator_1 JOYH_BUTTON_SELECT, %00000100
        indicator_1 JOYH_BUTTON_START,  %00001000
        indicator_1 JOYH_BUTTON_HOME,   %00010000
        indicator_1 JOYH_BUTTON_L3,     %00100000
        indicator_1 JOYH_BUTTON_R3,     %01000000
kbd:
        _i16
        ; select keyboard device page 0
        store #RIA_HID_DEV_KEYBOARD, HID::d0
        ldx #KBD_OFFSET+KBD_ROW+text_columns*2
        jsr kbd_dump_page
        ; and page 1
        store #RIA_HID_DEV_KEYBOARD | $10, HID::d0
        ldx #KBD_OFFSET+KBD_ROW+text_columns*3
        jsr kbd_dump_page

        _i8
        jmp mainloop

.proc kbd_dump_page
.i16
        ldy #0
loop:
        lda HID::d0,y
        and #$0F
        write_hex_char
        dex
        dex
        lda HID::d0,y
        lsrx 4
        write_hex_char
        dex
        dex
        iny
        lda HID::d0,y
        and #$0F
        write_hex_char
        dex
        dex
        lda HID::d0,y
        lsrx 4
        write_hex_char
        dex
        dex
        dex
        iny
        cpy #16
        bne loop
        rts
.endproc

; CGIA setup
text_offset  = $d000
chgen_offset = $d800
color_offset = $e000
bkgnd_offset = $e800

.include "../cgia/cgia_init.inc"
