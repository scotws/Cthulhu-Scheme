; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 28. Apr 2020

; This is the main file for Cthulhu Scheme. It mainly contains the REPL. 

; Main entry point
cthulhu:

; ==== SETUP ====

        ; Reset the system. Does not restart the kernel, use the 65c02
        ; reset for that. 
                cld

        ; Set default output port. We wait to set the input port until
        ; we've defined all the high-level procedures
                lda #<kernel_putc
                sta output
                lda #>kernel_putc
                sta output+1

        ; Set up the memory map. We use the default values for the RAM
        ; segments as defined in the platform file. These are stored in
        ; their RAM segment nibbles (RSN). Currently, these are
        ; static, but will probably be dynamic once we have garbage
        ; collection. This list will be expanded as we add more object
        ; types
                lda #RAM_SEGMENT_AST    ; AST, default nibble $10
                sta rsn_ast
                lda #RAM_SEGMENT_STR    ; Strings, default nibble $20
                sta rsn_str

        ; Clear the string buffer. At the moment, there is no way to get rid of
        ; strings, but we'll figure that out later. The AST stuff is set by the
        ; parser. 
                ldy #$02        ; First free byte is one word down
                sty hp_str
                lda rsn_str     ; MSB of RAM segment for strings
                sta hp_str+1

        ; Reset the pointer to the current entry in the string table, which is
        ; the very beginning of the RAM string segment. The MSB is still in A
                sta strp+1
                stz strp        ; LSB

        ; Clear the first word in the RAM segment to make clear that table is
        ; empty
                lda #00
                tay
                sta (hp_str)
                iny
                sta (hp_str),y

        ; The rest of the heap area is currently not accessable. 

        ; TODO define high-level procudures by loading from ROM

                ; Set default input port
                lda #<kernel_getc
                sta input
                lda #>kernel_putc
                sta input+1


; ==== REPL ====
; TODO https://eecs490.github.io/project-scheme-parser/
repl: 

; ==== READER ====
; The Reader's job is to accept input and place it into the current input
; buffer. Scheme does some things differently for line feeds in comments,
; strings, and inside parens. 
.include "reader.asm"

; ==== LEXER ====
; The Lexer (or tokenizer) converts the input string into tokens, stripping out
; whitespace and other characters we don't need for processing. This also does
; some basic checks if the input is correct. The result ends up in the token
; buffer
.include "lexer.asm"

; ==== PARSER ====
; The Parser does the really hard work of converting the token stream into an
; Abstract Syntax Tree (AST) consisting of Scheme objects. This, for example,
; is where strings are stored in the string table.
.include "parser.asm"

; ==== EVAL ====
; The Evaluator walks through the AST and actually executes any procedures,
; changing the AST. This is the actual "running" of the program. The result is
; a modified AST of Scheme objects, or maybe even just one or none at all.
.include "eval.asm"

; ==== PRINTER ====
;  The Printer returns the result of the whole operation, like printing the
;  result of  (+ 1 2) to the screen. 
.include "printer.asm"

; ==== GARGBAGE COLLECTION ====
; Garbage collection frees up space by reorganizing the various RAM segments of
; the heap. We'll figure this out later.
; TODO add garbage collection

; ==== ALL DONE ====

; Usually we fall through to here from the printer. However, if we were given
; an empty line, the lexer jumps here directly to save time.
repl_empty_line:
                jmp repl

repl_quit:
        ; We quit, which is pretty much the same as (exit) but without the
        ; question. MIT Scheme prints out "Moriturus te saluto." but we have
        ; better things in mind. Might need to be shortened if we really run
        ; out of space.
                lda #str_chant
                jsr help_print_string
                jmp platform_quit

