#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Chromium buildbot steps

Run the Dart layout tests.
"""

import os
import platform
import re
import shutil
import socket
import subprocess
import sys
import imp

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
REVISION = 'BUILDBOT_REVISION'
BUILDER_PATTERN = (r'^dartium-(mac|lucid64|lucid32|win)'
                   r'-(full|inc|debug)(-ninja)?(-(be|dev|stable|integration))?$')

if platform.system() == 'Windows':
  GSUTIL = 'e:/b/build/scripts/slave/gsutil.bat'
else:
  GSUTIL = '/b/build/scripts/slave/gsutil'
ACL = 'public-read'
GS_SITE = 'gs://'
GS_URL = 'https://sandbox.google.com/storage/'
GS_DIR = 'dartium-archive'
LATEST = 'latest'
CONTINUOUS = 'continuous'

REVISION_FILE = 'chrome/browser/ui/webui/dartvm_revision.h'

# Add dartium tools and build/util to python path.
SRC_PATH = os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DART_PATH = os.path.join(SRC_PATH, 'dart')
TOOLS_PATH = os.path.join(DART_PATH, 'tools', 'dartium')
BUILD_UTIL_PATH = os.path.join(SRC_PATH, 'build', 'util')
# We limit testing on drt since it takes a long time to run
DRT_FILTER = 'html'


sys.path.extend([TOOLS_PATH, BUILD_UTIL_PATH])
import archive
import utils

bot_utils = imp.load_source('bot_utils',
    os.path.join(DART_PATH, 'tools', 'bots', 'bot_utils.py'))

def DartArchiveFile(local_path, remote_path, create_md5sum=False):
  # Copy it to the new unified gs://dart-archive bucket
  # TODO(kustermann/ricow): Remove all the old archiving code, once everything
  # points to the new location
  gsutil = bot_utils.GSUtil()
  gsutil.upload(local_path, remote_path, public=True)
  if create_md5sum:
    # 'local_path' may have a different filename than 'remote_path'. So we need
    # to make sure the *.md5sum file contains the correct name.
    assert '/' in remote_path and not remote_path.endswith('/')
    mangled_filename = remote_path[remote_path.rfind('/') + 1:]
    local_md5sum = bot_utils.CreateChecksumFile(local_path, mangled_filename)
    gsutil.upload(local_md5sum, remote_path + '.md5sum', public=True)

def UploadDartiumVariant(revision, name, channel, arch, mode, zip_file):
  name = name.replace('drt', 'content_shell')
  system = sys.platform

  namer = bot_utils.GCSNamer(channel, bot_utils.ReleaseType.RAW)
  remote_path = namer.dartium_variant_zipfilepath(revision, name, system, arch,
      mode)
  DartArchiveFile(zip_file, remote_path, create_md5sum=True)
  return remote_path

def ExecuteCommand(cmd):
  """Execute a command in a subprocess.
  """
  print 'Executing: ' + ' '.join(cmd)
  try:
    pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (output, error) = pipe.communicate()
    if pipe.returncode != 0:
      print 'Execution failed: ' + str(error)
    return (pipe.returncode, output)
  except:
    import traceback
    print 'Execution raised exception:', traceback.format_exc()
    return (-1, '')


# TODO: Instead of returning a tuple we should make a class with these fields.
def GetBuildInfo():
  """Returns a tuple (name, dart_revision, version, mode, arch, channel,
     is_full) where:
    - name: A name for the build - the buildbot host if a buildbot.
    - dart_revision: The dart revision.
    - version: A version string corresponding to this build.
    - mode: 'Debug' or 'Release'
    - arch: target architecture
    - channel: the channel this build is happening on
    - is_full: True if this is a full build.
  """
  os.chdir(SRC_PATH)

  name = None
  version = None
  mode = 'Release'

  # Populate via builder environment variables.
  name = os.environ[BUILDER_NAME]

  # We need to chdir() to src/dart in order to get the correct revision number.
  with utils.ChangedWorkingDirectory(DART_PATH):
    dart_tools_utils = imp.load_source('dart_tools_utils',
                                       os.path.join('tools', 'utils.py'))
    dart_revision = dart_tools_utils.GetSVNRevision()

  version = dart_revision + '.0'
  is_incremental = '-inc' in name
  is_win_ninja = 'win-inc-ninja' in name
  is_full = False

  pattern = re.match(BUILDER_PATTERN, name)
  assert pattern
  arch = 'x64' if pattern.group(1) == 'lucid64' else 'ia32'
  if pattern.group(2) == 'debug':
    mode = 'Debug'
  is_full = pattern.group(2) == 'full'
  channel = pattern.group(5)
  if not channel:
    channel = 'be'

  # Fall back if not on builder.
  if not name:
    name = socket.gethostname().split('.')[0]

  return (name, dart_revision, version, mode, arch, channel, is_full,
          is_incremental, is_win_ninja)


def RunDartTests(mode, component, suite, arch, checked, test_filter=None,
                 is_win_ninja=False):
  """Runs the Dart WebKit Layout tests.
  """
  cmd = [sys.executable]
  script = os.path.join(TOOLS_PATH, 'test.py')
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


def UploadDartTestsResults(layout_test_results_dir, name, version,
                           component, checked):
  """Uploads test results to google storage.
  """
  print ('@@@BUILD_STEP archive %s_layout_%s_tests results@@@' %
         (component, checked))
  dir_name = os.path.dirname(layout_test_results_dir)
  base_name = os.path.basename(layout_test_results_dir)
  cwd = os.getcwd()
  os.chdir(dir_name)

  archive_name = 'layout_test_results.zip'
  archive.ZipDir(archive_name, base_name)

  target = '/'.join([GS_DIR, 'layout-test-results', name, component + '-' +
                     checked + '-' + version + '.zip'])
  status = UploadArchive(os.path.abspath(archive_name), GS_SITE + target)
  os.remove(archive_name)
  if status == 0:
    print ('@@@STEP_LINK@download@' + GS_URL + target + '@@@')
  else:
    print '@@@STEP_FAILURE@@@'
  os.chdir(cwd)


def ListArchives(pattern):
  """List the contents in Google storage matching the file pattern.
  """
  cmd = [GSUTIL, 'ls', pattern]
  (status, output) = ExecuteCommand(cmd)
  if status != 0:
    return []
  return output.split(os.linesep)


def RemoveArchives(archives):
  """Remove the list of archives in Google storage.
  """
  for archive in archives:
    if archive.find(GS_SITE) == 0:
      cmd = [GSUTIL, 'rm', archive.rstrip()]
      (status, _) = ExecuteCommand(cmd)
      if status != 0:
        return status
  return 0


def UploadArchive(source, target):
  """Upload an archive zip file to Google storage.
  """

  # Upload file.
  cmd = [GSUTIL, 'cp', source, target]
  (status, output) = ExecuteCommand(cmd)
  if status != 0:
    return status
  print 'Uploaded: ' + output

  # Set ACL.
  if ACL is not None:
    cmd = [GSUTIL, 'setacl', ACL, target]
    (status, output) = ExecuteCommand(cmd)
  return status


def main():
  (dartium_bucket, dart_revision, version, mode, arch, channel,
   is_full, is_incremental, is_win_ninja) = GetBuildInfo()
  drt_bucket = dartium_bucket.replace('dartium', 'drt')
  chromedriver_bucket = dartium_bucket.replace('dartium', 'chromedriver')

  def archiveAndUpload(archive_latest=False):
    print '@@@BUILD_STEP dartium_generate_archive@@@'
    cwd = os.getcwd()
    dartium_archive = dartium_bucket + '-' + version
    drt_archive = drt_bucket + '-' + version
    chromedriver_archive = chromedriver_bucket + '-' + version
    dartium_zip, drt_zip, chromedriver_zip = \
        archive.Archive(SRC_PATH, mode, dartium_archive,
                        drt_archive, chromedriver_archive,
                        is_win_ninja=is_win_ninja)
    status = upload('dartium', dartium_bucket, os.path.abspath(dartium_zip),
                    archive_latest=archive_latest)
    if status == 0:
      status = upload('drt', drt_bucket, os.path.abspath(drt_zip),
                      archive_latest=archive_latest)
    if status == 0:
      status = upload('chromedriver', chromedriver_bucket,
                      os.path.abspath(chromedriver_zip),
                      archive_latest=archive_latest)
    os.chdir(cwd)
    if status != 0:
      print '@@@STEP_FAILURE@@@'
    return status

  def upload(module, bucket, zip_file, archive_latest=False):
    status = 0

    # We archive to the new location on all builders except for -inc builders.
    if not is_incremental:
      print '@@@BUILD_STEP %s_upload_archive_new @@@' % module
      # We archive the full builds to gs://dart-archive/
      revision = 'latest' if archive_latest else dart_revision
      remote_path = UploadDartiumVariant(revision, module, channel, arch,
          mode.lower(), zip_file)
      print '@@@STEP_LINK@download@' + remote_path + '@@@'

    # We archive to the old locations only for bleeding_edge builders
    if channel == 'be':
      _, filename = os.path.split(zip_file)
      if not archive_latest:
        target = '/'.join([GS_DIR, bucket, filename])
        print '@@@BUILD_STEP %s_upload_archive@@@' % module
        status = UploadArchive(zip_file, GS_SITE + target)
        print '@@@STEP_LINK@download@' + GS_URL + target + '@@@'
      else:
        print '@@@BUILD_STEP %s_upload_latest@@@' % module
        # Clear latest for this build type.
        old = '/'.join([GS_DIR, LATEST, bucket + '-*'])
        old_archives = ListArchives(GS_SITE + old)

        # Upload the new latest and remove unnecessary old ones.
        target = GS_SITE + '/'.join([GS_DIR, LATEST, filename])
        status = UploadArchive(zip_file, target)
        if status == 0:
          RemoveArchives(
              [iarch for iarch in old_archives if iarch != target])
        else:
          print 'Upload failed'

        # Upload unversioned name to continuous site for incremental
        # builds.
        if '-inc' in bucket:
          continuous_name = bucket[:bucket.find('-inc')]
          target = GS_SITE + '/'.join([GS_DIR, CONTINUOUS,
                                       continuous_name + '.zip'])
          status = UploadArchive(zip_file, target)

      print ('@@@BUILD_STEP %s_upload_archive is over (status = %s)@@@' %
          (module, status))

    return status

  def test(component, suite, checked, test_filter=None):
    """Test a particular component (e.g., dartium or frog).
    """
    print '@@@BUILD_STEP %s_%s_%s_tests@@@' % (component, suite, checked)
    sys.stdout.flush()
    layout_test_results_dir = os.path.join(SRC_PATH, 'webkit', mode,
                                           'layout-test-results')
    shutil.rmtree(layout_test_results_dir, ignore_errors=True)
    status = RunDartTests(mode, component, suite, arch, checked,
                          test_filter=test_filter, is_win_ninja=is_win_ninja)

    if suite == 'layout' and status != 0:
      UploadDartTestsResults(layout_test_results_dir, dartium_bucket, version,
                             component, checked)
    return status

  result = 0

  # Archive to the revision bucket unless integration build
  if channel != 'integration':
    result = archiveAndUpload(archive_latest=False)

    # On dev/stable we archive to the latest bucket as well
    if channel != 'be':
      result = archiveAndUpload(archive_latest=True) or result

  # Run layout tests
  if mode == 'Release' or platform.system() != 'Darwin':
    result = test('drt', 'layout', 'unchecked') or result
    result = test('drt', 'layout', 'checked') or result

  # Run dartium tests
  result = test('dartium', 'core', 'unchecked') or result
  result = test('dartium', 'core', 'checked') or result

  # Run ContentShell tests
  # NOTE: We don't run ContentShell tests on dartium-*-inc builders to keep
  # cycle times down.
  if not is_incremental:
    # If we run all checked tests on dartium, we restrict the number of
    # unchecked tests on drt to DRT_FILTER
    result = test('drt', 'core', 'unchecked', test_filter=DRT_FILTER) or result
    result = test('drt', 'core', 'checked') or result

  # On the 'be' channel, we only archive to the latest bucket if all tests ran
  # successfull.
  if result == 0 and channel == 'be':
    result = archiveAndUpload(archive_latest=True) or result

if __name__ == '__main__':
  sys.exit(main())
