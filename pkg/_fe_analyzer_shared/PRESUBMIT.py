#!/usr/bin/env python3
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Shared front-end analyzer specific presubmit script.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import importlib.util
import importlib.machinery
import os.path
import subprocess

USE_PYTHON3 = True


def load_source(modname, filename):
    loader = importlib.machinery.SourceFileLoader(modname, filename)
    spec = importlib.util.spec_from_file_location(modname,
                                                  filename,
                                                  loader=loader)
    module = importlib.util.module_from_spec(spec)
    # The module is always executed and not cached in sys.modules.
    # Uncomment the following line to cache the module.
    # sys.modules[module.__name__] = module
    loader.exec_module(module)
    return module


def runSmokeTest(input_api, output_api):
    hasChangedFiles = False
    for git_file in input_api.AffectedTextFiles():
        filename = git_file.AbsoluteLocalPath()
        if filename.endswith(".dart"):
            hasChangedFiles = True
            break

    if hasChangedFiles:
        local_root = input_api.change.RepositoryRoot()
        utils = load_source('utils',
                            os.path.join(local_root, 'tools', 'utils.py'))
        dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
        smoke_test = os.path.join(local_root, 'pkg', '_fe_analyzer_shared',
                                  'tool', 'smoke_test_quick.dart')

        windows = utils.GuessOS() == 'win32'
        if windows:
            dart += '.exe'

        if not os.path.isfile(dart):
            print('WARNING: dart not found: %s' % dart)
            return []

        if not os.path.isfile(smoke_test):
            print('WARNING: _fe_analyzer_shared smoke test not found: %s' %
                  smoke_test)
            return []

        args = [dart, smoke_test]
        process = subprocess.Popen(
            args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        outs, _ = process.communicate()

        if process.returncode != 0:
            return [
                output_api.PresubmitError(
                    '_fe_analyzer_shared smoke test failure(s):',
                    long_text=outs)
            ]

    return []


def CheckChangeOnCommit(input_api, output_api):
    return runSmokeTest(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return runSmokeTest(input_api, output_api)
