; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 02. Apr 2020

; This is the main file for Cthulhu Scheme

; Label to mark the beginning of code. Useful for people who are porting this
; to other hardware configurations
code0:

; Main entry point
cthulhu:

; ==== SETUP ====

                ; Reset the system. Does not restart the kernel, use the 65c02
                ; reset for that. 
                cld

                ; Set default output port. We wait to set the input port until
                ; we've defined all the high-level procedures
                lda #<kernel_putc
                sta output
                lda #>kernel_putc
                sta output+1

                ; TODO clear the heap
                ; TODO define high-level procudures

                ; Set default input port
                lda #<kernel_getc
                sta input
                lda #>kernel_putc
                sta input+1

; ==== REPL ====
; TODO https://eecs490.github.io/project-scheme-parser/

repl: 
                ; Start overwriting input buffer
                stz ciblen
                stz ciblen+1

; ---- READ ----

repl_read:
        ; Basic structure taken from Tali Forth 2's REFILL and ACCEPT words. We
        ; currently don't have a history buffer system set up -- first we want to see
        ; if we have enough space.

                ldy #0

repl_read_loop:
        ; Out of the box, py65mon catches some CTRL sequences such as
        ; CTRL-c. We also don't need to check for CTRL-l because a
        ; vt100 terminal clears the screen automatically.

                ; Get a single character without going through the whole
                ; procedure of procedures
                jsr help_key_a

                ; We quit on both line feed and carriage return
                cmp #AscLF
                beq repl_read_eol
                cmp #AscCR
                beq repl_read_eol

                ; BACKSPACE and DEL do the same thing for the moment
                cmp #AscBS
                beq repl_read_backspace
                cmp #AscDEL             ; (CTRL-h)
                beq repl_read_backspace

                ; That's enough for now. Save and echo character.
                sta cib0,y
                iny
                
                jsr help_emit_a

                cpy cib_size-1        ; reached character limit?
                bne repl_read_loop    ; fall through if buffer limit reached

                bra repl_read_buffer_full

repl_read_eol:
                ; TODO jsr xt_space  ; print final space 

repl_read_buffer_full:
                sty ciblen      ; Y contains number of chars accepted already
                stz ciblen+1    ; we only accept 256 chars

                ; We have the characters in the buffer, now we can parse
                bra repl_tokenize

repl_read_backspace:
                ; Handle backspace and delete key, which currently do the same
                ; thing
                cpy #0          ; buffer empty?
                bne +

                lda #AscBELL    ; complain and don't delete beyond the start of line
                jsr help_emit_a
                iny
+
                dey
                lda #AscBS      ; move back one
                jsr help_emit_a
                lda #AscSP      ; print a space (rubout)
                jsr help_emit_a
                lda #AscBS      ; move back over space
                jsr help_emit_a

                bra repl_read_loop


; ---- TOKENIZE ----
repl_tokenize: 

                ; TODO skip over whitespace

                ; TODO Testing print 't' so we know where we are
                lda #AscLF
                jsr help_emit_a
                lda #'t'
                jsr help_emit_a

; ---- PARSE ----
repl_parse: 

                ; TODO Testing print 'p' so we know where we are
                lda #AscLF
                jsr help_emit_a
                lda #'p'
                jsr help_emit_a

; ---- EVALUATE ----
repl_eval:
                ; TODO Testing print 'e' so we know where we are
                lda #AscLF
                jsr help_emit_a
                lda #'e'
                jsr help_emit_a

                ; TODO testing: Result is 00

; ---- PRINT ----
repl_print: 
        ; The result of the procedure (or last part of the procedure in the case of
        ; something like (begin) is stored in the return variable in zero page. If it
        ; is zero, we don't have a return value.

        ; TODO see if we want to move this to a seperate file because it could
        ; turn out to be pretty large
        
                ; If result is zero, there is no return value 
                lda return
                ora return+1
                bne +

                lda #str_unspec
                jsr help_print_string

+               
                ; TODO see if result is fixnum
                ; TODO see if result is bool
                ; TODO see if result is string
                ; TODO see if result is object
                ; TODO see if result is symbol

; ==== ALL DONE ====
repl_done:

; TODO TEST keep doing stuff over and over
;
                jmp repl
