; Boolean Tests for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 10. Mai 2020
; This version: 17. Mai 2020

; Formats:
; - empty lines are ignored
; - lines that start with a semicolon ';' like this one are ignored
; - lines that start with a SECTION are printed to the output
; - All other lines are SENT-WANT combinations separated by commas

SECTION Boolian tests
"#f" -> "#f\n"
"#t" -> "#t\n"

"#t #t" -> "#t\n#t\n"
"#f #f" -> "#f\n#f\n"

"#t #f #t" -> "#t\n#f\n#t\n"
"#f #t #f" -> "#f\n#t\n#f\n"
