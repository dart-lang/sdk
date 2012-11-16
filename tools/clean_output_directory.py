#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import shutil
import sys
import utils

def Main():
  build_root = utils.GetBuildRoot(utils.GuessOS())
  shutil.rmtree(build_root, ignore_errors=True)
  return 0

if __name__ == '__main__':
  sys.exit(Main())
