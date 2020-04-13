;;; Main test file for Cthulhu Scheme
;;; First version: 13. April 2020
;;; This version: 13. April 2020

; The test suite is horribly simple at the moment, we can only run stuff that
; should work and complain if there is an error. The abilities will be expanded
; as the language inproves

; Booleans 
#f
#t
#t #t
#f #f
#t #f
#f #t

; Fixnums, decimal
; TODO

; Fixnums, hex
#x0
#x00
#x000
#x1
#x11
#x111
#x9
#x99
#x999
#xa
#xaa
#xaaa
#xA
#xAA
#xAAA
#xF
#xFF
#xFFF
#xf
#xff
#xfff

; Fixnums, binary
#b0
#b1
#b0000
#b1111
#b00001111
#b111100001111

; Fixnums, octal
; TODO

; All tests done!
