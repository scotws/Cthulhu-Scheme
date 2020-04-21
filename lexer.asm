; Lexer (Tokenizer) for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 21. Apr 2020

; The lexer (tokenizer) is kept in a separate file to make changes easier. It
; goes through the characters read into the input buffer (cib) and turns them
; into tokens which are stored in the token buffer (tkb). We do some
; processing in this stage because we don't want to touch the data too much.
lexer:
        .if DEBUG == true
                jsr debug_dump_input
        .fi

        ; Intialized indices to charater and token buffers
                ldy #0
                stz cibp
                stz cibp+1      ; MSB currently unused
                stz tkbp
                stz tkbp+1      ; MSB currently unused

        ; If this is just an empty line - we arrive here just with the
        ; end of line terminator (a zero) - we get this over as quickly
        ; as possible and just jump to the REPL again
                tya
                ora cib,y
                bne lexer_loop
                jmp repl_empty_line

lexer_loop:
                lda cib,y

        ; ---- Check for comments ----
        
        ; We have to deal with comments before we deal with whitespace
        ; because a LF in a comment will end the comment, and stripping
        ; whitespace out destroys that end-of-comment function
                cmp #$3B        ; semicolon
                bne _no_comment

        ; There are two kinds of comments in Scheme, but we just deal
        ; with the ';' here. Skip anything till the end of the line
        ; character and then continue. We assume that we have a LF in
        ; the input string, because the reader will store the LF in
        ; a comment. 

_comment_loop:
                iny
                lda cib,y

        ; Remember to check for both LF and CR because
        ; different computers will store different stuff
                cmp #AscLF
                beq _comment_done
                cmp #AscCR
                bne _comment_loop

_comment_done:
                jmp lexer_next

_no_comment:
        ; ---- Check for whitespace ----
        
        ; Deal with whitespace. This includes line feeds because
        ; we can have those inside delimiters and comments. See the
        ; discussion at the code for helper_is_whitespace in
        ; helpers.asm for what is all considered whitespace. This must
        ; come after we look for comments
                jsr help_is_whitespace
                bcc _not_whitespace

        ; It's whitespace, so we skip it
                jmp lexer_next

_not_whitespace:
_test_parens:
        ; ---- Check for parens ----
        
        ; We do this early because this is Scheme, and there are going
        ; to be a lot of them
                cmp #'('        ; check for open parens
                bne _not_parens_start

        ; We have an open parens. We store the token and move on
                lda #T_PAREN_START
                jsr lexer_add_token
                jmp lexer_next

_not_parens_start:
                cmp #')'        ; check for close parens
                bne _not_parens_end

        ; We have an close parens. We store the token and move on
                lda #T_PAREN_END
                jsr lexer_add_token
                jmp lexer_next

_not_parens_end:
        ; ---- Check for tick ----
        
        ; Ticks are used quite a lot in Scheme so we do this early as well
                cmp #$27                ; "'" tick for (quote)
                bne _not_tick

                lda #T_TICK
                jsr lexer_add_token
                jmp lexer_next

_not_tick:
        ; ---- Check for end of input ----

        ; We have a zero byte as a marker that the line is over
                bne _not_done
                jmp lexer_end_of_input          ; not the same as lexer_done

_not_done:
        ; ---- Check for sharp stuff ----

        ; See if first character is #
                cmp #'#'
                beq _got_sharp 
                jmp lexer_not_sharp             ; too far for branch

_got_sharp:
        ; We have a #, so see which type it is. First, see if this is
        ; a bool, so either #f or #t because they probably come up
        ; a lot. ("Probably" of course is not really good enough, at
        ; some point we should do some research to see just how common
        ; they are)
                iny                     
                lda cib,y
                
        ; TODO see if this past the end of the buffer

                cmp #'t'        ; We're optimists so we check for true first
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
        ; ---- Check to see if we have a backslash #\ ----

        ; A whole group of stuff starts with a sharp and a backslash.
        ; If this is not the case, we can skip over this part of the
        ; tokenization
                cmp #'\'
                bne _no_backslash

        ; ---- Check for single char #\a ----
        
        ; TODO See if we have the combination of a single character and
        ; a space or end-of-input ($00) after this.

_not_single_char:   
        ; ---- Check for named chars #\<NAME> ----

        ; TODO Scheme has a very annoying system of individually named
        ; characters, see
        ; https://groups.csail.mit.edu/mac/ftpdir/scheme-7.4/doc-html/scheme_6.html
        ; for details. At some point, we should support them:
        ;       #\altmode                 ESC
        ;       #\backnext                US
        ;       #\backspace               BS
        ;       #\call                    SUB
        ;       #\linefeed                LF
        ;       #\page                    FF
        ;       #\return                  CR
        ;       #\rubout                  DEL
        ;       #\space
        ;       #\tab                     HT
        ; Before we do any of this, we need to see how much space this 
        ; is going to take.

_not_named_char:                
        ; ---- Error in input ----

        ; TODO If we land here, we have a problem because we can't
        ; figure out what the #\ combination is

_no_backslash:
        ; ---- Check for vector constant #( ----

        ; TODO Vectors will be added at a later date

_not_vector:
        ; ---- Check if we have a radix prefix ----

        ; We have four prefixes for numbers:
        ;
        ;       #b for binary
        ;       #d for explicit decimal (default)
        ;       #o for octal (only if 'OCTAL = true' in platform file)
        ;       #x for hexadecimal
        ;
        ; The lexer stores numbers by starting with a T_NUM_START token, which
        ; is followed by a byte that marks the radix ($02, $08, $0A, or $10),
        ; and a byte that has the length of the string, including the sign '+'
        ; or '-'. This means that the maximal number of digits for a number can
        ; be 255 for positiv numbers (with no sign) and 254 for negative
        ; numbers (with a '-'). After the length byte, the actual digits are
        ; included as a string of bytes, before the string is terminated by the
        ; T_NUM_END token. It is up to the parser to decide if the number will
        ; be a fixnum or a bignum, and to convert it to whichever. 

        ; We test for hexadecimal first because this is
        ; probably going to be the most common case 
                cmp #'x'        ; #x is hexadecimal
                bne _not_hexnum
                lda #$10        ; Base 16
                bra lexer_got_number

_not_hexnum:
                cmp #'b'        ; #b is binary
                bne _not_binnum
                lda #$02        ; Base 2
                bra lexer_got_number

_not_binnum:
                cmp #'d'        ; #d is explicit decimal

        ; Our failure jump target depends if we have assembled
        ; support for octal numbers or not. This makes the code
        ; slightly messy. Did I mention I hate octal?
        .if OCTAL == true
                bne _not_expldecnum
        .else
                bne _illegal_radix
        .fi

                lda #$0A        ; Base 10
                bra lexer_got_number

        .if OCTAL == true
_not_expldecnum:
        ; Nobody in their right mind still uses octal, right?
        ; Still, we have to check for it if the OCTAL flag is
        ; set to true in the platforms file
                cmp #'o'        ; #o is octal
                bne lexer_not_octnum
                lda #$08        ; Base 8
        .fi 
_illegal_radix:                        
        ; If it wasn't one of #b, #d, #x, and possibly #o, this
        ; is bad, because this means we have some malformed
        ; number such as #s. 
                jmp lexer_illegal_radix

lexer_got_number:
        ; We have a number. We jump here with the radix in A (2, 10, 16, and
        ; possibly 8 if OCTAL is true).
                pha                     ; Save the radix for the moment
                lda #T_NUM_START
                jsr lexer_add_token

        ; Add the radix
                pla
                jsr lexer_add_token

        ; There are two places to put the length of the string in the token
        ; stream: At the beginning after the radix, which makes it easier for
        ; the parser later, or after the T_NUM_END token, which makes it easier
        ; for us. If we put it at the end, however, the parser will have to
        ; walk through the whole string to find the terminator, which is a O(n)
        ; operation. It should be faster to store a dummy value here, remember
        ; where it is, and then store the length once we have counted the
        ; string.
                ldx tkbp        ; get index of where length will be
                stx tmp0
                
                lda #0          ; dummy length value
                jsr lexer_add_token

        ; We now walk through the following characters in the buffer until we
        ; hit a delimiter, especially a space. We do no preprocessing and 
        ; leave up to the parser to actually check for an illegal character.
        ; This will have to all be rewritten later anyway if we have other
        ; number types. 
                iny             ; Y is still the input buffer index
                lda cib,y
                ldx #0          ; X counts length of string
                
        ; The first character must be a sign ('+' or '-') or a digit of the
        ; number base. It may not be a delimiter or the 00 that terminates the
        ; input
                cmp #'-'
                bne _check_for_plus
                lda #T_MINUS
                jsr lexer_add_token
                iny             ; skip minus character
                inx             ; string now has length of 1
                bra _sign_done
_check_for_plus:
                cmp #'+'
                bne _default_plus

        ; One way or the other this is a positive number, but
        ; we only have to skip the character if it is an
        ; explicit '+'
                iny

                ; drop through to _default_plus
_default_plus:
                lda #T_PLUS
                jsr lexer_add_token
                inx             ; string now has length of 1

        ; TODO we should be able to reuse large parts of this code for other
        ; elements such as strings and symbols, check rewrite as a subroutine
        ; once we get there. 

_sign_done:
        ; We're done with the sign. Get the first character,
        ; which is the first digit of the number, sign or no
        ; sign. 
                lda cib,y
                        
        ; Complain if this is end of input or a delimiter, we
        ; need at least one character to be a digit 
                beq lexer_terminator_too_early  ; 00 terminates input
                jsr help_is_delimiter
                bcs lexer_delimiter_too_early

        ; This should be our first real digit. We could in
        ; theory do some first processing here, but we don't
        ; want to, say, convert $30 ("0") to $00 because that
        ; might get the parser confused when it is looking for
        ; a terminator character
_number_loop:
                jsr lexer_add_token
                inx             ; String one character longer
                iny             ; Next character

        ; Now we're in the actual loop, we repeat until we find
        ; a delimiter or the input ends. 
                lda cib,y
                beq _legal_terminator

        ; Numbers can be treminated with a parens, for instance (+ #x1 #x2)
                jsr help_is_delimiter
                bcs _number_done
                
                bra _number_loop
                
_legal_terminator:
        ; TODO The digit sequence is over because the whole line is over. At the
        ; moment, we just drop through to the code to end with a line and then
        ; let the normal check at the top of the main lexer loop handle the
        ; fact that we're done with the input. We do waste a few cycles this
        ; way, though, so at some point we might want to come back to this part
        ; and make it more efficient.

                ; drop through to _number_done
        
_number_done:
        ; The number string is over. We add the length of the string to the front
        ; part of the token stream, and add a terminator token for the number
                lda #T_NUM_END
                jsr lexer_add_token

                txa             ; number of chars was in X
                ldx tmp0        ; index of length byte in token stream
                sta tkb,x

        ; Continue with next entry in the input stream
                jmp lexer_next_same_char


lexer_illegal_radix:
lexer_terminator_too_early:
lexer_delimiter_too_early:
        ; We were given a terminator or another delimiter too
        ; early, return an error and restart REPL
                lda #str_bad_number
                jsr help_print_string
                jmp repl

lexer_not_octnum
lexer_not_sharp:
        ; ---- Check for explicit digits 123 ----

        ; TODO this includes the decimal point so we can check for the period
        ; later

; TODO TODO HIER HIER TODO TODO

        ; Result is in carry flag: set we have a decimal number, clear
        ; this is something else

_not_decnum:
        ; ---- Check for strings ----
                cmp #$22        ; '"' ASCII value
                bne _not_string

        ; We have the beginning of a string. The way this works is that we add
        ; a token that marks the beginning of a string, then just add the
        ; characters as they come until we get another quotation mark, and then
        ; add the string terminator token. We include a conversion of CR to LF
        ; depending on how the flag is set in the platform file.

                lda #T_STR_START
                jsr lexer_add_token
_string_loop:
                iny
                lda cib,y

                cmp #$22        ; '"' closes string
                beq _string_done

        .if STRING_CR_TO_LF == true
                cmp #AscCR
                bne +
                lda #AscLF
+
        .fi
                jsr lexer_add_token
                bra _string_loop
_string_done:
                lda #T_STR_END
                jsr lexer_add_token
                bra lexer_next


_not_string:
        ; ---- Check for dots ---- 

        ; Dots are used as parts of pairs, such as ( 1 . 2 ) if the cdr is not
        ; the empty list
                cmp #'.'
                bne _not_dot
                
                lda #T_DOT
                jsr lexer_add_token
                bra lexer_next
_not_dot:
        ; --- Check for identifiers ----

        ; HIER HIER TODO
        

lexer_error:
        ; ---- Lexer errors ----
        
        ; Error, this isn't valid input. Complain and try again
                pha
                lda #str_unbound
                jsr help_print_string_no_lf
                pla
                jsr help_byte_to_ascii
                jsr help_emit_lf
                jmp repl

lexer_next:
        ; Move on to the next character in the input or, if we're all
        ; done, add the end-of-input token. Note this is a failsafe, we
        ; usually should just end when we find the zero byte
                iny

lexer_next_same_char:
        ; Make sure we don't go past the end of the input buffer, this
        ; is slightly paranoid
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

; Tokens that terminate a sequence of characters must have bit 7 set (for
; example, T_NUM_END is $82)

T_END           = $00   ; Terminates token stream
T_TICK          = $01   ; "'" - tick character
T_TRUE          = $02   ; '#t'
T_FALSE         = $03   ; '#f'
T_SHARP         = $04   ; '#' - note '#f', '#t' and others are precprocessed
T_DOT           = $05   ; "." - dot/period, used for pairs

T_NUM_START     = $12   ; Marks beginning of a number sequence
T_STR_START     = $13   ; Marks beginning of a string
T_ID_START      = $14   ; Marks beginning of an identifier

T_PLUS          = $20   ; '+' Also used in number token sequence
T_MINUS         = $21   ; '-' Also used in number token sequence
T_STAR          = $22   ; '*' Also used for math
T_SLASH         = $23   ; '\' Also used for math

T_NUM_END       = $82   ; Marks end of a number sequence, see T_NUM_START
T_STR_END       = $83   ; Marks end of a string, see T_STR_START
T_ID_END        = $84   ; Makrs end of an identifier, see T_ID_START

T_PAREN_START   = $AA   ; '(' - parens open
T_PAREN_END     = $FF   ; ')' - parens closed


; ===== CONTINUE WITH PARSER ====
lexer_done:
