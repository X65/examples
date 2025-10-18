.macro write_binary_char
        bmi :+
        lda #'0'
        sta text_offset,x
        bra :++
:       lda #'1'
        sta text_offset,x
:       inx
.endmacro

write_binary:
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        tay
        write_binary_char
        tya
        asl
        write_binary_char
        rts
