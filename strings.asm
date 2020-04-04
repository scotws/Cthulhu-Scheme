; String Data for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 04. Apr 2020

; General strings. All start with s_ and are terminated with a zero until we
; decide if we want Forth-style strings or these. String table aliases start
; with str_

str_unbound = 0
str_unspec  = 1

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers.
string_table:
        .word s_unbound, s_unspec ; 0-4

; TODO see if we want to keep the ';' in the individual strings
s_unbound:      .null   ";Unbound variable:"            ; REPL input error
s_unspec:       .null   ";Unspecified return value"     ; used eg with (display)


; ---- Other Strings ----

; Extended alphabetic characters are what Scheme R5RS allows to be used in
; identifiers. It might make more sense to save this as a ptext string than
; a null strings

s_extended:     .null "!$%&*+-./:<=>?@^_~"

