#!/usr/bin/env python
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import datetime
import sys

def Main():
  (_, input_file_name, output_file_name) = sys.argv
  if not input_file_name or not output_file_name:
    raise Exception('Missing argument')

  timestamp = str(datetime.datetime.now())

  with open(input_file_name, 'r') as input_file:
    with open(output_file_name, 'w') as output_file:
      output_file.write(input_file.read().replace('@@TIMESTAMP@@', timestamp))


if __name__ == '__main__':
  sys.exit(Main())
