#!/usr/bin/env python3
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Tool for listing Dart source files.

If the first argument is 'relative', the script produces paths relative to the
current working directory. If the first argument is 'absolute', the script
produces absolute paths.

Usage:
  python3 tools/list_dart_files_as_depfile.py <depfile> <directory> <pattern>
"""

import os
import re
import sys


def main(argv):
    depfile = argv[1]
    directory = argv[2]
    if not os.path.isabs(directory):
        directory = os.path.realpath(directory)

    pattern = None
    if len(argv) > 3:
        pattern = re.compile(argv[3])

    # Output a GN/Ninja depfile, whose format is a Makefile with one target.
    out = open(depfile, 'w')
    out.write(os.path.relpath(depfile))
    out.write(":")

    for root, directories, files in os.walk(directory):
        # We only care about actual source files, not generated code or tests.
        for skip_dir in ['.git', 'gen', 'test']:
            if skip_dir in directories:
                directories.remove(skip_dir)

        # If we are looking at the root directory, filter the immediate
        # subdirectories by the given pattern.
        if pattern and root == directory:
            directories[:] = filter(pattern.match, directories)

        for filename in files:
            if filename.endswith(
                    '.dart') and not filename.endswith('_test.dart'):
                fullname = os.path.join(directory, root, filename)
                fullname = fullname.replace(os.sep, '/')
                out.write(" \"")
                out.write(fullname)
                out.write("\"")

    out.write("\n")
    out.close()


if __name__ == '__main__':
    sys.exit(main(sys.argv))
