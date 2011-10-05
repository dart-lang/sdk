# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import cpplint
import os

def RunLint(input_api, output_api):
  result = []
  cpplint._cpplint_state.ResetErrorCounts()
  # Find all .cc and .h files in the change list.
  for svn_file in input_api.AffectedTextFiles():
    filename = svn_file.AbsoluteLocalPath()
    if filename.endswith('.cc') or filename.endswith('.h'):
      hacked_parent_svn = 0
      if filename.endswith('.h'):
        parent_path = os.path.dirname(input_api.PresubmitLocalPath())
        orig_path = os.path.join(parent_path, '.svn')
        renamed_path = os.path.join(parent_path, '.svn_orig')
        if (os.path.exists(renamed_path)):
          error_msg = '".svn_orig" exists in presubmit parent directory('
          error_msg += parent_path
          error_msg += '). Consider renaming it manually to ".svn".'
          result = [output_api.PresubmitError(error_msg)]
          return result
        if (os.path.exists(orig_path)):
          # Make the parent SVN directory non-discoverable by cpplint to get
          # the correct header guard checks. This is needed if using all Dart
          # checkout.
          os.rename(orig_path, renamed_path)
          hacked_parent_svn = 1
      # Run cpplint on the file.
      cpplint.ProcessFile(filename, 1)
      if hacked_parent_svn != 0:
        # Undo hacks from above: Restore the original name.
        os.rename(renamed_path, orig_path)
  # Report a presubmit error if any of the files had an error.
  if cpplint._cpplint_state.error_count > 0:
    result = [output_api.PresubmitError('Failed cpplint check.')]
  return result

def CheckChangeOnUpload(input_api, output_api):
  return RunLint(input_api, output_api)

def CheckChangeOnCommit(input_api, output_api):
  return RunLint(input_api, output_api)
