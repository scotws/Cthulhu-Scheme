#!/usr/bin/python3

"""Cthulhu Test creates a py65 65c02 emulator running Cthulhu Scheme and
feeds it tests, saving the results. This script requires py65 version
1.1.0 or later already be installed (`pip install --upgrade py65`).

RUNNING     : Run cthulhutest.py from the tests directory.

Results will be found in results.txt when finished. This code is based on
the test routines from Tali Forth 2, which is in the public domain.

PROGRAMMERS : Sam Colwell and Scot W. Stevenson
FILE        : cthulhutest.py

First version: 16. May 2018 (talitest.py for Tali Forth 2)
This version: 10. May 2020
"""

import argparse
import ast
import sys
import py65.monitor as monitor
from py65.devices.mpu65c02 import MPU as CMOS65C02
from py65.memory import ObservableMemory

RESULTS = 'results.txt'
CTHULHU_LOCATION = '../cthulhu-py65mon.bin'
CTHULHU_PANIC = 'PANIC:'
CTHULHU_PROMPT = '>'
CTHULHU_QUIT = '\n'                     # can also be "(exit)"
PY65MON_ERROR = '*** Unknown syntax:'
CTHULHU_ERRORS = ['Unbound variable:', 'Ill-formed number:']

# Commands in the test source files
SEPARATOR = ' -> '
INTRO = 'Cthulhu Scheme'
COMMENT_CHAR = ';'
SCHEME_COMMENT = '; '
SECTION_MARKER = 'SECTION'

# Usually we'll be running these tests with the debugger off. But just to be
# sure, we want to strip all the messages out that it sends
CTHULHU_DEBUG_MSG = ['Input Buffer:', 'Token Buffer:', 'AST: ', 'Heap pointer:']

# Add name of file with test to the set of TEST_FILES without the extension to
# add further tests
TEST_FILES = ['booleans', 'fixnums', 'mixes', 'procedures', 'strings']
EXTENSION = '.tst'
TESTLIST = ' '.join(["'"+str(t)+"' " for t in TEST_FILES])

# The dictionary of expected vs. received entries is created during the loading
# of the tests
sent_want = {}

OUTPUT_HELP = 'Output File, default "'+RESULTS+'"'
TESTS_HELP = "Available tests: 'all' or one or more of "+TESTLIST

parser = argparse.ArgumentParser()
parser.add_argument('-b', '--beep', action='store_true',
                    help='Make a sound at end of testing', default=False)
parser.add_argument('-m', '--mute', action='store_true',
                    help='Only print errors and summary', default=False)
parser.add_argument('-o', '--output', dest='output',
                    help=OUTPUT_HELP, default=RESULTS)
parser.add_argument('-s', '--suppress_tester', action='store_true',
                    help='Suppress the output while the tester is loading', default=False)
parser.add_argument('-t', '--tests', nargs='+', type=str, default=['all'],
                    help=TESTS_HELP)
parser.add_argument('-v', '--verbose', action='store_true',
                    help='Print extra information', default=False)
args = parser.parse_args()

# Make sure we were given a legal list of tests: Must be either 'all' or one or
# more of the legal tests
if (args.tests != ['all']) and (not set(args.tests).issubset(TEST_FILES)):
    print('ERROR: Illegal test. Aborting.')
    sys.exit(1)

if args.tests == ['all']:
    args.tests = list(TEST_FILES)


#### SETUP ####

# Create a string with all of the tests we will be running in it.
test_string = ""
test_index = -1

# Load all of the tests selected from the command line.
for test in args.tests:

    # Determine the test file name.
    testfile = test + EXTENSION

    with open(testfile, 'r') as infile:

        for line in infile:

            # Skip comments and whitespace
            if line.startswith(COMMENT_CHAR):
                continue
            if line.strip() == '': 
                continue

            # For now, skip section markers
            if line.startswith(SECTION_MARKER):
                continue

            # Add anything else as a normal test, including section markers
            raw_sent, raw_want = line.strip().split(SEPARATOR, 1)
            sent = str(ast.literal_eval(raw_sent))
            want = str(ast.literal_eval(raw_want))

            # We fill up the sent_want dictionary here
            sent_want[sent] = want

            # Add the actual test
            test_string = test_string + sent + '\n'
            
# Have Cthulhu Scheme quit at the end of all the tests.
test_string = test_string + CTHULHU_QUIT

print(sent_want)

#### TESTING ####

# Log the results
with open(args.output, 'wb') as fout:

    # Create a py65 monitor object loaded with Cthulhu Scheme
    class CthulhuMachine(monitor.Monitor):
        """Emulator for running Cthulhu Scheme test suite"""

        def __init__(self):
            # Use the 65C02 as the CPU type.
            # Don't pass along any of the command line arguments.
            # Don't use the built-in I/O.
            super().__init__(mpu_type=CMOS65C02,
                             argv="",
                             putc_addr=None,
                             getc_addr=None)
            # Load our I/O routines that take the tests from a string
            # and log the results to a file, echoing if not muted.
            self._install_io()
            # Load the Cthulhu Scheme binary
            self.onecmd("load " + CTHULHU_LOCATION + " 8000")

        def _install_io(self):

            def getc_from_test(_):
                """Parameter (originally "address") required by py65mon
                but unused here as "_"
                """
                global test_string, test_index
                test_index = test_index + 1

                if test_index < len(test_string):
                    result = ord(test_string[test_index])
                else:
                    result = 0

                return result

            def putc_results(_, value):
                """First parameter (originally "address") required
                by py65mon but unused here as "_"
                """
                global fout

                # Save results to file.
                if value != 0:
                    if not args.suppress_tester or \
                       test_index > end_of_tester:
                        fout.write(chr(value).encode())

                # Print to the screen if we are not muted.
                if not args.mute:
                    if not args.suppress_tester or \
                       test_index > end_of_tester:
                        sys.stdout.write(chr(value))
                        sys.stdout.flush()

            # Install the above handlers for I/O
            mem = ObservableMemory(subject=self.memory)
            mem.subscribe_to_write([0xF001], putc_results)
            mem.subscribe_to_read([0xF004], getc_from_test)
            self._mpu.memory = mem

    # Invoke Cthulhu
    cthulhu = CthulhuMachine()
    # Reset vector is $f006.
    cthulhu._mpu.pc = 0xf006
    # Run until break detected.
    cthulhu._run([0x00])


#### DIAGNOSIS ####

# Walk through results and find stuff that went wrong
print()
print('='*80)
print('Summary for: ' + ' '.join(args.tests))

# Check to see if we crashed before reading all of the tests.
if test_index < len(test_string) - 2:
    print("Cthulhu Scheme crashed before all tests completed\n")
else:
    print("Cthulhu Scheme ran all tests requested")

print()

# First, panics because they are so severe 
panics = []

with open(args.output, 'r') as rfile:

    for line in rfile:
        if CTHULHU_PANIC in line:
            panics.append(line)

# We shouldn't have any undefined words at all
if panics:

    for line in panics:
        print(line.strip())


# Second, stuff that failed the actual test
failed = []

with open(args.output, 'r') as rfile:

    for line in rfile:
        for error_str in CTHULHU_ERRORS:
            if error_str in line:
                failed.append(line)

if failed:
    for line in failed:
        print(line.strip())


# Walk through the lines and see what we got for which input

error_count = 0 

with open(args.output, 'r') as rfile:

    got = ''
    recording_result = False

    for line in rfile:

        # Skip the intro
        if line.startswith(INTRO):
            continue

        if line.startswith(CTHULHU_PROMPT):     # '>' by default

            # Crude way of skipping the first iteration when there is no 'got'
            # yet to be had
            if recording_result:

                if args.verbose:
                    print(raw_sent, ':', repr(raw_want), ':', repr(got))

                if raw_want != got:
                    error_count += 1
                    print('ERROR: Sent:', repr(raw_sent), 'Wanted:', repr(raw_want),\
                            'Got:', repr(got))

            line = line[2:]
            raw_sent = line.strip()
            recording_result = True

            if raw_sent == '':
                continue

            raw_want = sent_want[raw_sent]
            got = ''

        else:
            got = got + line


# Sum it all up.
print()

if (not panics) and (not failed) and (error_count == 0):
    print('All available tests passed')
else:
    print('Found', error_count, 'errors')

# If we got here, the program itself ran fine one way or another
if args.beep:
    print('\a')

sys.exit(0)
