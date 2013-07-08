#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

'''Tool for listing the directories under pkg, with their lib directories.
Used in pkg.gyp. Lists all of the directories in the directory passed in as an
argument to this script which have a lib subdirectory.

Usage:
  python tools/list_pkg_directories.py directory_to_list
'''

import os
import sys

def main(argv):
  directory = argv[1]
  paths = map(lambda x: x + '/lib', filter(lambda x: os.path.isdir(
      os.path.join(directory, x)), os.listdir(directory)))
  for lib in filter(lambda x: os.path.exists(os.path.join(directory, x)),
      paths):
    print '%s/%s' % (directory, lib)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
