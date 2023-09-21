#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


def main(args):
    for file in os.listdir(args[0]):
        if file.endswith('.cpp') or file.endswith('.h'):
            if not "suffix_tree" in file:
                print(file)


if __name__ == '__main__':
    main(sys.argv[1:])
