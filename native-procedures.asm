; Native-coded Procedures for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 03. Apr 2020

; This file contains the few procedures of Cthulhu Scheme that are hard-coded
; in assembler. All such procedures start with the proc_ label followed by
; their Scheme name with underscores, eg "proc_read_char" for "(read-char)".
; A question mark is is replaced by '_p', so "(char-whitespace? #\a)" becomes
; "proc_char_whitespace_p".

; See https://schemers.org/Documents/Standards/R5RS/HTML/ for details.

proc_char_whitespace_p:
        ; """Return boolean #t if character is whitespace, otherwise return #f.
        ; The whitespace characters are space, tab, line feed, form feed, and
        ; carriage return.
        ; """

proc_newline:
        ; """Write an end of line to a port. Returns an unspecified value.
        ; """
                ; We don't return a result 
                stz return
                stz return+1

                lda #AscLF
                jmp help_emit_a         ; JSR/RTS

proc_display:
        ; """Writes a string to standard output, does not write a newline.
        ; """

proc_read:
        ; """Convert external representation of Scheme objects into the objects
        ; - this is a parser.
        ; """

proc_read_char:
        ; """Returns the next character available from the input port. See
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Input-Procedures.html
        ; for details. Example: 
        ;       (read-char) f
        ; returns
        ;       Value: #\f
        ; """
        
proc_read_line: 
        ; """Returns the next line available from the input port. See
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Input-Procedures.html
        ; for details.
        ; """

proc_write_char:
        ; """Writes the character to a port and returns an unspecified value.
        ; If no port is provided, it defaults to the current output port.
        ; Expample:
        ;       (write-char #\a)
        ; returns
        ;       a
        ;       ;Unspecified return value
        ; """
