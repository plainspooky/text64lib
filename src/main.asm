;
;   TEXT64 Library (main file)
;

PATR_TABLE: equ $0000
ATTR_TABLE: equ $2000

            include	"./library/msx1bios.asm"
            include	"./library/msx1variables.asm"

            include "__config.asm"
            include "__macros.asm"

            org $c000-7
            db $fe
            dw binary_start
            dw binary_stop
            dw binary_exec

binary_start:
binary_exec:
            include "build_attr_byte.asm"
            include "clear_line.asm"
            include "clear_screen.asm"

txt64_charset:
            include	"charset/font64_ascii.asm"

binary_stop:
            end