#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to convert snapshot files to a C++ file which can be compiled and
# linked together with VM binary.

import getopt
import optparse
import string
import subprocess
import sys
import utils

HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()


def BuildOptions():
    result = optparse.OptionParser()
    result.add_option(
        "--vm_input_bin",
        action="store",
        type="string",
        help="input file name of the vm isolate snapshot in binary form")
    result.add_option(
        "--input_bin",
        action="store",
        type="string",
        help="input file name of the isolate snapshot in binary form")
    result.add_option(
        "--input_cc",
        action="store",
        type="string",
        help="input file name which contains the C buffer template")
    result.add_option(
        "--output",
        action="store",
        type="string",
        help="output file name into which snapshot in C buffer form is generated"
    )
    result.add_option(
        "-v",
        "--verbose",
        help='Verbose output.',
        default=False,
        action="store_true")
    return result


def ProcessOptions(options):
    if not options.vm_input_bin:
        sys.stderr.write('--vm_input_bin not specified\n')
        return False
    if not options.input_bin:
        sys.stderr.write('--input_bin not specified\n')
        return False
    if not options.input_cc:
        sys.stderr.write('--input_cc not specified\n')
        return False
    if not options.output:
        sys.stderr.write('--output not specified\n')
        return False
    return True


def WriteBytesAsText(out, input_file):
    """Writes byte contents of the input_file into out file as text.

  Output is formatted as a list of comma separated integer values - one value
  for each byte.
  """
    with open(input_file, 'rb') as input:
        lineCounter = 0
        line = ' '
        for byte in input.read():
            line += ' %d,' % ord(byte)
            lineCounter += 1
            if lineCounter == 10:
                out.write(line + '\n')
                line = ' '
                lineCounter = 0
        if lineCounter != 0:
            out.write(line + '\n')


def GenerateFileFromTemplate(output_file, input_cc_file, vm_isolate_input_file,
                             isolate_input_file):
    """Generates C++ file based on a input_cc_file template and two binary files

  Template is expected to have two %s placehoders which would be filled
  with binary contents of the given files each formatted as a comma separated
  list of integers.
  """
    snapshot_cc_text = open(input_cc_file).read()
    chunks = snapshot_cc_text.split("%s")
    if len(chunks) != 3:
        raise Exception("Template %s should contain exactly two %%s occurrences"
                        % input_cc_file)

    with open(output_file, 'w') as out:
        out.write(chunks[0])
        WriteBytesAsText(out, vm_isolate_input_file)
        out.write(chunks[1])
        WriteBytesAsText(out, isolate_input_file)
        out.write(chunks[2])


def Main():
    # Parse options.
    parser = BuildOptions()
    (options, args) = parser.parse_args()
    if not ProcessOptions(options):
        parser.print_help()
        return 1

    # If there are additional arguments, report error and exit.
    if args:
        parser.print_help()
        return 1

    GenerateFileFromTemplate(options.output, options.input_cc,
                             options.vm_input_bin, options.input_bin)

    return 0


if __name__ == '__main__':
    sys.exit(Main())
