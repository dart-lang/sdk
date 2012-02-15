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
  printable = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\
!#$%&'()*+,-./:;<=>?@[]^_`{|}~ "
  result = ' '
  lineNumber = 1
  for string_file in input_files:
    if string_file.endswith('dart'):
      fileHandle = open(string_file, 'rb')
      quoted = False
      result += '\n  // ----- ' + string_file + ' -----\n\n'
      for byte in fileHandle.read():
        if not quoted:
          result += '  "'
          quoted = True
        if byte in printable:
          result += byte
        elif byte == '\n':
          if lineNumber % 10 == 0:
            result += '\\n" /* L%d */\n' % lineNumber
          else:
            result += '\\n"\n'
          lineNumber += 1
          quoted = False
        elif byte == '\"':
          result += '\\"'
        else:
          result += '\\x%02x' % ord(byte)
  return result


def makeFile(output_file, input_cc_file, input_files):
  bootstrap_cc_text = open(input_cc_file).read()
  bootstrap_cc_text = bootstrap_cc_text.replace("{{DART_SOURCE}}",
      makeString(input_files))
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

    (options, args) = parser.parse_args()
    if not options.output:
      sys.stderr.write('--output not specified\n')
      return -1
    if not len(options.input_cc):
      sys.stderr.write('--input_cc not specified\n')
      return -1
    if len(args) == 0:
      sys.stderr.write('No input files specified\n')
      return -1

    files = [ ]
    for arg in args:
      files.append(arg)

    if not makeFile(options.output, options.input_cc, files):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('create_string_literal.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  sys.exit(main(sys.argv))
