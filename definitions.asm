; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 03. Apr 2020

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
        AscCP   = $10  ; CTRL-p
        AscCN   = $0e  ; CTRL-n

; ---- Zero page definitions ----

; The beginning of the useable zero page is defined in the platform file so
; the user can set it up depending on their hardware. We use the section
; definitions from 64Tass here to make it easier to adapt to different
; hardware, see http://tass64.sourceforge.net/#sections for details. The memory
; map is part of the individual platform file. Note we do not initialize the
; zero page entries here so it must be done in code. 

.section zp
return:  .word ?     ; return value: result of a procedure
tmp0:    .word ?     ; temporary storage, eg printing
tmp1:    .word ?     ; temporary storage
tmp2:    .word ?     ; temporary storage
output:  .word ?     ; output port, addr of routine
input:   .word ?     ; input port, addr of routine
ciblen:  .word ?     ; current size of input buffer
cibp:    .word ?     ; pointer (index?) to current char in input buffer
tkblen:  .word ?     ; current size of the token buffer
tkbp:    .word ?     ; pointer (index?) to current token in token buffer
hp:      .word ?     ; pointer to next free heap entry
.send zp


; ---- Input and other buffers ----

.section buffers
cib:    .fill cib_size  ; current input buffer
tkb:    .fill tkb_size  ; token buffer
.send buffers


; ---- Object tag nibbles ----

; Each object in Cthulhu Scheme has a four-bit tag that denotes the type. We
; store them here with t_ as a beginning

t_meta         = $00    ; used for end of input and other markers
t_bool         = $10    ; used for #t and #f; immediate
t_fixnum       = $20    ; used for fixed numbers; immediate
t_bignum       = $30    ; used for bignum
t_char         = $40    ; used for cars; immediate
t_undefined_05 = $50
t_undefined_06 = $60
t_undefined_07 = $70
t_undefined_08 = $80
t_undefined_09 = $90
t_undefined_0a = $a0
t_undefined_0b = $b0
t_undefined_0c = $c0
t_undefined_0d = $d0
t_undefined_0e = $e0
t_undefined_0f = $f0


; ---- Constant objects ----

; Some objects are used again and again so it is worth storing them as
; constants for speed reasons. These start with oc_

oc_end   = $0000        ; end of input for tokens and objects
oc_true  = $1fff        ; true bool #t, immediate
oc_false = $1000        ; false bool #f, immediate

