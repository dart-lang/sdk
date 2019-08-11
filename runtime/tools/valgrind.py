#!/usr/bin/python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Simple wrapper for running Valgrind and checking the output on
# stderr for memory leaks.

import subprocess
import sys
import re

VALGRIND_ARGUMENTS = [
    'valgrind',
    '--error-exitcode=1',
    '--leak-check=full',
    '--trace-children=yes',
    '--ignore-ranges=0x000-0xFFF',  # Used for implicit null checks.
    '--vex-iropt-level=1'  # Valgrind crashes with the default level (2).
]

# Compute the command line.
command = VALGRIND_ARGUMENTS + sys.argv[1:]

# Run Valgrind.
process = subprocess.Popen(
    command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
code = process.wait()
output = process.stdout.readlines()
errors = process.stderr.readlines()

# Always print the output, but leave out the 3 line banner printed
# by certain versions of Valgrind.
if len(output) > 0 and output[0].startswith("** VALGRIND_ROOT="):
    output = output[3:]
sys.stdout.writelines(output)

# If Valgrind produced an error, we report that to the user.
if code != 0:
    sys.stderr.writelines(errors)
    sys.exit(code)

# Look through the leak details and make sure that we don't have
# any definitely or indirectly lost bytes. We allow possibly lost
# bytes to lower the risk of false positives.
LEAK_RE = r"(?:definitely|indirectly) lost:"
LEAK_LINE_MATCHER = re.compile(LEAK_RE)
LEAK_OKAY_MATCHER = re.compile(r"lost: 0 bytes in 0 blocks")
leaks = []
for line in errors:
    if LEAK_LINE_MATCHER.search(line):
        leaks.append(line)
        if not LEAK_OKAY_MATCHER.search(line):
            sys.stderr.writelines(errors)
            sys.exit(1)

# Make sure we found the right number of leak lines.
if not len(leaks) in [0, 2, 3]:
    sys.stderr.writelines(errors)
    sys.stderr.write('\n\n#### Malformed Valgrind output.\n#### Exiting.\n')
    sys.exit(1)

# Success.
sys.exit(0)
