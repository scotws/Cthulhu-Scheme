; Definitions for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 30. March 2020

; ASCII Characters
; TODO decide which ones we actually need
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
