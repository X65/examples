; simple copy-value-via-accumulator helper
.macro store value, address
    lda value
    sta address
.endmacro

; helpers for setting accumulator and index registers width
.macro _a8
    sep #%00100000  ; 8-bit accumulator
    .a8
.endmacro
.macro _a16
    rep #%00100000  ; 16-bit accumulator
    .a16
.endmacro
.macro _i8
    sep #%00010000  ; 8-bit index
    .i8
.endmacro
.macro _i16
    rep #%00010000  ; 16-bit index
    .i16
.endmacro
