#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

'''Tool for listing the directories under pkg, with their lib directories.
Used in pkg.gyp. Lists all of the directories in the current directory
which have a lib subdirectory.

Usage:
  python tools/list_pkg_directories.py
'''

import os
import sys

def main(argv):
  paths = map(lambda x: x + '/lib', filter(os.path.isdir, os.listdir(argv[1])))
  for lib in filter(lambda x: os.path.exists(x), paths):
    print lib

if __name__ == '__main__':
  sys.exit(main(sys.argv))
