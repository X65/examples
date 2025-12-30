.a8
.i8

.macro  write_hex_char
        ora #$30                ; '0'..'9' or ':'..'?'
        cmp #$3A                ; ':' = '9'+1
        bcc :+                  ; 0..9 done
        adc #$06                ; carry=1 from CMP -> add 7 => 'A'..'F'
:       sta text_offset,x
        inx
.endmacro

write_hex:
        tay
        lsrx 4
        write_hex_char
        tya
        and #$0F
        write_hex_char
        rts
