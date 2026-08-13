#!/usr/bin/env python3
# Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

from contextlib import ExitStack
import subprocess
import sys

import utils


def Main():
    args = sys.argv[1:]

    with ExitStack() as stack:
        for ctx in utils.CoreDumpArchiver(args):
            stack.enter_context(ctx)
        exit_code = subprocess.call(args)

    utils.DiagnoseExitCode(exit_code, args)
    return exit_code


if __name__ == '__main__':
    sys.exit(Main())
