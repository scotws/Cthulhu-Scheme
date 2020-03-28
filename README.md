Cthulhu Scheme for the 65c02  
Scot W. Stevenson <scot.stevenson@gmail.com>   
First version: 28. Mar 2020
This version: 28. Mar 2020

## Dude, I am a Scheme god, all bow down before me. Just tell me how to start!

Run `py65mon -m 65c02 -r cthulhu-py65mon.bin` from this directory.


## Introduction

Cthulhu Scheme is a very primitive version of a bare-metal Scheme-like language
for the 65c02 8-bit MPU. The aim is to see how far you can go with the limited
hardware available. It is free -- released in the public domain -- but with
absolutely _no warranty_ of any kind.  Use at your own risk! (See `COPYING.txt`
for details.) Cthulhu Scheme is hosted at GitHub. You can find the most current
version at [FEHLT](FEHLT).


## More detail please

HIER HIER 


Tali Forth 2 aims to be, roughly in order of priority: 

- **Easy to try.** Download the source -- or even just the binary
  `taliforth-py65mon.bin` -- and run the emulator with `py65mon -m 65c02 -r
  taliforth-py65mon.bin` to get it running. This lets you experiment with a
  working 8-bit Forth for the 65c02 without any special configuration. This
  includes things like block wordset.

- **Simple**. The simple subroutine-threaded (STC) design and excessively
  commented source code give hobbyists the chance to study a working Forth at
  the lowest level. Separate documentation - including a manual with more than
  100 pages - in the `docs` folder discusses specific topics and offers
  tutorials. The aim is to make it easy to port Tali Forth 2 to various 65c02
  hardware projects. 

- **Specific**. Many Forths available are "general" implementations with a small
  core adapted to the target processor. Tali Forth 2 was written as a "bare
  metal Forth" for the 65c02 8-bit MPU and that MPU only, with its strengths and
  limitations in mind. 

- **Standardized**. Most Forths available for the 65c02 are based on ancient,
  outdated templates such as FIG Forth. Learning Forth with them is like trying
  to learn modern English by reading Chaucer. Tali Forth (mostly) follows the
  current ANS Standard, and ensures this passing an enhanced test suite.
  
The functional reference for Cthulhu Scheme is [MIT/GNU
Scheme](https://www.gnu.org/software/mit-scheme/). Programs written for MIT/GNU
Scheme should run on Cthulhu Scheme or have a very good, well documented reason
not to. 


## Seriously super lots more detail 

See `docs\manual.html` for the Cthulhu Scheme manual, which covers the
installation, setup, tutorials, and internal structure. The central discussion
forum is [FEHLT](FEHLT) at 6502.org.
