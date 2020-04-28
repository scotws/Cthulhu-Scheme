; Debugging helper routines 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 04. Apr 2020
; This version: 27. Apr 2020

; Do not include these routines in finished code - set the DEBUG flag in the
; platform to "false" for this. All routines start with debug_ . These are not
; documented at the moment, because they are still changing all the the time. 

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
                jsr help_byte_to_ascii  
                jmp help_emit_lf                ; JSR/RTS
.bend


debug_dump_hp:
        ; Print the value of the RAM heap pointer for pairs/AST
.block
                jsr help_emit_lf

                lda #strd_dump_hp               ; "Heap pointer: "
                jsr debug_print_string_no_lf

                lda hp_ast+1
                jsr help_byte_to_ascii
                lda hp_ast
                jsr help_byte_to_ascii  
                jmp help_emit_lf                ; JSR/RTS
.bend


debug_dump_ast: 
        ; Dump the raw data of the AST. Uses the generic AST walker from
        ; helpers
.block
                lda #strd_dump_ast              ; "AST root: "
                jsr debug_print_string_no_lf

                ; Start at the beginning of the tree. Print address where the
                ; first pair lives. We can't use tmp0 because the print routine
                ; uses it
                lda rsn_ast             ; RAM segment nibble
                pha                     ; save MSB
                jsr help_byte_to_ascii  ; print MSB

                ldy #2                  ; By definition
                tya
                jsr help_byte_to_ascii  ; print LSB

                pla                     ; get MSB back

                ; Initialize walker with MSB of root pair in A and LSB in Y
                ; (Remember "Little Young Americans", little-endian A and Y)
                jsr help_walk_init

_debug_dump_ast_loop:

                ; If carry is set we are at the last entry. Save the status
                ; flags for now
                php
                
                ; Make it pretty
                lda #strd_dump_arrow            ; "--> "
                jsr debug_print_string_no_lf

                ; Print cdr
                lda walk_cdr+1
                jsr help_byte_to_ascii          ; MSB
                lda walk_cdr
                jsr help_byte_to_ascii          ; LSB

                ; Colon as a divider between cdr and car
                lda #':'
                jsr help_emit_a

                ; Print the car
                lda walk_car+1
                jsr help_byte_to_ascii          ; MSB
                lda walk_car
                jsr help_byte_to_ascii          ; LSB

                ; Check to see if this was the last entry
                plp
                bcs _debug_dump_ast_done

                ; Get the next AST pair. If we are at the end, the carry flag
                ; is set
                jsr help_walk_next
                bra _debug_dump_ast_loop

_debug_dump_ast_done:
                jsr help_emit_lf
                rts
.bend


debug_dump_ds:
        ; Dump the contents of the Data Stack in Zero Page. This assumes that
        ; the Data Stack begins at 00FE, but we print everything starting 00FF
        ; to be sure.
                phx
                phy
                ldx #ds_start

                ; Print the address first
                lda #00                         ; MSB always 00
                jsr help_byte_to_ascii
                lda #$FF
                jsr help_byte_to_ascii
                lda #':'
                jsr help_emit_a                 ; "00FF:"

                ; Print 00FF
                lda 0,x     
                jsr help_byte_to_ascii          
                jsr help_emit_lf

_loop:
                ; With that out of the way we can loop through the next entries
                lda #00                         ; MSB by definition
                jsr help_byte_to_ascii

                dex                             ; LSB
                dex
                txa
                jsr help_byte_to_ascii
                lda #':'
                jsr help_emit_a                 ; "00FD:"

                lda 1,x                         ; MSB
                beq _check_end
_not_done:
                jsr help_byte_to_ascii

                lda 0,x                         ; LSB
                jsr help_byte_to_ascii
                jsr help_emit_lf
                bra _loop

_check_end:
                lda 0,x                         ; LSB
                beq _clean_up
                lda 1,x
                bra _not_done

_clean_up:
                ; By definition, 00 in A
                jsr help_byte_to_ascii
                lda #00
                jsr help_byte_to_ascii

                ; drop through to done

_done:
                ply
                plx
                rts


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


