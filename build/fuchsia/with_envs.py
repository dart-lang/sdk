#!/usr/bin/env python3
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import platform
import subprocess
import sys


def Main():
    """
    Execute the test-scripts with required environment variables. It acts like
    /usr/bin/env, but provides some extra functionality to dynamically set up
    the environment variables.
    """
    os.environ['SRC_ROOT'] = os.path.abspath(
        os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))
    os.environ['FUCHSIA_IMAGES_ROOT'] = os.path.join(os.environ['SRC_ROOT'],
                                                     'third_party', 'fuchsia',
                                                     'images')
    sdk_dir = ''
    if platform.system() == 'Linux':
        sdk_dir = 'linux'
    elif platform.system() == 'Darwin':
        sdk_dir = 'mac'
    else:
        assert False, 'Unsupported OS'
    os.environ['FUCHSIA_SDK_ROOT'] = os.path.join(os.environ['SRC_ROOT'],
                                                  'third_party', 'fuchsia',
                                                  'sdk', sdk_dir)
    # TODO(zijiehe): Remove this experimental config after upgrading sdk to a
    # version later than https://fxrev.dev/841540.
    subprocess.call([
        os.path.join(os.environ['FUCHSIA_SDK_ROOT'], 'tools', 'x64', 'ffx'),
        'config', 'set', 'product.experimental', 'true'
    ])
    subprocess.call(sys.argv[1:])


if __name__ == '__main__':
    sys.exit(Main())
