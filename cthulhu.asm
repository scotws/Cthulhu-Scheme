; Cthulhu Scheme for the 65c02 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 30. Mar 2020
; This version: 30. Mar 2020

; This is the main file for Cthulhu Scheme

; Label to mark the beginning of code. Useful for people who are porting this
; to other hardware configurations
code0:

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

                ; TODO clear the heap
                ; TODO define high-level procudures
                ; TODO initialize the history buffers

; ==== REPL ====

                ; TODO Read a string into the buffer



; TODO setup heap
; TODO initilize REPL

; TODO temporary halt of machine
;
        brk
