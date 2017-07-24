# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import imp
import os
import os.path
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

def _CheckNewTests(input_api, output_api):
  testsDirectories = [
      #    Dart 1 tests                DDC tests
      # =================       ==========================
      ("tests/language/",       "tests/language_2/"),
      ("tests/corelib/",        "tests/corelib_2/"),
      ("tests/lib/",            "tests/lib_2/"),
      ("tests/html/",           "tests/lib_2/html/"),
  ]

  result = []
  # Tuples of (new Dart 1 test path, expected DDC test path)
  dart1TestsAdded = []
  # Tuples of (original Dart test path, expected DDC test path)
  ddcTestsExists = []
  for f in input_api.AffectedFiles():
    for oldPath, newPath in testsDirectories:
      if f.LocalPath().startswith(oldPath):
        if f.Action() == 'A':
          # Compute where the new test should live.
          ddcTestPath = f.LocalPath().replace(oldPath, newPath)
          dart1TestsAdded.append((f.LocalPath(), ddcTestPath))
        elif f.Action() == 'M':
          # Find all modified tests in Dart 1.0
          filename = f.LocalPath()
          for oldPath, newPath in testsDirectories:
            if filename.find(oldPath) == 0:
              ddcTestFilePathAbs = "%s" % \
                  f.AbsoluteLocalPath().replace(oldPath, newPath)
              if os.path.isfile(ddcTestFilePathAbs):
                #originalDart1Test.append(f.LocalPath())
                ddcTestsExists.append((f.LocalPath(),
                    f.LocalPath().replace(oldPath, newPath)))

  # Does a Dart 2.0 DDC test exist if so it must be changed too.
  missingDDCTestsChange = []
  for (dartTest, ddcTest) in ddcTestsExists:
    foundDDCTestModified = False
    for f in input_api.AffectedFiles():
      if f.LocalPath() == ddcTest:
        # Found corresponding DDC test - great.
        foundDDCTestModified = True
        break
    if not foundDDCTestModified:
      # Add the tuple (dart 1 test path, DDC test path)
      missingDDCTestsChange.append((dartTest, ddcTest))

  if missingDDCTestsChange:
    errorList = []
    for idx, (orginalTest, ddcTest) in enumerate(missingDDCTestsChange):
      errorList.append(
          '%s. Dart 1.0 test changed: %s\n%s. DDC  test must change: ' \
          '%s\n' % (idx + 1, orginalTest, idx + 1, ddcTest))
    result.append(output_api.PresubmitError(
        'Error: If you change a Dart 1.0 test, you must also update the DDC '
        'test:\n%s' % ''.join(errorList)))

  if dart1TestsAdded:
    errorList = []
    for idx, (oldTestPath, newTestPath) in enumerate(dart1TestsAdded):
      errorList.append('%s. New Dart 1.0  test: %s\n'
          '%s. Should be DDC test: %s\n' % \
          (idx + 1, oldTestPath, idx + 1, newTestPath))
    result.append(output_api.PresubmitError(
        'Error: New Dart 1.0 test can not be added the test must be added as '
        'a DDC test:\n'
        'Fix tests:\n%s' % ''.join(errorList)))

  return result

def CheckChangeOnCommit(input_api, output_api):
  return (_CheckBuildStatus(input_api, output_api) +
          _CheckNewTests(input_api, output_api) +
          _CheckDartFormat(input_api, output_api))

def CheckChangeOnUpload(input_api, output_api):
  return (_CheckNewTests(input_api, output_api) +
          _CheckDartFormat(input_api, output_api))
