; List of Headers for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 03. Apr 2020
; This version: 24. Apr 2020

; This file contains a linked-list of the primitive procedures and special
; forms in for Cthulhu Scheme that are coded in native assembler. The first 16
; bits are the link to the next entry in the list. This is followed by the
; Scheme object, which for primitive procedures and special forms consists out
; of an 8-bit offset to the jump table (see procedures.asm) as the LSB and the
; Tag of the object as MSB. It is followed by the zero terminated string. 

; TODO The fact that we zero-terminate the string wastes one byte for each
; entry in the table, up to 256 bytes. Since the information is already
; contained in the table - the end of the string is defined by the start of the
; next entry in the list - we can recode this at some point to reclaim that
; space. For now, this is good enough.

;                          LSB       MSB
;                      +---------+---------+
;  h_proc_<PREV> -> +0 | Next list entry   | -> h_proc_<NEXT>
;                      +-------------------+
;                   +2 | Offset  |  Tag    | -> jump table access
;                      +-------------------+
;                   +4 | String  |   ...   | 
;                      +---------+---------+
;                      |   ...   |   ...   |
;                      +---------+---------+
;                      |   ...   |   00    |  (zero terminated)
;                   +n +---------+---------+

; The split between "most common", "less common" and "rare" for how the words
; are used is currently pure guesswork. We should find some analysis (or do one
; ourselves) to find out which words are used most and put these at the
; beginning of the list. (exit) is always the last entry

; TODO For the actual procedures and special forms, we currently only store an offset
; to the jump table in the LSB of the Scheme object. Put differently, the lower
; nibble of the MSB is currently not used. This makes access to the jump table
; slightly faster, but limits us to 256 built-in objects. We'll cross that
; bridge when we get there. 

; ---- Most common ----


proc_headers:
h_proc_apply:       
        .word h_spec_quote      ; link to next entry in list (as 16-bit addr)
        .byte 00                ; offset in jump table  (LSB)
        .byte OT_PROC           ; object tag
        .null "apply"           ; lower-case string, zero terminated

h_spec_quote:                   ; TODO figure out where to handle '
        .word h_proc_car
        .byte 01
        .byte OT_SPEC
        .null "quote"

h_proc_car:
        .word h_proc_cdr
        .byte 04
        .byte OT_PROC
        .null "car"    

h_proc_cdr:
        .word h_proc_cons
        .byte 05
        .byte OT_PROC
        .null "cdr"

h_proc_cons:
        .word h_spec_define
        .byte 06
        .byte OT_PROC
        .null "cons"

h_spec_define:
        .word h_spec_if
        .byte 07
        .byte OT_SPEC
        .null "define"

h_spec_if:
        .word h_proc_newline
        .byte 08
        .byte OT_SPEC
        .null "if"


; ---- Less common ----

h_proc_newline:
        .word h_proc_not
        .byte 03
        .byte OT_PROC
        .null "newline"

h_proc_not:
        .word h_proc_exit
        .byte 09
        .byte OT_PROC
        .null "not"


; ---- Rare ----

h_proc_exit:
        ; proc_exit is always the last entry - if the user wants to quit, it
        ; can't be that urgent
        .word 0000              ; end lf list
        .byte 02
        .byte OT_PROC
        .null "exit"

; ENDS 
