#!/usr/bin/env python

# Copyright (c) 2014 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script runs the async/await compiler on pub and then compiles the output
of that to a snapshot.

Usage: create_pub_snapshot.py <dart> <compiler> <package root> <output dir>

When #104 is fixed, this script is no longer needed. Instead, replace the
generate_pub_snapshot action in utils/pub.gyp with:

    'action': [
      '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)dart<(EXECUTABLE_SUFFIX)',
      '--package-root=<(PRODUCT_DIR)/pub_packages/',
      '--snapshot=<(SHARED_INTERMEDIATE_DIR)/pub.dart.snapshot',
      '../../sdk/lib/_internal/pub/bin/pub.dart',
    ]
"""

import os
import subprocess
import sys


def Main():
  if len(sys.argv) < 5:
    raise Exception("""Not enough arguments.

Usage: create_pub_snapshot.py <dart> <compiler> <package root> <output file>""")

  dart_path = sys.argv[1]
  compiler = sys.argv[2]
  package_root = sys.argv[3]
  output_dir = sys.argv[4]

  # Run the async compiler.
  status = subprocess.call([
    dart_path,
    '--package-root=' + package_root,
    compiler,
    output_dir,
    '--silent'
  ])
  if status != 0: return status

  # Generate the snapshot from the output of that.
  status = subprocess.call([
    dart_path,
    '--package-root=' + package_root,
    '--snapshot=' + os.path.join(output_dir, 'pub.dart.snapshot'),
    os.path.join(output_dir, 'pub_async/bin/pub.dart')
  ])
  if status != 0: return status


if __name__ == '__main__':
  sys.exit(Main())
