; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 10. Apr 2020

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

                ; Set up the heap. First, pointer to next free entry
                lda <#heap
                sta hp
                lda >#heap
                sta hp+1

                ; The AST, symbol, string, and bignum tables are all empty
                stz symtbl
                stz symtbl+1
                stz strtbl
                stz strtbl+1
                stz bnmtbl
                stz bnmtbl+1
                stz ast
                stz ast+1

                ; TODO define high-level procudures by loading from ROM

                ; Set default input port
                lda #<kernel_getc
                sta input
                lda #>kernel_putc
                sta input+1


; ==== REPL ====
; TODO https://eecs490.github.io/project-scheme-parser/

repl: 
                ; Start overwriting input buffer
                stz ciblen
                stz ciblen+1

; ==== READER ====
.include "reader.asm"

; ==== LEXER ====
.include "lexer.asm"

; ==== PARSER ====
.include "parser.asm"

; ==== EVAL ====
.include "eval.asm"

; ==== PRINTER ====
.include "printer.asm"

; ==== ALL DONE ====

; Usually we fall through to here from the printer. However, if we were given
; an empty line, the lexer jumps here directly to save time.
repl_done:

; TODO TEST keep doing stuff over and over
;
                jmp repl
