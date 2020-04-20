#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import os
import shutil
import sys
import subprocess
import utils


def Main():
    build_root = utils.GetBuildRoot(utils.GuessOS())
    print 'Deleting %s' % build_root
    if sys.platform != 'win32':
        shutil.rmtree(build_root, ignore_errors=True)
    else:
        # Intentionally ignore return value since a directory might be in use.
        subprocess.call(['rmdir', '/Q', '/S', build_root],
                        env=os.environ.copy(),
                        shell=True)
    return 0


if __name__ == '__main__':
    sys.exit(Main())
