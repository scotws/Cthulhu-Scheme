; Parser for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 13. Apr 2020

; The parser goes through the tokens created by the lexer in the token buffer
; (tkb) and create a Abstract Syntax Tree (AST) that is saved as part of the
; heap. 

; This is mainly based on Terrance Parr's "Language Implementation
; Patterns" p. 91 Homogeneous AST

; Each node of the AST consists of three entries, each 16 bit long: A pointer
; to the next node, the Scheme object of this node, and a pointer to this
; node's children. If there is no next node and/or no children, these entries
; are set to 0000. See the manual for details.
;
;                       +----------------+
;        prev node -->  |  Node Link     |  ---> next node
;                       +----------------+
;                       |  Scheme Object |  tag + object payload
;                       +----------------+
;                       |  Child Link    |  ---> child nodes  
;                       +----------------+
;
; This design allows simpler tree-walking code because it uses a single node
; type, however, it uses more RAM because even entries that never have children
; - bools or fixnums, for example - have a slot reserved for them that is
; always zero. This design might be changed in the future to a heterogeneous
; node type to save space, but first we want to make sure this works.


; ==== PARSER CODE ====

; At this stage, we should have the tokens in the token buffer, terminated by
; an end of input token (00). We now need to construct the abstact syntax tree
; (AST). 
parser: 

; ---- Debugging routines 

                .if DEBUG == true
                jsr debug_dump_token
                .fi 

; ---- Parser setup ----

                ; Clear the old AST
                stz ast
                stz ast+1
                
                ; Reset the pointer to the token buffer
                stz tkbp
                stz tkbp+1      ; fake, currently only using LSB
                
                ; The pointer to the current last entry in the ast should be
                ; zero at the beginning
                lda <#ast
                sta astp
                lda >#ast       ; paranoid, MSB always 00 for zero page
                sta astp+1


; ---- Parser main loop 

; Currently, we check for the various tokens by hand. Once the number of tokens
; reaches a certain size we should switch to a table-driven method for speed
; and size reasons. This makes debugging easier until we know what we are doing

                ldx #$FF
parser_loop:
                inx
                lda tkb,x

                ; ---- Check for end of input
_end_token:
                ; We assume there will always be an end token, so we don't 
                ; check for an end of the buffer.
                cmp #T_END      
                bne _not_end_token
                jmp parser_done

                ; ---- Check for boolean true token
_not_end_token:
                cmp #T_TRUE
                bne _not_true_token

                ; We have a true token, which makes our life easy, because we
                ; have the object as a constant
                lda <#OC_TRUE
                ldy >#OC_TRUE
                ; It is tempting to collapse the next two lines by adding the
                ; jump to parser_done to the end of parser_add_object and then
                ; just jumping as a JSR/RTS. In this case, it would work.
                ; However, other objects might require more stuff added, so for
                ; the moment, we leave it this way. Check the analog situation
                ; with the lexer. 
                jsr parser_add_object
                jmp parser_loop

                ; ---- Check for boolean false token
_not_true_token:
                cmp #T_FALSE
                bne _not_false_token

                ; We have a false token, which makes our life easy, because we
                ; have the object as a constant
                lda <#OC_FALSE
                ldy >#OC_FALSE
                jsr parser_add_object
                jmp parser_loop

                ; ---- Check for number token
_not_false_token:
                cmp #T_NUM_START
                beq +
                jmp parser_not_num              ; Too far for BRA
+
                ; We have a number start token, which means that the next bytes
                ; are going to be:
                ;
                ;       - radix: 2, 10, 16, or possibly 8 (one byte)
                ;       - length of number sequence including sign (one byte)
                ;       - sign token, either T_PLUS or T_MINUS (one byte)
                ;       - digits in ASCII (at least one byte)
                ;       - number sequence terminator T_NUM_END
                ;
                ; We assume that the lexer did its job and there are no
                ; formatting errors present and that the length and sign values
                ; are correct. However, we have not tested the actual digits
                ; themselves

                ; TODO currently, the lexer does not check to see if the radix
                ; is a valid #b, #d, #h or possibly #o. We just assume it's
                ; fine for the moment.

                ; Temporary storage for fixnums. We do it here to save space. 
                ; TODO use these for bignums also
                stz tmp1
                stz tmp1+1

                ; TODO Later we will have to decide if this is going to be
                ; a fixnum or a bignum. For the moment, we just go with fixnums
                inx                     ; skip over T_NUM_START TOKEN

                ; This should be the radix, which can be one of $02, $0A,
                ; $10 and possibly $08. We assume that the lexer didn't screw up
                ; and just save this for now
                lda tkb,x
                sta tmp0        ; radix
                inx

                ; This should be the length of the string, including the sign
                ; byte. Note this means that bignums are limited to 254
                ; characters as well
                lda tkb,x
                tay             ; we need the length of the string later ...
                dey             ; ... but we don't need to include the sign

                inx             ; Move to token for sign, T_PLUS or T_MINUS 
                lda tkb,x
                sta tmp0+1      ; Just store sign for now 

                inx

                ; We are now pointed to the first digit of the number sequence.
                ; The lexer should not allow numbers without digits, so we
                ; should be safe.

                ; There are two ways to convert the numbers from their ASCII
                ; representations to something we can actually use: Either with
                ; on general routine for all number bases or with individual
                ; ones for binary, decimal, hex, and (sigh) octal. At the
                ; moment, we are more worried about speed than about size, so
                ; we go with the specialized versions. 
                lda tmp0        ; radix

                cmp #$0a
                bne _not_dec

                ; ---- Convert decimal ----
                ; This should be the most common case so we do it first We
                ; arrive here with with X as the index to the first digit in
                ; the token buffer, Y the length of the string including the
                ; sign, and A as the radix, which we can now ignore. The sign
                ; is stored in tmp0+1 as a token.
                
                ; TODO convert decimal
                jmp parser_common_fixnum
                
_not_dec:
                cmp #$10
                bne _not_hex

                ; ---- Convert hex ----

                ; Having the length of the hex digit sequence makes it easy to
                ; decide if we have a fixnum or a bignum: If it is more than
                ; three digits, it's a bignum. 
                tya
                cmp #$04
                bcc _dec_fixnum

                ; TODO This would be a bignum, but we can't do that yet. We
                ; just give up and go get the next token
                jmp function_not_available

_dec_fixnum:
                ; We arrive here with a hex ASCII number sequence that is one,
                ; two, or three bytes long. We need to convert these to
                ; nibbles. We put our temporary number in tmp1 and tmp1+1. Note
                ; that we haven't checked yet if these are actually legal hex
                ; digits, and we haven't taken care of upper and lower case
                ; problems. We use a helper function for that.

                ; TODO This is probably not the best way to do this. Once code
                ; is stable or we at least have a testing suite working, come
                ; back and rewrite it, shifting nibbles in from the right like
                ; we do it with binary fixnums.

                ; We have already cleared tmp1 and tmp1+1 above for all fixnums

                ; -- First digit --
                ; We need at least one, so we don't have to test for the terminator token
                lda tkb,x
                jsr help_hexascii_to_value
                bpl _legal_first_hex_digit
                jmp parser_bad_digit

_legal_first_hex_digit:
                ; The Scheme objects are not stored little endian, so there are
                ; not either. 
                sta tmp1+1      ; MSB, lower nibble

                ; We don't use Y for the length to avoid counting problems, but
                ; look for the terminator token. 
                inx
                lda tkb,x
                cmp #T_NUM_END
                beq _done_hex

                ; -- Second digit --
                jsr help_hexascii_to_value
                bpl _legal_second_hex_digit
                jmp parser_bad_digit

_legal_second_hex_digit:
                asl
                asl
                asl
                asl
                ora tmp1+1      ; MSB, both nibbles
                sta tmp1+1

                inx
                lda tkb,x
                cmp #T_NUM_END
                beq _done_hex

                ; -- Third digit --
                jsr help_hexascii_to_value
                bpl _legal_third_hex_digit
                jmp parser_bad_digit

_legal_third_hex_digit:
                sta tmp1        ; LSB, lower nibble, upper is for object tag

                ; If we ended up here with three digits, we haven't checked for
                ; the number end token. We could check and panic, but we're
                ; going to trust the lexer here and just skip over it.
                inx
                
                ; drop through to _done_hex
_done_hex:
                ; We end here with the number in tmp1 and tmp1+1. However,
                ; there is a problem: The number is sorted back-to-front. So:
                ;
                ;       #x1   --> 0001, want 0001
                ;       #x12  --> 0021, want 0012
                ;       #x123 --> 0321, want 0123
                ;
                ; We don't want the common routine for fixnumbers to have to
                ; deal with this, so we do it ourselves here. If there is only
                ; one digit, we're done:
                cpy #1
                beq _done_hex_shuffle

                ; Two digits, we need to swap the nibbles in tmp1+1. See
                ; http://www.6502.org/source/general/SWN.html for a description
                ; of this:
                cpy #2
                bne _shuffle_three_digits
                lda tmp1+1      ; $21 for example
                asl
                adc #$80
                rol
                asl
                adc #$80
                rol
                sta tmp1+1
                bra _done_hex_shuffle

_shuffle_three_digits:
                ; Three characters, move stuff around more
                lda tmp1        ; $03
                tay
                lda tmp1+1      ; $21
                and #$0f        ; $01
                sta tmp1
                lda tmp1+1      ; $21
                and #$f0        ; $20
                sta tmp1+1
                tya             ; $03
                ora tmp1+1      ; $23
                sta tmp1+1
               
                ; drop through to _done_hex_shuffle

_done_hex_shuffle:

                ; Our hex number is now in the correct format to be built into
                ; an object. We still haven't taken the sign into account,
                ; though, and are pointing to the number terminator token in
                ; the token stream. We don't have to do anything about that
                ; because the next loop passage will do it for us.
                jmp parser_common_fixnum
                
_not_hex:               
                cmp #$02
                bne _not_binary

                ; ---- Convert binary ----
                
                ; Having the length of the binary digit sequence makes it easy to
                ; decide if we have a fixnum or a bignum: If it is more than
                ; twelve digits, it's a bignum. 
                tya
                cmp #$0D                ; "smaller than 13"
                bcc _bin_fixnum

                ; We arrive here with what should be a binary bignum, but we
                ; can't do that yet so we just whine and go back to the loop.
                jmp function_not_available

_bin_fixnum:
                ; We arrive here at the first digit of a binary number that can
                ; be up to twelve bits long. We haven't made sure these are
                ; legal chars either. 
                
                ; We have already cleared tmp1 and tmp1+1 above for all fixnums

                ; We need at least one bit or the lexer would not have
                ; constructed the fixnum. This means we don't have to compare
                ; with T_NUM_END, but we still do it here anyway because it
                ; makes the loop easier
_bin_fixnum_loop:
                lda tkb,x
                cmp #'0'
                beq _legal_bit_char
                cmp #'1'
                beq _legal_bit_char
                cmp #T_NUM_END
                beq _done_bin

                ; If it is none of the above, something is wrong
                jmp parser_bad_digit

_legal_bit_char:

                ; ASCII for '0' is $30 and '1' is $31. We mask the character to
                ; get the bit we want in bit 0
                and #$01                ; gives us $00 or $01
                ror                     ; push the bit into carry flag
                rol tmp1+1              ; rotate the carry flag into LSB ...
                rol tmp1                ; ... and highest bit of tmp1+1 to tmp1
                inx
                dey
                bne _bin_fixnum_loop    ; Repeat till we're done

_done_bin:
                ; Binary number is finished, nothing more to be done
                jmp parser_common_fixnum

_not_binary:
                ; if 'OCTAL == false' in the platform file we drop through 
                ; to _illegal_radix

                .if OCTAL == true
                cmp #$08
                bne _illegal_radix

                ; ---- Convert octal ----
                ; TODO convert octal
                bra parser_common_fixnum
                .fi
                
_illegal_radix:
                ; This really shouldn't happen: If we
                ; landed here, we have a radix we don't recognize because the
                ; lexer screwed up. Panic and return to REPL
                pha                             ; save the evil radix
                lda #str_bad_radix
                jsr help_print_string_no_lf
                bra parser_common_panic         ; prints offending byte and LF


                ; ---- Common processing for all fixnums ----
parser_common_fixnum:    
                ; The number is safe as bigendian in tmp1 and tmp1+1 in three
                ; nibbles, the sign is in tmp0+1 as T_PLUS or T_MINUS. We are
                ; pointed to the next token after the number sequence.

                ; TODO this will change a lot once we have bignum
                
                ; If we have a positive number, we're done and just need to
                ; construct the fixnum object
                lda tmp0+1
                cmp #T_MINUS
                beq _negative_number

                ; We're in luck, it's positive. The tag for a fixnum object is
                ; $20
                lda #OT_FIXNUM
                ora tmp1
                sta tmp1

                bra _add_fixnum_to_ast

_negative_number:
                ; TODO handle negative numbers

                ; drop through to _add_fixnum_to_ast

_add_fixnum_to_ast:
                lda tmp1+1
                ldy tmp1
                jsr parser_add_object

                ; Fixnum taken care of. Next token please!
_num_end:
                jmp parser_loop


parser_not_num: 
                ; TODO ADD NEXT CHECK HERE TODO 
                
                ; ---- No match found
paser_bad_token:
                ; This really shouldn't happen. Panic and return to main loop.
                ; The bad token should still be in A
                pha                             ; save the evil token
                lda #str_bad_token
                jsr help_print_string_no_lf
parser_common_panic:
                pla
                jsr help_byte_to_ascii          ; print bad token as hex number
                jsr help_emit_lf
                jmp repl


parser_bad_digit:
                ; Error routine if we found a digit that doesn't belong there
                pha
                lda #str_bad_number
                jsr help_print_string_no_lf
                bra parser_common_panic


function_not_available:
                ; TODO This is used for testing only
                lda #str_cant_yet
                jsr help_print_string
                jmp repl


; ==== PARSER HELPER ROUTINES =====

; Internel parser functions. Anything here that might be of use in other parts
; of Cthulhu Scheme should be moved to helpers.asm

parser_add_object: 
        ; Add a Scheme object to the AST. Assumes that the LSB of the object is in
        ; A and the MSB is in Y. Currently, we can just add immediate objects
        ; like booleans. When we arrive here, astp points to the last object in
        ; the tree we want to link to. We always add to the end of the list
        ; at which makes life easier. Uses tmp0, destroys X

        ; TODO at the moment, we can't add children. 
                phx             ; save index to token buffer
                phy             ; save MSB of the object
                pha             ; save LSB of the object
                
                ; Remember the first free byte of nemory as the start of the
                ; new node of the tree
                lda hp
                sta tmp0
                lda hp+1
                sta tmp0+1

                ; Store the termination object in the new node as the pointer
                ; to the next node. This marks the end of the tree in memory,
                ; though trees don't really have ends of course.
                lda <#OC_END
                ldy #0
                sta (hp),y
                iny
                lda >#OC_END
                sta (hp),y
                iny
                
                ; Store the object in the heap
                pla             ; retrieve LSB
                sta (hp),y
                iny
                pla             ; retrieve MSB, was in Y
                sta (hp),y
                iny

                ; Store the pointer to the children of this object. Since we
                ; don't know any objects with children yet, this is just zeros
                lda #0
                sta (hp),y
                iny
                sta (hp),y
                iny

                ; Update heap pointer to next free byte in heap
                tya
                clc
                adc hp
                sta hp
                bcc +
                inc hp+1
+
                ; Store address of new entry in header of old link
                lda tmp0        ; original LSB of hp
                tax             ; We'll need it again in a second
                sta (astp)
                ldy #1
                lda tmp0+1      ; original MSB of hp
                sta (astp),y
                
                ; Store address of new entry in astp. Yes, there are two
                ; pointers to the last entry in the tree, one from the
                ; previoius node and one from the outside. This prevents us
                ; having to walk through the whole tree to add something.
                sta astp+1      ; MSB, was tmp0+1
                stx astp        ; LSB, was tmp0

                plx             ; get back index for token buffer

                rts

; ==== OBJECT CONSTANTS ====

; Some objects are used again and again so it is worth storing them as
; constants for speed reasons. These are in capital letters and start with
; with OC_

OC_END   = $0000        ; end of input for AST 
OC_TRUE  = $1fff        ; true bool #t, immediate
OC_FALSE = $1000        ; false bool #f, immediate


; ==== CONTINUE TO EVALUATOR ====
                
parser_done:
        ; End parsing with termination object The evaluator assumes that we
        ; have a termination object so it's really, really important to get
        ; this right

                lda <#OC_END
                ldx >#OC_END
                jsr parser_add_object

                ; fall through to evaluator

