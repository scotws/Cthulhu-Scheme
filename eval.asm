; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 05. Apr 2020

; 
eval: 
                .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
                jsr debug_dump_hp
                .fi 
                

; ==== All done ====
eval_done:
                jmp print
