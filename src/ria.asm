.struct RIA
    .org    $FFC0

    ; math accelerator
    opera       .word
    operb       .word
    mulab       .word
    divab       .word

    ; monotonic clock
    tm          .byte 6
    _tm_res     .byte 2

    ; DMA
    addr_src    .faraddr
    step_src    .byte
    addr_dst    .faraddr
    step_dst    .byte
    count       .byte
    dma_err     .byte

    ; file access
    fda         .byte
    fdb         .byte
    fda_rw      .byte
    fdb_rw      .byte
    fda_st      .byte
    fdb_st      .byte

    ; UART
    uart_rdy    .byte
    uart_rxtx   .byte

    ; Random Number Generator
    rng         .word

    ; CPU Vectors (Native)
    cop_n       .addr
    brk_n       .addr
    abort_n     .addr
    nmi_n       .addr

    ; RIA interrupts sources enable
    irq_enable  .byte
    ; Interrupt Controller IRQ status
    irq_status  .byte

    ; CPU Vector (Native)
    irq_n       .addr

    ; RIA816 API
    op          .word
    stack       .byte
    status      .byte

    ; CPU Vector (Emulation)
    cop_e       .addr

    ; Extension devices
    extio       .byte
    extmem      .byte

    ; CPU Vector (Emulation)
    abort_e     .addr
    nmi_e       .addr
    reset_e     .addr
    irq_brk_e   .addr
.endstruct

.struct HID
    .org    $FFB0
    ; HID devices
    d0          .byte           ; Write: select device / Read: device dependent 0
    d1          .byte           ; ^^^^^  select: [ AAAA DDDD ]
    d2          .byte           ;        D - device type, A - device address/index
    d3          .byte
    d4          .byte
    d5          .byte
    d6          .byte
    d7          .byte
    d8          .byte
    d9          .byte
    d10         .byte
    d11         .byte
    d12         .byte
    d13         .byte
    d14         .byte
    d15         .byte
.endstruct

.struct TIMERS
    .org    $FF98
    ; CIA compatible timers
    ta_lo       .byte
    ta_hi       .byte
    tb_lo       .byte
    tb_hi       .byte
    _t_res      .byte
    icr         .byte
    cra         .byte
    crb         .byte
.endstruct

.struct GPIO
    .org    $FF80
    ; GPIO ports
    in0         .byte
    in1         .byte
    out0        .byte
    out1        .byte
    pol0        .byte
    pol1        .byte
    cfg0        .byte
    cfg1        .byte
.endstruct

.define RIA_HID_DEV_KEYBOARD $00
.define RIA_HID_DEV_MOUSE    $01
.define RIA_HID_DEV_GAMEPAD  $02

RIA_API_HALT        = $FF
RIA_API_ZXSTACK     = $00
RIA_API_GET_CHARGEN = $10
