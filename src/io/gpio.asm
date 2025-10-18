.include "../ria.asm"

.segment "INFO"
    .byte "GPIO extender demo"

.import __MAIN_START__
.segment "VECTORS"
    .word 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, __MAIN_START__, irq

.setcpu "65C02"

.code
        cli     ; enable IRQ

        ; lda #%00000010  ; enable IO interrupts
        ; sta RIA::irq_enable

loop:
        lda GPIO::in0
        sta $10
        lda GPIO::in1
        sta $11
        bra loop

irq:
        inc $12
        lda GPIO::in0           ; ACK Port0 interrupt
        lda GPIO::in1           ; ACK Port1 interrupt
        sta RIA::irq_status     ; ACK in Interrupt Controller
        rti
