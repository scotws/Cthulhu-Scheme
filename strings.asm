; String Data for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 01. Apr 2020


; General strings. All start with s_ and are terminated with a zero until we
; decide if we want Forth-style strings or these. String table aliases start
; with str_

str_unspec = 0

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers.
string_table:
        .word s_unspec ; 0-4

; TODO see if we want to keep the ';' in the individual strings
s_unspec:       .null   ";Unspecified return value"     ; used eg with (display)


