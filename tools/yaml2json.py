#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import subprocess
import sys

import utils


def Main():
    args = sys.argv[1:]
    yaml2json_dart = os.path.relpath(
        os.path.join(os.path.dirname(__file__), "yaml2json.dart"))
    command = [utils.CheckedInSdkExecutable(), yaml2json_dart] + args

    with utils.CoreDumpArchiver(args):
        exit_code = subprocess.call(command)

    utils.DiagnoseExitCode(exit_code, command)
    return exit_code


if __name__ == '__main__':
    sys.exit(Main())
