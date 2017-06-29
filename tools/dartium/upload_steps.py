#!/usr/bin/python

# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Steps to archive dartium, content_shell, and chromedriver from buildbots.

Imported by buildbot_annotated_steps.py
"""

import imp
import os
import platform
import re
import subprocess
import sys

import dartium_bot_utils
import archive

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
REVISION = 'BUILDBOT_REVISION'
BUILDER_PATTERN = (r'^(dartium)-(mac|lucid64|lucid32|win)'
    r'-(full|inc|debug)(-ninja)?(-(be|dev|stable|integration))?$')
NEW_BUILDER_PATTERN = (
    r'^dartium-(mac|linux|win)-(ia32|x64)(-inc)?-(be|dev|stable|integration)$')

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

SRC_PATH = dartium_bot_utils.srcPath()
DART_PATH = os.path.join(SRC_PATH, 'dart')

bot_utils = imp.load_source('bot_utils',
    os.path.join(DART_PATH, 'tools', 'bots', 'bot_utils.py'))

class BuildInfo(object):
  """
    name: A name for the build - the buildbot host if a buildbot.
    mode: 'Debug' or 'Release'
    arch: target architecture
    channel: the channel this build is happening on
    is_full: True if this is a full build.
    is_incremental: True if this is an incremental build.

  """
  def __init__(self, revision, version):

    self.revision = revision
    self.version = version
    self.name = os.environ[BUILDER_NAME]
    pattern = re.match(NEW_BUILDER_PATTERN, self.name)
    if pattern:
      self.arch = pattern.group(2)
      self.mode = 'Release'
      self.is_incremental = (pattern.group(3) == '-inc')
      self.is_full = not self.is_incremental
      self.channel = pattern.group(4)
    else:
      pattern = re.match(BUILDER_PATTERN, self.name)
      assert pattern
      self.arch = 'x64' if pattern.group(2) == 'lucid64' else 'ia32'
      self.mode = 'Debug' if pattern.group(3) == 'debug' else 'Release'
      self.is_incremental = '-inc' in self.name
      self.is_full = pattern.group(3) == 'full'
      self.channel = pattern.group(6) if pattern.group(6) else 'be'


def ArchiveAndUpload(info, archive_latest=False):
  print '@@@BUILD_STEP dartium_generate_archive@@@'
  cwd = os.getcwd()

  dartium_bucket = info.name
  drt_bucket = dartium_bucket.replace('dartium', 'drt')
  chromedriver_bucket = dartium_bucket.replace('dartium', 'chromedriver')
  dartium_archive = dartium_bucket + '-' + info.version
  drt_archive = drt_bucket + '-' + info.version
  chromedriver_archive = chromedriver_bucket + '-' + info.version
  dartium_zip, drt_zip, chromedriver_zip = archive.Archive(
      SRC_PATH,
      info.mode,
      dartium_archive,
      drt_archive,
      chromedriver_archive)

  status = 0
  # Upload bleeding-edge builds to old dartium-archive bucket
  if info.channel == 'be':
    status = (OldUpload('dartium', dartium_bucket,
                        os.path.abspath(dartium_zip),
                        archive_latest=archive_latest)
              or OldUpload('drt', drt_bucket,
                           os.path.abspath(drt_zip),
                           archive_latest=archive_latest)
              or OldUpload('chromedriver', chromedriver_bucket,
                           os.path.abspath(chromedriver_zip),
                           archive_latest=archive_latest))

  # Upload to new dart-archive bucket using GCSNamer, but not incremental
  # or perf builder builds.
  if not info.is_incremental:
    Upload('dartium', os.path.abspath(dartium_zip),
           info, archive_latest=archive_latest)
    Upload('drt', os.path.abspath(drt_zip),
           info, archive_latest=archive_latest)
    Upload('chromedriver', os.path.abspath(chromedriver_zip),
           info, archive_latest=archive_latest)

  os.chdir(cwd)
  if status != 0:
    print '@@@STEP_FAILURE@@@'
  return status


def OldUpload(module, bucket, zip_file, archive_latest=False):
  """Upload a zip file to the old bucket gs://dartium-archive/
  """
  # TODO(whesse): Remove the old archiving code (OldUpload, OldUploadFile,
  # and constants they use) once everything points to the new location.
  status = 0
  _, filename = os.path.split(zip_file)
  if not archive_latest:
    target = '/'.join([GS_DIR, bucket, filename])
    print '@@@BUILD_STEP %s_upload_archive_old@@@' % module
    status = OldUploadFile(zip_file, GS_SITE + target)
    print '@@@STEP_LINK@download@' + GS_URL + target + '@@@'
  else:
    print '@@@BUILD_STEP %s_upload_latest_old@@@' % module
    # Clear latest for this build type.
    old = '/'.join([GS_DIR, LATEST, bucket + '-*'])
    old_archives = ListArchives(GS_SITE + old)

    # Upload the new latest and remove unnecessary old ones.
    target = GS_SITE + '/'.join([GS_DIR, LATEST, filename])
    status = OldUploadFile(zip_file, target)
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
      status = OldUploadFile(zip_file, target)

  print ('@@@BUILD_STEP %s_upload_archive is over (status = %s)@@@' %
      (module, status))
  return status


def Upload(module, zip_file, info, archive_latest=False):
  """Upload a zip file to cloud storage bucket gs://dart-archive/
  """
  print '@@@BUILD_STEP %s_upload_archive @@@' % module
  revision = 'latest' if archive_latest else info.revision
  name = module.replace('drt', 'content_shell')
  namer = bot_utils.GCSNamer(info.channel, bot_utils.ReleaseType.RAW)
  remote_path = namer.dartium_variant_zipfilepath(revision,
                                                  name,
                                                  sys.platform,
                                                  info.arch,
                                                  info.mode.lower())
  UploadFile(zip_file, remote_path, checksum_files=True)

  print '@@@STEP_LINK@download@' + remote_path + '@@@'


def OldUploadFile(source, target):
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
    cmd = [GSUTIL, 'acl', 'set', ACL, target]
    (status, output) = ExecuteCommand(cmd)
  return status


def UploadFile(local_path, remote_path, checksum_files=False):
  # Copy it to the new unified gs://dart-archive bucket
  gsutil = bot_utils.GSUtil()
  gsutil.upload(local_path, remote_path, public=True)
  if checksum_files:
    # 'local_path' may have a different filename than 'remote_path'. So we need
    # to make sure the *.md5sum file contains the correct name.
    assert '/' in remote_path and not remote_path.endswith('/')
    mangled_filename = remote_path[remote_path.rfind('/') + 1:]
    local_md5sum = bot_utils.CreateMD5ChecksumFile(local_path,
                                                   mangled_filename)
    gsutil.upload(local_md5sum, remote_path + '.md5sum', public=True)
    local_sha256 = bot_utils.CreateSha256ChecksumFile(local_path,
                                                      mangled_filename)
    gsutil.upload(local_sha256, remote_path + '.sha256sum', public=True)

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


def UploadDartTestsResults(layout_test_results_dir, name, version,
                           component, checked):
  """Uploads test results to google storage.
  """
  print ('@@@BUILD_STEP archive %s_layout_%s_tests results@@@' %
         (component, checked))
  dir_name = os.path.dirname(layout_test_results_dir)
  base_name = os.path.basename(layout_test_results_dir)
  cwd = os.getcwd()
  try:
    os.chdir(dir_name)

    archive_name = 'layout_test_results.zip'
    archive.ZipDir(archive_name, base_name)

    target = '/'.join([GS_DIR, 'layout-test-results', name, component + '-' +
                       checked + '-' + version + '.zip'])
    status = OldUploadFile(os.path.abspath(archive_name), GS_SITE + target)
    os.remove(archive_name)
    if status == 0:
      print ('@@@STEP_LINK@download@' + GS_URL + target + '@@@')
    else:
      print '@@@STEP_FAILURE@@@'
  except:
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
