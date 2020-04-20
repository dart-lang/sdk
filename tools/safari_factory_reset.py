#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import string
import subprocess
import sys

import utils


def Main():
    args = sys.argv[1:]
    tools_dir = os.path.dirname(os.path.realpath(__file__))
    dart_script_name = os.path.join(tools_dir, 'testing', 'dart',
                                    'reset_safari.dart')
    command = [utils.CheckedInSdkExecutable(), '--checked', dart_script_name
              ] + args
    exit_code = subprocess.call(command)
    utils.DiagnoseExitCode(exit_code, command)
    return exit_code


if __name__ == '__main__':
    sys.exit(Main())
