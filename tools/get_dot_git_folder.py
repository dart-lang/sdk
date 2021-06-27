#!/usr/bin/env python3
# Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script is a wrapper around `git rev-parse --resolve-git-dir`.
# This is used for the build system to work with git worktrees.

import sys
import subprocess
import utils


def main():
    try:
        if len(sys.argv) != 3:
            raise Exception('Expects exactly 2 arguments.')
        args = ['git', 'rev-parse', '--resolve-git-dir', sys.argv[1]]

        windows = utils.GuessOS() == 'win32'
        if windows:
            process = subprocess.Popen(args,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       stdin=subprocess.PIPE,
                                       shell=True,
                                       universal_newlines=True)
        else:
            process = subprocess.Popen(args,
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE,
                                       stdin=subprocess.PIPE,
                                       shell=False,
                                       universal_newlines=True)

        outs, _ = process.communicate()

        if process.returncode != 0:
            raise Exception('Got non-0 exit code from git.')

        print(outs.strip())
    except:
        # Fall back to fall-back path.
        print(sys.argv[2])


if __name__ == '__main__':
    sys.exit(main())
