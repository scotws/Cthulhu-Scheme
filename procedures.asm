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
        ; """Applies a primitive procedure object to a list of operands, for
        ; instance '(apply + (list 3 4))'. We usually arrive here when the
        ; evaluator finds a '(' as OC_PARENS_START and has confirmed that the
        ; next object is either a primitive procedure - then we end up here
        ; - or a special form.
        
        ; We arrive here with the offset to the execution table in Y and the
        ; car and cdr of the next entry in the AST in walk_car and walk_cdr.
        
                ; TODO for now, we just jump!
                lda exec_table_lsb,y
                sta jump
                lda exec_table_msb,y
                sta jump+1
                jmp (jump)

proc_car:

proc_cdr:

proc_cons:
                jmp eval_next                   ; TODO or eval_done?

proc_exit:
        ; """Terminate Cthulhu Scheme (exit). We follow the procedure from
        ; Racket where we just quit, not MIT-Scheme where we ask the user
        ; first. 
        ; """
                jmp repl_quit

proc_newline:
        ; """Write an end of line to a port. Returns an unspecified value.
        ; """
                jsr help_emit_lf
                jmp eval_next                   ; TODO check this

proc_not:
        ; """Return #t if the single operand is #f, else return #f for
        ; absolutely everything, because everything in Scheme that is not #f is
        ; a boolean true, in contrast to C. In contrast to (and) and (or), this is not
        ; a special form. This was the first word with operands to be coded.
        ; """
                ; We should have already gotten the next entry in walk_car and
                ; walk_cdr
                ; TODO handle case of no operands
                lda walk_car+1          ; get MSB for object tag
                and #$F0                ; we only want the tag for now
                bne _not_a_bool

_not_a_bool:
        ; If it is not a bool, it is always true, because this is Scheme. Yes,
        ; even "(not 0)" is #t. 
                ; TODO


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
                jmp eval_next                   ; TODO for testing, protect table


; ===== EXECUTION JUMP TABLE ===== 

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
