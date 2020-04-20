; Reader (REPL) for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 13. Apr 2020
; This version: 19. Apr 2020

reader:
        ; Original structure adapted from Tali Forth 2's REFILL and ACCEPT
        ; words. We currently don't have a history buffer system set up --
        ; first we want to see if we have enough space.

        ; Clear the input flag. We use this to mark if we are in
        ; a comment, a string, or between delimiters. 
        ;
        ;       bit 7   - set: are in comment
        ;       bit 6   - set: are in string
        ;       bit 5-0 - RESERVED: counter for open parens
        ; 
        ; This limits us to 64 levels of parens. 
                
        ; We start out with all flags cleared and no parens
                stz input_f

        ; Clear the input buffer
                stz ciblen
                stz ciblen+1

        ; The prompt is kept in the strings.asm file so people
        ; can change it more easily
                lda #str_prompt
                jsr help_print_string_no_lf

        ; Clear index to current input buffer. Do this after we
        ; print the prompt because help_print_string_no_lf
        ; destroys Y
                ldy #0

reader_loop:
        ; Main input loop. The hard part is handled by the kernel routines in
        ; the platform file.

                ; Get a single character without going through the whole
                ; procedure of, well, procedures
                        jsr help_key_a

        ; ---- Check for end of line ----
                ; We quit input on both line feed and carriage return, but only 
                ; if we ; are not in a delimiter such as a parens, in a comment, 
                ; or a string. We do this early because every line has at least
                ; one of these
                        cmp #AscLF
                        beq reader_got_eol
                        cmp #AscCR
                        beq reader_got_eol

                        ; fall through to _not_an_eol

_not_an_eol:
        ; ---- Check for parens ----
                ; See if we have a parens, open or closed. This is a bit tricky
                ; because if we have a delimiter such as '(', a line feed does
                ; not mean the line is over, just that we move to the next
                ; line. We'll dealt with that case in reader_got_eol
                        ; TODO handle parens
                
_not_a_parens:
        ; ---- Check for comment ----
                ; See if we have a comment symbol ';'. Note that once you start
                ; a comment, the end-of-line character doesn't actually end the
                ; input, just the comment, and you move down one
                ; line. Everything that is input after the comment symbol is
                ; discarded later by the lexer up to the line feed character,
                ; so we need to store that, which we do in reader_got_eol. See
                ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Comments.html
                ; for more detail on comments.
                        cmp #$3B                ; semicolon
                        bne _not_a_comment

                ; It's comment symbol. Echo the semicolon, set bit 7 in the
                ; input flag and continue. Note that if somebody types lots of
                ; comments, or semicolons in comments, we set bit 7 over and
                ; over again. This should be faster than checking and
                ; branching. 
                        tax                     ; Save semicolon char
                        lda #$80                ; Get ready to set bit 7
                        tsb input_f             ; 65c02 only
                        txa
                        bra reader_comment_continue     ; saves char

        ; ---- Check for string ----
_not_a_comment:
                ; See if we have a string delimiter '"'. Once we start
                ; a string, the end-of-line character (LF or CR) doesn't
                ; actually end the input, but is saved. we take care of that in
                ; reader_got_eol
                        cmp #$22                ; quotation mark '"'
                        bne _not_a_string

                ; It's a string. If we are already in a string, we stop being
                ; in a string and clear bit 6 of the input flag; if we are new
                ; to the string, we set the bit. Put differently, we flip 
                ; bit 6.
                        tax                     ; Save quotation mark char
                        lda input_f
                        eor #%01000000          ; flip bit 6
                        sta input_f
                        txa
                        bra reader_string_continue      ; saves char
                
        ; ---- Deal with control characters ----
_not_a_string:                
                ; Out of the box, py65mon catches some CTRL sequences such as
                ; CTRL-c. We also don't need to check for CTRL-l because
                ; a vt100 terminal clears the screen automatically. You might
                ; have to change this if your hardware does other stuff. 
                        
                        ; BACKSPACE and DEL do the same thing for the moment
                        cmp #AscBS
                        beq reader_backspace
                        cmp #AscDEL             ; Is the same as CTRL-h
                        beq reader_backspace

                        ; See if we have CTRL-D
                        cmp #$04
                        bne reader_normal_char

                        ; End the REPL
                        jmp repl_quit

reader_normal_char:
reader_comment_continue:                
reader_string_continue:
                        jsr help_emit_a

                        ; Save character and see if we have reached the end of
                        ; the buffer
                        sta cib,y
                        iny
                        cpy cib_size
                        bcc reader_buffer_full
                        bra reader_loop

reader_got_eol:
        ; Deal with EOL characters, which are either LF or CR. We only use LF
        ; internally.

                ; If we are inside a comment (bit 7 of input_f set), an EOL
                ; ends the comment and we continue with the normal input
                        lda input_f             ; bit 7 marks comment
                        bmi _eol_in_comment
                
                ; If we are inside parens or a string, an EOL doesn't end the
                ; input, but just moves the cursor down. We could filter out
                ; the EOL if we are inside parens here already, but this might
                ; be useful information for the lexer error messages so we let
                ; it handle that there.
                        and #%01111111          ; input_f already in A
                        bne _eol_in_parens_or_string

                ; None of the input flags are set and we haven't counted
                ; a parens, so we just end the line
                        jsr help_emit_a
                        bra reader_input_done
                
_eol_in_comment:
        ; We receive an EOL while in a comment. This means we end the comment
        ; and continue with the normal input. We save the LF character so the
        ; lexer knows the comment is over, print a line feed, clear the comment
        ; status flag and get back to the input
                        lda #$80
                        trb input_f             ; bit 7 marks comment, now clear

                        ; drop through to _eol_in_parens_or_string

_eol_in_parens_or_string:
        ; Just save the line feed without ending the input
                        lda #AscLF
                        bra reader_comment_continue       ; stores LF

reader_backspace:
        ; Handle backspace and delete key, which currently do the same
        ; thing
                        cpy #0          ; buffer empty?
                        bne _skip_bell

                        ; If empty, complain and don't delete beyond the start
                        ; of line
                        lda #AscBELL    
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

                        jmp reader_loop

reader_input_done:
reader_buffer_full:
                        sty ciblen      ; Y contains number of chars accepted already
                        lda #0
                        sta ciblen+1    ; we only accept 254 chars for now

                        ; We save a zero byte as a terminator because this is more
                        ; robust than counting characters, given we're fooling around
                        ; with line feeds and whatnot in Scheme. Zero already A
                        sta cib,y 

                        ; We have the characters in the buffer, now we can parse. The
                        ; lexer is kept in a separate file
                        
                        ; fall through to lexer
