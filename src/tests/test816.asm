.p816       ; 65816 processor
.smart +    ; 8/16 smart mode

.segment "INFO"
    .byte "8/16 test"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, reset, 0

source = $0010
dest = $0020

.segment "CODE"
reset:
    clc
    xce
    rep #%00000011
    sep #%11000000
    lda #1
    xba
    lda #2
    xba
    lda #0
    xba
    ; wai

    ora $12,s
    lda ($23)
    pea $1234
    pei ($78)
    per reset

    bra :+
    jml ($ABCD)
:   lda [$34]
    lda [$56],y
    lda ($34,s),y

    ldx #15
    brl loop
loop:
    lda numbers,x
    sta source,x
    dex
    bpl loop

    bra jump

    lda #$ff
    sta $01
jump:
    ldx #<source
    ldy #<dest
    lda #15
    mvn 0,0

    ; set 16-bit accumulator
    rep #%00100000
    lda #$1234
    ; set 16-bit index
    rep #%00010000
    ldx #$5678
    ldy #$9abc

    sta $0030
    stx $0032
    sty $0034

    ; get back to 8-bit accumulator and index
    sep #%00110000
    sta $0038
    stx $003a
    sty $003c

    lda #$ff
    sta $0040
    sta $0042
    sta $0050
    sta $0052
    stz $0044
    stz $0046
    inc A
    sta $0048
    dec A
    sta $004a

    inc $0050
    dec $0052
    inc $0100
    dec $0102
    rep #%00100000  ; a16

    lda $0032

    lda #$FFFF
    sta $0054
    sta $0104
    lda #0
    sta $0056
    sta $0106
    dec A
    sta $004c
    inc A
    sta $004f
    inc $0054
    dec $0056
    inc $0104
    dec $0106

    ldx #0
    dex
    txy
    inx
    iny
    dey
    rep #%00010000  ; i16
    dex
    txy
    inx
    iny
    dey

    lda $0030
    clc
    adc $0032
    sta $0060
    lda $0032
    sec
    sbc $0030
    sta $0070
    lda $0034
    sta $0078
    sta $007a
    clc
    ror $0078

    sep #%00100000  ; a8
    lda $0030
    clc
    adc $0032
    sta $0062
    lda $0032
    sec
    sbc $0030
    sta $0072
    lda $0034
    sta $007c
    clc
    ror $007a
    clc
    ror $007c

forever:
    wdm $24
    jmp forever
    bcc forever

numbers:
    .byte $01,$10,$02,$20,$03,$30,$04,$40,$05,$50,$06,$60,$07,$70,$08,$80

