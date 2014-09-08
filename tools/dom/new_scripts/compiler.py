#!/usr/bin/python
# Copyright (C) 2014 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Compile an .idl file to Dart bindings (.h and .cpp files).

Design doc: ??????
"""

from optparse import OptionParser
import os
import sys

dart_script_path = os.path.dirname(os.path.abspath(__file__))
script_path = os.path.join(os.path.dirname(os.path.dirname(dart_script_path)),
                          'scripts')
sys.path.extend([script_path])

from dart_compiler import IdlCompiler
from code_generator_dart import CodeGeneratorDart


def parse_options():
    parser = OptionParser()
    parser.add_option('--output-directory')
    parser.add_option('--interfaces-info-file')
    parser.add_option('--write-file-only-if-changed', type='int', default='1')
    parser.add_option('--generate-global', type='int')

    # ensure output comes last, so command line easy to parse via regexes
    parser.disable_interspersed_args()

    options, args = parser.parse_args()
    if options.output_directory is None:
        parser.error('Must specify output directory using --output-directory.')
    options.write_file_only_if_changed = bool(options.write_file_only_if_changed)
    options.generate_global = bool(options.generate_global)
    if len(args) != 1:
        # parser.error('Must specify exactly 1 input file as argument, but %d given.' % len(args))
        return options, None
    idl_filename = os.path.realpath(args[0])
    return options, idl_filename


def idl_filename_to_interface_name(idl_filename):
    basename = os.path.basename(idl_filename)
    interface_name, _ = os.path.splitext(basename)
    return interface_name


class IdlCompilerDart(IdlCompiler):
    def __init__(self, *args, **kwargs):
        IdlCompiler.__init__(self, *args, **kwargs)

        interfaces_info = self.interfaces_info
        self.output_directory = self.output_directory

        self.code_generator = CodeGeneratorDart(interfaces_info, self.output_directory)

    def compile_file(self, idl_filename):
        interface_name = idl_filename_to_interface_name(idl_filename)
        header_filename = os.path.join(self.output_directory,
                                       'Dart%s.h' % interface_name)
        cpp_filename = os.path.join(self.output_directory,
                                    'Dart%s.cpp' % interface_name)
        return self.compile_and_write(idl_filename, (header_filename, cpp_filename))

    def generate_global(self):
        global_header_filename = os.path.join(self.output_directory, 'DartWebkitClassIds.h')
        global_cpp_filename = os.path.join(self.output_directory, 'DartWebkitClassIds.cpp')
        self.generate_global_and_write((global_header_filename, global_cpp_filename))


def main():
    options, idl_filename = parse_options()

    if options.generate_global:
        idl_compiler = IdlCompilerDart(options.output_directory,
                                       interfaces_info_filename=options.interfaces_info_file,
                                       only_if_changed=options.write_file_only_if_changed)
        idl_compiler.generate_global()
    else:
        idl_compiler = IdlCompilerDart(options.output_directory,
                                       interfaces_info_filename=options.interfaces_info_file,
                                       only_if_changed=options.write_file_only_if_changed)
        idl_compiler.compile_file(idl_filename)


if __name__ == '__main__':
    sys.exit(main())
