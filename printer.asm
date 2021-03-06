; Print routine for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 06. Apr 2020
; This version: 17. May 2020

; We use "printer" in this file instead of "print" to avoid any possible
; confusion with the helper functions. 

; The evaluator pushes the results to the Data Stack, which we go through until
; we find the empty list as the terminator
printer:

        .if DEBUG == true
                ; TODO test dump contents of the Data Stack
                jsr debug_dump_ds
        .fi

        ; Start at the beginning of the data stack minus two - by default, we
        ; start at $00FD. 
                ldx #ds_start-2
                stx dsp         ; Sadly, we use X for two different things

printer_loop:
        ; Get the MSB. We need to check if this is the end of the stack, which
        ; will happen a lot - this would be OC_EMPTY_LIST
                ldx dsp
                lda 1,x         ; by default the MSB at $00FE
                tay

                ; We cheat because we know that OC_EMPTY_LIST is 0000
                beq _check_for_end
_not_end:
                ; This is something else than the end. Processing might have
                ; destroyed the original MSB so we get it back
                tya

                ; Check the object's tag
                and #$f0        ; mask all but tag nibble

                ; Use the tag to get the entry in the jump table.
                ; First, we have to move the nibble over four bits,
                ; then multiply it by two, which is a left shift, so we
                ; end up wit three right shifts
                lsr
                lsr
                lsr     ; Fourth LSR and ASL cancle each other
                tax     ; This is why we save X as dsp

                ; Move down one line
                jsr help_emit_lf

                ; This instruction is 65c02 specific, see
                ; http://6502.org/tutorials/65c02opcodes.html#2 
                jmp (printer_table,x)
 

_check_for_end:
        ; We arrive here if the MSB is 00. If the LSB is also zero, we know
        ; that we have OC_EMPTY_LIST and the printing is done. 
                lda 0,x         ; LSB

                ; If it is not a zero, it is something else like a NOP object
                ; and we let the specialized routine handle it.
                bne printer_0_meta

                ; Whatever, we're done. This is going to be too far for
                ; a branch.
                jmp printer_done

printer_next:
        ; We arrive here after printing. Get the next entry from the Data
        ; Stack. The printer routines use X as the Data Stack pointer, so we
        ; don't have to reload it.
                dec dsp
                dec dsp

                bra printer_loop        

printer_done:
        ; Return to eval 
                rts             


; ==== PRINTER SUBROUTINES ====

; We land here with the MSB of the car in 1,x and the LSB in 0,x. Note that
; none of these print a line feed, we let other parts handle this for us.

printer_0_meta:
        ; ---- Meta ----

        ; This is a bit strange because we don't arrive here through the jump
        ; table but after the check for the end of the stack for printing, and
        ; finding out that LSB is not $00 as it would be for the end.
        ; Currently, this can only be OC_NOP, the No Operation Object, which is
        ; passed back by procedures like (newline) we only call for their side
        ; effects. 
        
        ; There are two ways to deal with this case: MIT Scheme prints
        ; "Unspecified return value" and Racket doesn't print anything. We use
        ; conditional assembly to let the user decide which one they want, but
        ; the default is to not print anything. See the platform file to
        ; change this
        .if PRINT_NOP_MSG == true
                lda #str_unspec
                jsr help_print_string
        .fi
                bra printer_next

printer_1_bool:
        ; ---- Booleans ----
                
                ldx dsp

        ; Booleans are terribly simple with two different versions. 
                lda 1,x         ; reload MSB to be safe
                and #$0F        ; get rid of tag nibble
                ora 0,x         ; OR with LSB

                bne _bool_true          ; not a zero means true
                lda #str_false
                bra _bool_printer
_bool_true:
                lda #str_true
_bool_printer:
                jsr help_print_string_no_lf
                bra printer_next


printer_2_fixnum:
        ; ---- Fixnums ----

                ldx dsp

        ; Print fixnums as decimal with a sign
        ; TODO Yeah, that is going to happen at some point. For the moment,
        ; however, we will just print it out in hex until we have everything
        ; else working
        ; TODO handle negative numbers
        ; TODO print as decimal number
                lda 1,x                 ; MSB
                and #$0F                ; Mask tag
                jsr help_byte_to_ascii

                lda 0,x                 ; LSB
                jsr help_byte_to_ascii

                bra printer_next


printer_3_char:
        ; ---- Characters ----
        ; TODO define tag and add code

printer_4_string:
        ; ---- Strings ----

                ldx dsp

        ; Strings are interned, so we just get a pointer to where they are in
        ; the heap's RAM segment for strings. This uses tmp2

                lda 1,x                 ; MSB
                and #$0F                ; mask tag
                ora rsn_str             ; merge with section nibble instead
                sta tmp2+1      
                lda 0,x                 ; LSB 
                sta tmp2

                ldy #0
_string_loop:
                lda (tmp2),y    
                beq printer_next       ; string is zero terminated

                ; TODO deal with escaped characters: LF is printed "\n" in the
                ; string instead of being executed

                jsr help_emit_a
                iny
                bra _string_loop


printer_5_bignum:
        ; ---- Bignums ----
        ; TODO define tag and add code

printer_6_var:
        ; ---- Variables ----
        ; TODO define variables and add code

printer_7_UNDEFINED:
        ; TODO define tag and add code

printer_8_pair:
        ; ---- Pair ----
        ; TODO define tag and add code

printer_9_UNDEFINED:
        ; TODO define tag and add code

printer_a_UNDEFINED:
        ; TODO define tag and add code

printer_b_UNDEFINED:
        ; TODO define tag and add code

printer_c_UNDEFINED:
        ; TODO define tag and add code

printer_d_UNDEFINED:
        ; TODO define tag and add code

printer_e_special:
        ; ---- Special forms----

        ; If we ended up here directly, the user typed something like "define"
        ; instead of "(define)". MIT-Scheme produces a rather unhelpful generic
        ; error message. Instead, we follow Racket and other Schemes by
        ; printing a string and the address where the actual code is located.
                lda #str_special_prt            ; "#<special:$"
                jsr help_print_string_no_lf
                bra print_common_exec

printer_f_proc:
        ; ---- Processes ----

        ; If we ended up here directly, the user typed something like "exit"
        ; instead of "(exit)". MIT-Scheme produces a rather unhelpful generic
        ; error message. Instead, we follow Racket and other Schemes by
        ; printing a string and the address where the actual code is located.
                lda #str_proc_prt               ; "#<procedure:$"
                jsr help_print_string_no_lf

                ; drop through to print_common_exec

print_common_exec:
                ldx dsp

                lda 1,x                 ; MSB
                jsr help_byte_to_ascii
                lda 0,x                 ; LSB
                jsr help_byte_to_ascii
                lda #'>'
                jsr help_emit_a

                bra printer_next


; ==== PRINTER JUMP TABLE ====

printer_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. 

        .word printer_0_meta, printer_1_bool, printer_2_fixnum, printer_3_char

        ;      4 string        5 bignum            6 var          7 UNDEF
        .word printer_4_string, printer_5_bignum, printer_6_var, printer_next

        ;      8 pair          9 UNDEF       A UNDEF       B UNDEF
        .word printer_8_pair, printer_next, printer_next, printer_next

        ;      C UNDEF       D UNDEF       E speical          F proc
        .word printer_next, printer_next, printer_e_special, printer_f_proc

