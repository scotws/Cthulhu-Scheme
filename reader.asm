; Reader (REPL) for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 13. Apr 2020
; This version: 13. Apr 2020

repl_read:
        ; Basic structure taken from Tali Forth 2's REFILL and ACCEPT words. We
        ; currently don't have a history buffer system set up -- first we want
        ; to see if we have enough space.

                ; Clear index to current input buffer
                ldy #0

                ; Clear the input flag. We use this to mark if we are in
                ; a comment or between delimiters. Currently, we only use bit
                ; 7 to mark if we are in comment.
                stz input_f

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
                
                ; See if we have a comment symbol ';'. Note that once you start
                ; a comment, the end-of-line character doesn't actually end the
                ; input, but limits where you skip, you just move down one
                ; line. Everything that is input after the comment symbol is
                ; discarded later by the lexer. See
                ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Comments.html
                ; for more detail.
                cmp #$3B                ; semicolon
                bne _not_a_comment

                ; It's comment.
                jsr help_emit_a
                tax
                lda input_f
                ora #$80                ; Set bit 7
                sta input_f
                txa
                bra _comment_continue

_not_a_comment:
                ; We quit on both line feed and carriage return, but only if we
                ; are not part of a delimiter or in a comment. 
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

                ; That's enough for now. Echo character.
                jsr help_emit_a

_comment_continue:                
                sta cib,y
                iny
                cpy cib_size-1          ; reached character limit?
                bra repl_read_loop      ; fall thru if buffer limit reached

repl_read_eol:
                ; If we were not in a comment and not inside parens, this just
                ; ends the line
                ldx input_f
                bpl repl_read_input_done
                
                ; We are inside a comment. Save the LF character so that the
                ; lexer knows when the comment is over, then print a line feed,
                ; clear the comment flag, and get back to it.
                lda #AscLF              ; be safe, some send CR
                jsr help_emit_a
                sta cib,y
                iny

                lda #$7F
                and input_f
                sta input_f

                bra repl_read_loop

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
                bne _skip_bell

                lda #AscBELL    ; complain and don't delete beyond the start of line
                jsr help_emit_a
                iny
_skip_bell:
                dey
                lda #AscBS      ; move back one
                jsr help_emit_a
                lda #AscSP      ; print a space (rubout)
                jsr help_emit_a
                lda #AscBS      ; move back over space
                jsr help_emit_a

                bra repl_read_loop

repl_read_input_done:
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
