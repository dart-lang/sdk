#!/usr/bin/env python
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script disguises test.py so it doesn't look like test.py to the testing
# infrastructure, which handles test.py specially. Any testing done through
# this script will not show up on testing dashboards and in the test results
# database.

# The front-end-* builders are currently using this script to run their unit
# tests, which must always pass and should not be approvable through the status
# file free workflow.

import os
import subprocess
import sys

exit(
    subprocess.call([
        sys.executable,
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "test.py")
    ] + sys.argv[1:]))
