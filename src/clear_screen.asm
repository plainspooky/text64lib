;
;   txt64_clear_screen:
;
;   Clear entire screen and filling atribute table with current foreground
;   and background colors.
;   Affects 'AF', 'BC', 'DE', 'HL', 'I'
;
txt64_clear_screen:
            proc
            local __clear_loop

        if USE_COLORS
            call txt64_build_attr_byte  ; build attribute byte
            ld i, a                     ; and store color in 'I'

            ld de,ATTR_TABLE            ; get attribute table
        endif

            ld hl,CRTCNT                ; get number of lines
            ld b,(hl)                   ; and store in 'B'
            dec b                       ; 'B' <- 'B' - 1

            ld hl,PATR_TABLE            ; get pattern table

          __clear_loop:
                push bc                 ; save 'BC'
                xor a                   ; 'A' <- 0

                ld bc,256               ; line size (256 bytes)
                call FILVRM             ; fill VRAM

            if USE_COLORS
                ld a,i                  ; 'A' <- 'I'
                ex de,hl                ; swap 'DE' <-> 'HL'

                ld bc,256               ; line size (256 bytes)
                call FILVRM             ; fill VRAM

                ex de,hl                ; swap 'DE' <-> 'HL' again
                inc d                   ; 'DE' <- 'DE' + 256
            endif

                inc h                   ; 'HL' <- 'HL' + 256
                pop bc                  ; restore 'BC'

                djnz __clear_loop

            ld a,1                      ; 'A' <- 1
            ld (CSRY),a                 ; Current line <- = 'A'
            ld (CSRX),a                 ; Current column <- = 'A'

            ret							; end of routine
            endp