; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 30. Apr 2020

; We walk the AST and actually execute what needs to be executed. Currently,
; most stuff is self-evaluating. This uses the AST walker from helpers.asm 

; ==== EVAL MAIN LOOP ====
eval: 
        ; This loop walks the upper level of the AST entries, its "spine" if
        ; you will, and prints the results. If there is more than one
        ; expression in the line, it prints them one by one

        .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
                ; jsr debug_dump_hp
        .fi 
                        
        ; Initialize the AST with the address of its RAM segment 
                lda rsn_ast             ; RAM segment nibble, default $10
                ldy #2                  ; by definition
                jsr help_walk_init 

eval_loop:
        ; Initialize the Data Stack where we will be storing the results. 
                ldx #ds_start           ; $FF by default 
                stx dsp

        ; We push the car to the Data Stack, which is the main way eval and
        ; apply communicate. Using the normal 6502 stack would be a nightmare
                jsr eval_push_car_to_stack

        ; The eval primitive procedure does the actual work. And calls 
                jsr proc_eval 

                ; We return here with the results on the Data Stack 

eval_next:
        ; We print the result of every evaluation, not all at once after the
        ; whole line has been evaluated. 
                jsr printer

        ; If we had reached the end of the AST, the walk has set walk_done to
        ; $FF
                lda walk_done           ; $FF true, term over; $00 false
                bne eval_done 

        ; Get next entry out of AST
                jsr help_walk_next

                bra eval_loop

eval_done:
        ; We're all done, so we go back to the REPL
                jmp repl


; ==== EVAL PROC ====

; So this is a bit confusing: There is part of the REPL we call eval and the
; actual primitive procedure (eval), which is this part. The main loop pushes
; the car to the Data Stack and then performes a subroutine jump here. 
; This should formally live with the other primitive procedures in
; procedures.asm, but it is so important for the REPL it lives here with its
; friend (apply).
proc_eval:

        ; Pull the car from the Data Stack. It is pointing to the MSB when we
        ; arrive, and this is all we need
                lda 1,x         ; MSB is stored in A
                inx             ; Pop and discard top entry
                inx
       
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

        ; We arrive here with the object right after the '(' on the top of the
        ; Data Stack. With procedures, the LSB is the offset to the jump table
        ; for procedures, and we don't need the MSB anymore. Still have to
        ; taken them both off the stack

                ldx dsp                 ; procs may assume that X is dsp
                lda 0,x                 ; take LSB
                tay

                lda exec_table_lsb,y
                sta jump
                lda exec_table_msb,y
                sta jump+1

                jmp (jump)


proc_apply_return:
        ; The procedures we call are tasked with moving to the last closing
        ; parens ')' in their term. We move on to the next entry for eval
        ; before we jump back. We should pull the old value and push the new
        ; one, but we can actually just overwrite the current value.

        ; TODO note this is the same routine we use in the current testing
        ; procedure (newline), so we can probably move this to the same
        ; subroutine
                
                ; If we have already reached the end - say "(newline)", then we
                ; don't want to get the next entry
                lda walk_done
                bne _done

                jsr help_walk_next

                lda walk_car            ; LSB
                sta 0,x
                lda walk_car+1          ; MSB
                sta 1,x

_done:
                jmp eval_0_meta_return
                

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
                bne eval_not_parens_start

        ; ---- Parens start '(' ----

                ; Get the next object from the AST
                ; TODO complain if there is no next object
                jsr help_walk_next

                ; We now have the car and cdr of the next object in walk_car.
                ; We first have to see if this is really a procedure or at
                ; least a special form 
                lda walk_car+1          ; MSB of the object

                ; mask everything but the object's tag
                and #$F0
                cmp #OT_PROC
                bne eval_not_a_proc
               
        ; ---- Primitive procedure ----

        ; This is a procedure, which means the LSB is the offset to the 
        ; routine stored in procedures.asm. We push the car on the Data Stack
        ; and let (apply) do its thing

                ldx dsp
                lda walk_car+1
                sta 1,x                 ; MSB
                lda walk_car            ; LSB
                sta 0,x
                stx dsp
                
                jmp proc_apply

eval_0_meta_return:        
        ; We return here from (apply) and first need to see if we are done.

                jmp proc_eval_next      ; TODO replace with RTS directly
        
        

eval_not_a_proc:
                cmp #OT_SPEC
                bne eval_not_a_spec

        ; ---- Special form ---- 

        ; TODO add special forms


eval_not_a_spec:
eval_not_legal_meta:
        ; If this is not a native procedure and not a special form, we're in
        ; trouble. Complain and return to REPL
                lda #str_cant_apply
                jsr help_print_string
                jmp repl


eval_not_parens_start:
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
                bne eval_not_legal_meta     ; temporary, TODO real error message

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
                jmp proc_eval_next      ; TODO replace with RTS directly

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

                jmp eval_next 


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

