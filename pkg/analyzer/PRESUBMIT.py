#!/usr/bin/env python3
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Analyzer specific presubmit script.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import os.path
import re

USE_PYTHON3 = True
PRESUBMIT_VERSION = '2.0.0'


def CheckNodeTextExpectationsCollectorUpdatingIsDisabled(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    node_text_expectations_file = os.path.join(local_root, 'pkg', 'analyzer',
                                               'test', 'src', 'dart',
                                               'resolution',
                                               'node_text_expectations.dart')
    for git_file in input_api.AffectedTestableFiles():
        filename = git_file.AbsoluteLocalPath()
        if (filename == node_text_expectations_file):
            isEnabledLine = re.compile('static const updatingIsEnabled = (.*);')
            for line in git_file.NewContents():
                m = isEnabledLine.search(line)
                if (m is not None):
                    value = m.group(1)
                    if (value == 'false'):
                        return []
                    else:
                        return [
                            output_api.PresubmitError(
                                'NodeTextExpectationsCollector.updatingIsEnabled '
                                'must be `false`')
                        ]
            return [
                output_api.PresubmitError(
                    'Could not validate '
                    'NodeTextExpectationsCollector.updatingIsEnabled')
            ]
    return []
