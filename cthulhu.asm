; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 04. Apr 2020

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
        ; TODO see how we can handle CTRL-d

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
                ; parens.

repl_read_loop:
        ; Out of the box, py65mon catches some CTRL sequences such as
        ; CTRL-c. We also don't need to check for CTRL-l because a
        ; vt100 terminal clears the screen automatically.

                ; Get a single character without going through the whole
                ; procedure of procedures
                jsr help_key_a

                ; TODO see if we have a delimiter. This is a bit tricky because
                ; if we have a delimiter such as '(', the line feed does not
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

                ; That's enough for now. Save and echo character.
                sta cib,y
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

                ; We have the characters in the buffer, now we can parse. The
                ; lexer is kept in a separate file
                jmp lexer

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


; The lexer is kept in a separate file


; ---- PARSER ----
; TODO move this to a separate file

; At this stage, we should have the tokens in the token buffer, terminated by
; an end of input token (00). We now need to construct the abstact syntax tree
; (AST).
parser: 
                .if DEBUG == true
                ; TODO TEST dump contents of token buffer
                jsr debug_dump_token
                .fi

                .if DEBUG == true
                ; TODO Testing print 'p' so we know where we are
                lda #'p'
                jsr debug_emit_a
                .fi


; ---- EVALUATE ----
; TODO Move this to a separate file.
eval:
                .if DEBUG == true
                ; TODO Testing print 'e' so we know where we are
                lda #'e'
                jsr debug_emit_a
                .fi


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
                bne _print_object

                lda #str_unspec
                jsr help_print_string

                jmp repl_done

_print_object:
                ; Figure out type of object we have been given
                lda return+1            ; MSB
                and #$f0                ; we just want the tag in the top nibble 

                ; TODO currently we just manually check which type this is.
                ; Move to a jump table once we have more versions going

                ; TODO see if result is bool
                cmp #ot_bool
                bne _print_fixnum

                ; We have a bool, which is always an immediate object. We can
                ; just print the result
                lda return              ; $00 is false, $ff is true
                bne _true

                lda #str_false
                bra _print_bool
_true
                lda #str_true
_print_bool:
                jsr help_print_string
                jmp repl_done

_print_fixnum:
                ; TODO see if result is fixnum
                ; TODO see if result is string
                ; TODO see if result is object
                ; TODO see if result is symbol

                ; If we landed here something went really wrong because we
                ; shouldn't have a token we can't print
                ; TODO Error message
                

; ==== ALL DONE ====
repl_done:

; TODO TEST keep doing stuff over and over
;
                jmp repl
