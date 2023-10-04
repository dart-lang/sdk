#!/usr/bin/env python3
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import platform
import signal
import subprocess
import sys
import time

sys.path.insert(
    0,
    os.path.abspath(
        os.path.join(os.path.dirname(__file__),
                     '../../third_party/fuchsia/test_scripts/test/')))

from common import catch_sigterm, wait_for_sigterm


def Main():
    """
    Execute the test-scripts with required environment variables. It acts like
    /usr/bin/env, but provides some extra functionality to dynamically set up
    the environment variables.
    """
    # Ensures the signals can be correctly forwarded to the subprocesses.
    catch_sigterm()

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

    with subprocess.Popen(sys.argv[1:]) as proc:
        try:
            proc.wait()
        except:
            # Use terminate / SIGTERM to allow the subprocess exiting cleanly.
            proc.terminate()


if __name__ == '__main__':
    sys.exit(Main())
