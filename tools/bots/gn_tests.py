#!/usr/bin/env python
#
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import os.path
import shutil
import sys
import subprocess

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..', '..'))

def main(argv):
  test_py = os.path.join(DART_ROOT, 'tools', 'test.py')
  build_result = subprocess.call(
      ['python', test_py] + ['--builder-tag=no_ipv6'] + argv[1:])
  if build_result != 0:
    return build_result
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
