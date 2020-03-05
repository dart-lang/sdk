# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import cpplint
import re
import StringIO


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
        offset = match.start()
        end_of_line = content.index('\n', offset)
        # We allow explicit use of memcpy with an opt-in via NOLINT
        if 'NOLINT' not in content[offset:end_of_line]:
            line_number = content[0:match.start()].count('\n') + 1
            print("%s:%d: use of memcpy is forbidden" % (filename, line_number))
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


def CheckFormatted(input_api, output_api):

    def convert_warning_to_error(presubmit_result):
        if not presubmit_result.fatal:
            # Convert this warning to an error.
            result_json = presubmit_result.json_format()
            return output_api.PresubmitError(
                message=result_json['message'],
                items=result_json['items'],
                long_text=result_json['long_text'])
        return presubmit_result

    results = input_api.canned_checks.CheckPatchFormatted(input_api, output_api)
    return [convert_warning_to_error(r) for r in results]


def CheckChangeOnUpload(input_api, output_api):
    return (RunLint(input_api, output_api) + CheckGn(input_api, output_api) +
            CheckFormatted(input_api, output_api))


def CheckChangeOnCommit(input_api, output_api):
    return (RunLint(input_api, output_api) + CheckGn(input_api, output_api) +
            CheckFormatted(input_api, output_api))
