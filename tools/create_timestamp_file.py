#!/usr/bin/env python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import sys
import os


def main(args):
    for file_name in args[1:]:
        dir_name = os.path.dirname(file_name)
        if not os.path.exists(dir_name):
            os.mkdir(dir_name)
        open(file_name, 'w').close()


if __name__ == '__main__':
    sys.exit(main(sys.argv))
