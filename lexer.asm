; Lexer (Tokenizer) for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 10. Apr 2020

; The lexer (tokenizer) is kept in a separate file to make changes easier. It
; goes through the characters read into the input buffer (cib) and turns them
; into tokens which are stored in the token buffer (tkb). We do a lot of
; processing in this stage because we don't want to touch the data too much.

; ==== LEXER CODE ====
lexer:
                .if DEBUG == true
                jsr debug_dump_input
                .fi

                ; Intialized indices to charater and token buffers
                ; TODO see if we actually need all of these here
                ldy #0
                stz cibp
                stz cibp+1      ; MSB currently unused
                stz tkbp
                stz tkbp+1      ; MSB currently unused

lexer_loop:
                lda cib,y

                ; Deal with whitespace. This includes line feeds because
                ; we can have those inside delimiters and comments. See the
                ; discussion at the code for helper_is_whitespace in
                ; helpers.asm for what is all considered whitespace
                jsr help_is_whitespace
                bcc _not_whitespace

                ; It's whitespace, so we skip it
                jmp lexer_next

_not_whitespace:
                ; ---- Check for parens ----
_test_parens:
                ; We do this early because this is Scheme, and there are going
                ; to be a lot of them
                ; TODO check for parens


                ; ---- Check for end of input ----
_test_done:      
                ; We have a zero byte as a marker that the line is over
                bne _not_done
                jmp lexer_end_of_input          ; not the same as lexer_done


                ; ---- Check for sharp stuff ----
_not_done:
                ; See if first character is #
                cmp #'#'
                bne _not_sharp

                ; We have a #, so see which type it is. First, see if this is
                ; a bool, so either #f or #t because they probably come up
                ; a lot. ("Probably" of course is not really good enough, at
                ; some point we should do some research to see just how common
                ; they are)
                iny                     ; TODO see if we're past end of buffer
                lda cib,y

                cmp #'t'                ; We're optimists so we check for true first
                bne _not_true

                ; We have a true bool. Add this to the token buffer
                lda #T_TRUE

                ; It's tempting to want to put the jmp instruction in the
                ; subroutine to add the token, and in this case, it would
                ; actually work. However, other tokens require a "payload" of
                ; (say) a pointer to a string that has been interned in the
                ; heap, so we can't do that. There might be a clever solution
                ; for this, but for the moment, we stick with the ugly JSR/JMP
                ; combination here
                jsr lexer_add_token
                jmp lexer_next

_not_true:
                cmp #'f'
                bne _not_false

                ; We have a false bool. Add this to the token buffer
                lda #T_FALSE
                jsr lexer_add_token
                jmp lexer_next

_not_false:
                ; ---- Check for char #\a ----
                ; TODO

_test_vector:
                ; ---- Check for vector constant #( ----
                ; TODO

_test_radix:
                ; ---- Check if we have a radix number prefix ----
                ; - #b binary
                ; - #o octal
                ; - #d decimal
                ; - #x hexadecimal
                ; If yes, what follows must be a number, so we can jump there
                ; TODO

_not_sharp:
                ; ---- Check for decimal numbers ----
                ; TODO check for minus as a sign

                ; Result is in carry flag: set we have a decimal number, clear
                ; this is something else
                jsr help_is_decdigit
                bcc _not_decnum

                ; We have a decimal number, start with the start token
                pha                     ; Save the first digit
                lda #T_DECNUM_START
                jsr lexer_add_token
                pla                     ; get back the first digit
                jsr lexer_add_token

_decnum_loop:
        ; We start our own little mini-loop to pick up numbers. This is not
        ; very effective in the long run, but good enough for a first version.
        ; Assumes the index for the buffer is in Y, and aborts if we have
        ; anything else than a decimal digit, which includes any end-of-line
        ; char
                iny
                lda cib,y
                jsr help_is_decdigit
                bcc _done_decnum

                jsr lexer_add_token
                bra _decnum_loop

_done_decnum:
                ; We add the token to signal the end of the number and then
                ; continue
                lda #T_DECNUM_END
                jsr lexer_add_token

                ; Remember not to increase Y because we are already pointing to
                ; the next character
                bra lexer_next_same_char

_not_decnum:
                ; ---- Check for strings ----
                ; TODO Test for strings

                ; ---- Check for comment ---- 
_not_string:
                ; TODO See if we have a comment. This is a bit tricky because
                ; we can't just bail to the next input line - the input can
                ; continue after the end of the line


                ; ---- Lexer errors ----
lexer_error:
                ; Error, this isn't valid input. Complain and try again
                lda #str_unbound
                jsr help_print_string
                ; TODO add offending variable name to error output
                jmp repl

lexer_next:
                ; Move on to the next character in the input or, if we're all
                ; done, add the end-of-input token. Note this is a failsafe, we
                ; usually should just end when we find the zero byte
                iny

lexer_next_same_char:
                ; Make sure we don't go past the end of the input buffer
                cpy ciblen
                beq lexer_end_of_input

                jmp lexer_loop

lexer_end_of_input:
                ; Add end-of-input token. The parser assumes that this will
                ; always be present so we really, really need to get this right
                lda #T_END
                jsr lexer_add_token

                ; Continue with parsing
                jmp lexer_done



; ==== LEXER HELPER ROUTINES ====

; Internal lexer functions. Anything here that might be of use to other parts
; of Cthulhu Scheme should be moved to helpers.asm. These all start with lexer_


lexer_add_token:
        ; Add a token to token buffer. Assumes token is an 8-bit number in A.
        ; TODO make sure we don't move past the end of the token buffer
                phy             ; Could also store in cibp
                ldy tkbp
                sta tkb,y       ; LSB is in A
                iny
                sty tkbp
                ply
                rts


; ==== TOKEN LIST ====
;
; Tokens are 8-bits long with names that start with T_ and are in upper case in
; the source code (which is for humans only). Some are followed by pointers or
; other data.

; 64tass doesn't seem to have a command for enum so we have to do this the hard
; way
        
; ---- Primitives ---- 

T_END           = $00
T_PAREN_OPEN    = $01   ; '('
T_PAREN_CLOSED  = $02   ; ')'
T_SHARP         = $03   ; '#' - note '#f', '#t' and others are precprocessed
T_LETTER        = $04   ; 'a' ... 'z', followed by single-byte ASCII letter
T_NUMBER        = $05   ; '0' ... '9', followed by single-byte ASCII number


; ---- Preprocessed ----

; We let the lexer do quite a bit of the heavy lifting so we don't have to
; touch the data more than we have to. Tokens that terminate a sequence of
; characters must have bit 7 set (for example, T_DECNUM_END is $82)

T_TRUE          = $10   ; '#t'
T_FALSE         = $11   ; '#f'
T_DECNUM_START  = $12   ; Marks beginning of a decimal number sequence

T_DECNUM_END    = $82   ; Marks end of a decimal number sequence, see $12

; ===== CONTINUE WITH PARSER ====
lexer_done:
