; Print routine for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 06. Apr 2020
; This version: 13. Apr 2020

; We use "printer" in this file instead of "print" to avoid any possible
; confusion with the helper functions

; ==== PRINTER ====
printer: 

; ==== PRINT MAIN LOOP ====

        ; We walk the AST - which should be rather short by now - and print the
        ; results. Don't touch tmp0 because it is used by print routines in
        ; helper.asm
                lda ast
                sta tmp1
                lda ast+1
                sta tmp1+1

printer_loop:
        ; TODO during development, we check the entries individually until we
        ; know what we are doing - this is one big case statement. Once the
        ; code is sound we can move to a table-driven system for speed.
.block
        ; Move down one line
                jsr help_emit_lf

                ldy #3                  ; MSB of the next node entry down ...
                lda (tmp1),y            ; ...  which contains the tag nibble
                and #$f0                ; mask all but tag nibble

_check_for_meta:
        ; The most common and important meta will be the end of the AST
                cmp #OT_META
                bne _not_meta

                ; ---- See if end of AST

                ; This currently is paranoid because the only meta object we
                ; have is the end of AST marker, which is $0000. 
                ora (tmp1)              ; LSB
                bne printer_error       ; We're in trouble, panic and re-REPL
                jmp printer_done

_not_meta:
                ; ---- See if bool object

                ; Booleans are so simple we currently don't bother jumping to
                ; a separate routine to print them. This will obviously have to
                ; change once we have a table-driven printing system, but for
                ; now, this is good enough to get us off the ground
                cmp #OT_BOOL
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
                jsr help_print_string_no_lf
                jmp printer_next

_not_bool: 
                ; ---- See if fixnum object
                cmp #OT_FIXNUM
                bne _not_fixnum

                ; We have a fixnum object, which we will now print. 

                ; TODO For the moment, however, we will just print it out in
                ; hex until we have everything else working
                ldy #3          ; tag nibble and high nibble of number
                lda (tmp1),y    ; MSB nibble
                and #$0F        ; Mask tab
                ; TODO handle negative numbers
                jsr help_byte_to_ascii
                ldy #2
                lda (tmp1),y    ; LSB
                jsr help_byte_to_ascii
                jmp printer_next


_not_fixnum: 
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

