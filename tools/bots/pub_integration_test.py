#!/usr/bin/env python3
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import os
import subprocess
import sys
import shutil
import tempfile

PUBSPEC = """name: pub_integration_test
environment:
  sdk: '>=2.10.0 <=3.0.0'
dependencies:
  shelf:
  test:
"""


def Main():
    parser = optparse.OptionParser()
    parser.add_option(
        '--mode', action='store', dest='mode', type='string', default='release')
    parser.add_option('--arch',
                      action='store',
                      dest='arch',
                      type='string',
                      default='x64')

    (options, args) = parser.parse_args()

    arch = 'ARM64' if options.arch == 'arm64' else 'X64'
    mode = ('Debug' if options.mode == 'debug' else 'Release')

    out_dir = 'xcodebuild' if sys.platform == 'darwin' else 'out'
    extension = '' if not sys.platform == 'win32' else '.exe'
    dart = os.path.abspath('%s/%s%s/dart-sdk/bin/dart%s' %
                           (out_dir, mode, arch, extension))
    print(dart)

    working_dir = tempfile.mkdtemp()
    try:
        pub_cache_dir = working_dir + '/pub_cache'
        env = os.environ.copy()
        env['PUB_CACHE'] = pub_cache_dir

        with open(working_dir + '/pubspec.yaml', 'w') as pubspec_yaml:
            pubspec_yaml.write(PUBSPEC)

        exit_code = subprocess.call([dart, 'pub', 'get'],
                                    cwd=working_dir,
                                    env=env)
        if exit_code != 0:
            return exit_code

        exit_code = subprocess.call([dart, 'pub', 'upgrade'],
                                    cwd=working_dir,
                                    env=env)
        if exit_code != 0:
            return exit_code
    finally:
        shutil.rmtree(working_dir)


if __name__ == '__main__':
    sys.exit(Main())
