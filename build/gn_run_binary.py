#!/usr/bin/env python3
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Helper script for GN to run an arbitrary binary. See compiled_action.gni.

Run with:
  python3 gn_run_binary.py <invoker> <binary_name> [args ...]

Where <invoker> is either "compiled_action" or "exec_script". If it is
"compiled_action" the script has a non-zero exit code on a failure. If it is
"exec_script" the script has no output on success and produces output otherwise,
but always has an exit code of 0.
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
        return ("Command failed: " + ' '.join(command) + "\n" + "output: " +
                _decode(e.output))
    except OSError as e:
        return ("Command failed: " + ' '.join(command) + "\n" + "output: " +
                _decode(e.strerror))


def _decode(bytes):
    return bytes.decode("utf-8")


def main(argv):
    error_exit = 0
    if argv[1] == "compiled_action":
        error_exit = 1
    elif argv[1] != "exec_script":
        print("The first argument should be either "
              "'compiled_action' or 'exec_script")
        return 1

    # Unless the path is absolute, this script is designed to run binaries
    # produced by the current build, which is the current working directory when
    # this script is run.
    path = os.path.abspath(argv[2])

    if not os.path.isfile(path):
        print("Binary not found: " + path)
        return error_exit

    # The rest of the arguments are passed directly to the executable.
    args = [path] + argv[3:]

    result = run_command(args)
    if result != 0:
        print(result)
        return error_exit
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
