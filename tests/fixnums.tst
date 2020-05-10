; Fixnum Tests for Cthulhu Scheme 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 10. Mai 2020
; This version: 10. Mai 2020

; Formats:
; - empty lines are ignored
; - lines that start with a semicolon ';' like this one are ignored
; - lines that start with a SECTION are printed to the output
; - All other lines are SENT-WANT combinations separated by commas

; TODO These will all have to be changed once default output is decimal

SECTION Fixnum tests, binary
"#b0000" -> "0000\n"
"#b0001" -> "0001\n"
"#b0010" -> "0002\n"
"#b0011" -> "0003\n"
"#b0100" -> "0004\n"
"#b1000" -> "0008\n"
"#b1111" -> "000F\n"

"#b00000000" -> "0000\n"
"#b00000001" -> "0001\n"
"#b10000000" -> "0080\n"
"#b11111111" -> "00FF\n"

; SECTION Fixnum tests, octal

; SECTION Fixnum tests, decimal

SECTION Fixnum tests, hex
"#x000" -> "0000\n"
"#x123" -> "0123\n"
"#xAAA" -> "0AAA\n"
"#xBBB" -> "0BBB\n"
"#xCCC" -> "0CCC\n"
"#xDDD" -> "0DDD\n"
"#xEEE" -> "0EEE\n"
"#xfff" -> "0FFF\n"
"#xFFF" -> "0FFF\n"

