;
;   txt64_build_attr_byte -> 'A'
;   ---------------------
;   Get current foreground and background colors and join them to build
;   a color attribute and return it in 'A'.
;
txt64_build_attr_byte:
            proc

            push hl                     ; save 'HL'

            ld a,(FORCLR)               ; get foreground color
        rept 4
            sla a                       ; 'A' <- shift left
        endm

            ld hl,BAKCLR                ; 'HL' to background color
            or (hl)                     ; 'A' <- 'A' or ('HL')

            pop hl                      ; restore 'HL'

            ret                         ; end of routine
            endp