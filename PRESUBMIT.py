# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import imp
import os
import scm
import subprocess
import tempfile

def _CheckBuildStatus(input_api, output_api):
   results = []
   status_check = input_api.canned_checks.CheckTreeIsOpen(
       input_api,
       output_api,
       json_url='http://dart-status.appspot.com/current?format=json')
   results.extend(status_check)
   return results

def _CheckDartFormat(input_api, output_api):
  local_root = input_api.change.RepositoryRoot()
  upstream = input_api.change._upstream
  utils = imp.load_source('utils',
      os.path.join(local_root, 'tools', 'utils.py'))

  prebuilt_dartfmt = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dartfmt')

  windows = utils.GuessOS() == 'win32'
  if windows:
    prebuilt_dartfmt += '.bat'

  if not os.path.isfile(prebuilt_dartfmt):
    print('WARNING: dartfmt not found: %s' % (prebuilt_dartfmt))
    return []

  def HasFormatErrors(filename=None, contents=None):
    args = [prebuilt_dartfmt, '--set-exit-if-changed']
    if contents:
      process = subprocess.Popen(args,
                                 stdout=subprocess.PIPE,
                                 stdin=subprocess.PIPE
                                 )
      out, err = process.communicate(input=contents)

      # There was a bug in the return code dartfmt returns when reading from
      # stdin so we have to check whether the content matches rather than using
      # the return code. When the next version of the dartfmt lands in the sdk
      # we can switch this line to "return process.returncode != 0"
      return out != contents
    else:
      try:
        subprocess.check_output(args + [filename, '-n'])
      except subprocess.CalledProcessError:
        return True
      return False

  unformatted_files = []
  for git_file in input_api.AffectedTextFiles():
    filename = git_file.AbsoluteLocalPath()
    if filename.endswith('.dart'):
      if HasFormatErrors(filename=filename):
        old_version_has_errors = False
        try:
          path = git_file.LocalPath()
          if windows:
            # Git expects a linux style path.
            path = path.replace(os.sep, '/')
          old_contents = scm.GIT.Capture(
            ['show', upstream + ':' + path],
            cwd=local_root,
            strip_out=False)
          if HasFormatErrors(contents=old_contents):
            old_version_has_errors = True
        except subprocess.CalledProcessError as e:
          # TODO(jacobr): verify that the error really is that the file was
          # added for this CL.
          old_version_has_errors = False

        if old_version_has_errors:
          print("WARNING: %s has existing and possibly new dartfmt issues" %
            git_file.LocalPath())
        else:
          unformatted_files.append(filename)

  if unformatted_files:
    return [output_api.PresubmitError(
        'File output does not match dartfmt.\n'
        'Fix these issues with:\n'
        '%s -w \\\n%s' % (prebuilt_dartfmt, ' \\\n'.join(unformatted_files)))]

  return []

def CheckChangeOnCommit(input_api, output_api):
  return (_CheckBuildStatus(input_api, output_api) +
          _CheckDartFormat(input_api, output_api))

def CheckChangeOnUpload(input_api, output_api):
  return _CheckDartFormat(input_api, output_api)
