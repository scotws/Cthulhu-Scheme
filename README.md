Cthulhu Scheme for the 65c02   
Scot W. Stevenson <scot.stevenson@gmail.com>   
First version: 28. Mar 2020  
This version: 13. Apr 2020  

## Dude, I am a Scheme god, all parens tremble before me. Just tell me how to start!

Run `py65mon -m 65c02 -r cthulhu-py65mon.bin` from this directory.


## Introduction

Cthulhu Scheme is a very, _very_ primitive version of a bare-metal Scheme-like
language for the 65c02 8-bit MPU. The aim is to see how far you can go with the
limited hardware available. It is free -- released in the public domain -- but
with absolutely _no warranty_ of any kind.  Use at your own risk! (See
`COPYING.txt` for details.) 


## More detail please

At the moment this is pre-alpha software, which means that it will assemble and
probably even run on a good day, but won't do anything useful yet. Part of this
is because I am using this project to get familiar with the 64tass assembler
(see http://tass64.sourceforge.net/#conditional-assembly) so there are a lot of
moving parts at the moment. Honestly, you might want to come back in a few
months. 

Note that the testing suite is still very primitive - all it does is run a bunch
of commands, and if it doesn't crash, all is well. This will be updated once we
get more commands going.


## Even more detail pretty please 

See `docs\manual.html` for the Cthulhu Scheme manual, which at some point will
cover the installation, setup, tutorials, and internal structure. Once this
project actually has something to write home about, I'll be announcing it
formally on 6502.org.
