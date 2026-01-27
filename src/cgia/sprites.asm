.include "../cgia.asm"

.segment "INFO"
    .byte "Sprites demo"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, nmi, reset, 0

.segment "LOWBSS"
sprite_descriptors:
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE
    .tag CGIA_SPRITE

.CODE
.define SPRITE_WIDTH   4
.define SPRITE_HEIGHT  26
.define SPRITE_COLOR_1 0
.define SPRITE_COLOR_2 23
.define SPRITE_COLOR_3 10

reset:
    sei                     ; disable IRQ

    ; disable all planes, so CGIA does not go haywire during reconfiguration
    lda #0
    sta CGIA::planes

    ; set border/background color
    lda #145
    sta CGIA::back_color

    ; configure plane0
    lda #<sprite_descriptors
    sta CGIA::offset0
    lda #>sprite_descriptors
    sta CGIA::offset0 + 1

    lda #%11111111  ; enable all 8 sprites
    sta CGIA::plane0 + CGIA_SPRITE_REGS::active
    lda #0          ; no border
    sta CGIA::plane0 + CGIA_SPRITE_REGS::border_columns
                    ; and allow sprites on whole screen
    sta CGIA::plane0 + CGIA_SPRITE_REGS::start_y
    sta CGIA::plane0 + CGIA_SPRITE_REGS::stop_y

    ; fill sprite descriptors table
    ldx #0
    ldy #0
sprites_loop:
    txa
    pha         ; store x for later

    tya
    asl         ; multiply x by 32
    asl
    asl
    asl
    asl
    sta sprite_descriptors, x   ; pos_x
    inx
    lda #0
    sta sprite_descriptors, x   ; pos_x
    inx

    lda #8
    sta sprite_descriptors, x   ; pos_y
    inx
    lda #0
    sta sprite_descriptors, x   ; pos_y
    inx

    lda #SPRITE_HEIGHT
    sta sprite_descriptors, x   ; lines_y
    inx
    lda #0
    sta sprite_descriptors, x   ; lines_y
    inx

    lda #(SPRITE_MASK_MULTICOLOR | (SPRITE_WIDTH-1))
    sta sprite_descriptors, x   ; flags
    inx

    inx     ; reserved

    lda #SPRITE_COLOR_1
    sta sprite_descriptors, x   ; color 01
    inx

    lda #SPRITE_COLOR_2
    sta sprite_descriptors, x   ; color 10
    inx

    lda #SPRITE_COLOR_3
    sta sprite_descriptors, x   ; color 11
    inx

    inx     ; reserved

    lda #<sprite_data
    sta sprite_descriptors, x   ; data_offset
    inx
    lda #>sprite_data
    sta sprite_descriptors, x   ; data_offset
    inx

    pla     ; pull stored x
    clc
    adc #<sprite_descriptors
    sta sprite_descriptors, x   ; next_dsc_offset
    inx
    lda #0
    adc #>sprite_descriptors
    sta sprite_descriptors, x   ; next_dsc_offset
    inx

    iny
    cpy #CGIA_SPRITES
    bne sprites_loop    ; fill next sprite descriptor

    ; modify sprites
    lda #%11111011 ;-5
    sta sprite_descriptors + 0*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x
    lda #$ff
    sta sprite_descriptors + 0*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
    lda #%11110110 ;-10
    sta sprite_descriptors + 1*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_y
    lda #$ff
    sta sprite_descriptors + 1*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_y + 1
    lda #(SPRITE_MASK_MIRROR_X | SPRITE_MASK_MIRROR_X | (SPRITE_WIDTH-1))
    sta sprite_descriptors + 2*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::flags
    lda #(SPRITE_MASK_MULTICOLOR | SPRITE_MASK_DOUBLE_WIDTH | (SPRITE_WIDTH-1))
    sta sprite_descriptors + 3*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::flags
    lda #(SPRITE_MASK_MULTICOLOR | SPRITE_MASK_MIRROR_X | (SPRITE_WIDTH-1))
    sta sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::flags
    lda #(SPRITE_MASK_MULTICOLOR | SPRITE_MASK_MIRROR_Y | (SPRITE_WIDTH-1))
    sta sprite_descriptors + 5*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::flags
    lda #(SPRITE_MASK_MULTICOLOR | (SPRITE_WIDTH-2))
    sta sprite_descriptors + 6*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::flags

    ; trigger NMI on VBL
    lda #%10000000
    sta CGIA::int_enable

    ; enable plane0 as sprites plane
    lda #%00010001
    sta CGIA::planes

forever:
    jmp forever ; do nothing more

nmi:
    ; ; delay
    ; inc $00
    ; lda $00
    ; cmp #60
    ; bne exit_nmi
    ; lda #0
    ; sta $0

    ; move sprite 4 -> v
    inc sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x
    inc sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x
    bne :+
    inc sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
    lda sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
    cmp #2
    bcc :+
    lda #0
    sta sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
:
    inc sprite_descriptors + 4*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_y

    ; move sprite 7 <- v
    dec sprite_descriptors + 7*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x
    lda sprite_descriptors + 7*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x
    cmp #$ff
    bne :+
    dec sprite_descriptors + 7*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
    bpl :+
    lda #1
    sta sprite_descriptors + 7*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_x + 1
:
    inc sprite_descriptors + 7*CGIA_SPRITE_DESC_LEN + CGIA_SPRITE::pos_y

exit_nmi:
    sta CGIA::int_status    ; ack interrupts
    rti         ; return from interrupt

.DATA
sprite_data:
    .byte %00000000, %00010101, %01000000, %00000000
    .byte %00000000, %01011111, %11010100, %00000000
    .byte %00000000, %01111111, %11111101, %00000000
    .byte %00000001, %01010101, %01111111, %01000000
    .byte %00000101, %01010101, %01011111, %11010000
    .byte %00000101, %10101010, %10100101, %11010000
    .byte %00000001, %10011001, %10101001, %01010100
    .byte %00000001, %10011001, %10101001, %01100100
    .byte %00000110, %10101010, %10100101, %01101001
    .byte %00000110, %10101010, %01101001, %10101001
    .byte %00010101, %10100101, %01011010, %10100100
    .byte %00000001, %01010101, %10101010, %01010000
    .byte %00000000, %01101010, %10100101, %01000000
    .byte %00010100, %01010101, %01011111, %11010000
    .byte %01101001, %01111101, %01111111, %11110100
    .byte %01100101, %11111101, %11010101, %11111101
    .byte %01100111, %11110101, %01101010, %01111101
    .byte %00010111, %11010101, %10101010, %10011101
    .byte %00011001, %01101001, %10101010, %10010100
    .byte %01111101, %01101001, %01101010, %01010000
    .byte %01111111, %01010101, %01010101, %11110100
    .byte %01111111, %01010101, %01010101, %01110101
    .byte %01111111, %01010101, %01010101, %01111101
    .byte %01011111, %01000000, %01010101, %01111101
    .byte %00010101, %00000000, %00000001, %01111101
    .byte %00000000, %00000000, %00000000, %00010100
