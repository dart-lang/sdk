# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

def CheckChangeOnCommit(input_api, output_api):
  results = []
  status_check = input_api.canned_checks.CheckTreeIsOpen(
      input_api,
      output_api,
      json_url='http://dart-status.appspot.com/current?format=json')
  results.extend(status_check)
  return results
