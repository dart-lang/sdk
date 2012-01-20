# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import cpplint


class PathHackException(Exception):
  def __init__(self, error_msg):
    self.error_msg = error_msg

  def __str__(self):
    return repr(self.error_msg)


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


def TryGitPathHack(filename, parent_path):
  def CommonSubdirectory(parent, child):
    while len(child) > len(parent):
      child, tail = os.path.split(child)
      if child == parent:
        return os.path.join(parent, tail)
  if os.path.exists(os.path.join(parent_path, '.git')):
    runtime_path = CommonSubdirectory(parent_path, filename)
    if runtime_path is not None:
      fake_svn_path = os.path.join(runtime_path, '.svn')
      if os.path.exists(fake_svn_path):
        error_msg = '".svn" exists in presubmit parent subdirectory('
        error_msg += fake_svn_path
        error_msg += '). Consider removing it manually.'
        raise PathHackException(error_msg)
      # Deposit a file named ".svn" in the runtime directory to fool
      # cpplint into thinking it is the source root.
      open(fake_svn_path, 'w').close()
      return lambda: os.remove(fake_svn_path)


def RunLint(input_api, output_api):
  result = []
  cpplint._cpplint_state.ResetErrorCounts()
  # Find all .cc and .h files in the change list.
  for svn_file in input_api.AffectedTextFiles():
    filename = svn_file.AbsoluteLocalPath()
    if filename.endswith('.cc') or filename.endswith('.h'):
      cleanup = None
      parent_path = os.path.dirname(input_api.PresubmitLocalPath())
      try:
        if filename.endswith('.h'):
          cleanup = TrySvnPathHack(parent_path)
          if cleanup is None:
            cleanup = TryGitPathHack(filename, parent_path)
      except PathHackException, exception:
        return [output_api.PresubmitError(str(exception))]
      # Run cpplint on the file.
      cpplint.ProcessFile(filename, 1)
      if cleanup is not None:
        cleanup()
  # Report a presubmit error if any of the files had an error.
  if cpplint._cpplint_state.error_count > 0:
    result = [output_api.PresubmitError('Failed cpplint check.')]
  return result


def CheckChangeOnUpload(input_api, output_api):
  return RunLint(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
  return RunLint(input_api, output_api)
