.include "../cgia.asm"
.include "../ria.asm"
.include "../macros.asm"

.segment "INFO"
    .byte "80 column text demo"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, 0

.setcpu "65816"

; CGIA setup
text_offset  = $d000
.define text_columns 40
.define text_rows    25
bg_color = 145
fg_color = 150

.code
.a8
.i8
        ; stop interrupts handling
        sei
        ; clear decimal mode
        cld
        ; stack pointer
        ldx #$ff
        txs

        ; go native mode
        clc
        xce

        ; stop all planes
        stz CGIA::planes

        _ai16
        ; clear all CGIA registers
        stz CGIA::mode
        ldx #CGIA::mode
        ldy #CGIA::mode+2
        lda #.sizeof(CGIA)-3
        mvn 0,0

        ; setup text plane
        ldx #cgia_planes
        ldy #CGIA::plane0
        lda #CGIA_PLANE_REGS_NO-1
        mvn 0,0
        store #display_list, CGIA::offset0

        _a8
        ldy #text_columns*text_rows-1
:       tya
        sta text_offset,y
        dey
        bpl :-
        _a16

        ; sync to vblank
:       lda CGIA::raster
        bne :-

        _ai8
        ; set border color
        store #bg_color, CGIA::back_color

        ; enable text plane 0
        store #%00000001, CGIA::planes

loop:
        bra loop

cgia_planes:
.byte $00,4,7,$00,$00,$00,$00,$00,bg_color,$ff,$7f,fg_color,$f8,$fa,$fc,$fe

display_list:
.byte   CGIA_DL_INS_LOAD_MEMORY | CGIA_DL_INS_LM_MEMORY_SCAN|CGIA_DL_INS_LM_CHARACTER_GENERATOR
.word   text_offset
.word   chgen_offset
.byte   $70, $70, $30
.repeat text_rows
.byte   CGIA_DL_MODE_PALETTE_TEXT | CGIA_DL_MULTICOLOR_BIT
.endrep
.byte   CGIA_DL_INS_JUMP|CGIA_DL_INS_DL_INTERRUPT
.word   display_list

chgen_offset:
.byte   $00, $00, $00, $00, $00, $00, $00, $00    ; 00
.byte   $3c, $c3, $ff, $c3, $c3, $ff, $c3, $3c    ; 01
.byte   $3c, $ff, $c3, $ff, $ff, $c3, $ff, $3c    ; 02
.byte   $00, $cc, $fc, $fc, $fc, $30, $30, $00    ; 03
.byte   $3c, $c3, $f3, $f3, $ff, $c3, $3f, $fc    ; 04
.byte   $30, $3c, $3c, $30, $30, $f0, $f0, $c0    ; 05
.byte   $30, $3c, $33, $33, $33, $ff, $cc, $30    ; 06
.byte   $30, $fc, $fc, $fc, $fc, $ff, $30, $3c    ; 07
.byte   $30, $30, $fc, $fc, $fc, $30, $30, $00    ; 08
.byte   $00, $33, $33, $3f, $ff, $33, $33, $00    ; 09
.byte   $c0, $c0, $fc, $f0, $fc, $30, $30, $00    ; 0a
.byte   $00, $30, $30, $cc, $cc, $30, $30, $00    ; 0b
.byte   $f0, $c0, $fc, $f0, $fc, $30, $30, $00    ; 0c
.byte   $f0, $c0, $ff, $f3, $ff, $3c, $33, $00    ; 0d
.byte   $0f, $03, $0f, $3c, $cc, $cc, $cc, $30    ; 0e
.byte   $30, $cc, $cc, $cc, $30, $30, $fc, $30    ; 0f
.byte   $fc, $cc, $cc, $00, $cc, $cc, $fc, $00    ; 10
.byte   $0c, $0c, $0c, $00, $0c, $0c, $0c, $00    ; 11
.byte   $fc, $0c, $0c, $fc, $c0, $c0, $fc, $00    ; 12
.byte   $fc, $0c, $0c, $fc, $0c, $0c, $fc, $00    ; 13
.byte   $cc, $cc, $cc, $fc, $0c, $0c, $0c, $00    ; 14
.byte   $fc, $c0, $c0, $fc, $0c, $0c, $fc, $00    ; 15
.byte   $fc, $c0, $c0, $fc, $cc, $cc, $fc, $00    ; 16
.byte   $fc, $0c, $0c, $00, $0c, $0c, $0c, $00    ; 17
.byte   $fc, $cc, $cc, $fc, $cc, $cc, $fc, $00    ; 18
.byte   $fc, $cc, $cc, $fc, $0c, $0c, $fc, $00    ; 19
.byte   $30, $30, $fc, $fc, $cc, $30, $30, $00    ; 1a
.byte   $f0, $c0, $f0, $c0, $fc, $30, $3c, $00    ; 1b
.byte   $30, $0c, $fc, $c3, $c3, $fc, $0c, $30    ; 1c
.byte   $0c, $30, $3f, $c3, $c3, $3f, $30, $0c    ; 1d
.byte   $3c, $3c, $c3, $c3, $ff, $3c, $3c, $3c    ; 1e
.byte   $3c, $3c, $ff, $ff, $c3, $c3, $3c, $3c    ; 1f
.byte   $00, $00, $00, $00, $00, $00, $00, $00    ; 20
.byte   $30, $30, $30, $30, $30, $00, $30, $00    ; 21
.byte   $cc, $cc, $cc, $00, $00, $00, $00, $00    ; 22
.byte   $00, $cc, $fc, $cc, $cc, $fc, $cc, $00    ; 23
.byte   $30, $3c, $c0, $3c, $0c, $fc, $30, $00    ; 24
.byte   $0c, $cc, $cc, $30, $30, $cc, $cc, $c0    ; 25
.byte   $30, $cc, $30, $f0, $fc, $cc, $fc, $00    ; 26
.byte   $30, $30, $30, $00, $00, $00, $00, $00    ; 27
.byte   $0c, $30, $30, $30, $30, $30, $0c, $00    ; 28
.byte   $c0, $30, $30, $30, $30, $30, $c0, $00    ; 29
.byte   $00, $cc, $30, $fc, $30, $cc, $00, $00    ; 2a
.byte   $00, $30, $30, $fc, $30, $30, $00, $00    ; 2b
.byte   $00, $00, $00, $00, $00, $30, $30, $c0    ; 2c
.byte   $00, $00, $00, $fc, $00, $00, $00, $00    ; 2d
.byte   $00, $00, $00, $00, $00, $30, $30, $00    ; 2e
.byte   $00, $0c, $0c, $30, $30, $c0, $c0, $00    ; 2f
.byte   $30, $cc, $cc, $fc, $cc, $cc, $30, $00    ; 30
.byte   $30, $30, $30, $30, $30, $30, $30, $00    ; 31
.byte   $30, $cc, $0c, $3c, $c0, $cc, $fc, $00    ; 32
.byte   $30, $cc, $0c, $30, $0c, $cc, $30, $00    ; 33
.byte   $0c, $3c, $cc, $cc, $fc, $0c, $0c, $00    ; 34
.byte   $fc, $c0, $c0, $f0, $0c, $cc, $30, $00    ; 35
.byte   $30, $cc, $c0, $fc, $cc, $cc, $30, $00    ; 36
.byte   $fc, $cc, $0c, $0c, $30, $30, $30, $00    ; 37
.byte   $30, $cc, $cc, $30, $cc, $cc, $30, $00    ; 38
.byte   $30, $cc, $cc, $3c, $0c, $cc, $30, $00    ; 39
.byte   $00, $30, $30, $00, $30, $30, $00, $00    ; 3a
.byte   $00, $30, $30, $00, $30, $30, $30, $00    ; 3b
.byte   $00, $0c, $30, $c0, $c0, $30, $0c, $00    ; 3c
.byte   $00, $00, $fc, $00, $00, $fc, $00, $00    ; 3d
.byte   $00, $c0, $30, $0c, $0c, $30, $c0, $00    ; 3e
.byte   $30, $cc, $0c, $0c, $30, $00, $30, $00    ; 3f
.byte   $30, $fc, $cc, $fc, $f0, $c0, $3c, $00    ; 40
.byte   $30, $fc, $cc, $cc, $fc, $cc, $cc, $00    ; 41
.byte   $f0, $cc, $cc, $f0, $cc, $cc, $f0, $00    ; 42
.byte   $30, $cc, $c0, $c0, $c0, $cc, $30, $00    ; 43
.byte   $f0, $cc, $cc, $cc, $cc, $cc, $f0, $00    ; 44
.byte   $fc, $c0, $c0, $f0, $c0, $c0, $fc, $00    ; 45
.byte   $fc, $c0, $c0, $f0, $c0, $c0, $c0, $00    ; 46
.byte   $30, $cc, $c0, $fc, $cc, $cc, $3c, $00    ; 47
.byte   $cc, $cc, $cc, $fc, $cc, $cc, $cc, $00    ; 48
.byte   $fc, $30, $30, $30, $30, $30, $fc, $00    ; 49
.byte   $0c, $0c, $0c, $0c, $0c, $cc, $30, $00    ; 4a
.byte   $cc, $cc, $cc, $f0, $cc, $cc, $cc, $00    ; 4b
.byte   $c0, $c0, $c0, $c0, $c0, $c0, $fc, $00    ; 4c
.byte   $cc, $fc, $fc, $cc, $cc, $cc, $cc, $00    ; 4d
.byte   $cc, $cc, $fc, $fc, $fc, $cc, $cc, $00    ; 4e
.byte   $30, $cc, $cc, $cc, $cc, $cc, $30, $00    ; 4f
.byte   $f0, $cc, $cc, $f0, $c0, $c0, $c0, $00    ; 50
.byte   $30, $cc, $cc, $cc, $cc, $cc, $30, $0c    ; 51
.byte   $f0, $cc, $cc, $f0, $cc, $cc, $cc, $00    ; 52
.byte   $30, $cc, $c0, $30, $0c, $cc, $30, $00    ; 53
.byte   $fc, $30, $30, $30, $30, $30, $30, $00    ; 54
.byte   $cc, $cc, $cc, $cc, $cc, $cc, $30, $00    ; 55
.byte   $cc, $cc, $cc, $cc, $cc, $30, $30, $00    ; 56
.byte   $cc, $cc, $cc, $fc, $fc, $fc, $cc, $00    ; 57
.byte   $cc, $cc, $30, $30, $30, $cc, $cc, $00    ; 58
.byte   $cc, $cc, $cc, $30, $30, $30, $30, $00    ; 59
.byte   $fc, $0c, $0c, $30, $c0, $c0, $fc, $00    ; 5a
.byte   $3c, $30, $30, $30, $30, $30, $3c, $00    ; 5b
.byte   $c0, $c0, $30, $30, $0c, $0c, $00, $00    ; 5c
.byte   $f0, $30, $30, $30, $30, $30, $f0, $00    ; 5d
.byte   $30, $30, $cc, $cc, $00, $00, $00, $00    ; 5e
.byte   $00, $00, $00, $00, $00, $00, $fc, $00    ; 5f
.byte   $00, $c0, $c0, $30, $00, $00, $00, $00    ; 60
.byte   $00, $00, $30, $0c, $3c, $cc, $3c, $00    ; 61
.byte   $c0, $c0, $f0, $cc, $cc, $cc, $f0, $00    ; 62
.byte   $00, $00, $30, $cc, $c0, $cc, $30, $00    ; 63
.byte   $0c, $0c, $3c, $cc, $cc, $cc, $3c, $00    ; 64
.byte   $00, $00, $30, $cc, $f0, $c0, $3c, $00    ; 65
.byte   $0f, $30, $30, $3c, $30, $30, $30, $00    ; 66
.byte   $00, $00, $3c, $cc, $cc, $3c, $0c, $30    ; 67
.byte   $c0, $c0, $f0, $cc, $cc, $cc, $cc, $00    ; 68
.byte   $30, $00, $30, $30, $30, $30, $0c, $00    ; 69
.byte   $0c, $00, $0c, $0c, $0c, $0c, $0c, $30    ; 6a
.byte   $c0, $c0, $cc, $cc, $f0, $cc, $cc, $00    ; 6b
.byte   $30, $30, $30, $30, $30, $30, $0c, $00    ; 6c
.byte   $00, $00, $cc, $fc, $fc, $cc, $cc, $00    ; 6d
.byte   $00, $00, $f0, $cc, $cc, $cc, $cc, $00    ; 6e
.byte   $00, $00, $30, $cc, $cc, $cc, $30, $00    ; 6f
.byte   $00, $00, $f0, $cc, $cc, $f0, $c0, $c0    ; 70
.byte   $00, $00, $3c, $cc, $cc, $3c, $0c, $0c    ; 71
.byte   $00, $00, $f0, $cc, $c0, $c0, $c0, $00    ; 72
.byte   $00, $00, $3c, $c0, $3c, $0c, $f0, $00    ; 73
.byte   $30, $30, $fc, $30, $30, $30, $0c, $00    ; 74
.byte   $00, $00, $cc, $cc, $cc, $cc, $30, $00    ; 75
.byte   $00, $00, $cc, $cc, $cc, $30, $30, $00    ; 76
.byte   $00, $00, $cc, $cc, $fc, $fc, $cc, $00    ; 77
.byte   $00, $00, $cc, $cc, $30, $cc, $cc, $00    ; 78
.byte   $00, $00, $cc, $cc, $cc, $3c, $0c, $3c    ; 79
.byte   $00, $00, $fc, $0c, $30, $c0, $fc, $00    ; 7a
.byte   $3c, $30, $30, $c0, $30, $30, $3c, $00    ; 7b
.byte   $30, $30, $30, $00, $30, $30, $30, $00    ; 7c
.byte   $f0, $30, $30, $0c, $30, $30, $f0, $00    ; 7d
.byte   $00, $00, $33, $cc, $00, $00, $00, $00    ; 7e
.byte   $00, $30, $30, $cc, $cc, $cc, $fc, $00    ; 7f
.byte   $00, $00, $00, $00, $00, $00, $00, $00    ; 80
.byte   $00, $00, $00, $00, $00, $00, $00, $ff    ; 81
.byte   $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0    ; 82
.byte   $00, $00, $00, $00, $00, $00, $ff, $ff    ; 83
.byte   $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0    ; 84
.byte   $00, $00, $00, $00, $00, $ff, $ff, $ff    ; 85
.byte   $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0    ; 86
.byte   $00, $00, $00, $00, $ff, $ff, $ff, $ff    ; 87
.byte   $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0    ; 88
.byte   $00, $00, $00, $ff, $ff, $ff, $ff, $ff    ; 89
.byte   $fc, $fc, $fc, $fc, $fc, $fc, $fc, $fc    ; 8a
.byte   $00, $00, $ff, $ff, $ff, $ff, $ff, $ff    ; 8b
.byte   $fc, $fc, $fc, $fc, $fc, $fc, $fc, $fc    ; 8c
.byte   $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff    ; 8d
.byte   $00, $3c, $fc, $fc, $fc, $fc, $3c, $00    ; 8e
.byte   $00, $3c, $fc, $cc, $cc, $fc, $3c, $00    ; 8f
.byte   $c0, $c0, $0c, $0c, $c0, $c0, $0c, $0c    ; 90
.byte   $cc, $cc, $33, $33, $cc, $cc, $33, $33    ; 91
.byte   $cc, $cc, $33, $33, $cc, $cc, $33, $33    ; 92
.byte   $33, $cc, $cc, $33, $33, $cc, $cc, $03    ; 93
.byte   $c0, $c0, $30, $30, $c0, $c0, $30, $30    ; 94
.byte   $00, $00, $00, $00, $cc, $cc, $33, $33    ; 95
.byte   $f0, $f0, $f0, $f0, $0f, $0f, $0f, $0f    ; 96
.byte   $f0, $f0, $f0, $f0, $00, $00, $00, $00    ; 97
.byte   $0f, $0f, $0f, $0f, $00, $00, $00, $00    ; 98
.byte   $00, $00, $00, $00, $f0, $f0, $f0, $f0    ; 99
.byte   $00, $00, $00, $00, $0f, $0f, $0f, $0f    ; 9a
.byte   $30, $30, $3c, $c0, $c0, $3c, $30, $30    ; 9b
.byte   $3c, $cc, $c0, $f0, $c0, $c0, $fc, $00    ; 9c
.byte   $cc, $cc, $3c, $30, $3c, $30, $30, $00    ; 9d
.byte   $3c, $cc, $f0, $c0, $f0, $cc, $3c, $00    ; 9e
.byte   $3c, $30, $fc, $30, $30, $30, $c0, $00    ; 9f
.byte   $30, $30, $3c, $3f, $0f, $00, $00, $00    ; a0
.byte   $30, $30, $30, $f0, $f0, $00, $00, $00    ; a1
.byte   $00, $00, $00, $f0, $f0, $30, $30, $30    ; a2
.byte   $00, $00, $00, $0f, $3f, $3c, $30, $30    ; a3
.byte   $0c, $0c, $03, $03, $0c, $0c, $03, $03    ; a4
.byte   $cc, $cc, $33, $33, $00, $00, $00, $00    ; a5
.byte   $cc, $cc, $30, $30, $30, $cc, $cc, $00    ; a6
.byte   $03, $03, $0c, $cc, $f0, $30, $00, $00    ; a7
.byte   $00, $30, $00, $30, $30, $c0, $cc, $30    ; a8
.byte   $00, $00, $00, $3c, $30, $30, $30, $00    ; a9
.byte   $00, $00, $00, $3c, $0c, $0c, $0c, $00    ; aa
.byte   $cc, $cc, $f0, $3c, $c3, $c3, $0c, $0f    ; ab
.byte   $cc, $cc, $f0, $3c, $cc, $fc, $3f, $0c    ; ac
.byte   $00, $30, $00, $30, $30, $30, $30, $30    ; ad
.byte   $33, $33, $cc, $f0, $cc, $33, $33, $00    ; ae
.byte   $cc, $cc, $33, $0f, $33, $cc, $cc, $00    ; af
.byte   $00, $00, $00, $00, $00, $00, $00, $00    ; b0
.byte   $00, $ff, $00, $ff, $00, $ff, $00, $ff    ; b1
.byte   $30, $3c, $cc, $c3, $cc, $3c, $30, $00    ; b2
.byte   $30, $30, $30, $30, $30, $30, $30, $30    ; b3
.byte   $30, $30, $30, $f0, $f0, $30, $30, $30    ; b4
.byte   $c0, $c0, $c0, $c0, $c0, $c0, $ff, $ff    ; b5
.byte   $03, $03, $03, $03, $03, $03, $ff, $ff    ; b6
.byte   $ff, $ff, $03, $03, $03, $03, $03, $03    ; b7
.byte   $ff, $ff, $c0, $c0, $c0, $c0, $c0, $c0    ; b8
.byte   $cc, $00, $00, $00, $00, $00, $00, $00    ; b9
.byte   $0c, $30, $30, $00, $00, $00, $00, $00    ; ba
.byte   $00, $30, $fc, $30, $30, $30, $00, $00    ; bb
.byte   $f3, $f3, $f3, $f3, $f3, $33, $33, $33    ; bc
.byte   $3c, $c3, $ff, $f3, $f3, $ff, $c3, $3c    ; bd
.byte   $3c, $c3, $ff, $ff, $f3, $ff, $c3, $3c    ; be
.byte   $00, $f3, $cf, $00, $00, $00, $00, $00    ; bf
.byte   $30, $30, $30, $3f, $3f, $00, $00, $00    ; c0
.byte   $30, $30, $30, $ff, $ff, $00, $00, $00    ; c1
.byte   $00, $00, $00, $ff, $ff, $30, $30, $30    ; c2
.byte   $30, $30, $30, $3f, $3f, $30, $30, $30    ; c3
.byte   $00, $00, $00, $ff, $ff, $00, $00, $00    ; c4
.byte   $30, $30, $30, $ff, $ff, $30, $30, $30    ; c5
.byte   $ff, $fc, $fc, $f0, $f0, $c0, $c0, $00    ; c6
.byte   $ff, $ff, $3f, $3f, $0f, $0f, $03, $03    ; c7
.byte   $ff, $fc, $3c, $30, $00, $00, $00, $00    ; c8
.byte   $03, $03, $0f, $0f, $0f, $0f, $03, $03    ; c9
.byte   $00, $00, $00, $00, $30, $3c, $fc, $ff    ; ca
.byte   $00, $c0, $c0, $f0, $f0, $c0, $c0, $00    ; cb
.byte   $ff, $fc, $3c, $30, $30, $3c, $fc, $ff    ; cc
.byte   $c3, $cf, $fc, $3c, $3c, $fc, $cf, $c3    ; cd
.byte   $03, $0f, $0c, $3c, $30, $f0, $c0, $c0    ; ce
.byte   $c0, $c0, $f0, $30, $3c, $0c, $0f, $03    ; cf
.byte   $30, $30, $30, $30, $30, $30, $30, $30    ; d0
.byte   $00, $00, $00, $00, $ff, $ff, $00, $00    ; d1
.byte   $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0    ; d2
.byte   $00, $00, $00, $00, $00, $ff, $ff, $00    ; d3
.byte   $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c    ; d4
.byte   $00, $00, $ff, $ff, $00, $00, $00, $00    ; d5
.byte   $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c    ; d6
.byte   $00, $ff, $ff, $00, $00, $00, $00, $00    ; d7
.byte   $00, $00, $00, $f0, $f0, $30, $30, $30    ; d8
.byte   $30, $30, $30, $f0, $f0, $00, $00, $00    ; d9
.byte   $00, $00, $00, $3f, $3f, $30, $30, $30    ; da
.byte   $00, $00, $3c, $3c, $3c, $3c, $00, $00    ; db
.byte   $cc, $cc, $cc, $cc, $cc, $00, $cc, $00    ; dc
.byte   $0c, $33, $3c, $cc, $cc, $3c, $f0, $30    ; dd
.byte   $00, $30, $30, $cc, $cc, $00, $00, $00    ; de
.byte   $cc, $ff, $f3, $f3, $ff, $cc, $00, $00    ; df
.byte   $00, $00, $3c, $fc, $f0, $fc, $3c, $00    ; e0
.byte   $00, $30, $cc, $f0, $cc, $cc, $f0, $c0    ; e1
.byte   $3c, $30, $30, $30, $30, $30, $30, $00    ; e2
.byte   $00, $00, $ff, $cc, $cc, $cc, $cc, $00    ; e3
.byte   $fc, $cc, $c0, $30, $c0, $cc, $fc, $00    ; e4
.byte   $00, $3c, $30, $cc, $cc, $cc, $30, $00    ; e5
.byte   $00, $00, $cc, $cc, $cc, $cc, $f3, $c0    ; e6
.byte   $00, $00, $3c, $30, $30, $30, $0c, $00    ; e7
.byte   $fc, $30, $30, $cc, $cc, $30, $30, $fc    ; e8
.byte   $00, $30, $cc, $fc, $cc, $cc, $30, $00    ; e9
.byte   $00, $30, $cc, $cc, $cc, $00, $cc, $00    ; ea
.byte   $00, $3c, $c0, $30, $cc, $cc, $30, $00    ; eb
.byte   $0c, $30, $30, $fc, $fc, $30, $30, $c0    ; ec
.byte   $00, $30, $fc, $fc, $fc, $fc, $fc, $30    ; ed
.byte   $3c, $f0, $c0, $fc, $c0, $f0, $3c, $00    ; ee
.byte   $30, $cc, $cc, $cc, $cc, $cc, $cc, $00    ; ef
.byte   $00, $fc, $00, $fc, $00, $fc, $00, $00    ; f0
.byte   $30, $30, $fc, $30, $30, $00, $fc, $00    ; f1
.byte   $c0, $30, $0c, $30, $c0, $00, $fc, $00    ; f2
.byte   $0c, $30, $c0, $30, $0c, $00, $fc, $00    ; f3
.byte   $00, $0c, $33, $33, $30, $30, $30, $30    ; f4
.byte   $0c, $0c, $0c, $0c, $cc, $cc, $30, $00    ; f5
.byte   $30, $30, $00, $fc, $00, $30, $30, $00    ; f6
.byte   $00, $33, $cc, $00, $33, $cc, $00, $00    ; f7
.byte   $30, $cc, $30, $00, $00, $00, $00, $00    ; f8
.byte   $30, $fc, $30, $00, $00, $00, $00, $00    ; f9
.byte   $00, $00, $00, $00, $30, $30, $00, $00    ; fa
.byte   $00, $00, $0f, $30, $f0, $f0, $30, $00    ; fb
.byte   $30, $cc, $cc, $cc, $cc, $00, $00, $00    ; fc
.byte   $30, $cc, $0c, $30, $fc, $00, $00, $00    ; fd
.byte   $f0, $0c, $30, $0c, $f0, $00, $00, $00    ; fe
.byte   $cc, $cc, $03, $f3, $f0, $f3, $33, $00    ; ff
