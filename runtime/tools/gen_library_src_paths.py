#!/usr/bin/env python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a source path mapping in a C++ source file from
# a C++ source template and list of dart library files.

import os
import sys
import utils

from os.path import join
from optparse import OptionParser

HOST_OS = utils.GuessOS()


def makeString(input_file, var_name):
  result = 'static const char ' + var_name + '[] = {\n '
  fileHandle = open(input_file, 'rb')
  lineCounter = 0
  for byte in fileHandle.read():
    result += '\'\\x%02x' % ord(byte) + '\', '
    lineCounter += 1
    if lineCounter == 19:
      result += '\n '
      lineCounter = 0
  result += '0};\n'
  return result

def makeSourceArrays(in_files):
  result = '';
  file_count = 0;
  for string_file in in_files:
    if string_file.endswith('.dart'):
      file_count += 1
      file_string = makeString(string_file, "source_array_" + str(file_count))
      result += file_string
  return result

def makeFile(output_file, input_cc_file, include, var_name, lib_name, in_files):
  part_index = [ ]
  bootstrap_cc_text = open(input_cc_file).read()
  bootstrap_cc_text = bootstrap_cc_text.replace("{{SOURCE_ARRAYS}}", makeSourceArrays(in_files))
  bootstrap_cc_text = bootstrap_cc_text.replace("{{INCLUDE}}", include)
  bootstrap_cc_text = bootstrap_cc_text.replace("{{VAR_NAME}}", var_name)
  main_file_found = False
  file_count = 0
  for string_file in in_files:
    if string_file.endswith('.dart'):
      file_count += 1
      if (not main_file_found):
        inpt = open(string_file, 'r')
        for line in inpt:
          # File with library tag is the main file.
          if line.startswith('library '):
            main_file_found = True
            bootstrap_cc_text = bootstrap_cc_text.replace(
                 "{{LIBRARY_SOURCE_MAP}}",
                 ' "' + lib_name + '",\n' +
                 ' source_array_' + str(file_count) + ',\n')
        inpt.close()
        if (main_file_found):
          continue
      part_index.append(' "' +
          lib_name + "/" + os.path.basename(string_file).replace('\\', '\\\\') + '",\n')
      part_index.append(' source_array_' + str(file_count) + ',\n\n')
  bootstrap_cc_text = bootstrap_cc_text.replace("{{LIBRARY_SOURCE_MAP}}", '')
  bootstrap_cc_text = bootstrap_cc_text.replace("{{PART_SOURCE_MAP}}",
                                                ''.join(part_index))
  open(output_file, 'w').write(bootstrap_cc_text)
  return True

def main(args):
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--output",
                      action="store", type="string",
                      help="output file name")
    parser.add_option("--input_cc",
                      action="store", type="string",
                      help="input template file")
    parser.add_option("--include",
                      action="store", type="string",
                      help="variable name")
    parser.add_option("--library_name",
                      action="store", type="string",
                      help="library name")
    parser.add_option("--var_name",
                      action="store", type="string",
                      help="variable name")

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
    if not len(options.library_name):
      sys.stderr.write('--library_name not specified\n')
      return -1
    if len(args) == 0:
      sys.stderr.write('No input files specified\n')
      return -1

    files = [ ]
    for arg in args:
      files.append(arg)

    if not makeFile(options.output,
                    options.input_cc,
                    options.include,
                    options.var_name,
                    options.library_name,
                    files):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('gen_library_src_paths.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  sys.exit(main(sys.argv))
