; Procedures and Special Forms for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 24. Apr 2020

; This file contains the procedures and special forms of Cthulhu Scheme that
; are coded natively in assembler. For now, we keep special forms such as
; (define) and primitive procedures such as (not) here. 

; All procedure start with the proc_ label followed by their Scheme name with
; underscores, eg "proc_read_char" for "(read-char)".  A question mark is is
; seplaced by '_p', so "(char-whitespace?  #\a)" becomes
; "proc_char_whitespace_p". Special forms start with the spec_ label followed
; by their Scheme name with underscores, so "(define)" becomes "spec_define".
; An exclamation mark becomes '_e', so "(set!)" "spec_set_e". 

; See https://schemers.org/Documents/Standards/R5RS/HTML/ for details.


; ===== PRIMITVE PROCEDURES ====

; These are ordered alphabetically. For each procedure, we must add an entry to
; the headers.asm file, which is a linked list. 

proc_apply:
        ; """Calls a procedure with a list of arguments. Example:
        ; '(apply + (list 3 4))'. We jump to this procedure with the pointer to
        ; the rest of the AST.
        ; """

proc_car:

proc_cdr:

proc_cons:

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

                jmp eval_next                   ; TODO or eval_done?
                
_done:
                jmp repl_quit

proc_newline:
        ; """Write an end of line to a port. Returns an unspecified value.
        ; """
                jsr help_emit_lf
                jmp eval_next                   ; TODO check this

proc_not:


; ==== SPECIAL FORMS ====

spec_and:

spec_begin:

spec_define:

spec_if:

spec_lambda:

spec_let:

spec_or:

spec_quote:
        ; """Supresses execution of procedure in parens (roughly speaking). Can
        ; be start with a tick "'" instead.
        ; """

spec_set_e:


; ===== JUMP TABLE ===== 

        ; Jump table for primitive procedures and special forms
        ; ("executables"). We are limited to 256 routines at the moment because
        ; we use one byte for the index to the jump tables, which are split in
        ; MSB and LSB parts. At the moment, this is ordered by hand, which is
        ; not sustainable and very, very error prone. Note what we store here
        ; are the addresses, not Scheme objects. 

        ; Keep the numbers in the comments after the entries so we can later
        ; create an automatic verification tool that compares them to the
        ; entries in the linked list in header.asm

exec_table_lsb:
        .byte <proc_apply       ; 00
        .byte <spec_quote       ; 01
        .byte <proc_exit        ; 02
        .byte <proc_newline     ; 03
        .byte <proc_car         ; 04
        .byte <proc_cdr         ; 05
        .byte <proc_cons        ; 06
        .byte <spec_define      ; 07
        .byte <spec_if          ; 08
        .byte <proc_not         ; 09
        
exec_table_msb:
        .byte >proc_apply       ; 00
        .byte >spec_quote       ; 01
        .byte >proc_exit        ; 02
        .byte >proc_newline     ; 03
        .byte >proc_car         ; 04
        .byte >proc_cdr         ; 05
        .byte >proc_cons        ; 06
        .byte >spec_define      ; 07
        .byte >spec_if          ; 08
        .byte >proc_not         ; 09


; ==== TODO FOR LATER ====

proc_char_whitespace_p:
        ; """Return boolean #t if character is whitespace, otherwise return #f.
        ; The whitespace characters are space, tab, line feed, form feed, and
        ; carriage return.
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
