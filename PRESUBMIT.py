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
    if not contents:
      args += [filename, '-n']

    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stdin=subprocess.PIPE
                               )
    process.communicate(input=contents)

    # Check for exit code 1 explicitly to distinguish it from a syntax error
    # in the file (exit code 65). The repo contains many Dart files that are
    # known to have syntax errors for testing purposes and which can't be
    # parsed and formatted. Don't treat those as errors.
    return process.returncode == 1

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
    lineSep = " \\\n"
    if windows:
      lineSep = " ^\n";
    return [output_api.PresubmitError(
        'File output does not match dartfmt.\n'
        'Fix these issues with:\n'
        '%s -w%s%s' % (prebuilt_dartfmt, lineSep,
            lineSep.join(unformatted_files)))]

  return []

def _CheckNewTests(input_api, output_api):
  testsDirectories = [
      #    Dart 1 tests              Dart 2.0 tests
      # =================       ==========================
      ("tests/language/",       "tests/language_2/"),
      ("tests/corelib/",        "tests/corelib_2/"),
      ("tests/lib/",            "tests/lib_2/"),
      ("tests/html/",           "tests/lib_2/html/"),
  ]

  result = []
  # Tuples of (new Dart 1 test path, expected Dart 2.0 test path)
  dart1TestsAdded = []
  # Tuples of (original Dart test path, expected Dart 2.0 test path)
  dart2TestsExists = []
  for f in input_api.AffectedTextFiles():
    localpath = f.LocalPath()
    if not(localpath.endswith('.status')):
      for oldPath, newPath in testsDirectories:
        if localpath.startswith(oldPath):
          if f.Action() == 'A':
            # Compute where the new test should live.
            dart2TestPath = localpath.replace(oldPath, newPath)
            dart1TestsAdded.append((localpath, dart2TestPath))
          elif f.Action() == 'M':
            # Find all modified tests in Dart 1.0
            for oldPath, newPath in testsDirectories:
              if localpath.find(oldPath) == 0:
                dart2TestFilePathAbs = "%s" % \
                    f.AbsoluteLocalPath().replace(oldPath, newPath)
                if os.path.isfile(dart2TestFilePathAbs):
                  #originalDart1Test.append(localpath)
                  dart2TestsExists.append((localpath,
                      localpath.replace(oldPath, newPath)))

  # Does a Dart 2.0 test exist if so it must be changed too.
  missingDart2TestsChange = []
  for (dartTest, dart2Test) in dart2TestsExists:
    foundDart2TestModified = False
    for f in input_api.AffectedFiles():
      if f.LocalPath() == dart2Test:
        # Found corresponding Dart 2 test - great.
        foundDart2TestModified = True
        break
    if not foundDart2TestModified:
      # Add the tuple (dart 1 test path, Dart 2.0 test path)
      missingDart2TestsChange.append((dartTest, dart2Test))

  if missingDart2TestsChange:
    errorList = []
    for idx, (orginalTest, dart2Test) in enumerate(missingDart2TestsChange):
      errorList.append(
          '%s. Dart 1.0 test changed: %s\n%s. Only the Dart 2.0 test can '\
          'change: %s\n' % (idx + 1, orginalTest, idx + 1, dart2Test))
    result.append(output_api.PresubmitError(
        'Error: Changed Dart 1.0 test detected - only 1.0 status files can '\
        'change. Migrate test to Dart 2.0 tests:\n%s' % ''.join(errorList)))

  if dart1TestsAdded:
    errorList = []
    for idx, (oldTestPath, newTestPath) in enumerate(dart1TestsAdded):
      errorList.append('%s. New Dart 1.0  test: %s\n'
          '%s. Should be Dart 2.0 test: %s\n' % \
          (idx + 1, oldTestPath, idx + 1, newTestPath))
    result.append(output_api.PresubmitError(
        'Error: New Dart 1.0 test can not be added the test must be added '\
        'as a Dart 2.0 test:\nFix tests:\n%s' % ''.join(errorList)))

  return result

def CheckChangeOnCommit(input_api, output_api):
  return (_CheckBuildStatus(input_api, output_api) +
          _CheckNewTests(input_api, output_api) +
          _CheckDartFormat(input_api, output_api))

def CheckChangeOnUpload(input_api, output_api):
  return (_CheckNewTests(input_api, output_api) +
          _CheckDartFormat(input_api, output_api))
