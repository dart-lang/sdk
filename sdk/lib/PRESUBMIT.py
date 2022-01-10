#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""sdk/lib specific presubmit script.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import imp
import os.path
import subprocess

USE_PYTHON3 = True


def runSmokeTest(input_api, output_api):
    hasChangedFiles = False
    for git_file in input_api.AffectedTextFiles():
        filename = git_file.AbsoluteLocalPath()
        if filename.endswith('libraries.yaml') or filename.endswith(
                'libraries.json'):
            hasChangedFiles = True
            break

    if hasChangedFiles:
        local_root = input_api.change.RepositoryRoot()
        utils = imp.load_source('utils',
                                os.path.join(local_root, 'tools', 'utils.py'))
        dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
        yaml2json = os.path.join(local_root, 'tools', 'yaml2json.dart')
        libYaml = os.path.join(local_root, 'sdk', 'lib', 'libraries.yaml')
        libJson = os.path.join(local_root, 'sdk', 'lib', 'libraries.json')

        windows = utils.GuessOS() == 'win32'
        if windows:
            dart += '.exe'

        if not os.path.isfile(dart):
            print('WARNING: dart not found: %s' % dart)
            return []

        if not os.path.isfile(yaml2json):
            print('WARNING: yaml2json not found: %s' % yaml2json)
            return []

        args = [
            dart, yaml2json, libYaml, libJson, '--check',
            '--relative=' + local_root + '/'
        ]
        process = subprocess.Popen(args,
                                   stdout=subprocess.PIPE,
                                   stdin=subprocess.PIPE)
        outs, _ = process.communicate()

        if process.returncode != 0:
            return [
                output_api.PresubmitError('lib/sdk smoketest failure(s)',
                                          long_text=outs)
            ]

    return []


def CheckChangeOnCommit(input_api, output_api):
    return runSmokeTest(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return runSmokeTest(input_api, output_api)
