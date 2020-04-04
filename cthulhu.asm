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

                ; TODO clear the heap
                ; TODO define high-level procudures by loading from file

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
        ; Some of this (like adding a token to the token buffer) could be moved
        ; to a subroutine to save space. However, we are currently leaving it
        ; here unrolled for speed reasons. This might change at a later date

                ; Initialize indices to character and token buffers
                ldy #0
                sty tkbp
                sty tkbp+1      ; MSB currently unused
                sty cibp
                sty cibp+1      ; MSB currently unused

repl_tokenize_loop:
                lda cib,y

                .if DEBUG == true
                ; TODO TESTING Quit on '@', just for the moment
                cmp #'@'
                bne +
                brk
+
                .fi

                ; TODO skip over whitespace. This includes line feeds because
                ; we can have those inside delimiters and comments
                
                ; Convert to lower case
                ; TODO this is currently just fake
                jsr help_to_lowercase


                ; ---- Testing for sharp stuff ----
_test_sharp:
                ; See if first character is #
                cmp #'#'
                bne _test_fixnum        ; TODO or whatever next test is

                ; We have a #, so see which type it is. First, see if this is
                ; a bool, so either #f or #t because they probably come up
                ; a lot. ("Probably" of course is not really good enough, at
                ; some point we should do some research to see just how common
                ; they are)

                iny
                ; TODO see if we're past the end of the line

                lda cib,y
                cmp #'t'                ; We're optimists so we check for true first
                bne _test_bool_false

                ; We have a true bool. Add this to the token buffer
                lda <#oc_true           ; Token is an immediate constant
                ldx >#oc_true 
                jsr repl_add_token
                jmp repl_tokenize_next

_test_bool_false:
                cmp #'f'
                bne _test_char
                
                ; We have a false bool. Add this to the token buffer
                lda <#oc_false          ; Token is an immediate constant
                ldx >#oc_false
                jsr repl_add_token
                jmp repl_tokenize_next

_test_char:
                ; TODO See if char #\a

_test_vector:
                ; TODO See if vector constant #(

_test_radix: 
                ; TODO See if we have a radix number prefix
                ; - #b binary
                ; - #o octal
                ; - #d decimal
                ; - #x hexadecimal
                ; If yes, what follows must be a number, so we can jump there


                ; ---- Testing for numbers ----

_test_fixnum:
                ; TODO See if we have a number

_test_comment:  
                ; TODO See if we have a comment. This is a bit tricky because
                ; we can't just bail to the next input line - the input can
                ; continue after the end of the line
                
repl_tokenize_error:
                ; Error, this isn't valid input. Complain and try again
                lda #str_unbound
                jsr help_print_string
                ; TODO add offending variable name to error output
                jmp repl

repl_tokenize_next:
                ; Move on to the next character in the input or, if we're all
                ; done, add the end-of-input token
                iny
                cpy ciblen
                beq _end_of_input
                jmp repl_tokenize_loop

_end_of_input:
                ; Add end-of-input token
                lda #0
                tax
                jsr repl_add_token

                ; Continue with parsing
                bra repl_parse


; ---- Tokenizer helper functions ----

repl_add_token:
        ; Tokenizer subroutine: Add token to token buffer. Assumes LSB of token is in
        ; A and MSB of token is in X. Does not touch X.
        ; TODO make sure we don't move past the end of the token buffer
                phy                     ; Could also store in cibp
                ldy tkbp

                sta tkb,y             ; LSB is in A
                iny
                txa
                sta tkb,y             ; MSB is in X
                iny

                sty tkbp 
                ply

                rts


; ---- PARSE ----

; At this stage, we should have the tokens in the token buffer, terminated by
; an end of input token (0000). We now need to construct a tree (or another
; structure) that reflects the input.
repl_parse: 
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
repl_eval:
                .if DEBUG == true
                ; TODO Testing print 'e' so we know where we are
                lda #'e'
                jsr debug_emit_a
                .fi

                ; TODO TESTING
                ; Evaluate returns the result in the return zero page location.
                ; For the moment, this is trivial
                lda tkb
                sta return
                lda tkb+1
                sta return+1


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
                cmp #t_bool
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
