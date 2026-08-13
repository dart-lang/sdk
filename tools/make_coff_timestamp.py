# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import subprocess
import utils
import sys


def Main():
    p = subprocess.Popen(['git', 'show', '--no-patch', '--format=%ct'],
                         shell=utils.IsWindows(),
                         cwd=utils.DART_DIR)
    p.communicate()
    return p.wait()


if __name__ == '__main__':
    sys.exit(Main())
