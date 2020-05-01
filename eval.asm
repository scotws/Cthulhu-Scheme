; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 01. May 2020

; We walk the AST and actually execute what needs to be executed. This uses
; the AST walker from helpers.asm  

; ==== EVALULATOR MAIN LOOP ====
eval: 
        ; This loop walks the upper level of the AST entries, its "spine" so to
        ; speak, and prints the results. If there is more than one expression
        ; in the line, it prints them one by one

        .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
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

        ; TODO this seems to be the only place where we use this at the moment,
        ; so see if we need this as a subroutine or can inline the code here
                jsr eval_push_car_to_stack

        ; The eval primitive procedure does the actual work. From there it
        ; calls (apply) when needed
                jsr proc_eval 

                ; We return here with the results on the Data Stack 
                ; Fall through to eval_next

eval_next:
        ; We print the result of every evaluation, not all at once after the
        ; whole line has been evaluated. 
                jsr printer

        ; If we had reached the end of the AST, the walk helper function has
        ; set walk_done to $FF
                lda walk_done      ; $FF true, term over; $00 false, continue
                bne eval_done 

        ; Get next entry out of AST
                jsr help_walk_next
                bra eval_loop

eval_done:
        ; We're all done, so we go back to the REPL
                jmp repl


; ==== EVAL PROC ====

; So this is a bit confusing: There is part of the REPL we call the evalulator
; and the actual primitive procedure (eval), which is this part. The main loop
; pushes the car to the Data Stack and then performes a subroutine jump here.
; This should formally live with the other primitive procedures in
; procedures.asm, but it is so important for the REPL it gets to stay here with
; its friend (apply).
proc_eval:
        ; Pull the car from the Data Stack. It is pointing to the MSB when we
        ; arrive, and this is all we need for now
                lda 1,x 
                inx             ; Discard top entry of the Data Stack
                inx
       
        ; We need to mask everything but the object's tag nibble
                and #$f0
        
        ; Use the tag to get the entry in the jump table. First, we have to
        ; move the nibble to the right over four bits, then multiply it by two,
        ; which is a left shift, so we end up wit three right shifts
                lsr     
                lsr
                lsr             ; fourth LSR and ASL cancle each other out
                tax

        ; This instruction is 65c02 specific, see
        ; http://6502.org/tutorials/65c02opcodes.html#2 It is unfortunately not
        ; available as a subroutine jump, that would be the 65816. It is
        ; annoying that we have to use the X register for both this and the
        ; Data Stack, we really have to be careful 
                jmp (eval_table,x)

proc_eval_next:
        ; We return here after taking care of the actual car. We push the
        ; result to the Data Stack and return to the calling routine. 
                rts


; ==== EVAL SUBROUTINES ====

eval_0_meta:
        ; We currently land here with three possible objects: '(' as
        ; OC_PARENS_START, ')' as OC_PARENS_END, and '() as OC_EMPTY_LIST. We
        ; only care about the LSB because the MSB is what brought us here with
        ; the OT_META tag. 

        ; If this is an open parens, we assume that the next object is
        ; executable - a primitive procedure or a special form - and needs to
        ; be sent to (apply). We want this to be the first entry so 
                cpy #<OC_PARENS_START           ; defined in parser.asm
                bne eval_not_parens_start

        ; ---- Parens start '(' ----

                ; Get the next object from the AST
                ; TODO complain if there is no next object
                jsr help_walk_next

                ; We now have the car of the next object in walk_car and the
                ; cdr in walk_cdr. We first have to see if this is really
                ; a procedure or at least a special form like it should be
                lda walk_car+1          ; MSB of the object car

                ; mask everything but the tag
                and #$F0
                cmp #OT_PROC
                bne eval_not_a_proc
               
        ; ---- Primitive procedure ----

        ; This is a primitve procedure, which means the LSB is the offset to
        ; the routine stored in procedures.asm. We push the car on the Data
        ; Stack and let (apply) do its thing
                ldx dsp                 ; X last was index to jump table 
                lda walk_car+1
                sta 1,x                 ; MSB
                lda walk_car            ; LSB
                sta 0,x
                stx dsp
                
                jmp proc_apply          ; Not a subroutine jump!

eval_0_meta_return:        
        ; We return here from (apply)
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
        ; If we are here, this could be because of inballanced parens. MIT
        ; Scheme deals with this with a simple "Unspecified return value" which
        ; is not very helpful, Racket gives us "read: unexpected ')'" which at
        ; least tells us what is going on. We follow Racket.
                lda #str_extra_parens
                jsr help_print_string
                jmp repl                        ; Return to main loop
        
_empty_list:
        ; ---- Empty list '()' ----

        ; The empty list marks the end of the input. We push the empty string
        ; symbol to the Data Stack
                cpy #<OC_EMPTY_LIST  
                bne eval_not_legal_meta     ; temporary, TODO real error message

                ; The empty list is formally self-evaluating, so we fall
                ; through to self-evaluating objects  
                

; ---- Self-evaluating objects ---- 

; All of these are self-evaluating and just print themselves. Since we already
; have the object on the Data Stack, we don't even have to push it anymore.
eval_1_bool:
eval_2_fixnum:
eval_3_char:
eval_4_string:
eval_e_spec:
eval_f_proc:
                jmp proc_eval_next      ; TODO replace with RTS directly

eval_5_bignum:
        ; TODO add code for bignums

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

; eval_f_proc: Naked procedures are self-evaluating, so we keep them up at the
; beginning with booleans and strings

; eval_e_spec: Naked special forms are self-evaluating, so keep them up at the
; beginning with the booleans and strings

                jmp eval_next   ; TODO catch undefined stuff during development


; ===== EVALUATION JUMP TABLE ====

eval_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. In theory, we would have to go
        ; through the individual routines above for all, but some of these are
        ; self-evaluating, and so they just print out their results when they
        ; hit the printer. To increase speed, these just to the next entry
        ; TODO change targets to self-evaluating once code is stable

        .word eval_0_meta, eval_1_bool, eval_2_fixnum, eval_3_char

        ;      4 string       5 bignum   6 UNDEF    7 UNDEF
        .word eval_4_string, eval_next, eval_next, eval_next

        ;      8 UNDEF    9 UNDEF    A UNDEF    B UNDEF
        .word eval_8_pair, eval_next, eval_next, eval_next

        ;     C UNDEF    D UNDEF    E special    F primitive
        ;                             forms       procedures
        .word eval_next, eval_next, eval_e_spec, eval_f_proc


; ==== PROCEDURE APPLY  ====

; Apply is so central to the loop it lives here instead of with the other
; primitive procedures in procedures.asm.

apply: 
proc_apply:
        ; """Applies a primitive procedure object to a list of operands, for
        ; instance '(apply + (list 3 4))'. We arrive here when the evaluator
        ; finds a '(' as OC_PARENS_START and has confirmed that the next object
        ; is either a primitive procedure - then we end up here - or a special
        ; form. We arrive here with the object right after the '(' on the top
        ; of the Data Stack. 

                ; We make completely sure that X is the Data Stack pointer so
                ; the procedures don't have to consider anything else
                ldx dsp

                ; With procedures, the LSB is the offset to the jump table for
                ; code in procedures.asm. This means there is one unused
                ; nibble, the lower nibble of the MSB
                lda 0,x                 ; LSB
                tay                     ; use Y so X can stay dsp

                lda exec_table_lsb,y
                sta jump
                lda exec_table_msb,y
                sta jump+1

                jmp (jump)

proc_apply_return:
        ; This is where the procedures jump (JMP, not RTS) to when they are
        ; done. They are responsible for moving to the closing parens ')'
        ; of their term. We move on to the next entry for eval before we jump
        ; back. We should pull the old value and push the new one, but we can
        ; actually just overwrite the current value.

        ; TODO note this is pretty much the same routine we use in the current
        ; testing procedure (newline), so we can probably move this to the same
        ; subroutine
                
                ; If we have already reached the end - say "(newline)", then we
                ; don't want to get the next entry
                lda walk_done
                bne _done

                ; Not the end of the line. Get next entry
                jsr help_walk_next

                lda walk_car            ; LSB
                sta 0,x
                lda walk_car+1          ; MSB
                sta 1,x

_done:
        ; Remember we have come from the meta processing part of eval, so we
        ; need to go back there. 
                jmp eval_0_meta_return  ; TODO replace with direct RTS
                

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


