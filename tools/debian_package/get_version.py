#!/usr/bin/env python3
#
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import sys
from os import listdir
from os.path import join, split, abspath, dirname

sys.path.append(join(dirname(__file__), '..'))
import utils


def Main():
    print(utils.GetVersion())


if __name__ == '__main__':
    sys.exit(Main())
