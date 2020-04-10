# Makefile for Tali Forth 2's diagrams (uses ditaa to compile)
# Original version: 16. Dec 2018 (Tali Forth 2)
# This version: 10. April 2020

# This makefile is called from the main project Makefile.

# Add any diagram images to this space separated list.
DIAGRAM_IMAGES=ast_node.png memory_map.png

all:	$(DIAGRAM_IMAGES)

# Create a .png file for each .txt file in this directory.
%.png:	%.txt
	ditaa -o $<

