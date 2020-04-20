; Debugging helper routines 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 04. Apr 2020
; This version: 20. Apr 2020

; Do not include these routines in finished code - set the DEBUG flag in the
; platform file for this. All routines start with debug_ . These are not
; documented at the moment, because they are currently changing all the the
; time. 

debug_dump_input:
        ; Hexdump contents of the character input buffer (cib)
        ; Destroys X
.block
                jsr help_emit_lf

                lda #strd_dump_input            ; "Input: "
                jsr debug_print_string_no_lf

                ldx #0
-
                lda cib,x
                beq _done

                jsr help_byte_to_ascii
                inx
                
                lda #' '
                jsr help_emit_a
                bra -
_done:
                jmp help_byte_to_ascii          ; JSR/RTS

.bend

debug_dump_token: 
        ; Hexdump contents of the token buffer. Assumes that tokens are one
        ; byte long. Currently not clever enough to handle multi-byte tokens.
        ; Destroys X
.block
                jsr help_emit_lf

                lda #strd_dump_token            ; "Token: "
                jsr debug_print_string_no_lf

                ldx #0
-
                lda tkb,x
                cmp #T_END
                beq _done

                jsr help_byte_to_ascii
                inx

                lda #' '
                jsr help_emit_a

                ; We make sure that we don't go off the end of the buffer
                ; because we don't trust the code to always include the
                ; terminal token
                cpx tkbp
                bne - 
_done:
                ; we land here with a T_END token
                jmp help_byte_to_ascii          ; JSR/RTS
.bend

debug_dump_hp:
        ; Print the value of the RAM heap pointer for pairs/AST
                jsr help_emit_lf

                lda #strd_dump_hp               ; "Heap pointer: "
                jsr debug_print_string_no_lf

                lda hp_ast+1
                jsr help_byte_to_ascii
                lda hp_ast
                jmp help_byte_to_ascii          ; JSR/RTS



debug_dump_ast: 
        ; Dump the raw data of the AST. This is a lower-level version of
        ; printing the cons cells, so we can use it for anything
        ; TODO change name once it has settled down
.block
                jsr help_emit_lf

                lda #strd_dump_ast              ; "AST root: "
                jsr debug_print_string_no_lf

                ; Start at the beginning of the tree. Print address where the
                ; first pair lives. We can't use tmp0 because the print routine
                ; uses it
                lda rsn_ast             ; RAM segment nibble
                sta tmp1+1
                jsr help_byte_to_ascii
                lda #2                  ; By definitioin
                sta tmp1
                jsr help_byte_to_ascii

_loop:
                ; Make it pretty
                lda #strd_dump_arrow            ; "--> "
                jsr debug_print_string_no_lf

                ; First, print cdr of pair
                ldy #1
                lda (tmp1),y
                sta tmp2+1                      ; save copy for end check
                jsr help_byte_to_ascii          ; MSB
                lda (tmp1)
                sta tmp2                        ; pointer to next entry, LSB
                jsr help_byte_to_ascii          ; LSB

                lda #':'
                jsr help_emit_a

                ; Then, print playload (actual object)
                ldy #3
                lda (tmp1),y                    ; MSB
                jsr help_byte_to_ascii
                ldy #2
                lda (tmp1),y                    ; LSB
                jsr help_byte_to_ascii

                ; See if we are at the end of the tree
                lda tmp2
                ora tmp2+1      ; Cheating: We know that OC_EMPTY_LIST is 0000
                beq _done

                ; Not done, get linked entry
                lda tmp2
                sta tmp1

                ; Remember the pointer to the next pair is saved as a pointer
                ; object, not just an address, so we have to replace the object
                ; tag by the RAM segment nibble
                lda tmp2+1
                and #$0F
                ora rsn_ast
                sta tmp1+1

                bra _loop

_done:
                rts
.bend


; ==== DEBUG PRINT ROUTINES ====

debug_emit_a:
        ; Print a single char, usally to show where we are. Char is in A
                pha
                jsr help_emit_lf

                pla
                jsr help_emit_a

                jmp help_emit_lf        ; JSR/RTS


debug_print_string_no_lf:
        ; """Given the number of a zero terminated string in A, print to the
        ; current output without adding a line feed. Uses Y and tmp0 by falling
        ; through to debug_print_common
        ; """
                ; Get the entry from the string table
                asl
                tay
                lda sd_table,y
                sta tmp0                ; LSB
                iny
                lda sd_table,y
                sta tmp0+1              ; MSB

                ; fall through to debug_print_common
debug_print_common:
        ; """Common print routine used by both the print functions and
        ; the error printing routine. Assumes string address is in tmp0. Uses
        ; Y.
        ; """
                ldy #0
_loop:
                lda (tmp0),y
                beq _done               ; strings are zero-terminated

                jsr help_emit_a         ; allows vectoring via output
                iny
                bra _loop
_done:
                rts


debug_print_string: 
        ; """Print a zero-terminated string to the console/screen, adding a LF.
        ; We do not check to see if the index is out of range. Uses tmp0.
        ; Assumes number of string is in A.
        ; """
                jsr debug_print_string_no_lf
                jmp help_emit_lf        ; JSR/RTS


; ===== DEBUGGING STRINGS ====

; We could use the normal string procedures but we want to keep everything that
; is debugging in its own file so we save space for later. See strings.asm for
; an explanation of the format

strd_dump_token  = 0
strd_dump_ast    = 1
strd_dump_hp     = 2
strd_dump_input  = 3
strd_dump_arrow  = 4
strd_dump_strtbl = 5
strd_dump_str    = 6

s_dump_token:   .null   "Token Buffer: "
s_dump_ast:     .null   "AST root: "
s_dump_hp:      .null   "AST heap pointer: "
s_dump_input:   .null   "Input Buffer: "
s_dump_arrow:   .null   " --> "
s_dump_strtbl:  .null   "String table: "
s_dump_str:     .null   "String pointer: "

sd_table:
        .word s_dump_token, s_dump_ast, s_dump_hp, s_dump_input    ; 0-3
        .word s_dump_arrow, s_dump_strtbl, s_dump_str              ; 4-7


