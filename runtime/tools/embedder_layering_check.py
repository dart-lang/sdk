#!/usr/bin/env python
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Simple tool for verifying that sources from the standalone embedder do not
# directly include sources from the VM or vice versa.

import glob
import os
import re
import sys

INCLUDE_DIRECTIVE_RE = re.compile(r'^#include "(.*)"')

PLATFORM_LAYER_RE = re.compile(r'^runtime/platform/')
VM_LAYER_RE = re.compile(r'^runtime/(vm|lib)/')
BIN_LAYER_RE = re.compile(r'^runtime/bin/')

# Tests that don't match the simple case of *_test.cc.
EXTRA_TEST_FILES = [
    'runtime/bin/run_vm_tests.cc',
    'runtime/bin/ffi_unit_test/run_ffi_unit_tests.cc',
    'runtime/vm/libfuzzer/dart_libfuzzer.cc'
]


def CheckFile(sdk_root, path):
    includes = set()
    with open(os.path.join(sdk_root, path)) as file:
        for line in file:
            m = INCLUDE_DIRECTIVE_RE.match(line)
            if m is not None:
                header = os.path.join('runtime', m.group(1))
                if os.path.isfile(os.path.join(sdk_root, header)):
                    includes.add(header)

    errors = []
    for include in includes:
        if PLATFORM_LAYER_RE.match(path):
            if VM_LAYER_RE.match(include):
                errors.append(
                    'LAYERING ERROR: %s must not include %s' % (path, include))
            elif BIN_LAYER_RE.match(include):
                errors.append(
                    'LAYERING ERROR: %s must not include %s' % (path, include))
        elif VM_LAYER_RE.match(path):
            if BIN_LAYER_RE.match(include):
                errors.append(
                    'LAYERING ERROR: %s must not include %s' % (path, include))
        elif BIN_LAYER_RE.match(path):
            if VM_LAYER_RE.match(include):
                errors.append(
                    'LAYERING ERROR: %s must not include %s' % (path, include))
    return errors


def CheckDir(sdk_root, dir):
    errors = []
    for file in os.listdir(dir):
        path = os.path.join(dir, file)
        if os.path.isdir(path):
            errors += CheckDir(sdk_root, path)
        elif path.endswith('test.cc') or path in EXTRA_TEST_FILES:
            None  # Tests may violate layering.
        elif path.endswith('.cc') or path.endswith('.h'):
            errors += CheckFile(sdk_root, os.path.relpath(path, sdk_root))
    return errors


def DoCheck(sdk_root):
    return CheckDir(sdk_root, 'runtime')


if __name__ == '__main__':
    errors = DoCheck('.')
    print '\n'.join(errors)
    if errors:
        sys.exit(-1)
