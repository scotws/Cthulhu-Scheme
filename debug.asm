; Debugging helper routines 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 04. Apr 2020
; This version: 04. Apr 2020

; Do not include these in finished code. All routines start with debug_ 

; Hexdump contents of the token buffer

debug_dump_token: 
                lda #AscLF
                jsr help_emit_a

                ldx #0
-
                lda tkb,x
                jsr help_byte_to_ascii  ; LSB
                inx
                lda tkb,x
                jsr help_byte_to_ascii  ; MSB
                inx

                lda #' '
                jsr help_emit_a

                cpx tkbp
                bne - 

                lda #AscLF
                jmp help_emit_a         ; JSR/RTS


; Print a single char to show where we are. Char is in A
debug_emit_a:
                pha
                lda #AscLF
                jsr help_emit_a

                pla
                jsr help_emit_a

                lda #AscLF
                jmp help_emit_a         ; JSR/RTS

