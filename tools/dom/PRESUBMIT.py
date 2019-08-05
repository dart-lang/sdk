# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""
Presubmit tests for dom tools.

This file is run by git_cl or gcl when an upload or submit happens with
any files at this level or lower are in the change list.

See: http://www.chromium.org/developers/how-tos/depottools/presubmit-scripts
"""

import os


def _AnySdkFiles(input_api):
    """ Returns true if any of the changed files are in the sdk, meaning we should
  check that docs.dart was run.
  """
    for f in input_api.change.AffectedFiles():
        if f.LocalPath().find('sdk') > -1:
            return True
    return False


def CheckChangeOnUpload(input_api, output_api):
    results = []
    # TODO(amouravski): uncomment this check once docs.dart is faster.
    #  if _AnySdkFiles(input_api):
    #    results.extend(CheckDocs(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    results = []
    if _AnySdkFiles(input_api):
        results.extend(CheckDocs(input_api, output_api))
    return results


def CheckDocs(input_api, output_api):
    """Ensure that documentation has been generated if it needs to be generated.

  Prompts with a warning if documentation needs to be generated.
  """
    results = []

    cmd = [os.path.join(input_api.PresubmitLocalPath(), 'dom.py'), 'test_docs']

    try:
        input_api.subprocess.check_output(
            cmd, stderr=input_api.subprocess.STDOUT)
    except (OSError, input_api.subprocess.CalledProcessError), e:
        results.append(
            output_api.PresubmitPromptWarning(
                ('Docs test failed!%s\nYou should run `dom.py docs`' %
                 (e if input_api.verbose else ''))))

    return results
