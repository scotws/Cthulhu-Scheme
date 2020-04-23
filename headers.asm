; List of Headers for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 03. Apr 2020
; This version: 23. Apr 2020

; This file contains a linked-list of the primitive (built-in, assembler coded)
; procedures for Cthulhu Scheme.  

;                          LSB       MSB
;                      +---------+---------+
;  h_proc_<PREV> -> +0 | Next list entry   | -> h_proc_<NEXT>
;                      +-------------------+
;                   +2 | Address of code   | -> proc_<PROC>
;                      +-------------------+
;                   +4 | String  |   ...   | 
;                      +---------+---------+
;                      |   ...   |   ...   |
;                      +---------+---------+
;                      |    0    |    0    |  (zero terminated)
;                   +n +---------+---------+

; The split between "most common", "less common" and "rare" for how the words
; are used is currently pure guesswork. We should find some analysis (or do one
; ourselves) to find out which words are used most and put these at the
; beginning of the list. (exit) is always the last entry

; TODO consider storing the Scheme object in the header instead of the address
; of the code. This would not only speed up the process but also allow us to
; store other objects here that are not just processes. See the parser for
; details

; ---- Most common ----

        ; These contain the special forms

proc_headers:
h_proc_apply:       
        .word h_proc_quote ; link to next entry in list (16-bit address)
        .word proc_apply   ; link to actual code (16-bit address)
        .null "apply"       ; lower-case string, zero terminated

h_proc_quote:                   ; TODO figure out where to handle '
        .word h_proc_car
        .word proc_quote
        .null "quote"

h_proc_car:
        .word h_proc_cdr
        .word proc_car
        .null "car"    

h_proc_cdr:
        .word h_proc_cons
        .word proc_cdr
        .null "cdr"

h_proc_cons:
        .word h_proc_define
        .word proc_cons
        .null "cons"

h_proc_define:
        .word h_proc_if
        .word proc_define
        .null "define"

h_proc_if:
        .word h_proc_not
        .word proc_if
        .null "if"


; ---- Less common ----

h_proc_not:
        .word h_proc_exit
        .word proc_not
        .null "not"


; ---- Rare ----

h_proc_exit:
        ; proc_exit is always the last entry - if the user wants to quit, it
        ; can't be that urgent
        .word  0000
        .word  proc_exit
        .null "exit"
