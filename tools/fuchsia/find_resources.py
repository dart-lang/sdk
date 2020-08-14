#!/usr/bin/env python
#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# Finds files in the given directories and their subdirectories, and prints them
# in the json format expected by GN fuchsia_component's resources arg:
# [
#   {
#     "path": "path/to/file.dart",
#     "dest": "data/path/to/file.dart"
#   },
#   ...
# ]

import sys
import os

from os.path import join, abspath, relpath

DART_DIR = abspath(join(__file__, '..', '..', '..'))


def listFiles(path):
  allFiles = []
  for dirpath, dirs, files in os.walk(join(DART_DIR, path)):
    allFiles += [relpath(abspath(join(dirpath, p)), DART_DIR) for p in files]
  return allFiles


def printOutput(files):
  print('[')
  print(',\n'.join([
    '  {\n    "path": "%s",\n    "dest": "data/%s"\n  }' % (f, f) for f in files
  ]))
  print(']')


def main():
  if len(sys.argv) < 2:
    print('Expected at least 1 arg, the paths to search.')
    return 1
  allFiles = []
  for directory in sys.argv[1:]:
    files = listFiles(directory)
    if len(files) == 0:
      print('Did not find any files in the directory: ' + directory)
      return 2
    allFiles += files
  printOutput(sorted(allFiles))
  return 0


if __name__ == '__main__':
  sys.exit(main())
