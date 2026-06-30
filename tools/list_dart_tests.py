#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


def main(argv):
    directory = argv[1]

    for root, directories, files in os.walk(directory):
        for filename in files:
            if filename.endswith('_test.dart'):
                fullname = os.path.relpath(os.path.join(root, filename))
                fullname = fullname.replace(os.sep, '/')
                print(fullname)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
