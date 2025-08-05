#!/usr/bin/env python3
# Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import os.path
import platform
import subprocess
import sys

USE_PYTHON3 = True


def is_windows():
    os_id = platform.system()
    return os_id == 'Windows'


def checked_in_sdk_path():
    tools_dir = os.path.dirname(os.path.realpath(__file__))
    return os.path.join(tools_dir, 'sdks', 'dart-sdk')


def checked_in_sdk_executable():
    name = 'dart'
    if is_windows():
        name = 'dart.exe'
    return os.path.join(checked_in_sdk_path(), 'bin', name)


def generate_tests(tools_dir, tests_dir):
    for file in os.listdir(tests_dir):
        if not file.endswith('_generator.dart'):
            continue

        gen_file = os.path.join(tests_dir, file)
        test_file = gen_file.replace('_generator.dart', '_test.dart')
        if os.path.exists(test_file):
            os.remove(test_file)
        process = subprocess.run([
            checked_in_sdk_executable(),
            '--packages=%s' %
            os.path.join(tools_dir, 'empty_package_config.json'),
            gen_file,
        ],
                                 capture_output=True)
        if process.returncode != 0:
            sys.exit(process.returncode)
        f = open(test_file, 'wb')
        f.write(process.stdout)
        f.close()


def Main():
    tools_dir = os.path.dirname(os.path.realpath(__file__))
    vm_tests_dir = os.path.join(tools_dir, '..', 'runtime', 'tests', 'vm',
                                'dart')
    generate_tests(tools_dir, vm_tests_dir)


if __name__ == '__main__':
    Main()
