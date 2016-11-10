# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Helper script for GN to run an arbitrary binary. See compiled_action.gni.

Run with:
  python gn_run_binary.py <binary_name> [args ...]
"""

import os
import sys
import subprocess

# Run a command, swallowing the output unless there is an error.
def run_command(command):
  try:
    subprocess.check_output(command, stderr=subprocess.STDOUT)
    return 0
  except subprocess.CalledProcessError as e:
    return ("Command failed: " + ' '.join(command) + "\n" +
            "output: " + e.output)

# Unless the path is absolute, this script is designed to run binaries produced
# by the current build. We always prefix it with "./" to avoid picking up system
# versions that might also be on the path.
if os.path.isabs(sys.argv[1]):
  path = sys.argv[1]
else:
  path = './' + sys.argv[1]

# The rest of the arguements are passed directly to the executable.
args = [path] + sys.argv[2:]

sys.exit(run_command(args))
