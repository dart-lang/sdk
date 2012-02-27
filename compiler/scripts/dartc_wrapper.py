#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


def Main():
  script_name = os.path.basename(sys.argv[0])
  script_dir = os.path.dirname(sys.argv[0])
  dartc_script = os.path.join(script_dir, 'compiler', 'bin', 'dartc')
  os.putenv("DART_SCRIPT_NAME", script_name)

  return os.execv(dartc_script, [dartc_script] + sys.argv[1:])


if __name__ == '__main__':
  sys.exit(Main())
