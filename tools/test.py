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

    cleanup_dart = False
    if '--cleanup-dart-processes' in args:
        args.remove('--cleanup-dart-processes')
        cleanup_dart = True

    tools_dir = os.path.dirname(os.path.realpath(__file__))
    repo_dir = os.path.dirname(tools_dir)
    dart_test_script = os.path.join(repo_dir, 'pkg', 'test_runner', 'bin',
                                    'test_runner.dart')
    command = [utils.CheckedInSdkExecutable(), dart_test_script] + args

    # The testing script potentially needs the android platform tools in PATH so
    # we do that in ./tools/test.py (a similar logic exists in ./tools/build.py).
    android_platform_tools = os.path.normpath(
        os.path.join(tools_dir,
                     '../third_party/android_tools/sdk/platform-tools'))
    if os.path.isdir(android_platform_tools):
        os.environ['PATH'] = '%s%s%s' % (os.environ['PATH'], os.pathsep,
                                         android_platform_tools)

    with utils.FileDescriptorLimitIncreaser():
        with utils.CoreDumpArchiver(args):
            exit_code = subprocess.call(command)

    if cleanup_dart:
        cleanup_command = [
            sys.executable,
            os.path.join(tools_dir, 'task_kill.py'), '--kill_dart=True',
            '--kill_vc=False'
        ]
        subprocess.call(cleanup_command)

    utils.DiagnoseExitCode(exit_code, command)
    return exit_code


if __name__ == '__main__':
    sys.exit(Main())
