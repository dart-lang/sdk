#!/usr/bin/env python3
# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""CFE et al presubmit python script.

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
    local_root = input_api.change.RepositoryRoot()
    utils = load_source('utils', os.path.join(local_root, 'tools', 'utils.py'))
    dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
    test_helper = os.path.join(local_root, 'pkg', 'front_end',
                               'presubmit_helper.dart')

    windows = utils.GuessOS() == 'win32'
    if windows:
        dart += '.exe'

    if not os.path.isfile(dart):
        print('WARNING: dart not found: %s' % dart)
        return []

    if not os.path.isfile(test_helper):
        print('WARNING: CFE et al presubmit_helper not found: %s' % test_helper)
        return []

    args = [dart, test_helper, input_api.PresubmitLocalPath()]
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stdin=subprocess.PIPE)
    outs, _ = process.communicate()

    if process.returncode != 0:
        return [
            output_api.PresubmitError('CFE et al presubmit script failure(s):',
                                      long_text=outs)
        ]

    return []


def CheckChangeOnCommit(input_api, output_api):
    return runSmokeTest(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return runSmokeTest(input_api, output_api)
