; Low-Level Helper Functions for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 30. Apr 2020

; Many of these were originally taken from Tali Forth 2, which is in the public
; domain. All routines start with help_. They are all responsible for saving
; the register status 

; ---- Byte to ASCII ----
help_byte_to_ascii:
        ; """Convert byte in A to two ASCII hex digits and EMIT them. Destroys
        ; the value in A
        ; """
                pha
                lsr             ; convert high nibble first
                lsr
                lsr
                lsr
                jsr help_nibble_to_ascii
                pla

                ; fall through to help_nibble_to_ascii

help_nibble_to_ascii:
        ; """Private helper function for byte_to_ascii: Print lower nibble
        ; of A and and EMIT it. This does the actual work.
        ; """
                and #$0F
                ora #'0'
                cmp #$3A        ; '9+1
                bcc +
                adc #$06

+               jmp help_emit_a       ; JSR/RTS 


; ---- Compare 16 bit numbers ----

; TODO ADD Compare 16 bit


; ---- Convert to lower case ----
help_to_lowercase:
; Given a character in A, return the lower case version in A as well.
; Scheme is case-insensitive, see 
; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Uppercase-and-Lowercase.html
; for details
; TODO Add conversion routine to lower case
                rts

; ---- Emit line feed quickly
help_emit_lf:
        ; Print a line feed. Since we do this so often it is worth the savings. 
                lda #AscLF

                ; drop through to help_emit_a

; ---- Emit character in A quickly ----
help_emit_a:
        ; Print the character in A without fooling around. This still allows
        ; the output to be vectored. Call it with JSR. 
                jmp (output)    ; JSR/RTS

; ---- Key A ----
help_key_a:
        ; The 65c02 doesn't have a JSR (ADDR,X) instruction like the
        ; 65816, so we have to fake the indirect jump to vector it.
        ; This is depressingly slow. We use this routine internally
        ; when we just want a character
                jmp (input)             ; JSR/RTS


; ---- System print routines ----

help_print_string_no_lf:
        ; """Given the number of a zero terminated string in A, print to the
        ; current output without adding a line feed. Uses Y and tmp0 by falling
        ; through to help_print_common
        ; """
                ; Get the entry from the string table
                asl
                tay
                lda string_table,y
                sta tmp0                ; LSB
                iny
                lda string_table,y
                sta tmp0+1              ; MSB

                ; fall through to help_print_common
help_print_common:
        ; """Common print routine used by both the print functions and
        ; the error printing routine. Assumes string address is in tmp0. Uses
        ; Y.
        ; """
                ldy #0
_loop:
                lda (tmp0),y
                beq _done               ; strings are zero-terminated

                jsr help_emit_a         ; allows vectoring via output
                iny
                bra _loop
_done:
                rts

help_print_string: 
        ; """Print a zero-terminated string to the console/screen, adding a LF.
        ; We do not check to see if the index is out of range. Uses tmp0.
        ; Assumes number of string is in A.
        ; """
                jsr help_print_string_no_lf
                lda #AscLF              ; we don't use (newline) because of string
                jmp help_emit_a         ; JSR/RTS


; ---- Tokenization Helpers ----

help_is_decdigit:
        ; """Given a character A, see if it is a decimal digit from 0 to 9. If
        ; yes, set the Carry Flag, else clear it. Perserves A. 
        ; """
        ; TODO Tali Forth has a more general version of this in DIGIT? that can
        ; deal with other radixes, long term adapt that
.block
                cmp #'0'
                bcc _below_zero         ; A is < '0'

                cmp #':'                ; A is >= ':', which is '9'+1
                bcs _above_nine         

                sec
                rts
                
_above_nine:    
                clc
_below_zero:
                ; Carry flag is clear
                rts
.bend

       
help_is_delimiter:
        ; """Given a character in A, see if it is a legal Scheme delimiter. The
        ; result is returned in the Carry flag: Set mans is a delimiter,
        ; cleared means it is not. See the list of delimiters at
        ; https://www.gnu.org/software/mit-scheme/documentation/mit-scheme-ref/Delimiters.html
        ; """
        ; TODO this has the basic structure as help_is_extended_alpha, we
        ; should see if we can combine the two routines
                jsr help_is_whitespace
                bcs _delimiter_done

                ; That was the easy one. We now run through the list of
                ; delimiter characters (see strings.asm) to see if any one is
                ; here
                clc
                phx
                ldx s_delimiters        ; length of delimiter chars string

_delimiter_loop:
                ; Check back to front
                cmp s_delimiters,X
                beq _found_delimiter
                dex
                bne _delimiter_loop

                ; If we end up here we didn't find a delimiter, clear carry
                ; flag and return
                plx
                clc
                rts

_found_delimiter:
                plx
                ; drop through to _is_delimiter
_is_delimiter:
                sec
                ; drop through to _delimiter_done
_delimiter_done:
                rts


help_is_extended_alpha:
        ; """Given a character in A, set the carry flag if it
        ; is an extende alphabetic character (see strings.asm). Otherwise
        ; clear the carry flag.
        ; """
        ; TODO this has the basic structure as help_is_delimiter_loop, we
        ; should see if we can combine the two routines
                clc
                phx
                ldx s_extended          ; length of extended chars string
_alpha_loop:
                cmp s_extended,X
                beq _found_extended
                dex
                bne _alpha_loop

                ; If we end up here we didn't find a delimiter, clear carry
                ; flag and return
                plx
                clc
                rts

_found_extended:
                plx
                ; drop through to _is_extended
_is_extrended:
                sec
                ; drop through to _extended_done
_extended_done:
                rts


help_is_letter:
        ; """Given an upper- or lowercase letter in A, set the carry flag if it
        ; is a legal letter from 'a' to 'z', and return the lowercase version
        ; in A. We need to keep this as a separate routine because identifiers
        ; may only start with a letter or extended alphabetic character. See 
        ; http://www.obelisk.me.uk/6502/algorithms.html for a discussion of
        ; this routine
        ; """
                ; See if upper case
                cmp #'A'
                bcc _not_letter       ; too low
                cmp #'Z'+1
                bcc _uppercase

                ; No, but there is still hope for lowercase
                cmp #'a'
                bcc _not_letter       ; between upper- and lowercase
                cmp #'z'+1
                bcc _is_letter

                ; drop through to _not_letter
_not_letter:
                clc
                rts
_uppercase:
                clc
                adc #'a'-'A'    ; 32, if you're curious
                ; drop through to _is_letter
_is_letter:
                sec
                rts


help_is_whitespace:
        ; """Given in a character in A, see if it is legally a Scheme
        ; whitespace character. Result is returned in the Carry flag: Set means
        ; is whitespace, cleared means is not. For details on what Scheme
        ; consideres whitespace, see
        ; https://groups.csail.mit.edu/mac/ftpdir/scheme-7.4/doc-html/scheme_6.html.
        ; In short, it is space ($20), tab (HT, $09), page (FF, $0C), linefeed
        ; (LF, $0A), and return (CR, $0D). This routine is the basis for the
        ; Scheme procedure (char-whitespace? char)
        ; """
        ; TODO This is probably not the fastest version possible, because we
        ; will have lots of parens and normal ASCII chars before we have
        ; something exotic like a page character. We should come back to this
        ; and speed stuff up
.block
                sec             ; default is whitespace
                cmp #$20        ; SPACE, assumed to be the most common char
                beq _done
                cmp #$09        ; TAB, probably the second most common in Scheme
                beq _done
                cmp #$0A        ; Linefeed, normally ends input but not with Scheme
                beq _done
                cmp #$0D        ; Return, normally ends input but not with Scheme
                beq _done
                cmp #$0C        ; Page, which is strange, but in the standard
                beq _done

                clc             ; If we end up here, it's not whitespace
_done:
                rts
.bend
 
; ---- Parser helpers ----

help_hexascii_to_value:
        ; """Given a character that is probably a ASCII hex digit, return the
        ; corresponding value as the lower nibble. For instance 'F' is returned
        ; as $0F. If there was an error, the sign bit (bit 7) is set. This
        ; routine has been tested for correct digits, but not yet for incorrect
        ; digits.
        ; """
.block        
                jsr help_is_decdigit
                bcc _see_if_letter

                ; It's a digit 0-1
                sec
                sbc #'0'
                bra _done
                
_see_if_letter:
                ; What is really annoying is that this can be an uppercase or
                ; lower case letter, and that there are characters in the ASCII
                ; table between '9' and 'A'. 
                cmp #'A'        ; lower than 'A' can't be right
                bcc _error
                cmp #'g'        ; 'g' or above can't be right
                bcs _error

                ; We assume that we will mostly be writing in lowercase,
                ; because that's what I do. 
                cmp #'a'
                bcc _uppercase

                ; We know for sure now it's a legal lowercase letter
                sec
                sbc #71         ; moves 'a' to 10 ($0A)
_done:
                and #$0F        ; paranoid
                rts

_uppercase:
                ; It might be uppercase, but we can't be sure yet
                cmp #'G'
                bcs _error

                ; It's uppercase
                sec
                sbc #55         ; moves 'A' to 10 ($0A)
                bra _done

_error:
                ; Something went wrong and we don't really care what, so we
                ; just return with bit 7 set
                lda #$80
                rts
.bend

; ---- AST Walker ----

; The AST walker walks through a tree constructed out of cons cells by the
; parser one pair at the time and returns the car and cdr as entries in the
; Zero Page, and car also in A and Y. It is used by first calling
; help_walk_init, which puts the first values in the Zero Page. After that, it
; is used with help_walk_next get the next pair. The walker is used by the
; Evaluator, Reader and Debug routines. 

; It is assumed that we first have the cdr and then the car. All data is little
; endian. 
;                         LSB   MSB
;                       +-----+------+
;        prev pair -->  |  cdr cell  |  ---> next pair
;                       +-----+------+
;                       |  car cell  |
;                       +-----+------+

; We do absolutely no checking if the user gave us a correct address. If this
; is not a pair, so be it, we will return garbage.

; TODO Currently the walker is not able to handle branches or recursion or
; "depth first". This will be added once we have an AST that demands it. 

help_walk_init:
        ; Initialize the walker. Call with the MSB of the first pair in A and
        ; the LSB in Y (remember "Little Young Americans", little endian Y and
        ; A). Then call this routine. It will load the first car and cdr into
        ; their respective fields. You can use this routine to set a different
        ; root of the the tree than the AST it is usually used for. Destroys
        ; A and Y. If this is the last pair in the tree, carry is set, else
        ; cleared.
                sty walk_curr           ; LSB
                sta walk_curr+1         ; MSB

        ; This routine is call less than help_walk_common so we branch here and
        ; drop through there
                bra help_walk_common

help_walk_next:
        ; Move on to the next entry, loading its car and cdr into Zero Page and
        ; the car into Y and A, and setting carry flag depending if this is the
        ; last entry.
                lda (walk_curr)
                pha
                ldy #1
                lda (walk_curr),y       ; MSB

        ; Remember that what is stored in the cdr is not a simple 65c02
        ; address but the Cthulhu Scheme pair object. This means that
        ; the first nibble of the MSB is the pair tag and not the
        ; correct address. We have to replace it by the RAM segment
        ; nibble for the AST. 
        
        ; TODO make this more general so we can walk any pair chain in any RAM
        ; segment, not just the current AST
                and #$0F                ; mask the pair tag
                ora rsn_ast             ; replace by nibble for the AST

                sta walk_curr+1 
                pla
                sta walk_curr           ; LSB

                ; drop through to help_walk_common

help_walk_common: 
        ; Common code sequence to copy stuff from current pair into the
        ; respective Zero Page variables and check to see if this is end of the
        ; tree
        
        ; Start with the cdr which we are pointing to and place it in Zero Page
                lda (walk_curr)
                sta walk_cdr            ; LSB
                ldy #1
                lda (walk_curr),y
                sta walk_cdr+1          ; MSB
                iny

        ; Handle question if this is the last entry. We have the MSB of the cdr
        ; Note this is cheating because we assume that OT_EMPTY_LIST is $0000 
                stz walk_done           ; Default is not done, $00
                ora walk_cdr            ; MSB in A, logical or with LSB
                bne _store_car
                dec walk_done           ; Wrap $00 -> $FF, we're done

                ; fall through to _store_car

        ; Place the car in Zero Page    
_store_car:
                lda (walk_curr),y       ; LSB
                sta walk_car
                pha                     ; We return this later in Y
                iny
                lda (walk_curr),y       ; MSB
                sta walk_car+1

        ; We return the MSB of the car in A and the LSB of car in Y in addition
        ; to storing them in the Zero Page. The MSB is still in A.
        ; TODO we don't use this, see if we can get rid of it
                ply

                rts

; ---- END ----
