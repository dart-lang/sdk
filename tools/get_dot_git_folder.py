#!/usr/bin/env python
# Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script is a wrapper around `git rev-parse --resolve-git-dir`.
# This is used for the build system to work with git worktrees.

import sys
import subprocess


def main():
    if len(sys.argv) != 2:
        raise Exception('Expects exactly 1 argument.')

    return subprocess.call(
        ['git', 'rev-parse', '--resolve-git-dir', sys.argv[1]])


if __name__ == '__main__':
    sys.exit(main())
