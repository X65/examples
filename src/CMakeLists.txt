include_directories(.)

add_xex(test816)
target_sources(test816 PRIVATE
    tests/test816.asm
)

add_xex(swboy)
target_sources(swboy PRIVATE
    cgia/swboy.c
    reset_vector.asm
)
add_xex(raster_bars)
target_sources(raster_bars PRIVATE
    cgia/raster_bars.asm
)
add_xex(vbl)
target_sources(vbl PRIVATE
    cgia/vbl.asm
)
add_xex(rsi)
target_sources(rsi PRIVATE
    cgia/rsi.asm
)
add_xex(sprites)
target_sources(sprites PRIVATE
    cgia/sprites.asm
)
add_xex(sotb)
target_sources(sotb PRIVATE
    cgia/sotb.asm
)
add_xex(mixed_modes)
target_sources(mixed_modes PRIVATE
    cgia/mixed_modes.asm
)
add_xex(lkhs_raster_bar)
target_sources(lkhs_raster_bar PRIVATE
    cgia/lkhs_raster_bar.asm
)
add_xex(four_byte_burger)
target_sources(four_byte_burger PRIVATE
    cgia/four_byte_burger.asm
)
add_xex(mode0)
target_sources(mode0 PRIVATE
    cgia/mode0.asm
)
add_xex(text_modes)
target_sources(text_modes PRIVATE
    cgia/text_modes.asm
)
add_xex(text_80_columns)
target_sources(text_80_columns PRIVATE
    cgia/text_80_columns.asm
)
add_xex(bitmap_modes)
target_sources(bitmap_modes PRIVATE
    cgia/bitmap_modes.asm
)

# add_xex(pwm_samples)
# target_sources(pwm_samples PRIVATE
#     cgia/pwm_samples.asm
# )
add_xex(doremi)
target_sources(doremi PRIVATE
    sound/doremi.asm
)
add_xex(opl)
target_sources(opl PRIVATE
    sound/opl.asm
)
add_xex(MontyOnTheRun.sid)
target_sources(MontyOnTheRun.sid PRIVATE
    sound/MontyOnTheRun.asm
)
add_xex(Driller.sid)
target_sources(Driller.sid PRIVATE
    sound/Driller.asm
)

add_xex(hello_uart)
target_sources(hello_uart PRIVATE
    uart/hello.asm
)

add_xex(gpio)
target_sources(gpio PRIVATE
    io/gpio.asm
)

add_xex(controller)
target_sources(controller PRIVATE
    io/controller.asm
)

add_xex(irq)
target_sources(irq PRIVATE
    io/irq.asm
)

add_xex(ext)
target_sources(ext PRIVATE
    io/ext.asm
)

add_xex(bogo)
target_sources(bogo PRIVATE
    bench/bogo.asm
)

add_xex(sieve)
target_sources(sieve PRIVATE
    bench/sieve.c
    reset_vector.asm
)
target_compile_options(sieve PUBLIC -O)

add_xex(wozmon)
target_sources(wozmon PRIVATE
    mon/wozmon.s
    reset_vector.asm
)
target_link_options(wozmon PUBLIC --start-addr $F000)
