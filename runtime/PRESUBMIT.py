# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import cpplint
import re

# memcpy does not handle overlapping memory regions. Even though this
# is well documented it seems to be used in error quite often. To avoid
# problems we disallow the direct use of memcpy.  The exceptions are in
# third-party code and in platform/globals.h which uses it to implement
# bit_cast and bit_copy.
def CheckMemcpy(filename):
  if filename.endswith(os.path.join('platform', 'globals.h')) or \
     filename.find('third_party') != -1:
    return 0
  fh = open(filename, 'r')
  content = fh.read()
  match = re.search('\\bmemcpy\\b', content)
  if match:
    line_number = content[0:match.start()].count('\n') + 1
    print "%s:%d: use of memcpy is forbidden" % (filename, line_number)
    return 1
  return 0


def RunLint(input_api, output_api):
  result = []
  cpplint._cpplint_state.ResetErrorCounts()
  memcpy_match_count = 0
  # Find all .cc and .h files in the change list.
  for git_file in input_api.AffectedTextFiles():
    filename = git_file.AbsoluteLocalPath()
    if filename.endswith('.cc') or filename.endswith('.h'):
      # Run cpplint on the file.
      cpplint.ProcessFile(filename, 1)
      # Check for memcpy use.
      memcpy_match_count += CheckMemcpy(filename)

  # Report a presubmit error if any of the files had an error.
  if cpplint._cpplint_state.error_count > 0 or memcpy_match_count > 0:
    result = [output_api.PresubmitError('Failed cpplint check.')]
  return result


def CheckGn(input_api, output_api):
  return input_api.canned_checks.CheckGNFormatted(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
  return (RunLint(input_api, output_api) +
          CheckGn(input_api, output_api))


def CheckChangeOnCommit(input_api, output_api):
  return (RunLint(input_api, output_api) +
          CheckGn(input_api, output_api))
