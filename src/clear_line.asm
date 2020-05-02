;
;   txt64_clear_line
;   ----------------
;   Clear a line of text over the cursor.
;   Affects 'AF', 'BC', 'DE', 'HL'
;
txt64_clear_line:
            proc
            ld a,(CSRY)                 ; get current line number
            dec a                       ; 'A'<-'A'-1

txt64_clear_line_no_csry:
            ld de,PATR_TABLE
            ld h,a                      ; 'H' <- 'A' | 'L' <- 0
            ld l,0                      ; 'HL'<- 'A' × 256 + 'L'
            adc hl, de

            xor a                       ; 'A' <- 0

            ld bc,256                   ; an entire line
            call FILVRM                 ; fill VRAM

        if USE_COLORS
            ld de,ATTR_TABLE
            add hl,de                   ; 'HL' = 'HL' + 'DE'

            call txt64_build_attr_byte  ; build color attribute

            ex de,hl                    ; swap 'DE' <-> 'HL'
            ld bc,256                   ; an entire line
            call FILVRM                 ; fill VRAM
        endif

            ret                         ; end of routine
            endp