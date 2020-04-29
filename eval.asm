; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 29. Apr 2020

; We walk the AST and actually execute what needs to be executed. Currently,
; most stuff is self-evaluating. This uses the AST walker from helpers.asm 
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

        ; Initialize the Data Stack where we will be storing the results. 
                ldx #ds_start           ; $FF by default 
                stx dsp

        ; The normal eval procedure does the actual work. 
                jsr eval_push_car_to_stack
                jsr proc_eval

                ; We return here with the results on the Data Stack 

eval_next:
        ; We print the result of every evaluation, not all at once after the
        ; whole line has been evaluated. 
                jsr printer

        ; If we had reached the end of the AST, the walker had set the carry
        ; flag. 
                plp
                bcs eval_done           ; probably later a JMP

        ; Get next entry out of AST
                jsr help_walk_next
                bra eval_loop


; ---- Print stuff ----

eval_done:
        ; We're all done, so we go back to the REPL
                jmp repl


; ==== EVAL PROC ====

; So this is going to be a bit confusing: There is part of the REPL we call
; eval and the actual primitive procedure (eval), which is this part. The main
; loop pushes the car to the Data Stack and then performes a subroutine jump
; here. We assume that the LSB of the car is in Y and the MSB is in MSR.
proc_eval:
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
        ; available as a subroutine jump, that would be the 65816. It is
        ; annoying that we have to use the X register for both this and the
        ; Data Stack
                jmp (eval_table,x)

proc_eval_next:
        ; We return here after taking care of the actual car. We push the
        ; result to the Data Stack and return to the calling routine. 
        
                rts



; ==== APPLY PROC ====

; Apply is so central to the loop it lives here instead of with the other
; primitive procedures in procedures.asm.
apply: 
proc_apply:
        ; """Applies a primitive procedure object to a list of operands, for
        ; instance '(apply + (list 3 4))'. We usually arrive here when the
        ; evaluator finds a '(' as OC_PARENS_START and has confirmed that the
        ; next object is either a primitive procedure - then we end up here
        ; - or a special form.

        ; We arrive here with the offset to the execution table in Y and the
        ; car and cdr of the next entry in the AST in walk_car and walk_cdr.

                ; TODO for now, we just jump!
                lda exec_table_lsb,y
                sta jump
                lda exec_table_msb,y
                sta jump+1
                jmp (jump)
                

; ==== EVALUATION HELPER ROUTINES ====

eval_push_car_to_stack:         
        ; """Take the car of an object that was placed by the AST walk into
        ; walk_car and push it to the Data Stack so the printer can print it.
        ; Changes X.""" 
                ldx dsp                 ; points to MSB of last entry

        ; The Data Stack points to the last MSB entry by default. We move the
        ; pointer before we store
                dex                     ; initially $FE
                dex                     ; initially $FD
                lda walk_car            ; LSB is pushed first, initially $FD
                sta 0,x
                lda walk_car+1          ; MSB is pushed second, initially $FE
                sta 1,x

                stx dsp                 ; We'll need X for jumps later

                rts


; ==== EVALUATION SUBROUTINES ====

eval_0_meta:
        ; We currently land here with three possible objects: '(' as
        ; OC_PARENS_START, ')' as OC_PARENS_END, and '() as OC_EMPTY_LIST. The
        ; car of the current object is in Y (LSB) and A (MSB). We only care
        ; about the LSB at the moment because the MSB in A is what brought us
        ; here with the OT_META tag. 

        ; If this is an open parens, we assume that the next object is
        ; executable and needs to be sent to (apply). 
                cpy #<OC_PARENS_START           ; defined in parser.asm
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
_not_legal_meta:
        ; If this is not a native procedure and not a special form, we're in
        ; trouble. Complain and return to REPL
                lda #str_cant_apply
                jsr help_print_string
                jmp repl


_not_parens_start:
                cpy #<OC_PARENS_END             ; from parser.asm     
                bne _empty_list                 ; move this up 

        ; ---- Parens close ')' ----

        ; This is strange because actually the individual processes are
        ; responsible for reaching the closing parents and getting over it.
        ; If we are here, this could be because of inballanced parens.
        ; TODO handle naked closed parents
        

_empty_list:
        ; ---- Empty list ----

        ; The empty list marks the end of the input. We push the empty string
        ; symbol to the Data Stack
                cpy #<OC_EMPTY_LIST  
                bne _not_legal_meta     ; temporary, TODO real error message

                ; The Empty List is basically self-evaluating, so we fall
                ; through to self-evaluating objects  
                

; ---- Self-evaluating objects ---- 

; All of these are self-evaluating and just print themselves. Since we already
; have the object on the Data Stack, we don't even have to push it anymore.
eval_1_bool:
eval_2_fixnum:
eval_3_char:
eval_4_string:
eval_f_proc:
                bra proc_eval_next

eval_5_bignum:

eval_6_UNDEFINED:
        ; TODO define tag and add code

eval_7_UNDEFINED:
        ; TODO define tag and add code


; ---- Pairs ---- 

eval_8_pair:
        ; TODO write code for pair

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


; eval_f_proc: Naked procedures are currently self-evaluating, so we keep them
; up at the beginning with booleans and strings

; ---- Special forms ----
eval_e_spec:
        ; TODO define tag and add code

                bra eval_next 


; ===== EVALUATION JUMP TABLE ====

eval_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. In theory, we would have to go
        ; through the individual routines above for all, but some of these are
        ; self-evaluating, and so they just print out their results when they
        ; hit the printer. To increase speed, these just to the next entry

        .word eval_0_meta, eval_1_bool, eval_2_fixnum, eval_3_char

        ;      4 string       5 bignum   6 UNDEF    7 UNDEF
        .word eval_4_string, eval_next, eval_next, eval_next

        ;      8 UNDEF    9 UNDEF    A UNDEF    B UNDEF
        .word eval_8_pair, eval_next, eval_next, eval_next

        ;     C UNDEF    D UNDEF    E special    F primitive
        ;                             forms       procedures
        .word eval_next, eval_next, eval_e_spec, eval_f_proc

