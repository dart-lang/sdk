#!/usr/bin/env python3
# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


def main(args):
    if os.path.isfile(args[1]):
        print("true")
    else:
        print("false")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
