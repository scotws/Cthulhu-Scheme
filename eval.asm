; Evaluator for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 05. Apr 2020
; This version: 10. Apr 2020

eval: 

; ---- Debugging routines ----

                .if DEBUG == true
                ; TODO TEST dump contents of AST 
                jsr debug_dump_ast
                jsr debug_dump_hp
                .fi 
                
; ===== EVAL MAIN LOOP =====

; TODO walk the tree, executing the entries

; TODO we can skip this all for the moment because we can only do #t and #f and
; they both just evaluate to themselves


; ==== CONTINUE TO PRINTER ====
eval_done:
                
