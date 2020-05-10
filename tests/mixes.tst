; Mixed Tests for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 10. Mai 2020
; This version: 10. Mai 2020

; Formats:
; - empty lines are ignored
; - lines that start with a semicolon ';' like this one are ignored
; - lines that start with a SECTION are printed to the output
; - All other lines are SENT-WANT combinations separated by commas

SECTION Mixed tests
"#f #t #xaaa" -> "#f\n#t\n0AAA\n"
"#f #x123 #t" -> "#f\n0123\n#t\n"


