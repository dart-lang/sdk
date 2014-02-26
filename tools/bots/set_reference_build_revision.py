#!/usr/bin/env python
#
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes a revision number into src/chrome/tools/test/reference_build/REVISON
   Must be run from the root of a Dartium or multivm checkout.

Usage:
  $ ./src/dart/tools/bots/set_reference_build_revision.py <revision>
"""

import os
import sys

def main(argv):
  revision = argv[1]
  output = os.path.join('src', 'chrome', 'tools',
                        'test', 'reference_build',
                        'REQUESTED_REVISION')
  dirname = os.path.dirname(output)
  if dirname and not os.path.exists(dirname):
    os.makedirs(dirname)
  with file(output, 'w') as f:
    f.write(revision)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
