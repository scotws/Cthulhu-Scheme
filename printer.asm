; Print routine for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 06. Apr 2020
; This version: 10. Apr 2020

; We use "printer" in this file instead of "print" to avoid any possible
; confusion with the helper functions

; ==== PRINTER ====
printer: 

; ---- Debug routines ---- 

        .if DEBUG == true
        jsr debug_dump_ast
;       jsr debug_dump_hp
        lda #AscLF
        jsr help_emit_a
        .fi

; ==== PRINT MAIN LOOP ====

        ; We walk the AST - which should be rather short by now - and print the
        ; results. Don't touch tmp0 because it is used by print routines in
        ; helper.asm
                lda ast
                sta tmp1
                lda ast+1
                sta tmp1+1

printer_loop:
.block
                ldy #3                  ; MSB of the next node entry down ...
                lda (tmp1),y            ; ...  which contains the tag nibble
                and #$f0                ; mask all but tag nibble

_check_for_meta:
        ; The most common and important meta will be the end of the AST
                cmp #ot_meta
                bne _not_meta

                ; ---- See if end of AST

                ; This currently is paranoid because the only meta object we
                ; have is the end of AST marker, which is $0000. 
                ora (tmp1)              ; LSB
                bne printer_error       ; We're in trouble, panic and re-REPL
                jmp printer_done

_not_meta:
                ; ---- See if bool object
                cmp #ot_bool
                bne _not_bool

                ; We have a bool, now we need to figure out which one
                ldy #2
                lda (tmp1),y            ; LSB
                bne _bool_true          ; not a zero means true
                lda #str_false
                bra _bool_printer
_bool_true:
                lda #str_true
_bool_printer:
                jsr help_print_string
                jmp printer_next

_not_bool: 
                ; ---- See if TODO object

; **** TODO HERE TODO  ****

                ; ADD NEW PRINTS HERE 

                ; Fall through to printer_error if we didn't find a match
.bend

; ---- Print error ----
printer_error:
                ; If we landed here something went really wrong because we
                ; shouldn't have an object we can't print
                lda str_bad_object
                jsr help_print_string_no_lf

                ldy #1
                lda (tmp1),y
                jsr help_byte_to_ascii
                lda (tmp1)
                jsr help_byte_to_ascii

                bra printer_done

; ---- Get next entry ----
printer_next:
                ; Get next entry out of AST
                lda (tmp1)              ; LSB of next entry
                tax
                ldy #1
                lda (tmp1),y            ; MSB of next entry
                sta tmp1+1
                stx tmp1
                
                jmp printer_loop


; ===== RETURN TO REPL ====
printer_done:
                ; fall through to repl_done
