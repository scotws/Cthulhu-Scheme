; Parser for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 05. Apr 2020

; The parser is kept in a separate file to make changes easier. It goes through
; the tokens created by the lexer in the token buffer (tkb) and create
; a Abstract Syntax Tree (AST) that is saved as part of the heap. 

; ==== PARSER CODE ====

; At this stage, we should have the tokens in the token buffer, terminated by
; an end of input token (00). We now need to construct the abstact syntax tree
; (AST).
parser: 

; ---- Debugging routines 

                .if DEBUG == true
                ; TODO TEST dump contents of token buffer
                jsr debug_dump_token
                .fi 


; ---- Parser setup ----

                ; Clear the old AST
                stz ast
                stz ast+1
                
                ; Reset the pointer to the token buffer
                stz tkbp
                stz tkbp+1      ; currently only using LSB
                
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

                ldx #0
parser_loop:
                lda tkb,x

                ; ---- Check for end of input
_end_token:
                ; We assume there will always be an end token, so we don't 
                ; check for an end of the buffer.
                cmp #T_END      
                bne _true_token 

                ; ---- Check for boolean true token
_true_token:
                cmp #T_TRUE
                bne _false_token

                ; We have a true token, which makes our life easy, because we
                ; have the object as a constant
                lda <#OC_TRUE
                ldy >#OC_TRUE
                jsr parser_add_object
                jmp parser_done

                ; ---- Check for boolean false token
_false_token:
                cmp #T_FALSE
                bne paser_bad_token     ; TODO HIER ADD NEXT TOKEN TODO

                ; We have a true token, which makes our life easy, because we
                ; have the object as a constant
                lda <#OC_TRUE
                ldy >#OC_TRUE
                jsr parser_add_object
                jmp parser_done


                ; ---- No match found
paser_bad_token:
                ; This really shouldn't happen. Panic and return to main loop.
                ; The bad token should still be in A
                pha                             ; save the evil token
                lda #str_bad_token
                jsr help_print_string_no_lf
                pla
                jsr help_emit_a                 ; print bad token as hex number
                jmp repl


                ; ---- End parsing with termination object
                ; The evaluator assumes that we have a termination object so
                ; it's really, really important to get this right
parser_done:
                lda <#OC_END
                ldx >#OC_END
                jsr parser_add_object
                jmp eval                ; continue with evaluation


; ==== PARSER HELPER ROUTINES =====

; Internel parser functions. Anything here that might be of use in other parts
; of Cthulhu Scheme should be moved to helpers.asm

parser_add_object: 
        ; Add a Scheme object to the AST. Assumes that the LSB of the object is in
        ; A and the MSB is in Y. Currently, we can just add immediate objects
        ; like booleans. When we arrive here, astp points to the last object in
        ; the tree we want to link to. We always add to the end of the list
        ; at the moment which makes it easier. Uses tmp0, destroys X

        ; TODO At the moment, this is still just a simple single-linked list,
        ; we will change to an actual tree later. 
                phy             ; save MSB of the object
                pha             ; save LSB of the object
                
                ; Remember the first free byte of nemory as the start of the
                ; new node of the tree (well, list at the moment)
                lda hp
                sta tmp0
                lda hp+1
                sta tmp0+1

                ; Store the termination object in the new node as the pointer
                ; to the next node, this marks the end of the tree  
                lda <#OC_END
                sta (tmp0)
                ldy #1
                lda >#OC_END
                sta (tmp0),y
                
                ; Move heap pointer two entries down. This is where the payload
                ; of the new object goes
                inc hp
                inc hp

                ; Store the object in the heap
                pla             ; retrieve LSB
                sta (hp)
                inc hp
                pla             ; retrieve MSB, was in Y
                sta (hp) 
                inc hp

                ; Store address of new entry in header of old link
                lda tmp0
                tax             ; We'll need it again in a second
                sta (astp)
                ldy #1
                lda tmp0+1
                sta (astp),y
                
                ; Store address of new entry in astp. Yes, there are two
                ; pointers to the last entry in the tree.
                sta astp+1      ; MSB, was tmp0+1
                stx ast         ; LSB, was tmp0

                rts

; ==== OBJECT CONSTANTS ====

; Some objects are used again and again so it is worth storing them as
; constants for speed reasons. These are in capital letters and start with
; with OC_

OC_END   = $0000        ; end of input for tokens and objects
OC_TRUE  = $1fff        ; true bool #t, immediate
OC_FALSE = $1000        ; false bool #f, immediate

