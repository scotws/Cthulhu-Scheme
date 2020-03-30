; Platform-dependent file and Kernel for Cthulhu Scheme
; Platform: py65mon (default)
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth)
; This version: 30. March 2020

; This file is adapted from the platform system of Tali Forth 2
; Code is for the 64Tass assembler

; 65C02 processor (Cthulhu Scheme will not compile on older 6502)
        .cpu "65c02"

; No special text encoding (eg. ASCII)
        .enc "none"

; Start ROM at memory location $8000
        * = $8000


; ==== MEMORY MAP ====

; TODO change memory map, this is all still Tali Forth

; Of the 32 KiB we use, 24 KiB are reserved for Tali (from $8000 to $DFFF)
; and the last eight (from $E000 to $FFFF) are left for whatever the user
; wants to use them for.

; Drawing is not only very ugly, but also not to scale. See the manual for
; details on the memory map. Note that some of the values are hard-coded in
; the testing routines, especially the size of the input history buffer, the
; offset for PAD, and the total RAM size. If these are changed, the tests will
; have to be changed as well


;    $0000  +-------------------+  ram_start, zpage, user0
;           |  User varliables  |
;           +-------------------+
;           |                   |
;           |                   |
;           +~~~~~~~~~~~~~~~~~~~+  <-- dsp
;           |                   |
;           |  ^  Data Stack    |
;           |  |                |
;    $0078  +-------------------+  dsp0, stack
;           |                   |
;           |   (Reserved for   |
;           |      kernel)      |
;           |                   |
;    $0100  +-------------------+
;           |                   |
;           |  ^  Return Stack  |  <-- rsp
;           |  |                |
;    $0200  +-------------------+  rsp0, buffer, buffer0
;           |  |                |
;           |  v  Input Buffer  |
;           |                   |
;    $0300  +-------------------+  cp0
;           |  |                |
;           |  v  Dictionary    |
;           |       (RAM)       |
;           |                   |
;   (...)   ~~~~~~~~~~~~~~~~~~~~~  <-- cp
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;    $7C00  +-------------------+  hist_buff, cp_end
;           |   Input History   |
;           |    for ACCEPT     |
;           |  8x128B buffers   |
;    $7fff  +-------------------+  ram_end


; Hard physical addresses. Some of these are somewhat silly for the 65c02,
; where for example the location of the Zero Page is fixed by hardware. Note we
; currently don't use the complete zero page

ram_start = $0000          ; start of installed 32 KiB of RAM
ram_end   = $8000-1        ; end of installed RAM
zpage     = ram_start      ; begin of Zero Page ($0000-$00ff)
zpage_end = $7F            ; end of Zero Page used ($0000-$007f)	
stack0    = $0100          ; begin of Return Stack ($0100-$01ff)

; ==== MAIN CODE ROUTINES ====

.include "../definitions.asm"           ; aliases and other definitions
.include "../cthulhu.asm"               ; main code
.include "../helpers.asm"               ; various general subroutines
.include "../native-procedures.asm"     ; assembler-coded procedures
.include "../procedures.asm"            ; high-level procedures
.include "../strings.asm"               ; all text including error strings


; SOFT PHYSICAL ADDRESSES

; Tali currently doesn't have separate user variables for multitasking. To
; prepare for this, though, we've already named the location of the user
; variables user0. Note cp0 starts one byte further down so that it currently
; has the address $300 and not $2FF. This avoids crossing the page boundry when
; accessing the user table, which would cost an extra cycle.

; hist_buff = ram_end-$03ff  ; begin of history buffers
; bsize     = $ff              ; size of input/output buffers
; buffer0   = stack0+$100      ; input buffer ($0200-$027f)


; ==== KERNEL ROUTINES ====

; This section attempts to isolate the hardware-dependent parts of Cthulhu
; Scheme to make it easier for people to port it to their own machines.
; Ideally, you shouldn't have to touch any other files. There are three
; routines and one string that must be present for Cthulhu Scheme to run:

;       kernel_init - Initialize the low-level hardware
;       kernel_getc - Get single character in A from the keyboard (blocks)
;       kernel_putc - Prints the character in A to the screen
;       s_kernel_id - The zero-terminated string printed at boot

; This default version Cthulu Scheme ships with is written for the py65mon
; machine monitor (see the manual for details).

; Py65mon by default puts the basic I/O routines at the beginning of $f000. We
; don't want to change that because it would make using it out of the box
; harder, so we just advance past the virtual hardware addresses. This is crude
; but good enough for now.
* = $f010

; All vectors currently end up in the same place - we restart the system
; hard. If you want to use them on actual hardware, you'll have to redirect
; them all.
v_nmi:
v_reset:
v_irq:
kernel_init:
        ; """Initialize the hardware. This is called with a JMP and not
        ; a JSR because we don't have anything set up for that yet. With
        ; py65mon, of course, this is really easy. -- At the end, we JMP
        ; back to the label cthulhu to start the Scheme system.
        ; """
.block
                
                ; Since the default case for Cthulhu is the py65mon emulator,
                ; we have no use for interrupts. If you are going to include
                ; them in your system in any way, you're going to have to do it
                ; from scratch. Sorry.
                sei             ; Disable interrupts

                ; We've successfully set everything up, so print the kernel
                ; string
                ldx #0
-               lda s_kernel_id,x
                beq _done
                jsr kernel_putc
                inx
                bra -
_done:
                jmp cthulhu
.bend

kernel_getc:
        ; """Get a single character from the keyboard. By default, py65mon
        ; is set to $f004, which we just keep. Note that py65mon's getc routine
        ; is non-blocking, so it will return '00' even if no key has been
        ; pressed. We turn this into a blocking version by waiting for a
        ; non-zero character.
        ; """
.block
_loop:
                lda $f004
                beq _loop
                rts
.bend


kernel_putc:
        ; """Print a single character to the console. By default, py65mon
        ; is set to $f001, which we just keep.
        ; """
                sta $f001
                rts


platform_bye:
                brk

; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot
s_kernel_id:
        .text "Cthulhu Scheme default kernel for py65mon (30. Mar 2020)", Asclf, 0


; Add the interrupt vectors
* = $fffa

.word v_nmi
.word v_reset
.word v_irq

; END
