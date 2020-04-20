#!/usr/bin/env python
#
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Generates an assembly source file the defines a symbol with the bytes from
# a given file.

import os
import sys
from optparse import OptionParser


def Main():
    parser = OptionParser()
    parser.add_option(
        "--output",
        action="store",
        type="string",
        help="output assembly file name")
    parser.add_option(
        "--input", action="store", type="string", help="input binary blob file")
    parser.add_option("--symbol_name", action="store", type="string")
    parser.add_option("--executable", action="store_true", default=False)
    parser.add_option("--target_os", action="store", type="string")
    parser.add_option("--size_symbol_name", action="store", type="string")
    parser.add_option("--target_arch", action="store", type="string")

    (options, args) = parser.parse_args()
    if not options.output:
        sys.stderr.write("--output not specified\n")
        parser.print_help()
        return -1
    if not options.input:
        sys.stderr.write("--input not specified\n")
        parser.print_help()
        return -1
    if not os.path.isfile(options.input):
        sys.stderr.write("input file does not exist: %s\n" % options.input)
        parser.print_help()
        return -1
    if not options.symbol_name:
        sys.stderr.write("--symbol_name not specified\n")
        parser.print_help()
        return -1
    if not options.target_os:
        sys.stderr.write("--target_os not specified\n")
        parser.print_help()
        return -1

    with open(options.output, "w") as output_file:
        if options.target_os in ["mac", "ios"]:
            if options.executable:
                output_file.write(".text\n")
            else:
                output_file.write(".const\n")
            output_file.write(".global _%s\n" % options.symbol_name)
            output_file.write(".balign 32\n")
            output_file.write("_%s:\n" % options.symbol_name)
        elif options.target_os in ["win"]:
            output_file.write("ifndef _ML64_X64\n")
            output_file.write(".model flat, C\n")
            output_file.write("endif\n")
            if options.executable:
                output_file.write(".code\n")
            else:
                output_file.write(".const\n")
            output_file.write("public %s\n" % options.symbol_name)
            output_file.write("%s label byte\n" % options.symbol_name)
        else:
            if options.executable:
                output_file.write(".text\n")
                output_file.write(".type %s STT_FUNC\n" % options.symbol_name)
            else:
                output_file.write(".section .rodata\n")
                output_file.write(".type %s STT_OBJECT\n" % options.symbol_name)
            output_file.write(".global %s\n" % options.symbol_name)
            output_file.write(".balign 32\n")
            output_file.write("%s:\n" % options.symbol_name)

        size = 0
        with open(options.input, "rb") as input_file:
            if options.target_os in ["win"]:
                for byte in input_file.read():
                    output_file.write("byte %d\n" % (byte if isinstance(byte, int) else ord(byte)))
                    size += 1
            else:
                for byte in input_file.read():
                    output_file.write(".byte %d\n" % (byte if isinstance(byte, int) else ord(byte)))
                    size += 1

        if options.target_os not in ["mac", "ios", "win"]:
            output_file.write(".size {0}, .-{0}\n".format(options.symbol_name))

        if options.size_symbol_name:
            if not options.target_arch:
                sys.stderr.write("--target_arch not specified\n")
                parser.print_help()
                return -1

            is64bit = 0
            if options.target_arch:
                if options.target_arch in ["arm64", "x64"]:
                    is64bit = 1

            if options.target_os in ["win"]:
                output_file.write("public %s\n" % options.size_symbol_name)
                output_file.write("%s label byte\n" % options.size_symbol_name)
                if (is64bit == 1):
                    output_file.write("qword %d\n" % size)
                else:
                    output_file.write("dword %d\n" % size)
            else:
                if options.target_os in ["mac", "ios"]:
                    output_file.write(
                        ".global _%s\n" % options.size_symbol_name)
                    output_file.write("_%s:\n" % options.size_symbol_name)
                else:
                    output_file.write(".global %s\n" % options.size_symbol_name)
                    output_file.write("%s:\n" % options.size_symbol_name)
                if (is64bit == 1):
                    output_file.write(".quad %d\n" % size)
                else:
                    output_file.write(".long %d\n" % size)

        if options.target_os in ["win"]:
            output_file.write("end\n")

    return 0


if __name__ == "__main__":
    sys.exit(Main())
