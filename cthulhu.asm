; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 30. Mar 2020

; This is the main file for Cthulhu Scheme

; Label to mark the beginning of code. Useful for people who are porting this
; to other hardware configurations
code0:

.include "definitions.asm"      ; Top-level definitions, memory map

; Main entry point
cthulhu:

; TODO setup heap
; TODO initilize REPL

; TODO temporary halt of machine
;
        brk


.include "strings.asm"          ; All strings including error messages
