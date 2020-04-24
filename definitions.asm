; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 24. Apr 2020

; The lexer tokens are kept in the lexer.asm file so that they can be changed
; more easily


; ---- ASCII Characters ----

; TODO Figure out which ones we actually need

        AscCC   = $03  ; break (CTRL-c)
        AscBELL = $07  ; bell sound
        AscBS   = $08  ; backspace
        AscLF   = $0a  ; line feed
        AscCR   = $0d  ; carriage return
        AscESC  = $1b  ; escape
        AscSP   = $20  ; space
        AscDEL  = $7f  ; delete (CTRL-h)
;       AscCP   = $10  ; CTRL-p
;       AscCN   = $0e  ; CTRL-n


; ---- Zero page definitions ----

; The beginning of the useable zero page is defined in the platform file so
; the user can set it up depending on their hardware. We use the section
; definitions from 64Tass here to make it easier to adapt to different
; hardware, see http://tass64.sourceforge.net/#sections for details. The memory
; map is part of the individual platform file. Note we do not initialize the
; zero page entries here so it must be done in code. 

.section zp
; Temporary variables
tmp0:    .word ?     ; temporary storage, eg printing
tmp1:    .word ?     ; temporary storage
tmp2:    .word ?     ; temporary storage

; Hardware vectors
output:  .word ?     ; output port, addr of routine
input:   .word ?     ; input port, addr of routine
jump:    .word ?     ; target for indirect jumps, used by evaluator

; I/O and parsing buffers
input_f  .byte ?     ; input flag for Reader, see details there
ciblen:  .word ?     ; current size of input buffer
cibp:    .word ?     ; index of current char in input buffer
tkblen:  .word ?     ; current size of the token buffer
tkbp:    .word ?     ; index of current token in token buffer

; RAM segments
rsn_ast  .byte ?     ; RAM segment nibble for AST segment (default 1)
astp     .word ?     ; pointer to current entry in AST
hp_ast   .word ?     ; next free byte in AST RAM segment

rsn_str  .byte ?     ; RAM segment nibble for strings (default 2)
strp     .word ?     ; pointer to current entry in string table
hp_str   .word ?     ; next free byte in string RAM segment

; AST walker
walk_curr   .word ?  ; Pointer (addr) to current pair in AST
walk_car    .word ?  ; Contents of current pair's car field
walk_cdr    .word ?  ; Contents of current pair's cdr field

.send zp


; ---- Buffers ----

.section buffers
cib:    .fill cib_size          ; current input buffer
tkb:    .fill tkb_size          ; token buffer
.send buffers


; ---- General RAM objects ---- 

.section ram
heap:   .fill heap_size         ; RAM available for heap
.send ram 


; ---- Object tag nibbles ----

; Each object in Cthulhu Scheme has a four-bit tag that denotes the type. We
; store them here with ot_ as a beginning. These are used by the parser as well
; as the evaluator so we keep them saved here. Note if we change these, we
; migght have to change the Object Constants that live in parser.asm as well.

OT_META         = $00   ; used for the empty list and terminators
OT_BOOL         = $10   ; used for #t and #f; immediate
OT_FIXNUM       = $20   ; used for fixed numbers; immediate
OT_BIGNUM       = $30   ; reserved for bignum
OT_CHAR         = $40   ; reserved for chars; immediate
OT_STRING       = $50   ; used for strings; interned
OT_VAR          = $60   ; used for variables
ot_undefined_07 = $70
OT_PAIR         = $80   ; used for pairs
ot_undefined_09 = $90
ot_undefined_0a = $a0
ot_undefined_0b = $b0
ot_undefined_0c = $c0
ot_undefined_0d = $d0
OT_SPEC         = $e0   ; special forms such as (lambda) or (if)
OT_PROC         = $f0   ; built-in procedures

; end
