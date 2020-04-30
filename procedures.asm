; Procedures and Special Forms for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 30. Apr 2020

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

; Note (apply) is so central to the main REPL it lives in eval.asm. 


; ===== PROCEDURE CODE =====

; These are ordered alphabetically. For each procedure, we must add an entry to
; the headers.asm file, which is a linked list. Procedures are responsible for
; moving along on the AST to the ')' they come from.

; proc_apply lives in eval.asm because it is so important for the REPL

proc_car:

proc_cdr:

proc_cons:
                rts


; proc_eval lives in eval.asm because it is so important for the REPL

proc_exit:
        ; """Terminate Cthulhu Scheme (exit). We follow the procedure from
        ; Racket where we just quit, not MIT-Scheme where we ask the user
        ; first. This is the simplest of the procedures because we don't have
        ; to fool around with stacks and ASTs, we just drop everything.
        ; """
                jmp repl_quit


proc_newline:
        ; """Write an end of line to a port. Doesn't return a value. In
        ; contrast to MIT Scheme, which returns an "unspecified value", we
        ; follow Racket and don't return a value at all.
        ; """
        ; TODO This is the first procedure that was written for the eval/apply
        ; loop. The first part of the code can probably be move to a subroutine
        ; once we're sure this is the right way forward.
        
                ; We have the AST entry for the actual procedure in walk_car.
                ; As part of our housekeeping, we move one entry further to the
                ; ')' part.
                jsr help_walk_next

                ; In theory, we need to pull the last entry off the Data Stack
                ; and then push the new car. We can just overwrite them,
                ; however. Assumes that X is the dsp, which should be taken
                ; care of by (apply)
                lda walk_car            ; LSB
                sta 0,x
                lda walk_car+1          ; MSB
                sta 1,x

                ; This is the actual work of the procedure
                ; jsr help_emit_lf              ; TODO enable

                ; TODO test with 'q' for debugging
                lda #'q'
                jsr help_emit_a

                jmp proc_apply_return


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
                rts


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
