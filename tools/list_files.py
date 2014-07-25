#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tool for listing files whose name match a pattern.

Usage:
  python tools/list_files.py PATTERN DIRECTORY...
"""

import os
import re
import sys


def main(argv):
  pattern = re.compile(argv[1])
  for directory in argv[2:]:
    for root, directories, files in os.walk(directory):
      if '.svn' in directories:
        directories.remove('.svn')
      for filename in files:
        fullname = os.path.relpath(os.path.join(root, filename))
        fullname = fullname.replace(os.sep, '/')
        if re.search(pattern, fullname):
          print fullname


if __name__ == '__main__':
  sys.exit(main(sys.argv))
