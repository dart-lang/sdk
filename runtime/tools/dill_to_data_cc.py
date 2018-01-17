#!/usr/bin/env python
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script to create a cc file with uint8 array of bytes corresponding to the
# content of given a dill file.

import optparse
import sys

# Option => Help mapping.
OPTION_MAP = {
  'dill_file': 'Path to the input dill file.',
  'data_symbol': 'The C name for the data array.',
  'size_symbol': 'The C name for the data size variable.',
  'output': 'Path to the generated cc file.',
}


def BuildOptionParser():
  parser = optparse.OptionParser()
  for opt, help_text in OPTION_MAP.iteritems():
    parser.add_option('--%s' % opt, type='string', help=help_text)
  return parser


def ValidateOptions(options):
  for opt in OPTION_MAP.keys():
    if getattr(options, opt) is None:
      sys.stderr.write('--%s option not specified.\n' % opt)
      return False
  return True


def WriteData(input_filename, data_symbol, output_file):
  output_file.write('uint8_t %s[] = {\n' % data_symbol)
  with open(input_filename, 'rb') as f:
    first = True
    size = 0
    for byte in f.read():
      if first:
        output_file.write('  %d' % ord(byte))
        first = False
      else:
        output_file.write(',\n  %d' % ord(byte))
      size += 1
  output_file.write('\n};\n')
  return size


def WriteSize(size_symbol, size, output_file):
  output_file.write('intptr_t %s = %d;\n' % (size_symbol, size))


def Main():
  opt_parser = BuildOptionParser()
  (options, args) = opt_parser.parse_args()
  if not ValidateOptions(options):
    opt_parser.print_help()
    return 1
  if args:
    sys.stderr.write('Unknown args: "%s"\n' % str(args))
    parser.print_help()
    return 1

  with open(options.output, 'w') as output_file:
    output_file.write('#include <stdint.h>\n')
    output_file.write('extern "C" {\n')
    size = WriteData(options.dill_file, options.data_symbol, output_file)
    WriteSize(options.size_symbol, size, output_file)
    output_file.write("}")


if __name__ == '__main__':
  sys.exit(Main())
