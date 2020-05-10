; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 30. Apr 2020

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

; The beginning of the useable zero page and its size are defined in the
; platform file so the user can set it up depending on their hardware. We use
; the section definitions from 64Tass here to make it easier to adapt to
; different hardware, see http://tass64.sourceforge.net/#sections for details.
; The memory map is part of the individual platform file. Note we do not
; initialize the zero page entries here so it must be done in code. 

.section zp

; Data Stack
; Leave this as the first entry so if the Data Stack overflows it takes itself
; out, 
dsp     .byte ?      ;  Offset for Data Stack pointer

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
walk_done   .byte ?  ; End of term? $FF is true, $00 is false

; Temporary variables
; Leave these as the last entries so if the Data Stack overflows there is at
; least some chance of surviving
tmp0:    .word ?     ; temporary storage, eg printing
tmp1:    .word ?     ; temporary storage
tmp2:    .word ?     ; temporary storage

.send zp

; The space between here and (zp_start + zp_size) is used as the "Data Stack",
; where the results are stored by the evaluator. It grows from high to low
; (from ds_start, which is (zp_start + zp_size), towards 0000). At the moment
; there is no bounds checking because we have so much space it is not required.
; This might change in the future. 

; ---- Data Stack ----

ds_start = <(zp_start + zp_size - 1) ; By default $00FF


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
; might have to change the Object Constants that live in parser.asm as well.

OT_META         = $00   ; used for the empty list and terminators
OT_BOOL         = $10   ; used for #t and #f; immediate
OT_FIXNUM       = $20   ; used for fixed numbers; immediate
OT_CHAR         = $30   ; reserved for chars; immediate
OT_STRING       = $40   ; used for strings; interned
OT_BIGNUM       = $50   ; reserved for bignum
OT_VAR          = $60   ; used for variables
ot_undefined_07 = $70
OT_PAIR         = $80   ; used for pairs, so in cons cell cdr field
ot_undefined_09 = $90
ot_undefined_0a = $a0
ot_undefined_0b = $b0
ot_undefined_0c = $c0
ot_undefined_0d = $d0
OT_SPEC         = $e0   ; special forms such as (lambda) or (if)
OT_PROC         = $f0   ; built-in procedures

; end
