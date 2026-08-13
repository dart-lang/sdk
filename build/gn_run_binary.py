#!/usr/bin/env python3
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Helper script for GN to run an arbitrary binary. See compiled_action.gni.

Run with:
  python3 gn_run_binary.py <binary_name> [args ...]

Swallows output on success.
"""

import os
import sys
import subprocess

def _decode(bytes):
    return bytes.decode("utf-8")

def main(argv):
    # Unless the path is absolute, this script is designed to run binaries
    # produced by the current build, which is the current working directory when
    # this script is run.
    path = os.path.abspath(argv[1])

    if not os.path.isfile(path):
        print("Binary not found: " + path)
        return 1

    # The rest of the arguments are passed directly to the executable.
    command = [path] + argv[2:]

    # Run a command, swallowing the output unless there is an error.
    try:
        subprocess.check_output(command, stderr=subprocess.STDOUT)
        return 0
    except subprocess.CalledProcessError as e:
        print("Command failed: " + ' '.join(command) + "\n" + "exitCode: " +
              str(e.returncode) + "\n" + "output: " + _decode(e.output))

        # -9 = SIGKILL
        # For other signals, the VM gets a chance to print a stack trace and
        # other information, but if it is killed the only information about
        # why is in system logs.
        if e.returncode == -9 and sys.platform == 'darwin':
            shortname = os.path.basename(path)
            subprocess.run([
                "log", "show", "--last", "5m", "--predicate",
                'eventMessage CONTAINS "SIGKILL" OR eventMessage CONTAINS "' +
                shortname + '"'
            ],
                           stdout=None,
                           stderr=None)
        return 1
    except OSError as e:
        print("Command failed: " + ' '.join(command) + "\n" + "output: " +
              _decode(e.strerror))
        return 1

if __name__ == '__main__':
    sys.exit(main(sys.argv))
