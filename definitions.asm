; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 06. Apr 2020

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
tmp0:    .word ?     ; temporary storage, eg printing
tmp1:    .word ?     ; temporary storage
tmp2:    .word ?     ; temporary storage
output:  .word ?     ; output port, addr of routine
input:   .word ?     ; input port, addr of routine
ciblen:  .word ?     ; current size of input buffer
cibp:    .word ?     ; index of current char in input buffer
tkblen:  .word ?     ; current size of the token buffer
tkbp:    .word ?     ; index of current token in token buffer
hp:      .word ?     ; pointer to next free heap entry
symtbl:  .word ?     ; pointer to first entry in symbol table in heap
strtbl:  .word ?     ; pointer to first entry in string table in heap
bnmtbl:  .word ?     ; pointer to first entry in bignum table in heap
ast      .word ?     ; pointer to root of Abstract Systax Tree (AST)
astp     .word ?     ; pointer to current entry in AST
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

ot_meta         = $00    ; used for end of input and other markers
ot_bool         = $10    ; used for #t and #f; immediate
ot_fixnum       = $20    ; used for fixed numbers; immediate
ot_bignum       = $30    ; used for bignum
ot_char         = $40    ; used for chars; immediate
ot_undefined_05 = $50
ot_undefined_06 = $60
ot_undefined_07 = $70
ot_undefined_08 = $80
ot_undefined_09 = $90
ot_undefined_0a = $a0
ot_undefined_0b = $b0
ot_undefined_0c = $c0
ot_undefined_0d = $d0
ot_undefined_0e = $e0
ot_undefined_0f = $f0

; end
