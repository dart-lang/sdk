#!/usr/bin/env python3
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import platform
import subprocess
import sys

sys.path.insert(
    0,
    os.path.abspath(
        os.path.join(os.path.dirname(__file__),
                     '../../third_party/fuchsia/test_scripts/test/')))

from common import catch_sigterm


def Main():
    """
    Execute the test-scripts with required environment variables. It acts like
    /usr/bin/env, but provides some extra functionality to dynamically set up
    the environment variables.
    """
    # Ensures the signals can be correctly forwarded to the subprocesses.
    catch_sigterm()

    if platform.machine() in ['arm64', 'aarch64']:
        host_cpu = 'arm64'
    else:
        host_cpu = 'x64'

    os.environ['SRC_ROOT'] = os.path.abspath(
        os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))
    os.environ['FUCHSIA_IMAGES_ROOT'] = os.path.join(os.environ['SRC_ROOT'],
                                                     'third_party', 'fuchsia',
                                                     'images')
    os.environ['FUCHSIA_SDK_ROOT'] = os.path.join(os.environ['SRC_ROOT'],
                                                  'third_party', 'fuchsia',
                                                  'sdk', 'linux')

    os.environ['FUCHSIA_GN_SDK_ROOT'] = os.path.join(os.environ['SRC_ROOT'],
                                                     'third_party', 'fuchsia',
                                                     'gn-sdk', 'src')
    os.environ['FUCHSIA_READELF'] = os.path.join(os.environ['SRC_ROOT'],
                                                 'buildtools',
                                                 'linux-' + host_cpu, 'clang',
                                                 'bin', 'llvm-readelf')
    # On arm64, `ffx debug symbolize` tries to run the x64 symbolizer. qemu-binfmt can handle this.
    if host_cpu == 'arm64':
        os.environ['QEMU_LD_PREFIX'] = '/usr/x86_64-linux-gnu'

    with subprocess.Popen(sys.argv[1:]) as proc:
        try:
            proc.wait()
        except:
            # Use terminate / SIGTERM to allow the subprocess exiting cleanly.
            proc.terminate()
        return proc.returncode


if __name__ == '__main__':
    sys.exit(Main())
