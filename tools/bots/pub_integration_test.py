#!/usr/bin/env python
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import subprocess
import sys
import shutil
import tempfile

PUBSPEC = """name: pub_integration_test
dependencies:
  shelf:
  test:
"""

def Main():
  out_dir = 'xcodebuild' if sys.platform == 'darwin' else 'out'
  extension = '' if not sys.platform == 'win32' else '.bat'
  pub = os.path.abspath(
    '%s/ReleaseX64/dart-sdk/bin/pub%s' % (out_dir, extension))

  working_dir = tempfile.mkdtemp()
  try:
    pub_cache_dir = working_dir + '/pub_cache'
    env = os.environ.copy()
    env['PUB_CACHE'] = pub_cache_dir

    with open(working_dir + '/pubspec.yaml', 'w') as pubspec_yaml:
      pubspec_yaml.write(PUBSPEC)

    exit_code = subprocess.call([pub, 'get'], cwd=working_dir, env=env)
    if exit_code is not 0:
      return exit_code

    exit_code = subprocess.call([pub, 'upgrade'], cwd=working_dir, env=env)
    if exit_code is not 0:
      return exit_code
  finally:
    shutil.rmtree(working_dir);

if __name__ == '__main__':
  sys.exit(Main())
