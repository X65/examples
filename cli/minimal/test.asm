; **************************************************************************************
;
;                      The worlds most simple test program.
;
; **************************************************************************************

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
        nop                                         ; so we can test the breakpoint.
        clc                                         ; switch to 65816 mode
        xce
        rep     #$30                                ; 16 bit AXY
        dec     a                                   ; A will be $FFFF hence 16 bit.
        ldx     #$ABCD

h1:     jmp     h1

ProgramEnd:
    
;
;       The vector block follows, loaded into $FFE0 ... $FFFF
;
        .word   $FFE0
        .word   $FFFF
        .word 0, 0, 0, 0, 0, 0, 0, 0
        .word 0, 0, 0, 0, 0, 0, ProgramStart, 0