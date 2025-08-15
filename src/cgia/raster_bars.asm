.include "../cgia.asm"

.segment "INFO"
    .byte "Raster Bars demo"

.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, reset, 0

.segment "CODE"

.define FRAME_DELAY 2

reset:
    sei     ; we do not use interrupts in this demo

    ldx #FRAME_DELAY            ; init delay loop
    lda #0                      ; start with black color

forever:
    ldy #0                      ; wait for line 0 (actually starts in front porch)
:   cpy CGIA::raster            ; check if we are on 0 raster line
    bne :-                      ; loop if not
    sta CGIA::back_color        ; set background color
    iny                         ; wait for next line

wait:
    cpy CGIA::raster            ; check if we are on Y raster line
    bne wait                    ; loop if not

    inc CGIA::back_color        ; increase background color

    iny                         ; move to next raster line
    cpy #240                    ; check if we reached line 240
    bcc wait                    ; wait for next line if not

    dex                         ; delay moving the bars
    bne forever
    ldx #FRAME_DELAY            ; reload delay

    inc A                       ; start with next color

    jmp forever
