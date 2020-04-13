; Platform-dependent file and Kernel for Cthulhu Scheme
; Platform: py65mon (default)
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth)
; This version: 11. Apr 2020

; This file is adapted from the platform system of Tali Forth 2 for the 64Tass
; assembler. To adapt it, you will need to relace the kernel routines at the
; bottom of the file with your own code and adapt the memory map to your layout


; ==== ASSEMBERLER FLAGS ====

; Set this to 'false' for production code. As 'true', this will assemble the
; debugging routines in debug.asm and various parts of the code
DEBUG = true

; Normal people don't use octal (#o) numbers anymore, but there are bound to be
; freaks out there who still use it. As a compromise, we include the code but
; don't actually use it unless this is set to true. You know who you are.
OCTAL = false


; ==== BASIC MACHINE DEFINITIONS ====

; 65C02 processor (Cthulhu Scheme will not compile on older 6502)
        .cpu "65c02"

; No special text encoding (eg. ASCII)
        .enc "none"


; ==== MEMORY MAP ====

ram_start = $0000       ; Start of RAM. Must contain the Zero Page
ram_size  = $8000       ; assumes 32 KiB of RAM

zp_start  = $0000       ; start of zero page, 
zp_size   = $80         ; max bytes allowed in Zero Page

; Remember, 65c02 reserves $0100 to $01ff for the stack

; We currently allow for a normal keyboard input buffer of 256 chars. This
; might be expanded once we know how much RAM we will actually need. Currently,
; there is no history setup for the REPL because of the same reason. It might
; be added later. 
buffers_start   = $0200         ; start of the buffer RAM area
cib_size        = $100          ; size of the input buffer, used by reader
tkb_size        = $100          ; size of the token buffer, used by lexer

; The heap is where we store various tables (string table, symbol table, bignum
; table, etc) and various objects. The variable hp points to the next free byte
; in the heap. We want to keep this as large as possible. Once we add garbage
; collection, we will probably have to reserve some space to rebuild things.
; For the moment, we use what RAM we have for the heap. Remember the 65c02
; reserves $0000 to $00ff for the zero page and $100 to $1ff for the stack, so
; we have to subtract $200 as well.
heap_size       = ram_size - ($200+cib_size+tkb_size)

; Of the 32 KiB ROM we assume we have, by default we use $8000 to $efff (28
; KiB) for code and constant data like strings, $f000 to $f010 for I/O
; routines, and everything after that until the interrupt vector addresses at
; $fffa for the kernel and possible user routines. 

; Py65mon by default puts the basic I/O routines at the beginning of $f000. We
; don't want to change that because it would make using it out of the box
; harder, so we just advance past the virtual hardware addresses. This is crude
; but good enough for now.
io_start = $f000
io_size  = $10

; We assume there are no holes in the memory map, that is, 32 KiB of RAM and
; 32 KiB of ROM
rom_start = $8000                       ; $8000 by default
rom_size = io_start - rom_start         ; $f000 - $8000 = $7000 (28 KiB)

; The vectors on the 65c02 are hardcoded to $fffa. Our maximum address size is
; $ffff for the 65c02, this might come in handy for sanity checks later
vectors_start = $fffa
max_address   = $ffff


; ==== SECTION DEFINITIONS ====

; This makes use of the 64Tass section commands, see 
; http://tass64.sourceforge.net/#sections for details. We have the assembler
; check for overflows. You shouldn't have to change anything beyond this point
; unless you are doing something really sneaky. 

; ---- Zero Page
* = zp_start
.dsection zp
.cerror * > (zp_start+zp_size), "Too many Zero Page entries, hit buffers (soft limit)"
.cerror * > $100, "Too many Zero page entries, hit buffers (hard limit)"

; ---- Buffer RAM section
* = buffers_start
.dsection buffers

; ---- General RAM section
; This starts directly after the buffers. The separationen between buffers for
; RAM and for other stuff is somewhat artificial and may be given up later
.dsection ram 
.cerror * > rom_start, "Too much RAM allocated, hit ROM"

; ---- ROM section
* = rom_start
.dsection rom
.cerror * > io_start, "Too much code and data in ROM, hit I/O"

; ---- I/O Addresses 
* = io_start
.dsection io

; ---- Kernel
; The kernel starts directly after the I/O section
.dsection kernel
.cerror * > vectors_start, "Kernel too large, hit interrupt vectors"

; ---- Interrupt vectors
; These are hardcoded for the 65c02, we include them to allow for easier
; porting to other architectures. The check for vectors going beyond the
; maximal address range is paranoid 
* = vectors_start
.dsection vectors
.cerror * >= max_address, "Vectors too large, exceeded address range"


; ==== INCLUDE FILES ====

; We work with includes and section definitions here so we don't have to
; remember to add them in the code itself unless there is a special case

; ---- Code ROM sections ----
.section rom
.include "../cthulhu.asm"               ; main code, contains REPL
.include "../helpers.asm"               ; various general subroutines
.include "../native-procedures.asm"     ; assembler-coded procedures
.include "../procedures.asm"            ; high-level procedures
.send

; ---- Optional debugging routines ----
; These are getting to be quite large, at some point we might run out of ROM
; space to do it this way
.if DEBUG == true
        .section rom
        .include "../debug.asm" 
        .send
.fi

; ---- Data ROM sections ----
.section rom
.include "../definitions.asm"           ; aliases and other definitions
.include "../headers.asm"               ; link list of native procedures
.include "../strings.asm"               ; all text including error strings
.send


; ==== I/O ROUTINES ====

; For the py65mon, all we have to do is skip over the addresses where the
; built-in stuff is located. You might have to change this depending on your
; hardware

.section io
.fill io_size                           ; Save space for the py65mon I/O
.send


; ==== KERNEL ROUTINES ====

.section kernel

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

; All interrupt vectors currently end up in the same place - we restart the system
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

platform_quit:
        ; What to do when it is time to quit. This is part of the platform file
        ; so people can jump back to their own kernel or other system. For
        ; py65mon, we just halt the processor.
                brk

; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot
s_kernel_id:
        .null "Cthulhu Scheme default kernel for py65mon (13. Apr 2020)", Asclf
.send


; ==== INTERRUPT VECTORS ====

; This address cannot be changed for the 65c02

.section vectors
.word v_nmi
.word v_reset
.word v_irq
.send

; ==== END ====
.end
