#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tool for listing the directories under pkg, with their lib directories.
Used in pkg.gyp. Lists all of the directories in the directory passed in as an
argument to this script which have a lib subdirectory.

Usage:
  python tools/list_pkg_directories.py OPTIONS DIRECTORY
"""

import optparse
import os
import sys

def get_options():
  result = optparse.OptionParser()
  result.add_option("--exclude",
      help='A comma-separated list of directory names to exclude.')
  return result.parse_args()

def main(argv):
  (options, args) = get_options()
  directory = args[0]
  exclude = options.exclude.split(',') if options.exclude else []

  paths = [
    path + '/lib' for path in os.listdir(directory)
    if path not in exclude and os.path.isdir(os.path.join(directory, path))
  ]

  for lib in filter(lambda x: os.path.exists(os.path.join(directory, x)),
      paths):
    print '%s/%s' % (directory, lib)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
