; **************************************************************************************
;
;                               Open simple text window
;
; **************************************************************************************

        textWidth  = 48
        textHeight = 30
        textSize   = textWidth * textHeight

        dispCharacters = $4000
        dispForeground = dispCharacters + $0800
        dispBackground = dispCharacters + $1000
        dispFontData   = dispCharacters + $1800

        .include    "text.inc"

        .autsiz                                     ; generate code based on last REP/SEP
;
;       Start code at $200 (e.g. above zero page and stack)
;
ProgramStart = $200

        * = ProgramStart-6
        .word   $FFFF                               ; first word of XEX file
        .word   ProgramStart                        ; first byte to copy
        .word   ProgramEnd-1                        ; last byte to copy


;
;       This is the main code block.
;
        clc                                         ; switch to 65816 mode
        xce

        sep     #$30                                ; 8 bit AXY


        stz     CGIA_Mode                           ; initialize CGIA
        stz     CGIA_Planes

        
        ldx     #$7F                                ; clear all CGIA registers
_ClearCGIA:
        stz     CGIA,x
        dex
        bpl     _ClearCGIA

        phb                                         ; fetch character generator from RIA firmware
        pla
        sta     RIA_Stack                           ; bank address
        lda     #>dispFontData                      ; high byte
        sta     RIA_Stack
        lda     #<dispFontData                      ; low byte
        sta     RIA_Stack
        lda     #RIA_API_GET_CHARGEN                ; execute get font.
        sta     RIA_Op

        sep     #$20                                ; X 16 A 8
        rep     #$10
        ldx     #textSize-1                         ; fill with test text.
_FillMe:
        txa     
        sta     dispCharacters,x
        sta     dispForeground,x
        eor     #$44
        sta     dispBackground,x
        dex
        bne     _FillMe        

        
        rep     #$30                                ; set display list offset
        lda     #dspl_display_list
        sta     CGIA_Offset0

        sep     #$30
        
        lda     #7                                  ; set row height to 8 pixels
        sta     CGIA_Plane0+CGIAP_RowHeight

        lda     #%00000001                          ; and finally enable the plane
        sta     CGIA_Planes

h1:     jmp     h1

dspl_display_list:
        .byte   CGIA_DL_IN_LOAD_SCAN | CGIA_DL_IN_LMS|CGIA_DL_IN_LFS|CGIA_DL_IN_LBS|CGIA_DL_IN_LCG
        .word   dispCharacters
        .word   dispForeground
        .word   dispBackground
        .word   dispFontData
        .rept   30
        .byte   CGIA_DL_IN_MODE2
        .endrept
        .byte   CGIA_DL_IN_JUMP | CGIA_DL_IN_VBL
        .word   dspl_display_list

ProgramEnd:
    
;
;       The vector block follows, loaded into $FFE0 ... $FFFF
;
        .word   $FFE0
        .word   $FFFF
        .word   0, 0, 0, 0, 0, 0, 0, 0
        .word   0, 0, 0, 0, 0, 0, ProgramStart, 0
        