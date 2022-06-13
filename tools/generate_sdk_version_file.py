#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import utils
import sys

SDK_VERSION_FILE = os.path.join(utils.DART_DIR, 'sdk', 'version')


def Main():
    version = utils.ReadVersionFile()
    with open(SDK_VERSION_FILE, 'w') as versionFile:
        versionFile.write(f'{version.major}.{version.minor}.0\n')
    return 0


if __name__ == '__main__':
    sys.exit(Main())
