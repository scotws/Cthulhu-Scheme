; Debugging helper routines 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 04. Apr 2020
; This version: 05. Apr 2020

; Do not include these in finished code. All routines start with debug_ . These
; are currently not documented


debug_dump_token: 
        ; Hexdump contents of the token buffer. Assumes that tokens are one
        ; byte long. Currently not clever enough to handle multi-byte tokens
.block
                lda #AscLF
                jsr help_emit_a

                ldx #0
-
                lda tkb,x
                cmp #T_END
                beq _done

                jsr help_byte_to_ascii
                inx

                lda #' '
                jsr help_emit_a

                ; We make sure that we don't go off the end of the buffer
                ; because we don't trust the code to always include the
                ; terminal token
                cpx tkbp
                bne - 
_done:
                jsr help_byte_to_ascii

                lda #AscLF
                jmp help_emit_a         ; JSR/RTS
.bend


debug_emit_a:
        ; Print a single char, usally to show where we are. Char is in A
                pha
                lda #AscLF
                jsr help_emit_a

                pla
                jsr help_emit_a

                lda #AscLF
                jmp help_emit_a         ; JSR/RTS

