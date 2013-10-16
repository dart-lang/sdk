# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import cpplint
import re


class PathHackException(Exception):
  def __init__(self, error_msg):
    self.error_msg = error_msg

  def __str__(self):
    return repr(self.error_msg)

def AddSvnPathIfNeeded(runtime_path):
  # Add the .svn into the runtime directory if needed for git or svn 1.7.
  fake_svn_path = os.path.join(runtime_path, '.svn')
  if os.path.exists(fake_svn_path):
    return None
  open(fake_svn_path, 'w').close()
  return lambda: os.remove(fake_svn_path)


def TrySvnPathHack(parent_path):
  orig_path = os.path.join(parent_path, '.svn')
  renamed_path = os.path.join(parent_path, '.svn_orig')
  if os.path.exists(renamed_path):
    error_msg = '".svn_orig" exists in presubmit parent directory('
    error_msg += parent_path
    error_msg += '). Consider renaming it manually to ".svn".'
    raise PathHackException(error_msg)
  if os.path.exists(orig_path):
    # Make the parent SVN directory non-discoverable by cpplint to get
    # the correct header guard checks. This is needed if using all Dart
    # checkout.
    os.rename(orig_path, renamed_path)
    return lambda: os.rename(renamed_path, orig_path)


def RunLint(input_api, output_api):
  result = []
  cpplint._cpplint_state.ResetErrorCounts()
  memcpy_match_count = 0
  # Find all .cc and .h files in the change list.
  for svn_file in input_api.AffectedTextFiles():
    filename = svn_file.AbsoluteLocalPath()
    if filename.endswith('.cc') or filename.endswith('.h'):
      cleanup_parent = None
      cleanup_runtime = None
      try:
        runtime_path = input_api.PresubmitLocalPath()
        parent_path = os.path.dirname(runtime_path)
        if filename.endswith('.h'):
          cleanup_runtime = AddSvnPathIfNeeded(runtime_path)
          cleanup_parent = TrySvnPathHack(parent_path)
      except PathHackException, exception:
        return [output_api.PresubmitError(str(exception))]
      # Run cpplint on the file.
      cpplint.ProcessFile(filename, 1)
      if cleanup_parent is not None:
        cleanup_parent()
      if cleanup_runtime is not None:
        cleanup_runtime()
      # memcpy does not handle overlapping memory regions. Even though this
      # is well documented it seems to be used in error quite often. To avoid
      # problems we disallow the direct use of memcpy.  The exceptions are in
      # third-party code and in platform/globals.h which uses it to implement
      # bit_cast and bit_copy.
      if not filename.endswith(os.path.join('platform', 'globals.h')) and \
         filename.find('third_party') == -1:
        fh = open(filename, 'r')
        content = fh.read()
        match = re.search('\\bmemcpy\\b', content)
        if match:
          line_number = content[0:match.start()].count('\n') + 1
          print "%s:%d: use of memcpy is forbidden" % (filename, line_number)
          memcpy_match_count += 1

  # Report a presubmit error if any of the files had an error.
  if cpplint._cpplint_state.error_count > 0 or memcpy_match_count > 0:
    result = [output_api.PresubmitError('Failed cpplint check.')]
  return result


def CheckChangeOnUpload(input_api, output_api):
  return RunLint(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
  return RunLint(input_api, output_api)
