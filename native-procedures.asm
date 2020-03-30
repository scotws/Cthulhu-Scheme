; Native-coded Procedures for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 30. Mar 2020

; This file contains the few procedures of Cthulhu Scheme that are hard-coded
; in assembler. All such procedures start with the proc_ label followed by
; their Scheme name with underscores (eg "proc_read_char" for "(read-char)".  

proc_read_char:
        ; """Returns the next character available from the input port. See
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Input-Procedures.html
        ; for details.
        ; """
        
proc_read_line: 
        ; """Returns the next line available from the input port. See
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Input-Procedures.html
        ; for details.
        ; """

