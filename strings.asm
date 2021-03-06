; String Data for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 01. May 2020

; ---- General strings ----

; All start with s_ and are terminated with a zero until we decide if we want
; Forth-style strings or these. String table aliases start with str_
; TODO reorder once things have calmed down

str_unbound       = 0
str_unspec        = 1
str_true          = 2
str_false         = 3
str_bad_token     = 4
str_bad_object    = 5
str_bad_number    = 6
str_bad_radix     = 7
str_cant_yet      = 8    ; TODO temp during development
str_extra_parens  = 9
str_chant         = 10
str_prompt        = 11
str_UNUSED_2      = 12   ; TODO currently unused
str_proc_prt      = 13
str_special_prt   = 14
str_cant_apply    = 15

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers.
string_table:
        .word s_unbound, s_unspec, s_true, s_false      ; 0-3
        .word s_bad_token, s_bad_object, s_bad_number, s_bad_radix   ; 4-7
        .word s_cant_yet, s_extra_parens, s_chant, s_prompt             ; 8-11
        .word s_UNUSED_2, s_proc_prt, s_special_prt                 ; 12-15

; If you change the error strings, you will have to change the test files
; because the test routines depend on them being exactly the same.
s_unbound:      .null   "Unbound variable: "            ; REPL input error
s_unspec:       .null   "Unspecified return value"      ; from printer
s_true:         .null   "#t"                            ; from printer
s_false:        .null   "#f"                            ; from printer
s_bad_token:    .null   "PANIC: Bad token: $"           ; from parser
s_bad_object:   .null   "PANIC: Bad object in AST: "    ; from printer
s_bad_number:   .null   "Ill-formed number: $"          ; from lexer
s_bad_radix:    .null   "PANIC: Bad radix: $"           ; from parser
s_cant_yet:     .null   "ALPHA: Can't do that yet"      ; from parser
s_extra_parens  .null   "Unexpected ')'"                ; from eval
s_chant:        .null   "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn." 
s_prompt:       .null   "> "
s_UNUSED_2      .null   "STRING UNUSED 2"
s_proc_prt:     .null   "#<procedure:"                  ; from printer 
s_special_prt:  .null   "#<special:"                    ; from printer
s_cant_apply:   .null   "Object not applicable"         ; from apply

; ---- Other Strings ----

; We store the string of delimiter characters "Forth style" with the length of
; the string before the actual string contents. In 64tass, the double quotation
; mark acts as an escape. We go from back to front so most common delimiters
; are at the end. See 
; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Delimiters.html
; for more on delimiters
s_delimiters:   .ptext "[]{}|`""';()"

; Extended alphabetic characters are what Scheme R5RS allows to be used in
; identifiers. See https://www-sop.inria.fr/indes/fp/Bigloo/doc/r5rs-5.html
s_extended:     .ptext "!$%&*+-./:<=>?@^_~"

s_letters:      .null "abcdefghijklmnopqrstuvwxyz"
s_digits:       .null "0123456789"

