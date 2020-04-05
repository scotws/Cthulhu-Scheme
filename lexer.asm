; Lexer (Tokenizer) for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 05. Apr 2020

; The lexer (tokenizer) is kept in a separate file to make changes easier. It
; goes through the characters read into the input buffer (cib) and turns them
; into tokens which are stored in the token buffer (tkb). We do a lot of
; processing in this stage because we don't want to touch the data too much.

; ==== LEXER CODE ====
lexer:
                ; Intialized indices to charater and token buffers
                ldy #0
                sty tkbp
                sty tkbp+1      ; MSB currently unused
                sty cibp
                sty cibp+1      ; MSB currently unused


lexer_loop:
                lda cib,y

                .if DEBUG == true
                ; TODO TESTING Quit on '@', just for the moment
                cmp #'@'
                bne +
                brk
+
                .fi

                ; Skip over whitespace. This includes line feeds because
                ; we can have those inside delimiters and comments
                ; TODO this is currently fake
                jsr lexer_eat_whitespace


                ; ---- Check for parens ----
_test_parens:
                ; We do this early because this is Scheme, and there are going
                ; to be a lot of them
                ; TODO check for parens


                ; ---- Check for sharp stuff ----
_test_sharp:

                ; See if first character is #
                cmp #'#'
                bne _post_sharp_test    ; TODO weird label, but keep during editing

                ; We have a #, so see which type it is. First, see if this is
                ; a bool, so either #f or #t because they probably come up
                ; a lot. ("Probably" of course is not really good enough, at
                ; some point we should do some research to see just how common
                ; they are)
                iny                     ; TODO see if we're past end of buffer
                lda cib,y

                cmp #'t'                ; We're optimists so we check for true first
                bne _test_bool_false

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

_test_bool_false:
                cmp #'f'
                bne _test_char

                ; We have a false bool. Add this to the token buffer
                lda #T_FALSE
                jsr lexer_add_token
                jmp lexer_next

_test_char:
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

_post_sharp_test:        ; TODO weird label name, leave while testing


                ; ---- Check for strings ----
_test_string:
                ; TODO


                ; ---- Check for numbers ----
_test_number:
                ; TODO See if we have a number
                

                ; ---- Check for comment ---- 
_test_comment:
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
                ; done, add the end-of-input token
                iny
                cpy ciblen
                beq _end_of_input
                jmp lexer_loop

_end_of_input:
                ; Add end-of-input token. The parser assumes that this will
                ; always be present so we really, really need to get this right
                lda #T_END
                jsr lexer_add_token

                ; Continue with parsing
                jmp parser



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

lexer_eat_whitespace:
        ; Consume whitespace in the character buffer
        ; TODO code this
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
T_PAREN_OPEN    = $01    ; '('
T_PAREN_CLOSED  = $02    ; ')'
T_SHARP         = $03    ; '#' - note '#f', '#t' and others are precprocessed
T_LETTER        = $04    ; 'a' ... 'z', followed by single-byte ASCII letter


; ---- Preprocessed ----

; We let the lexer do quite a bit of the heavy lifting so we don't have to
; touch the data more than we have to

T_TRUE          = $10   ; '#t'
T_FALSE         = $11   ; '#f'
T_STRING        = $12   ; followed by 16-bit (12-bit) pointer to string in table
T_FIXNUM        = $13   ; followed by 16-bit (12-bit) number 
T_SYMBOL        = $14   ; followed by 16-bit (12-bit) pointer to symbol in table
T_BIGNUM        = $15   ; followed by 16-bit (12-bit) pointer to number in table
