#!/usr/bin/env python
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

from optparse import OptionParser

def writePatch(output_file_name, input_file_names):
  dart_file_names = filter(lambda name: name.endswith('.dart'),
                           input_file_names)
  with open(output_file_name, 'w') as output_file:
    for dart_file_name in dart_file_names:
      with open(dart_file_name, 'r') as dart_file:
        output_file.write(dart_file.read())


def main():
  parser = OptionParser()
  parser.add_option('--output', action='store', type='string',
                    help='output file path')
  (options, args) = parser.parse_args()
  if not options.output:
    parser.error('missing --output option\n')
  if len(args) == 0:
    parser.error('no input files given\n')
  writePatch(options.output, args)


if __name__ == '__main__':
  main()
