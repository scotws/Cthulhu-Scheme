; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 25. Apr 2020

; We walk the AST and actually execute what needs to be executed. Currently,
; everything is self-evaluating, so this is just going through the motions.
; This uses the AST walker from helpers.asm 
eval: 

        .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
                ; jsr debug_dump_hp
        .fi 
                        
        ; Initialize the AST with the address of its RAM segment 
                lda rsn_ast             ; RAM segment nibble, default $10
                ldy #2                  ; by definition
                jsr help_walk_init      ; returns car in A and Y

eval_loop:
        ; If carry is sent we are at the last entry, but we don't want to know
        ; that until the end. Save the status flags for now
                php

        ; A contains the MSB of the car, the "payload" of the cons cell (pair).
        ; We need to mask everything but the object's tag nibble
                and #$f0
        
        ; Use the tag to get the entry in the jump table. First, we have to
        ; move the nibble over four bits, then multiply it by two, which is
        ; a left shift, so we end up wit three right shifts
                lsr     
                lsr
                lsr             ; fourth LSR and ASL cancle each other out
                tax

        ; This instruction is 65c02 specific, see
        ; http://6502.org/tutorials/65c02opcodes.html#2 It is unfortunately not
        ; available as a subroutine jump, that would be the 65816.
                jmp (eval_table,x)

eval_next:
        ; If we had reached the end of the AST, the walker had set the carry
        ; flag. 
                plp
                bcs eval_done           ; probably later a JMP

eval_next_no_check:
        ; Get next entry out of AST
                jsr help_walk_next
                bra eval_loop


; ===== EVALUATION SUBROUTINES ====

eval_0_meta:
        ; We currently land here with three possible objects: '(' as
        ; OC_PARENS_START, ')' as OC_PARENS_END, and '() as OC_EMPTY_LIST. The
        ; car of the current object is in Y (LSB) and A (MSB). We only care
        ; about the LSB at the moment because the MSB in A is what brought us
        ; here with the OT_META tag. 

        ; If this is an open parens, we assume that the next object is
        ; executable and needs to be sent to (apply). 
                cpy #$AA        ; hard-coded in parser.asm
                bne _not_parens_start

        ; ---- Parens open '(' ----

                ; Get the next object from the AST
                ; TODO complain if there is no next object
                jsr help_walk_next

        ; The MSB is in A and the LSB in Y. We need to make sure this is
        ; executable - a primitive procedure or a special form - and complain
        ; if not.
                ; mask everything but the object's tag
                and #$F0
                cmp #OT_PROC
                bne _not_a_proc
               
        ; ---- Primitive procedure ----

        ; This is a procedure, which means the LSB in Y is (currently) the
        ; offset to the routine stored in procedures.asm. Jump to apply with Y
        ; TODO figure out how to do this when we are recursive
                jmp proc_apply

_not_a_proc:
                cmp #OT_SPEC
                bne _not_a_spec

        ; ---- Special form ---- 

        ; TODO add special forms

        
_not_a_spec:
        ; If this is not a native procedure and not a special form, we're in
        ; trouble. Complain and return to REPL
                lda #str_cant_apply
                jsr help_print_string
                jmp repl


_not_parens_start:
                cpy #$FF        ; hard-coded in parser.asm
                bne _not_parens_end

        ; ---- Parens close ')' ----
        
_not_parens_end:

        ; ---- Null list ----
        ; TODO handle the null list 

                bra eval_next           ; TODO temporary

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

eval_8_pair:
        ; TODO write code for pair
                bra eval_next   ; paranoid, currently not reached

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

eval_e_spec:
        ; TODO define tag and add code

eval_f_proc:
                bra eval_next   ; paranoid, never reached


; ===== EVALUATION JUMP TABLE ====

eval_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. In theory, we would have to go
        ; through the individual routines above for all, but some of these are
        ; self-evaluating, and so they just print out their results when they
        ; hit the printer. To increase speed, these just to the next entry

        ;      0 meta      1 bool     2 fixnum   3 bignum
        .word eval_0_meta, eval_next, eval_next, eval_next

        ;      4 char     5 string   6 UNDEF    7 UNDEF
        .word eval_next, eval_next, eval_next, eval_next

        ;      8 UNDEF    9 UNDEF    A UNDEF    B UNDEF
        .word eval_8_pair, eval_next, eval_next, eval_next

        ;     C UNDEF    D UNDEF    E special    F primitive
        ;                             forms       procedures
        .word eval_next, eval_next, eval_e_spec, eval_f_proc


; ==== CONTINUE TO PRINTER ====
eval_done:
                
