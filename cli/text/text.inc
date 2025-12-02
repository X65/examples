

    CGIA_DL_IN_LMS  = %00010000
    CGIA_DL_IN_LFS  = %00100000
    CGIA_DL_IN_LBS  = %01000000
    CGIA_DL_IN_LCG  = %10000000
    CGIA_DL_IN_VBL  = %10000000

    CGIA_DL_IN_EMPTY_LINE = $00
    CGIA_DL_IN_DUPL_LINE  = $01
    CGIA_DL_IN_JUMP       = $02
    CGIA_DL_IN_LOAD_SCAN  = $03

    CGIA_DL_IN_MODE2      = $0A
    CGIA_DL_IN_MODE3      = $0B
    CGIA_DL_IN_MODE4      = $0C
    CGIA_DL_IN_MODE5      = $0D
    CGIA_DL_IN_MODE6      = $0E
    CGIA_DL_IN_MODE7      = $0F

    RIA = $FFC0
    RIA_Stack = RIA + $30
    RIA_Op = RIA + $31

    CGIA = $FF00
    CGIA_Mode = CGIA
    CGIA_Planes = CGIA+$30
    CGIA_Offset0 = CGIA+$38
    CGIA_Plane0 = CGIA+$40
    CGIAP_RowHeight = 2

    RIA_API_GET_CHARGEN = $10
