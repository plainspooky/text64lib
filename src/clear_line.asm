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

            ld de,ATTR_TABLE            ; begin of attribute table

            ld h,a                      ; 'H' <- 'A' | 'L' <- 0
            ld l,0                      ; 'HL'<- 'A' × 256 + 'L'

            xor a                       ; 'A' <- 0

            ld bc,256                   ; an entire line
            call FILVRM                 ; fill VRAM

            add hl,de                   ; 'HL' = 'HL' + 'DE'
            ex de,hl                    ; swap 'DE' <-> 'HL'

            call txt64_build_attr_byte  ; build color attribute

            ex de,hl                    ; swap 'DE' <-> 'HL'
            ld bc,256                   ; an entire line
            call FILVRM                 ; fill VRAM

            ret                         ; end of routine
            endp