; Print routine for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 06. Apr 2020
; This version: 21. Apr 2020

; We use "printer" in this file instead of "print" to avoid any possible
; confusion with the helper functions. 

; We walk the AST, which should be quite a bit shorter by now, and print
; a representantion of what is left. This uses the AST walker from helpers.asm

; TODO In future, the evaluator might not directly change the original AST but
; create a second one with the results, so we leave this code separate from the
; evaluator for the moment, even though it does exactly the just same thing
; except for the part with the actual jump table. 
printer: 
        .if DEBUG == true
                ; TODO test dump contents of the AST
                jsr debug_dump_ast
        .fi
               
        ; Initialize the AST with the address of its RAM segment. 
                lda rsn_ast     ; RAM segment nibble
                ldy #02         ; by definition
                jsr help_walk_init
                
printer_loop:

        ; A contains the MSB of the car ... you know the drill from the
        ; evaluator.
                and #$f0        ; mask all but tag nibble

        ; Use the tag to get the entry in the jump table.
        ; First, we have to move the nibble over four bits,
        ; then multiply it by two, which is a left shift, so we
        ; end up wit three right shifts
                lsr
                lsr
                lsr     ; Fourth LSR and ASL cancle each other
                tax

        ; Move down one line
        ; TODO This is different from the evaluator as well
                jsr help_emit_lf

        ; This instruction is 65c02 specific, see
        ; http://6502.org/tutorials/65c02opcodes.html#2 
                jmp (printer_table,X)
                
printer_next:
        ; Get next entry out of AST
                jsr help_walk_next
                
        ; If we have reached the end of the AST, the walker sets the carry flag
        ; TODO we need to take care of the car of the last entry as well, this
        ; ends too soon!
                bcc printer_loop
                bra printer_done        ; this will have to be jmp later


; ==== PRINTER SUBROUTINES ====

; We land here with the car and cdr stored in walk_car and walk_cdr
; respectively and the LSB of the car still in Y. The MSB was in A but was
; destroyed, so we need to reclaim it.

; ---- Meta ----
printer_0_meta:
        ; This marks the end of the tree (which at the moment is just a list
        ; anyway) 
                bra printer_done

; ---- Booleans ----
printer_1_bool:
        ; Booleans are terribly simple with two different versions. 
                lda walk_car+1          ; MSB of car
                and #$0F                ; Get rid of tag
                ora walk_car 

                bne _bool_true          ; not a zero means true
                lda #str_false
                bra _bool_printer
_bool_true:
                lda #str_true
_bool_printer:
                jsr help_print_string_no_lf
                bra printer_next


        ; ---- Fixnums ----
printer_2_fixnum:
        ; Print fixnums as decimal with a sign
        ; TODO Yeah, that is going to happen at some point. For the moment,
        ; however, we will just print it out in hex until we have everything
        ; else working
        ; TODO handle negative numbers
        ; TODO print as decimal number
                lda walk_car+1          ; MSB
                and #$0F                ; Mask tag
                jsr help_byte_to_ascii

                tya                     ; still Y
                jsr help_byte_to_ascii

                bra printer_next


printer_3_bignum:
        ; TODO define tag and add code

printer_4_char:
        ; TODO define tag and add code

        ; ---- Strings ----
printer_5_string:
        ; Strings are interned, so we just get a pointer to where they are in
        ; the heap's RAM segment for strings. This uses tmp2

                lda walk_car+1          ; MSB
                and #$0F                ; mask tag
                ora rsn_str             ; merge with section nibble instead
                sta tmp2+1      
                sty tmp2                ; LSB

                ldy #0
_string_loop:
                lda (tmp2),y    
                beq printer_next       ; string is zero terminated

                ; TODO deal with escaped characters: LF is printed "\n" in the
                ; string instead of being executed

                jsr help_emit_a
                iny
                bra _string_loop


printer_6_UNDEFINED:
        ; TODO define tag and add code

printer_7_UNDEFINED:
        ; TODO define tag and add code

printer_8_UNDEFINED:
        ; TODO define tag and add code

printer_9_UNDEFINED:
        ; TODO define tag and add code

printer_A_UNDEFINED:
        ; TODO define tag and add code

printer_B_UNDEFINED:
        ; TODO define tag and add code

printer_C_UNDEFINED:
        ; TODO define tag and add code

printer_D_UNDEFINED:
        ; TODO define tag and add code

printer_E_UNDEFINED:
        ; TODO define tag and add code

printer_F_UNDEFINED:
        ; TODO define tag and add code

        ; TODO paranoid catch during testing
                bra printer_next


; ==== PRINTER JUMP TABLE ====

printer_table:
        ; Based on the offset provided by the object tag nibbles, we use this
        ; to jump to the individual routines. 

        ;      0 meta        1 bool          2 fixnum          3 bignum
        .word printer_done, printer_1_bool, printer_2_fixnum, printer_next

        ;      4 char     5 string   6 UNDEF    7 UNDEF
        .word printer_next, printer_5_string, printer_next, printer_next

        ;      8 UNDEF    9 UNDEF    A UNDEF    B UNDEF
        .word printer_next, printer_next, printer_next, printer_next

        ;      C UNDEF    D UNDEF    E  UNDEF   F UNDEF
        .word printer_next, printer_next, printer_next, printer_next


; ==== RETURN TO REPL ====
printer_done:
                ; fall through to repl_done

