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
hp:      .word ?     ; pointer to next free heap entry
.send zp


; ---- Input and other buffers ----

.section buffers
cib0:    .fill cib_size      ; current input buffer
.send buffers
