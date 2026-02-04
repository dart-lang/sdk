#!/usr/bin/env python3
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Analysis server specific presubmit script.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import importlib.util
import importlib.machinery
import os.path
import subprocess

USE_PYTHON3 = True
PRESUBMIT_VERSION = '2.0.0'


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


def CheckSorted(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    utils = load_source('utils', os.path.join(local_root, 'tools', 'utils.py'))
    dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
    windows = utils.GuessOS() == 'win32'
    if windows:
        dart += '.exe'
    sourceArgs = [
        arg for git_file in input_api.AffectedTestableFiles()
        for arg in ('-s', git_file.AbsoluteLocalPath())
    ]
    result = subprocess.run([
        dart,
        'run',
        '-r',
        os.path.join(local_root, 'pkg', 'analysis_server', 'test',
                     'verify_sorted_test.dart'),
    ] + sourceArgs,
                            capture_output=True)
    if result.returncode != 0:
        return [
            output_api.PresubmitError('\n'.join([
                line for line in result.stdout.decode('utf-8').splitlines()
                if 'Unsorted file' in line
            ]))
        ]
    return []
