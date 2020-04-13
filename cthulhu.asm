; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 10. Apr 2020

; This is the main file for Cthulhu Scheme. It mainly contains the REPL. 

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

                ; Set up the heap. First, pointer to next free entry
                lda <#heap
                sta hp
                lda >#heap
                sta hp+1

                ; The AST, symbol, string, and bignum tables are all empty
                stz symtbl
                stz symtbl+1
                stz strtbl
                stz strtbl+1
                stz bnmtbl
                stz bnmtbl+1
                stz ast
                stz ast+1

                ; TODO define high-level procudures by loading from ROM

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

                ; Clear index to current input buffer
                ldy #0

                ; Print prompt. If this gets any more complicated we
                ; will need to move this to its own little routine
                lda #'>'
                jsr help_emit_a
                lda #' '
                jsr help_emit_a

                ; TODO Set up input status byte to handle delimiters, strings,
                ; and levels of parens: clear at start, set bit 7 for comment,
                ; set bit 6 for strings (so we don't trigger when we have
                ; a semicolon in a string), and the rest for counting levels of
                ; parens. This needs to be documented as well.

repl_read_loop:
        ; Out of the box, py65mon catches some CTRL sequences such as
        ; CTRL-c. We also don't need to check for CTRL-l because a
        ; vt100 terminal clears the screen automatically.

                ; Get a single character without going through the whole
                ; procedure of procedures
                jsr help_key_a

                ; TODO see if we have a delimiter. This is a bit tricky because
                ; if we have a delimiter such as '(', a line feed does not
                ; mean the line is over, just that we move to the next line. 
                
                ; TODO see if we have a comment ';' symbol. This is a bit
                ; tricky because if we are entering a comment, the line feed
                ; does not end the input but just moves a line down.

                ; We quit on both line feed and carriage return, but only if we
                ; are not part of a delimiter or in a comment. 
                ; TODO handle when in delimiter or in comment
                cmp #AscLF
                beq repl_read_eol
                cmp #AscCR
                beq repl_read_eol

                ; BACKSPACE and DEL do the same thing for the moment
                cmp #AscBS
                beq repl_read_backspace
                cmp #AscDEL             ; (CTRL-h)
                beq repl_read_backspace

                ; See if we have CTRL-D
                cmp #$04
                beq repl_input_end

                ; That's enough for now. Save and echo character.
                sta cib,y
                iny
                
                jsr help_emit_a

                cpy cib_size-1        ; reached character limit?
                bne repl_read_loop    ; fall thru if buffer limit reached

repl_read_eol:
repl_read_buffer_full:
                sty ciblen      ; Y contains number of chars accepted already
                lda #0
                sta ciblen+1    ; we only accept 256 chars

                ; We save a zero byte as a terminator because this is more
                ; robust than counting characters, given we're fooling around
                ; with line feeds and whatnot in Scheme.
                sta cib,y 

                ; We have the characters in the buffer, now we can parse. The
                ; lexer is kept in a separate file
                jmp lexer

repl_input_end:
                ; We quit, which is pretty much the same as (exit) but without
                ; the question. MIT Scheme prints out "Moriturus te saluto."
                ; but we have better things in mind. Might need to be shortened
                ; if we really run out of space.
                jsr help_emit_lf
                lda #str_end_input
                jsr help_print_string
                lda #str_chant
                jsr help_print_string
                jmp platform_quit


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

; We keep the main parts of the REPL in separate files because they can be
; quite large and to make it easer for people to swap the code out if they want
; to create their own versions. This setup assumes that the code flow enters at
; the top of the file and leaves at the bottom. 

; ==== LEXER ====
.include "lexer.asm"

; ==== PARSER ====
.include "parser.asm"

; ==== EVAL ====
.include "eval.asm"

; ==== PRINTER ====
.include "printer.asm"

; ==== ALL DONE ====

; Usually we fall through to here from the printer. However, if we were given
; an empty line, the lexer jumps here directly to save time.
repl_done:

; TODO TEST keep doing stuff over and over
;
                jmp repl
