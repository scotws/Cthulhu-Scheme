# Makefile for Cthulhu Scheme
# First version: 30. Mar 2020
# This version: 06. Apr 2020

# This is based on the Makefile for Tali Forth 2, which was originally written
# by Sam Colwell

# The manual is not automatically updated because not everybody can be expected
# to have the asciidoc toolchain and ditaa installed. Cthulhu requires python 3.x,
# Ophis, and GNU make to build the 65c02 binary image.

# Example uses ($ is the prompt - yours might be C:\>):
#
# - Build cthulhu-py65mon.bin for use with the py65mon simulator.
#   The py65mon version is the default.
#   $ make

# - Build Cthulhu Scheme for a different platform (Steckschwein shown here).
#   There must be a matching platform file in the platform folder.
#   $ make cthulhu-steckschwein.bin

# Determine which python launcher to use (python3 on Linux and OSX,
# "py -3" on Windows) and other OS-specific commands (rm vs del).
ifdef OS
	RM = del
	PYTHON = py -3
else
	RM = rm -f
	PYTHON = python3
endif

COMMON_SOURCES=definitions.asm cthulhu.asm native-procedures.asm helpers.asm procedures.asm strings.asm debug.asm lexer.asm parser.asm eval.asm printer.asm
# TEST_SOURCES=tests/core_a.fs tests/core_b.fs tests/core_c.fs tests/string.fs tests/double.fs tests/facility.fs tests/tali.fs tests/tools.fs tests/block.fs tests/user.fs tests/cycles.fs tests/talitest.py tests/ed.fs tests/search.fs tests/asm.fs

all:	cthulhu-py65mon.bin
clean:
	$(RM) *.bin *.prg

cthulhu-%.bin: platforms/platform-%.asm $(COMMON_SOURCES)
	64tass --nostart \
	--list=docs/$*-listing.txt \
	--labels=docs/$*-labelmap.txt \
	--output $@ \
	$<

cthulhu-%.prg: platforms/platform-%.asm $(COMMON_SOURCES)
	ophis -l docs/$*-listing.txt \
	-m docs/$*-labelmap.txt \
	-o $@ \
	-c $<

# Some convenience targets to make running the tests and simulation easier.

# Convenience target to run the py65mon simulator.
# Because cthulhu-py65mon.bin is listed as a dependency, it will be
# reassembled first if any changes to its sources have been made.
sim:	cthulhu-py65mon.bin
	py65mon -m 65c02 -r cthulhu-py65mon.bin

# Some convenience targets for the documentation.
docs/manual.html: docs/*.adoc
	cd docs && asciidoctor -a toc=left manual.adoc

docs/ch_glossary.adoc:	native_words.asm
	$(PYTHON) tools/generate_glossary.py > docs/ch_glossary.adoc

# The diagrams use ditaa to generate pretty diagrams from text files.
# They have their own makefile in the docs/pics directory.
docs-diagrams: docs/pics/*.txt
	cd docs/pics && $(MAKE)

docs: docs/manual.html # docs-diagrams
