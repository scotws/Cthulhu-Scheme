; String Data for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 21. Apr 2020

; ---- General strings ----

; All start with s_ and are terminated with a zero until we decide if we want
; Forth-style strings or these. String table aliases start with str_

str_unbound    = 0
str_unspec     = 1
str_true       = 2
str_false      = 3
str_bad_token  = 4
str_bad_object = 5
str_bad_number = 6
str_bad_radix  = 7
str_cant_yet   = 8      ; TODO temp during development
str_end_input  = 9 
str_chant      = 10
str_prompt     = 11
str_exit_kill  = 12

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers.
string_table:
        .word s_unbound, s_unspec, s_true, s_false      ; 0-3
        .word s_bad_token, s_bad_object, s_bad_number, s_bad_radix   ; 4-7
        .word s_cant_yet, s_end_input, s_chant, s_prompt             ; 8-11
        .word s_exit_kill                                            ; 12-15

; If you change the error strings, you will have to change the test files
; because the test routines depend on them being exactly the same.
; TODO see if we want to keep the ';' in the individual error strings
s_unbound:      .null   ";Unbound variable: "           ; REPL input error
s_unspec:       .null   ";Unspecified return value"     ; used eg with (display)
s_true:         .null   "#t"
s_false:        .null   "#f"
s_bad_token:    .null   "PANIC: Bad token: $"           ; from parser
s_bad_object:   .null   "PANIC: Bad object in AST: "    ; from printer
s_bad_number:   .null   ";Ill-formed number: $"         ; from lexer
s_bad_radix:    .null   "PANIC: Bad radix: $"           ; from parser
s_cant_yet:     .null   "ALPHA: Can't do that yet"      ; from parser
s_end_input:    .null   "End of input stream reached."  ; from reader
s_chant:        .null   "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn." 
s_prompt:       .null   "> "
s_exit_kill:    .null   "Kill Scheme (y or n)? "       ; from proc_exit

; ---- Other Strings ----

; Extended alphabetic characters are what Scheme R5RS allows to be used in
; identifiers. It might make more sense to save this as a ptext string than
; a null strings

s_extended:     .null "!$%&*+-./:<=>?@^_~"

