; Parser for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 28. Apr 2020

; The parser goes through the tokens created by the lexer in the token buffer
; (tkb) and create a Abstract Syntax Tree (AST) that is saved as part of the
; heap. Since this is Scheme, we build the AST out of "pairs" which consist of
; a "car" and "cdr" part of 16-bits each. Linking the cdrs create a "spine"
; list-like structure that points to the data in cars.  See the manual for
; details.
;                         LSB   MSB
;                       +-----+------+
;        prev pair -->  |  cdr cell  |  ---> next pair
;                       +-----+------+
;                       |  car cell  | 
;                       +-----+------+

; The pointers to pairs are defined as pair objects with their own tag. See the
; documentation for more details.


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

        ; Set up the RAM memory segment we use for the cons cells (pairs) we
        ; keep the AST in. 

        ; Clear the old AST. We keep the string table for now which is set up
        ; in the main routine cthulhu.asm
        ; TODO figure out how to deal with the string buffer, probably when we
        ; do garbage collection
                lda #$02        ; Skip dummy cdr at beginning of RAM
                sta hp_ast
                lda rsn_ast     ; MSB of RAM segment for AST
                sta hp_ast+1

        ; The pointer to the current pair starts off pointing to the dummy
        ; value at the first two bytes of the RAM segment
                sta astp+1      ; still have MSB of RAM segment
                stz astp

        ; Reset the pointer to the token buffer
                stz tkbp
                stz tkbp+1      ; fake, currently only using LSB
                

; ---- Parser main loop 

; Currently, we check for the various tokens by hand. Once the number of tokens
; reaches a certain size we should consider a table-driven method for speed
; and size reasons. This makes debugging easier until we know what we are doing

                ldx #$FF        ; index -1 at beginning
parser_loop:
                inx
                lda tkb,x

        ; ---- Check for tick ("quote")

        ; We check for the "'" here because it turns up a lot
        ; TODO see if we should convert this to (quote) here or later
                cmp #T_TICK
                bne _not_tick

        ; It's a tick. This is pretty common. To add stuff to the AST, we put
        ; the LSB in Y and the MSB in A, and of course we're little endian.
        ; Remember this with "Little Young Americans" - little endian, Y, A.
                ldy #<OC_PROC_QUOTE
                lda #>OC_PROC_QUOTE
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_tick:
        ; ---- Check for parens
        
        ; This is Scheme, so we're going to have a lot of these. 
                cmp #T_PAREN_START
                bne _not_paren_start

        ; We have a parens '(', which will cause the evaluator to trigger
        ; actual work. Before we do that, we need to see if we have a ')' as
        ; the next character, which would mean we have '()', which is the empty
        ; list.
                inx
                lda tkb,x
                cmp #T_PAREN_END
                bne _not_empty_list

                ; This is an empty list.
                ldy #<OC_EMPTY_LIST
                lda #>OC_EMPTY_LIST
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_empty_list:
        ; We don't have the empty list, but a normal start. Move back to the
        ; original token and save
                dex     
                ldy #<OC_PARENS_START
                lda #>OC_PARENS_START
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_paren_start:
                cmp #T_PAREN_END
                bne _not_paren_end

        ; Here is a closing parens
                ldy #<OC_PARENS_END
                lda #>OC_PARENS_END
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_paren_end:
        ; ---- Check for end of input

        ; We assume there will always be an end token, so we don't 
        ; check for an end of the buffer.
                cmp #T_END      
                bne _not_end_token

                jmp parser_done

_not_end_token:
        ; ---- Check for boolean true token

                cmp #T_TRUE
                bne _not_true_token

        ; We have a true token, which makes our life easy, because we
        ; have the object as a constant
                ldy <#OC_TRUE
                lda >#OC_TRUE

        ; It is tempting to collapse the next two lines by adding the jump to
        ; parser_done to the end of parser_add_object_to_ast and then just
        ; jumping as a JSR/RTS. In this case, it would work.  However, other
        ; objects might require more stuff added. For the moment, we leave it
        ; this way an come back later for optimization. Check the analog
        ; situation with the lexer. 
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_true_token:
        ; ---- Check for boolean false token
        
                cmp #T_FALSE
                bne _not_false_token

        ; We have a false token, which makes our life easy, because we
        ; have the object as a constant
                ldy <#OC_FALSE
                lda >#OC_FALSE
                jsr parser_add_object_to_ast
                jmp parser_loop

_not_false_token:
        ; ---- Check for number token

                cmp #T_NUM_START
                beq +
                jmp parser_not_num      ; too far for BNE
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

                inx             ; skip over T_NUM_START token

        ; TODO Later we will have to decide if this is going to be
        ; a fixnum or a bignum. For the moment, fixnums are all we know

        ; This token should be the radix, which can be one of $02, $0A,
        ; $10 and possibly $08. We assume that the lexer didn't screw up
        ; and just save this for now
                lda tkb,x
                sta tmp0        ; radix
                inx

        ; This should be the length of the digit sequence, including the sign
        ; byte. Note this means that bignums are limited to 254
        ; characters as well for the moment. In the far future, we
        ; might want to remove this limitation, possibly by checking
        ; the length of the digit sequence first.
                lda tkb,x
                tay             ; We need the length of the string later ...
                dey             ; ... but we don't need to include the sign

                inx             ; Move to token for sign, T_PLUS or T_MINUS 
                lda tkb,x
                sta tmp0+1      ; Just store sign for now 

                inx             ; Move to first digit

        ; We are now pointed to the first digit of the number sequence.
        ; The lexer should not have allowed numbers to be stored
        ; without digits, so we should be safe.

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

        ; This should be the most common case so we do it first. We
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

        ; First digit. We need at least one hex digit, so we don't have
        ; to test for the terminator token; we do so anyway because it
        ; makes the loop simpler

_hex_fixnum_loop:
                lda tkb,x

                cmp #T_NUM_END
                beq _done_hex

                jsr help_hexascii_to_value
                bpl _legal_hex_digit
                jmp parser_bad_digit

_legal_hex_digit:
        ; We have a legal digit. We shift it as a nibble "through the right"
        ; into the temporary variables

        ; First, shift the nibble to the left side of the A
                asl
                asl
                asl
                asl

        ; Shift the nibble in through the right of tmp1+1 and through
        ; to tmp1
                rol             ; bit 7 of A now in carry flag
                rol tmp1+1      ; bit 7 of tmp1+1 now in carry flag
                rol tmp1        ; now is bit 0 of tmp1

                rol 
                rol tmp1+1 
                rol tmp1   

                rol
                rol tmp1+1 
                rol tmp1   

                rol
                rol tmp1+1 
                rol tmp1   

                ; Loop control
                inx
                dey     
                bne _hex_fixnum_loop

_done_hex:
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

        ; We need at least one bit or the lexer would not have constructed the
        ; fixnum. This means we don't have to compare with T_NUM_END in the
        ; first pass, but we do it here anyway because it makes the loop
        ; easier

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
                inx                     ; next character

                dey                     ; decrease counter
                bne _bin_fixnum_loop

_done_bin:
        ; Binary number is finished, nothing more to be done
                jmp parser_common_fixnum

_not_binary:
        ; If the assembler flag 'OCTAL == false' in the platform file we drop
        ; through to _illegal_radix.

        .if OCTAL == true
                cmp #$08
                bne _illegal_radix

        ; ---- Convert octal ----
        ; TODO convert octal
                bra parser_common_fixnum
        .fi
        
_illegal_radix:
        ; This really shouldn't happen: If we landed here, we have a radix we
        ; don't recognize because the lexer screwed up. Panic and return to
        ; REPL
                pha                             ; save the evil radix
                lda #str_bad_radix
                jsr help_print_string_no_lf
                jmp parser_common_panic 


parser_common_fixnum:    
        ; ---- Common processing for all fixnums ----

        ; The number is safe as bigendian in tmp1 and tmp1+1 in three
        ; nibbles, the sign is in tmp0+1 as T_PLUS or T_MINUS. We are
        ; pointed to the next token after the number sequence.

        ; If we have a positive number, we're done and just need to
        ; construct the fixnum object
                lda tmp0+1
                cmp #T_MINUS
                beq _negative_number

        ; We're in luck, it's positive. The tag for a fixnum object is
        ; $20
                lda #OT_FIXNUM
                ora tmp1        ; construct tag byte with MSB of number
                sta tmp1

                bra _add_fixnum_to_ast

_negative_number:
        ; TODO handle negative numbers

                ; drop through to _add_fixnum_to_ast

_add_fixnum_to_ast:
                ldy tmp1+1
                lda tmp1
                jsr parser_add_object_to_ast

_num_done:
        ; Fixnum taken care of. Next token please!
                jmp parser_loop


parser_not_num: 
        ; ---- Check for string ----
                cmp #T_STR_START
                bne parser_not_string

        ; We have a string. All strings are interned, that is, saved to the
        ; heap with only a pointer to the beginning of the string saved in the
        ; object. They are also saved to the string table so we can later check
        ; if we have already saved them. In theory, we could add "immediate
        ; strings" that are two characters long, but for the moment, that is
        ; more effort that would seem to be worth it. 
        
        ; The string table is not a Scheme linked list of cons cells, but
        ; a simple linked list where the string starts in the byte after the
        ; pointer to the next entry in the list. The list is terminated by
        ; 0000, the string by 00. Then we add an object to the AST that points
        ; to the string (not the entry in the string table). Strings are
        ; zero-terminated so we don't have to worry about length. 

        ; At this point, strp points to the end of the string table (most
        ; recent entry), which should be $0000; hp_str to the next free byte in
        ; the RAM segment for strings (after the 00 that terminates the
        ; string). rsn_str is the MSB of the root of the string table, its $00
        ; the LSB which is not saved explicitly anywhere. 
         
        ; TODO see if we already have this string stored so we don't have to go
        ; through this all again

        ; We can add the string object to the AST because we have the address
        ; where the string starts in hp_str - the next free byte
                lda hp_str+1    ; MSB of next free byte in string RAM segment

                and #$0F        ; mask high nibble (paranoid)
                ora #OT_STRING  ; object tag nibble for strings
                ldy hp_str      ; LSB goes in Y, MSB is in A
        
                jsr parser_add_object_to_ast   ; Updates AST heap pointer

        ; Now we actually add the string to the RAM segment
                inx             ; move to first character of string
                ldy #0
_string_loop:
                lda tkb,x
                cmp #T_STR_END 
                beq _string_end

                sta (hp_str),y
                iny
                inx
                bra _string_loop

_string_end:
                ; Store 00 as the string terminator
                lda #0
                iny
                sta (hp_str),y

                ; Update pointer to next free byte in heap's RAM segment
                tya
                clc
                adc hp_str
                sta hp_str
                bcc +
                inc hp_str+1
+
                ; This is where the next terminator for the string table goes
                lda #0
                sta (hp_str)
                ldy #1
                sta (hp_str),y

                ; The string pointer needs to point to this terminator
                lda hp_str
                sta strp
                lda hp_str+1
                sta strp+1

                ; Finally, need to move the hp_str up by two again
                tya             ; #1
                inc a
                clc
                adc hp_str
                bcc +
                inc hp_str+1
+
                jmp parser_loop
 
parser_not_string:                
        ; ---- Check for identifier ----
                cmp #T_ID_START
                beq parser_have_id
                jmp parser_not_id               ; too far for BNE

parser_have_id:
        ; It's not a string, so we'll assume it's an identifier. At the moment,
        ; this could be a variable, a symbol or a procedure. It might make
        ; sense later to split up the proceedures into commonly used, to test
        ; first, then the symbol and variable tables, and then the less
        ; commonly used procedures. Or we bite the bullet and just build some
        ; sort of tree structure once the procedures are complete.

        ; TODO check variable table
        ; TODO check symbol table

_find_proc:
        ; ---- Check for procedure ----

        ; It's not a symbol and it is not a variable, so let's assume it's
        ; a procedure. We keep the procedure "headers" in headers.asm (see
        ; there for details) as a linked list that starts at proc_headers. We
        ; need to actually compare the strings to see if they are identical.
        ; We assume that the input has been changed to lowercase. 

        ; Since we are here because of T_ID_START, the next character in the
        ; token stream must be an ASCII character, because we trust the lexer
                inx             ; point to first character

        ; Go through the linked list of procedure headers. A "0000" as the next
        ; entry address terminates.

        ; TODO This is not optimized for speed, which would be useless until we
        ; decide if we want to even do it his way. 

        ; TODO We're going to need a very close procedure for variables and
        ; symbols so this might be moved to a subroutine in helpers.asm

                ; Get start of list of process headers. We'll need this later
                ; for the next entry
                lda #<proc_headers
                sta tmp0
                lda #>proc_headers
                sta tmp0+1

                ; The start of our string is at tbk,x. Life is easier if we can
                ; store it to a temporary variable 
                txa
                clc
                adc #<tkb
                sta tmp1                ; address of mystery string in tmp1
                lda #>tkb
                bcc +
                inc a
+
                sta tmp1+1

_find_proc_loop:
        ; We now compare character by character. The lexer stored the mystery
        ; string of the identifier with the T_ID_END token as the last entry

                ; The known string in the header list starts four bytes down from 
                ; the beginning of the entry. If we had a addressing mode like
                ; CMP (tmp0),X and ORA (tmp0),X we could save this step but
                ; we don't, only CMP (tmp0),Y.
                lda #4
                clc
                adc tmp0
                sta tmp2                ; LSB address of the known string in tmp2

                lda tmp0+1              ; MSB
                sta tmp2+1
                bcc +
                inc tmp2+1
+
                ldy #0
_compare_loop:
                lda (tmp1),y            ; char of the mystery string

                ; See if mystery string done 
                cmp #T_ID_END
                beq _mystery_string_done

                ; See if character is the same
                cmp (tmp2),y            ; known character string 
                bne _next_entry         ; chars don't match, next entry

                ; See if our known string is done. If yes, this is not a match
                ; because we already checked for the end of the mystery string
                lda (tmp2),y
                beq _next_entry

                ; If we land here, the characters match and we're not at the
                ; end of either string. Keep checking.
                iny
                bra _compare_loop


_mystery_string_done:
        ; The mystery string is over, but we don't know if the known string
        ; is complete as well, so we need one more test. Otherwise, "cat" and
        ; "cats" would be considered equal
                lda (tmp2),y
                beq _found_id           ; strings are both over, it's a match!

                ; fall through to _next_entry

_next_entry:
        ; The characters didn't match so we need to try the next entry. We kept
        ; the pointer to the entry around in tmp0 and now feel very clever
                lda (tmp0)
                pha
                ldy #1
                lda (tmp0),y
                sta tmp0+1
                pla
                sta tmp0

                ; If we have arrived at the end of the header list, we have no
                ; match and need to try something completely different
                ora tmp0+1
                bne _find_proc_loop   ; concentrate and try again, Mrs. Dunham

                ; fall through to _bad_word

_bad_word:
        ; If we arrive here, we haven't found the word the user gave us in the
        ; variable list, the symbol list or amongst the processes. Complain and
        ; return to the REPL
                lda #str_unbound                ; "Unbound variable: "
                jsr help_print_string_no_lf

        ; Print the offending name. We can just used the token buffer because
        ; this is all screwed up anyway and we have to go back to the REPL
_bad_word_loop:
                lda tkb,x
                cmp #T_ID_END
                beq _bad_word_done
                jsr help_emit_a
                inx
                bra _bad_word_loop
_bad_word_done:
                jsr help_emit_lf
                jmp repl

_found_id:
        ; We have found a match, so this is a process or a special form or
        ; something else that is stored in the header list. We create an object
        ; and store it. The Scheme object is stored in the header entries two
        ; bytes down from the current address which we left in tmp0

        ; Before we forget it, we need to get the correct X back as the pointer
        ; to the current character in the token buffer. We basically need to
        ; add Y to X, which is not that easy with the 65c02. We don't need tmp1
        ; anymore, so we can clobber it
                tya
                stx tmp1
                clc
                adc tmp1
                tax
        
        ; Get the Scheme object, which is stored little endian in the header.
        ; See headers.asm for details on the structure
                ldy #2
                lda (tmp0),y    ; LSB of process object
                pha
                iny
                lda (tmp0),y    ; MSB with tag, goes in A
                ply             ; LSB goes in Y

                jsr parser_add_object_to_ast
                jmp parser_loop

parser_not_id: 
        ; Whatever this is, it is not an id

        ; ----- TODO CONTINUE HERE TODO ----

paser_bad_token:
        ; ---- No match found ----

        ; Oh dear, this really shouldn't happen. Panic and return
        ; to main loop. The bad token should still be in A
                pha                             ; save the evil token
                jsr help_emit_lf
                lda #str_bad_token
                jsr help_print_string_no_lf

parser_common_panic:
                pla
                jsr help_byte_to_ascii          ; print bad token as hex number
                jsr help_emit_lf
                jmp repl

parser_bad_digit:
        ; Error routine if we found a digit that doesn't belong there
                pha                             ; save the bad digit
                lda #str_bad_number
                jsr help_print_string_no_lf
                bra parser_common_panic

function_not_available:
        ; TODO This is during development only
                lda #str_cant_yet
                jsr help_print_string
                jmp repl


; ==== PARSER HELPER ROUTINES =====

; Internel parser functions. Anything here that might be of use in other parts
; of Cthulhu Scheme should be moved to helpers.asm

parser_add_object_to_ast: 
        ; Add a Scheme object to the AST, which in practice means adding a new
        ; pair. Assumes that the LSB of the object is in Y and the MSB (the
        ; part with the tag that designates the type of object) is in A. You
        ; can remember this with "Little Young Americans" - little endian, Y,
        ; A. We always add to the end of the list at which makes life easier.
        ; The AST lives in the RAM segment for AST. Uses tmp0.  
        
        ; We could use (cons) and other built-in Scheme procedures for this but
        ; we can make it faster with low-level routines. 

        ; TODO make sure we don't advance past the end of the heap 
        
                phx             ; save index to token buffer
                pha             ; save MSB of the object (with tag)
                phy             ; save LSB of the object to top of stack
                
        ; Remember the first free byte of memory as the start of the
        ; new pair. This is a pure address, not a Scheme pointer; the first
        ; time is it wherever rsn_ast points to.
                lda hp_ast
                sta tmp0
                lda hp_ast+1
                sta tmp0+1

        ; Store the empty list in the cdr of the new node, which marks 
        ; the end of the tree in memory. 
        ; TODO the OC_EMPTY_LIST is currently defined as $0000, but just to be
        ; safe, we do this the hard way with the constant. Later, once we are
        ; very, very sure that OC_EMPTY_LIST is always going to be 0000, we can
        ; simplify this.
                lda <#OC_EMPTY_LIST
                ldy #0
                sta (hp_ast),y
                iny
                lda >#OC_EMPTY_LIST
                sta (hp_ast),y
                iny
                
        ; Store the object in the new car. We are little endian
                pla             ; retrieve LSB of object, was in Y
                sta (hp_ast),y
                iny
                pla             ; retrieve MSB (with tag), was in A
                sta (hp_ast),y
                iny

        ; Update heap pointer to next free byte in heap
                tya
                clc
                adc hp_ast
                sta hp_ast
                bcc _store_address
                inc hp_ast+1

_store_address:
        ; Store address of new entry in cdr of old link - hp_ast needs to be
        ; moved to wherever astp is pointing to. We need to turn this into an
        ; official pair object while we are at it. 
                lda tmp0+1      ; original MSB of hp_ast, which is just an addr
                and #$0F        ; mask whatever the high nibble was (paranoid)
                ora #OT_PAIR
                ldy #1
                sta (astp),y

                lda tmp0        ; original LSB of hp_ast
                sta (astp)

        ; Store address of new entry in astp, which is the original hp_ast.
                sta astp        ; still have original LSB
                lda tmp0+1
                sta astp+1      ; MSB, was tmp0+1

                plx             ; get back index for token buffer

                rts


; ==== OBJECT CONSTANTS ====

; Some objects are used again and again so it is worth storing them as
; constants for speed reasons. These are in capital letters and start with
; with OC_

OC_EMPTY_LIST     = $0000   ; end of list terminating object "()"
OC_PARENS_START   = $00AA   ; parens open '('
OC_PARENS_END     = $00FF   ; parens close ')' 
OC_TRUE           = $1FFF   ; true bool #t, immediate
OC_FALSE          = $1000   ; false bool #f, immediate
OC_PROC_APPLY     = $F000   ; primitive procedure (apply)
OC_PROC_QUOTE     = $F002   ; primitive procedure (quote)


; ==== CONTINUE TO EVALUATOR ====
                
parser_done:
                ; fall through to evaluator
