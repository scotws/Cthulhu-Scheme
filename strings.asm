; String Data for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 29. Mar 2020

; TODO move to Cthulhu, this is still for Tali Forth 2

; ## GENERAL STRINGS

; All general strings start with "s_", aliases with "str_"

; .alias str_ok              0
; .alias str_see_size       12

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers.
string_table:
        .word s_ok, s_compiled, s_redefined, s_wid_forth, s_abc_lower ; 0-4
        .word s_abc_upper, s_wid_editor, s_wid_asm, s_wid_root        ; 5-8
        .word s_see_flags, s_see_nt, s_see_xt, s_see_size             ; 9-12

s_ok:         .byte " ok", 0         ; note space at beginning
s_compiled:   .byte " compiled", 0   ; note space at beginning
s_redefined:  .byte "redefined ", 0  ; note space at end

s_abc_lower:  .byte "0123456789abcdefghijklmnopqrstuvwxyz"
s_abc_upper:  .byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

s_wid_asm:    .byte "Assembler ", 0  ; Wordlist ID 2, note space at end
s_wid_editor: .byte "Editor ", 0     ; Wordlist ID 1, note space at end
s_wid_forth:  .byte "Forth ", 0      ; Wordlist ID 0, note space at end
s_wid_root:   .byte "Root ", 0       ; Wordlist ID 3, note space at end

s_see_flags:  .byte "flags (CO AN IM NN UF HC): ", 0
s_see_nt:     .byte "nt: ", 0
s_see_xt:     .byte "xt: ", 0
s_see_size:   .byte "size (decimal): ", 0


; ## ERROR STRINGS

; All error strings must be zero-terminated, all names start with "es_",
; aliases with "err_". If the string texts are changed, the test suite must be
; as well

.alias err_allot        0
.alias err_badsource    1
.alias err_compileonly  2
.alias err_defer        3
.alias err_divzero      4
.alias err_noname       5
.alias err_refill       6
.alias err_state        7
.alias err_syntax       8
.alias err_underflow    9
.alias err_negallot     10
.alias err_wordlist     11
.alias err_blockwords   12

error_table:
        .word es_allot, es_badsource, es_compileonly, es_defer  ;  0-3
        .word es_divzero, es_noname, es_refill, es_state        ;  4-7
        .word es_syntax, es_underflow, es_negallot, es_wordlist ;  8-11
        .word es_blockwords                                    ; 12

es_allot:       .byte "ALLOT using all available memory", 0
es_badsource:   .byte "Illegal SOURCE-ID during REFILL", 0
es_compileonly: .byte "Interpreting a compile-only word", 0
es_defer:       .byte "DEFERed word not defined yet", 0
es_divzero:     .byte "Division by zero", 0
es_noname:      .byte "Parsing failure", 0
es_refill:      .byte "QUIT could not get input (REFILL returned -1)", 0
es_state:       .byte "Already in compile mode", 0
es_syntax:      .byte "Undefined word", 0
es_underflow:   .byte "Stack underflow", 0
es_negallot:    .byte "Max memory freed with ALLOT", 0
es_wordlist:    .byte "No wordlists available", 0
es_blockwords:  .byte "Please assign vectors BLOCK-READ-VECTOR and BLOCK-WRITE-VECTOR",0
