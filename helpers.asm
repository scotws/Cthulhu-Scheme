; Low-Level Helper Functions for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mär 2020
; This version: 30. Mär 2020

; These were originally taken from Tali Forth 2, which is in the public domain

byte_to_ascii:
        ; """Convert byte in A to two ASCII hex digits and EMIT them"""
                pha
                lsr             ; convert high nibble first
                lsr
                lsr
                lsr
                jsr _nibble_to_ascii
                pla

                ; fall through to _nibble_to_ascii

_nibble_to_ascii:
        ; """Private helper function for byte_to_ascii: Print lower nibble
        ; of A and and EMIT it. This does the actual work.
        ; """
                and #$0F
                ora #'0'
                cmp #$3A        ; '9+1
                bcc +
                adc #$06

; TODO change this to the Scheme basic entry
+               jmp kernel_putc

                rts 
