; List of Headers for Cthulhu Scheme
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 03. Apr 2020
; This version: 03. Apr 2020

; This file contains a linked-list of the built-in procedures for Cthulhu
; Scheme 

; We could use the structure elements from 64tass for this but it would make
; switching to a different assembler very hard. Instead, we use a simple
; format. All headers start with 'n_'
;
;              8 bit     8 bit
;               LSB       MSB
; h_proc  ->  +---------+---------+
;          +0 | Next Header       | -> h_next_proc
;             +-------------------+
;          +2 | Start of Code     | -> proc_word
;             +-------------------+
;          +4 | Length  | Str ... | TODO possible status byte?
;             +---------+---------+
;             |   ...   |   ...   |
;             +---------+---------+
;             |   ...   |   ...   | (name string does not end with a zero)
;          +n +---------+---------+

; TODO TEST entry for (newline)
h_newline:
        .addr 0000              ; end of header list
        .addr proc_newline
        .byte 7
        .text "newline"

