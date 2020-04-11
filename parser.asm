; Parser for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 11. Apr 2020

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
                bne _not_fixnum

                ; We have a start token, which means that the next bytes
                ; are going to be unsigned ASCII decimal digits (for the moment). 
-
                inx                     ; skip over T_NUM_START TOKEN
                lda tkb,x

                ; TODO panic if there is an end token before the string was
                ; terminated cleanly

                cmp #T_NUM_END
                beq _fixnum_end

                ; TODO for testing, just print out the numbers
                jsr help_emit_a
                bra - 

_fixnum_end:
                ; TODO add fixnum object
                jmp parser_loop




_not_fixnum: 
                ; TODO ADD NEXT CHECK HERE TODO 
                
                ; ---- No match found
paser_bad_token:
                ; This really shouldn't happen. Panic and return to main loop.
                ; The bad token should still be in A
                pha                             ; save the evil token
                lda #str_bad_token
                jsr help_print_string_no_lf
                pla
                jsr help_byte_to_ascii          ; print bad token as hex number
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

