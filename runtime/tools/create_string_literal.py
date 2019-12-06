#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a string literal in a C++ source file from a C++
# source template and text file.

import os
import sys
from os.path import join
import time
from optparse import OptionParser


def makeString(input_files):
    result = ' '
    for string_file in input_files:
        if string_file.endswith('dart'):
            fileHandle = open(string_file, 'rb')
            lineCounter = 0
            result += ' // ' + string_file + '\n   '
            for byte in fileHandle.read():
                result += ' %d,' % ord(byte)
                lineCounter += 1
                if lineCounter == 10:
                    result += '\n   '
                    lineCounter = 0
            if lineCounter != 0:
                result += '\n   '
    result += ' // Terminating null character.\n    0'
    return result


def makeFile(output_file, input_cc_file, include, var_name, input_files):
    bootstrap_cc_text = open(input_cc_file).read()
    bootstrap_cc_text = bootstrap_cc_text.replace("{{INCLUDE}}", include)
    bootstrap_cc_text = bootstrap_cc_text.replace("{{VAR_NAME}}", var_name)
    bootstrap_cc_text = bootstrap_cc_text.replace("{{DART_SOURCE}}",
                                                  makeString(input_files))
    open(output_file, 'w').write(bootstrap_cc_text)
    return True


def main(args):
    try:
        # Parse input.
        parser = OptionParser()
        parser.add_option(
            "--output", action="store", type="string", help="output file name")
        parser.add_option(
            "--input_cc",
            action="store",
            type="string",
            help="input template file")
        parser.add_option(
            "--include", action="store", type="string", help="variable name")
        parser.add_option(
            "--var_name", action="store", type="string", help="variable name")

        (options, args) = parser.parse_args()
        if not options.output:
            sys.stderr.write('--output not specified\n')
            return -1
        if not len(options.input_cc):
            sys.stderr.write('--input_cc not specified\n')
            return -1
        if not len(options.include):
            sys.stderr.write('--include not specified\n')
            return -1
        if not len(options.var_name):
            sys.stderr.write('--var_name not specified\n')
            return -1
        if len(args) == 0:
            sys.stderr.write('No input files specified\n')
            return -1

        files = []
        for arg in args:
            files.append(arg)

        if not makeFile(options.output, options.input_cc, options.include,
                        options.var_name, files):
            return -1

        return 0
    except Exception as inst:
        sys.stderr.write('create_string_literal.py exception\n')
        sys.stderr.write(str(inst))
        sys.stderr.write('\n')
        return -1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
