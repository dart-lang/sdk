#!/usr/bin/env python
#
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Fetches an archived chromium build into
  src/chrome/tools/test/reference_build unless
  src/chrome/tools/test/reference_build/REQUESTED_REVISION is the same as
  src/chrome/tools/test/reference_build/CURRENT_REVISION.
  Must be run from the root of a Dartium or multivm checkout.

Usage:
  $ ./src/dart/tools/bots/fetch_reference_build_revision.py
"""

import os
import subprocess
import sys

def main(argv):
  dirname = os.path.join('src', 'chrome', 'tools',
                        'test', 'reference_build')
  request = os.path.join(dirname, 'REQUESTED_REVISION')
  found = os.path.join(dirname, 'CURRENT_REVISION')
  if not os.path.exists(request):
    return
  with file(request, 'r') as f:
    request_revision = f.read()

  if os.path.exists(found):
    with file(found, 'r') as f:
      found_revision = f.read()
    if found_revision == request_revision:
      return

  get_script = os.path.join('src', 'dart', 'tools',
                            'bots', 'get_chromium_build.py')
  get_script = os.path.abspath(get_script)
  exit_code = subprocess.call(['python', get_script,
                               '-r', request_revision,
                               '-t', dirname])
  if exit_code == 0:
    with file(found, 'w') as f:
      f.write(request_revision)
  return exit_code

if __name__ == '__main__':
  sys.exit(main(sys.argv))
