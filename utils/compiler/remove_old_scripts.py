#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

'''
Tool for deleting files given on the command line, and touching a
file on success.

Usage:
  python tools/list_files.py FILE_TO_TOUCH FILES_TO_DELETE...
'''

import os
import sys


def main(argv):
  file_to_touch = argv[1]
  for filename in argv[2:]:
    if os.path.exists(filename):
      os.remove(filename)
  with file(file_to_touch, 'a'):
    os.utime(file_to_touch, None)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
