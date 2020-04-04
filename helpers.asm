; Low-Level Helper Functions for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 03. Apr 2020

; Many of these were originally taken from Tali Forth 2, which is in the public
; domain. All routines start with help_. They are all responsible for saving
; the register status 
; TODO make sure we save the register status

; ---- Byte to ASCII ----
help_byte_to_ascii:
        ; """Convert byte in A to two ASCII hex digits and EMIT them"""
                pha
                lsr             ; convert high nibble first
                lsr
                lsr
                lsr
                jsr help_nibble_to_ascii
                pla

                ; fall through to help_nibble_to_ascii

help_nibble_to_ascii:
        ; """Private helper function for byte_to_ascii: Print lower nibble
        ; of A and and EMIT it. This does the actual work.
        ; """
                and #$0F
                ora #'0'
                cmp #$3A        ; '9+1
                bcc +
                adc #$06

+               jmp help_emit_a       ; JSR/RTS 


; ---- Compare 16 bit numbers ----

; TODO ADD Compare 16 bit


; ---- Convert to lower case ----
help_to_lowercase:
; Given a character in A, return the lower case version in A as well.
; Scheme is case-insensitive, see 
; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Uppercase-and-Lowercase.html
; for details
; TODO Add conversion routine to lower case
                rts


; ---- Emit A ----
help_emit_a:
        ; Print the character in A without fooling around. This still allows
        ; the output to be vectored. Call it with JSR. 
                jmp (output)    ; JSR/RTS

; ---- Key A ----
help_key_a:
        ; The 65c02 doesn't have a JSR (ADDR,X) instruction like the
        ; 65816, so we have to fake the indirect jump to vector it.
        ; This is depressingly slow. We use this routine internally
        ; when we just want a character
                jmp (input)             ; JSR/RTS


; ---- System print routines----

help_print_string_no_lf:
        ; """Given the number of a zero terminated string in A, print to the
        ; current output without adding a line feed. Uses Y and tmp0 by falling
        ; through to help_print_common
        ; """
                ; Get the entry from the string table
                asl
                tay
                lda string_table,y
                sta tmp0                ; LSB
                iny
                lda string_table,y
                sta tmp0+1              ; MSB

                ; fall through to help_print_common
help_print_common:
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

help_print_string: 
        ; """Print a zero-terminated string to the console/screen, adding a LF.
        ; We do not check to see if the index is out of range. Uses tmp0.
        ; Assumes number of string is in A.
        ; """
                jsr help_print_string_no_lf
                lda #AscLF              ; we don't use (newline) because of string
                jmp help_emit_a         ; JSR/RTS


; ---- Tokenization Helpers ----

help_is_whitespace:
        ; """Given in a character in A, see if it is legally a Scheme
        ; whitespace character. Result is returned in the Carry flag: Set means
        ; is whitespace, cleared means is not.
        ; """
        ; TODO
        rts
        
help_is_delimiter:
        ; """Given a character in A, see if it is a legal Scheme delimiter. The
        ; result is returned in the Carry flag: Set mans is a delimiter,
        ; cleared means it is not. See the list of delimiters at
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Delimiters.html
        ; """
        ; TODO check for whitespace, because whitespace is delimiters
        ; TODO check for ();"'`|
        ; TODO check for []{}
        rts
