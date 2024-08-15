#!/usr/bin/env vpython3
# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys

sys.path.insert(
    0,
    os.path.abspath(
        os.path.join(os.path.dirname(__file__),
                     '../../third_party/fuchsia/test_scripts/test/')))

# pylint: disable=wrong-import-position
from test_env_setup import setup_env
from compatible_utils import force_running_unattended

if __name__ == '__main__':
    force_running_unattended()
    # Note, the dart process can only get the pid of with_envs.py, i.e. ppid of
    # this script.
    sys.exit(setup_env(os.getppid()))
