;
;   txt64_scroll_up
;   ---------------
;   Description.
;   Affects 'AF', 'BC', 'DE', 'HL', 'IX'
;
;   Without color support!
;
txt64_scroll_up:
            proc
            local __scroll_loop

            ld hl,CRTCNT                ; total of lines in text mode
            ld b,(hl)                   ; copy it to 'B'
            dec b                       ; number of lines to scroll up

            ld ix,PATR_TABLE + 256      ; line #1
            ld hl,0
            ld de,0

          __scroll_loop:
                push bc                 ; save 'BC'

                ld bc,256               ; an entire line
                ld de,ix                ; VRAM address
                ld hl,txt64_line_buffer ; RAM address

                ex de,hl                ; swap 'DE' <-> 'HL'

                call LDIRMV             ; copy VRAM block to RAM

                ld bc,256               ; an entire line
                ld de,ix                ; VRAM aaddress
                ld hl,txt64_line_buffer ; RAM aaddress

                dec d                   ; 'DE' <- 'DE' - 256

                call LDIRVM             ; copy RAM block to VRAM

                inc ixh                 ; go to the next line

                pop bc                  ; restore 'BC'

                djnz __scroll_loop      ; while 'B' > 0

            ld a,23                     ; set to the 24th line of screen
            call txt64_clear_line_no_csry  ; clear last line

            ret                         ; end of routine
            endp