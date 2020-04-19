; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 18. Apr 2020

eval: 

        ; We walk the AST and evaluate the nodes. This is the first of two
        ; places we do this walk - the other is the printer - so we will have
        ; to see if we can merge the code to save space. Note the object tag
        ; nibbles live in definitions.asm

        ; TODO currently everything evaluates itself so we're just going
        ; through the motions for now

; ---- Debugging routines ----

        .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
                jsr debug_dump_hp
        .fi 
                        
; ===== EVAL MAIN LOOP =====

        ; We walk the AST - which should be rather short at this point - and 
        ; print the results. Don't touch tmp0 because it is used by print
        ; routines in helper.asm
                lda rsn_ast     ; RAM segment nibble, default $10
                sta tmp1
                stz tmp1+1      ; Segment must start on 4 KiB line

eval_loop:
                ldy #3          ; MSB of the next node entry down ...
                lda (tmp1),y    ; ...  which contains the tag nibble
                and #$f0        ; mask all but tag nibble
        
        ; Use the tag to get the entry in the jump table.
        ; First, we have to move the nibble over four bits,
        ; then multiply it by two, which is a left shift, so we
        ; end up wit three right shifts
                lsr     
                lsr
                lsr             ; Fourth LSR and ASL cancle each other
                tax

        ; 65c02 specific, see
        ; http://6502.org/tutorials/65c02opcodes.html#2
                jmp (eval_table,X)

eval_next:
        ; Next incarnation of the loop
                lda (tmp1)              ; LSB of next entry
                tax
                ldy #1
                lda (tmp1),y            ; MSB of next entry
                sta tmp1+1
                stx tmp1

                bra eval_loop



; ===== EVALUATION SUBROUTINES ====

eval_0_meta:
        ; This marks the end of the tree (which at the moment is just a list
        ; anyway) so we can just jump directly to the printer from the jump
        ; table. Later, we'll have to actually do some work here.

eval_1_bool:
eval_2_fixnum:
eval_3_bignum:
eval_4_char:
eval_5_string:
        ; All of these are self-evaluating and just print themselves. To
        ; save speed, we don't even come here, but directly jump to eval_next.
        ; We leave these labels here in case we need to do something clever at
        ; some point.
                bra eval_next           ; paranoid, never reached

eval_6_UNDEFINED:
        ; TODO define tag and add code

eval_7_UNDEFINED:
        ; TODO define tag and add code

eval_8_UNDEFINED:
        ; TODO define tag and add code

eval_9_UNDEFINED:
        ; TODO define tag and add code

eval_A_UNDEFINED:
        ; TODO define tag and add code

eval_B_UNDEFINED:
        ; TODO define tag and add code

eval_C_UNDEFINED:
        ; TODO define tag and add code

eval_D_UNDEFINED:
        ; TODO define tag and add code

eval_E_UNDEFINED:
        ; TODO define tag and add code

eval_F_UNDEFINED:
        ; TODO define tag and add code


; ===== EVALUATION JUMP TABLE ====

eval_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. In theory, we would have to go
        ; through the individual routines above for all, but some of these are
        ; self-evaluating, and so they just print out their results when they
        ; hit the printer. To increase speed, these just to the next entry

        ;      0 meta     1 bool     2 fixnum   3 bignum
        .word eval_done, eval_next, eval_next, eval_next

        ;      4 char     5 string   6 UNDEF    7 UNDEF
        .word eval_next, eval_next, eval_next, eval_next

        ;      8 UNDEF    9 UNDEF    A UNDEF    B UNDEF
        .word eval_next, eval_next, eval_next, eval_next

        ;      C UNDEF    D UNDEF    E  UNDEF   F UNDEF
        .word eval_next, eval_next, eval_next, eval_next


; ==== CONTINUE TO PRINTER ====
eval_done:
                
