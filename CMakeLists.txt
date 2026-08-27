cmake_minimum_required(VERSION 3.20)

#Note this line must be before project!
set(CMAKE_TOOLCHAIN_FILE ./cc65-toolchain.cmake)

project(x65-examples ASM C)

function(ADD_XEX executable_name)
    add_executable(${executable_name})
    # --target selects the character mapping, among other things. cl65 defaults
    # to the c64 target, whose charmap is PETSCII: `.asciiz "Press"` assembles as
    # D0 52 45 53 rather than 50 72 65 73, silently, and the X65 font renders the
    # result as mojibake. This has to hold for every build type - it used to be
    # set only in the Debug flags, so a build with no CMAKE_BUILD_TYPE produced
    # bad strings. It lives here rather than in CMAKE_<LANG>_FLAGS_INIT because
    # CMake's compiler probes link without x65.cfg and fail under it.
    target_compile_options(${executable_name} PUBLIC
        --target none
        -C ${CMAKE_SOURCE_DIR}/x65.cfg
        -Wa --listing,${CMAKE_CURRENT_BINARY_DIR}/${executable_name}.lst,--cpu,65816
    )
    target_link_options(${executable_name} PUBLIC
        --target none
        -C ${CMAKE_SOURCE_DIR}/x65.cfg
        -Ln ${CMAKE_CURRENT_BINARY_DIR}/${executable_name}.lbl
        --mapfile ${CMAKE_CURRENT_BINARY_DIR}/${executable_name}.map
        -Wl --dbgfile,${CMAKE_CURRENT_BINARY_DIR}/${executable_name}.dbg
    )
    set_target_properties(${executable_name} PROPERTIES
        OUTPUT_NAME ${executable_name} SUFFIX ".xex"
    )
endfunction()

add_subdirectory(src)
