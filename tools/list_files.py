#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Tool for listing files whose name match a pattern.

If the first argument is 'relative', the script produces paths relative to the
current working directory. If the first argument is 'absolute', the script
produces absolute paths.

Usage:
  python tools/list_files.py {absolute, relative} PATTERN DIRECTORY...
"""

import os
import re
import sys


def main(argv):
    mode = argv[1]
    if mode not in ['absolute', 'relative']:
        raise Exception("First argument must be 'absolute' or 'relative'")
    pattern = re.compile(argv[2])
    for directory in argv[3:]:
        if mode in 'absolute' and not os.path.isabs(directory):
            directory = os.path.realpath(directory)
        for root, directories, files in os.walk(directory):
            if '.git' in directories:
                directories.remove('.git')
            for filename in files:
                if mode in 'absolute':
                    fullname = os.path.join(directory, root, filename)
                else:
                    fullname = os.path.relpath(os.path.join(root, filename))
                fullname = fullname.replace(os.sep, '/')
                if re.search(pattern, fullname):
                    print (fullname)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
