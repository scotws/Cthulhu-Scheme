; Print routine for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 06. Apr 2020
; This version: 18. Apr 2020

; We use "printer" in this file instead of "print" to avoid any possible
; confusion with the helper functions. 

; ==== PRINTER ====

printer: 
        ; We walk the AST - which should be rather short right now - and print 
        ; the results. Don't touch tmp0 because it is used by print routines in
        ; helper.asm
                lda ast
                sta tmp1
                lda ast+1
                sta tmp1+1

printer_loop:
        ; Move down one line
                jsr help_emit_lf

                ldy #3          ; MSB of the next node entry down ...
                lda (tmp1),y    ; ...  which contains the tag nibble
                and #$f0        ; mask all but tag nibble

        ; Use the tag to get the entry in the jump table.
        ; First, we have to move the nibble over four bits,
        ; then multiply it by two, which is a left shift, so we
        ; end up wit three right shifts
                lsr
                lsr
                lsr     ; Fourth LSR and ASL cancle each other
                tax

        ; 65c02 specific, see
        ; http://6502.org/tutorials/65c02opcodes.html#2
                jmp (printer_table,X)
                
printer_next:
        ; Get next entry out of AST
                lda (tmp1)      ; LSB of next entry
                tax
                ldy #1
                lda (tmp1),y    ; MSB of next entry
                sta tmp1+1
                stx tmp1
                
                jmp printer_loop


; ==== PRINTER SUBROUTINES ====

; ---- Meta ----
printer_0_meta:
        ; This marks the end of the tree (which at the moment is just a list
        ; anyway) 
                bra printer_done


; ---- Booleans ----
printer_1_bool:
        ; Booleans are terribly simple with two different versions

                ldy #2
                lda (tmp1),y            ; LSB
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
                ldy #3          ; tag nibble and high nibble of number
                lda (tmp1),y    ; MSB nibble
                and #$0F        ; Mask tag


        ; TODO handle negative numbers
        ; TODO print as decimal number

                jsr help_byte_to_ascii
                ldy #2
                lda (tmp1),y    ; LSB
                jsr help_byte_to_ascii

                bra printer_next


printer_3_bignum:
        ; TODO define tag and add code

printer_4_char:
        ; TODO define tag and add code

        ; ---- Strings ----
printer_5_string:
        ; Strings are interned, so we just get a pointer to where they are in
        ; the heap (later: string memory segment). This uses tmp2

                ldy #2          
                lda (tmp1),y    ; LSB of address in heap
                sta tmp2
                iny
                lda (tmp1),y    ; MSB with tag and high nibble of pointer
                and #$0F        ; mask tag
                sta tmp2+1      

                ldy #0
_string_loop:
                lda (tmp2),y    
                beq _string_done        ; string is zero terminated

                ; TODO deal with escaped characters

                jsr help_emit_a

_string_done:
                bra printer_next

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

