#!/usr/bin/python

# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dartium buildbot steps

Archive dartium, content_shell, and chromedriver to the cloud storage bucket
gs://dart-archive, and run tests, including the Dart layout tests.
"""

import imp
import os
import platform
import re
import shutil
import subprocess
import sys

import dartium_bot_utils
import upload_steps
import utils

SRC_PATH = dartium_bot_utils.srcPath()
DART_PATH = os.path.join(SRC_PATH, 'dart')

# We limit testing on drt since it takes a long time to run.
DRT_FILTER = 'html'

def RunDartTests(mode, component, suite, arch, checked, test_filter=None,
                 is_win_ninja=False):
  """Runs the Dart WebKit Layout tests.
  """
  cmd = [sys.executable]
  script = os.path.join(DART_PATH, 'tools', 'dartium', 'test.py')
  cmd.append(script)
  cmd.append('--buildbot')
  cmd.append('--mode=' + mode)
  cmd.append('--component=' + component)
  cmd.append('--suite=' + suite)
  cmd.append('--arch=' + arch)
  cmd.append('--' + checked)
  cmd.append('--no-show-results')

  if is_win_ninja:
    cmd.append('--win-ninja-build')

  if test_filter:
    cmd.append('--test-filter=' + test_filter)

  status = subprocess.call(cmd)
  if status != 0:
    print '@@@STEP_FAILURE@@@'
  return status


def Test(info, component, suite, checked, test_filter=None):
  """Test a particular component (e.g., dartium or content_shell(drt)).
  """
  print '@@@BUILD_STEP %s_%s_%s_tests@@@' % (component, suite, checked)
  sys.stdout.flush()
  layout_test_results_dir = os.path.join(SRC_PATH, 'webkit', info.mode,
                                         'layout-test-results')
  shutil.rmtree(layout_test_results_dir, ignore_errors=True)
  status = RunDartTests(info.mode, component, suite, info.arch, checked,
                        test_filter=test_filter, is_win_ninja=info.is_win_ninja)
    # Archive test failures
  if suite == 'layout' and status != 0:
    upload_steps.UploadDartTestsResults(layout_test_results_dir,
                                        info.name,
                                        info.version,
                                        component, checked)
  return status


def main():
  # We need to chdir() to src/dart in order to get the correct revision number.
  with utils.ChangedWorkingDirectory(DART_PATH):
    dart_tools_utils = imp.load_source('dart_tools_utils',
                                       os.path.join('tools', 'utils.py'))
    dart_revision = dart_tools_utils.GetSVNRevision()

  version = dart_revision + '.0'
  info = upload_steps.BuildInfo(dart_revision, version)

  result = 0

  # Archive to the revision bucket unless integration build
  if info.channel != 'integration':
    result = upload_steps.ArchiveAndUpload(info, archive_latest=False)
    # On dev/stable we archive to the latest bucket as well
    if info.channel != 'be':
      result = (upload_steps.ArchiveAndUpload(info, archive_latest=True)
                or result)

  # Run layout tests
  if info.mode == 'Release' or platform.system() != 'Darwin':
    result = Test(info, 'drt', 'layout', 'unchecked') or result
    result = Test(info, 'drt', 'layout', 'checked') or result

  # Run dartium tests
  result = Test(info, 'dartium', 'core', 'unchecked') or result
  result = Test(info, 'dartium', 'core', 'checked') or result

  # Run ContentShell tests
  # NOTE: We don't run ContentShell tests on dartium-*-inc builders to keep
  # cycle times down.
  if not info.is_incremental:
    # If we run all checked tests on dartium, we restrict the number of
    # unchecked tests on drt to DRT_FILTER
    result = Test(info, 'drt', 'core', 'unchecked',
                  test_filter=DRT_FILTER) or result
    result = Test(info, 'drt', 'core', 'checked') or result

  # On the 'be' channel, we only archive to the latest bucket if all tests were
  # successful.
  if result == 0 and info.channel == 'be':
    result = upload_steps.ArchiveAndUpload(info, archive_latest=True) or result

if __name__ == '__main__':
  sys.exit(main())
