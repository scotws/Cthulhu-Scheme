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

                lda #strd_token_dump
                jsr debug_print_string_no_lf

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


; ==== DEBUG PRINT ROUTINES ====

debug_print_string_no_lf:
        ; """Given the number of a zero terminated string in A, print to the
        ; current output without adding a line feed. Uses Y and tmp0 by falling
        ; through to debug_print_common
        ; """
                ; Get the entry from the string table
                asl
                tay
                lda sd_table,y
                sta tmp0                ; LSB
                iny
                lda sd_table,y
                sta tmp0+1              ; MSB

                ; fall through to debug_print_common
debug_print_common:
        ; """Common print routine used by both the print functions and
        ; the error printing routine. Assumes string address is in tmp0. Uses
        ; Y.
        ; """
                ldy #0
_loop:
                lda (tmp0),y
                beq _done               ; strings are zero-terminated

                jsr help_emit_a         ; allows vectoring via output
                iny
                bra _loop
_done:
                rts


debug_print_string: 
        ; """Print a zero-terminated string to the console/screen, adding a LF.
        ; We do not check to see if the index is out of range. Uses tmp0.
        ; Assumes number of string is in A.
        ; """
                jsr debug_print_string_no_lf
                lda #AscLF              ; we don't use (newline) because of string
                jmp help_emit_a         ; JSR/RTS


; ===== DEBUGGING STRINGS ====

; We could use the normal string procedures but we want to keep everything that
; is debugging in its own file so we save space for later. See strings.asm for
; an explanation of the format

strd_token_dump = 0

s_dump_token:   .null   "Token Buffer: "

sd_table:
        .word s_dump_token              ; 0-3


