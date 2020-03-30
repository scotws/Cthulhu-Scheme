; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 30. March 2020

; ASCII Characters
; TODO Figure out which ones we actually need
;
        AscCC   = $03  ; break (CTRL-c)
        AscBELL = $07  ; bell sound
        AscBS   = $08  ; backspace
        AscLF   = $0a  ; line feed
        AscCR   = $0d  ; carriage return
        AscESC  = $1b  ; escape
        AscSP   = $20  ; space
        AscDEL  = $7f  ; delete (CTRL-h)
        AscCP   = $10  ; CTRL-p (used to recall previous input history)
        AscCN   = $0e  ; CTRL-n (used to recall next input history)

; Zero page definitions
; The beginning of the useable zero page is defined in the platsform file so
; the user can set it up depending on their hardware

        output = zpage+0  ; output port (2 bytes)
        input  = zpage+2  ; input port (2 bytes)

