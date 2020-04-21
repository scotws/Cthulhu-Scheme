; Primitive Procedures for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 19. Apr 2020

; This file contains the procedures of Cthulhu Scheme that are "primitive",
; that is, hard-coded in assembler. All such procedures start with the proc_
; label followed by their Scheme name with underscores, eg "proc_read_char" for
; "(read-char)".  A question mark is is replaced by '_p', so "(char-whitespace?
; #\a)" becomes "proc_char_whitespace_p".

; See https://schemers.org/Documents/Standards/R5RS/HTML/ for details.

; ===== PROCEDURE ROUTINES ====

; These are ordered alphabetically. For each procedure, we must add an entry to
; the 

proc_apply:
        ; """Calls a procedure with a list of arguments. Example:
        ; '(apply + (list 3 4))'. We jump to this procedure with the pointer to
        ; the rest of the AST.
        ; """

proc_exit:
        ; """Terminate Cthulhu Scheme (exit). We follow the procedure from MIT
        ; Scheme where we ask the user if (exit) is used and just quit if it is
        ; CTRL-d
        ; """

        lda #str_exit_kill              ; "Kill Scheme (y or n)?"
        jsr help_print_string_no_lf
        jsr help_key_a
        cmp #'y'                        ; only "y" ends
        beq _done

        jmp eval_next           ; TODO or eval_done?
        
_done:
        jmp repl_quit

proc_quote:
        ; """Supresses execution of procedure in parens (roughly speaking). Can
        ; be start with a tick "'" instead.
        ; """



; ===== JUMP TABLE ===== 

        ; Jump table for primitive procedures. We are limited to 256 procedures
        ; at the moment because we use one byte for the index to the jump
        ; tables, which are split in MSB and LSB parts.

proc_table_lsb:
        ;     00           01          02
        .byte <proc_apply, <proc_quote, <proc_exit

proc_table_msb:

        ;     00           01          02
        .byte >proc_apply, >proc_quote, >proc_exit



; ==== TODO FOR LATER ====

proc_char_whitespace_p:
        ; """Return boolean #t if character is whitespace, otherwise return #f.
        ; The whitespace characters are space, tab, line feed, form feed, and
        ; carriage return.
        ; """

proc_newline:
        ; """Write an end of line to a port. Returns an unspecified value.
        ; """

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
