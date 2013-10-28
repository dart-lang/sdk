#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import hashlib
import imp
import os
import subprocess
import sys

DART_DIR = os.path.abspath(
    os.path.normpath(os.path.join(__file__, '..', '..', '..')))

def GetUtils():
  '''Dynamically load the tools/utils.py python module.'''
  return imp.load_source('utils', os.path.join(DART_DIR, 'tools', 'utils.py'))

utils = GetUtils()

SYSTEM_RENAMES = {
  'win32': 'windows',
  'windows': 'windows',
  'win': 'windows',

  'linux': 'linux',
  'linux2': 'linux',
  'lucid32': 'linux',
  'lucid64': 'linux',

  'darwin': 'macos',
  'mac': 'macos',
  'macos': 'macos',
}

ARCH_RENAMES = {
  '32': 'ia32',
  'ia32': 'ia32',

  '64': 'x64',
  'x64': 'x64',
}

class Channel(object):
  BLEEDING_EDGE = 'be'
  DEV = 'dev'
  STABLE = 'stable'
  ALL_CHANNELS = [BLEEDING_EDGE, DEV, STABLE]

class ReleaseType(object):
  RAW = 'raw'
  SIGNED = 'signed'
  RELEASE = 'release'
  ALL_TYPES = [RAW, SIGNED, RELEASE]

class Mode(object):
  RELEASE = 'release'
  DEBUG = 'debug'
  ALL_MODES = [RELEASE, DEBUG]

class GCSNamer(object):
  """
  This class is used for naming objects in our "gs://dart-archive/"
  GoogleCloudStorage bucket. It's structure is as follows:

  For every (channel,revision,release-type) tuple we have a base path:

    gs://dart-archive/channels/{be,dev,stable}
                     /{raw,signed,release}/{revision,latest}/

  Under every base path, the following structure is used:
    - /VERSION
    - /api-docs/dart-api-docs.zip
    - /dartium/{chromedriver,content_shell,dartium}
         -{linux,macos,windows}-{ia32,x64}-release.zip
    - /sdk/dartsdk-{linux,macos,windows}-{ia32,x64}-release.zip
    - /editor/darteditor-{linux,macos,windows}-{ia32,x64}.zip
    - /editor/darteditor-installer-macos-{ia32,x64}.dmg
    - /editor-eclipse-update
         /{index.html,features/,plugins/,artifacts.jar,content.jar}
  """
  def __init__(self, channel=Channel.BLEEDING_EDGE,
      release_type=ReleaseType.RAW):
    assert channel in Channel.ALL_CHANNELS
    assert release_type in ReleaseType.ALL_TYPES

    self.channel = channel
    self.release_type = release_type
    self.bucket = 'gs://dart-archive'

  # Functions for quering complete gs:// filepaths

  def version_filepath(self, revision):
    return '%s/channels/%s/%s/%s/VERSION' % (self.bucket, self.channel,
        self.release_type, revision)

  def editor_zipfilepath(self, revision, system, arch):
    return '/'.join([self.editor_directory(revision),
      self.editor_zipfilename(system, arch)])

  def editor_installer_zipfilepath(self, revision, system, arch, extension):
    return '/'.join([self.editor_directory(revision),
      self.editor_installer_zipfilename(system, arch, extension)])

  def sdk_zipfilepath(self, revision, system, arch, mode):
    return '/'.join([self.sdk_directory(revision),
      self.sdk_zipfilename(system, arch, mode)])

  def dartium_variant_zipfilepath(self, revision, name, system, arch, mode):
    return '/'.join([self.dartium_directory(revision),
      self.dartium_variant_zipfilename(name, system, arch, mode)])

  def apidocs_zipfilepath(self, revision):
    return '/'.join([self.apidocs_directory(revision),
      self.apidocs_zipfilename()])

  # Functions for querying gs:// directories

  def dartium_directory(self, revision):
    return self._variant_directory('dartium', revision)

  def sdk_directory(self, revision):
    return self._variant_directory('sdk', revision)

  def editor_directory(self, revision):
    return self._variant_directory('editor', revision)

  def editor_eclipse_update_directory(self, revision):
    return self._variant_directory('editor-eclipse-update', revision)

  def apidocs_directory(self, revision):
    return self._variant_directory('api-docs', revision)

  def misc_directory(self, revision):
    return self._variant_directory('misc', revision)

  def _variant_directory(self, name, revision):
    return '%s/channels/%s/%s/%s/%s' % (self.bucket, self.channel,
        self.release_type, revision, name)

  # Functions for quering filenames

  def apidocs_zipfilename(self):
    return 'dart-api-docs.zip'

  def editor_zipfilename(self, system, arch):
    return 'darteditor-%s-%s.zip' % (
        SYSTEM_RENAMES[system], ARCH_RENAMES[arch])

  def editor_installer_zipfilename(self, system, arch, extension):
    assert extension in ['dmg']
    return 'darteditor-installer-%s-%s.%s' % (
        SYSTEM_RENAMES[system], ARCH_RENAMES[arch], extension)

  def sdk_zipfilename(self, system, arch, mode):
    assert mode in Mode.ALL_MODES
    return 'dartsdk-%s-%s-%s.zip' % (
        SYSTEM_RENAMES[system], ARCH_RENAMES[arch], mode)

  def dartium_variant_zipfilename(self, name, system, arch, mode):
    assert name in ['chromedriver', 'dartium', 'content_shell']
    assert mode in Mode.ALL_MODES
    return '%s-%s-%s-%s.zip' % (
        name, SYSTEM_RENAMES[system], ARCH_RENAMES[arch], mode)

def run(command, env=None, shell=False):
  print "Running command: ", command

  p = subprocess.Popen(command, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=env, shell=shell)
  (stdout, stderr) = p.communicate()
  if p.returncode != 0:
    print >> sys.stderr, "Failed to execute '%s'. Exit code: %s." % (
        command, p.returncode)
    print >> sys.stderr, "stdout: ", stdout
    print >> sys.stderr, "stderr: ", stderr
    raise Exception("Failed to execute %s." % command)

class GSUtil(object):
  GSUTIL_IS_SHELL_SCRIPT = False
  GSUTIL_PATH = None

  def _layzCalculateGSUtilPath(self):
    if not GSUtil.GSUTIL_PATH:
      buildbot_gsutil = utils.GetBuildbotGSUtilPath()
      if os.path.isfile(buildbot_gsutil):
        GSUtil.GSUTIL_IS_SHELL_SCRIPT = True
        GSUtil.GSUTIL_PATH = buildbot_gsutil
      else:
        dart_gsutil = os.path.join(DART_DIR, 'third_party', 'gsutil', 'gsutil')
        possible_locations = (list(os.environ['PATH'].split(os.pathsep))
            + [dart_gsutil])
        for directory in possible_locations:
          location = os.path.join(directory, 'gsutil')
          if os.path.isfile(location):
            GSUtil.GSUTIL_IS_SHELL_SCRIPT = False
            GSUtil.GSUTIL_PATH = location
            break
      assert GSUtil.GSUTIL_PATH

  def execute(self, gsutil_args):
    self._layzCalculateGSUtilPath()

    env = dict(os.environ)
    # If we're on the buildbot, we use a specific boto file.
    if utils.GetUserName() == 'chrome-bot':
      boto_config = {
        'linux': '/mnt/data/b/build/site_config/.boto',
        'macos': '/Volumes/data/b/build/site_config/.boto',
        'win32': r'e:\b\build\site_config\.boto',
      }[utils.GuessOS()]
      env['AWS_CREDENTIAL_FILE'] = boto_config
      env['BOTO_CONFIG'] = boto_config

    if GSUtil.GSUTIL_IS_SHELL_SCRIPT:
      gsutil_command = [GSUtil.GSUTIL_PATH]
    else:
      gsutil_command = [sys.executable, GSUtil.GSUTIL_PATH]

    run(gsutil_command + gsutil_args, env=env,
        shell=(GSUtil.GSUTIL_IS_SHELL_SCRIPT and sys.platform == 'win32'))

  def upload(self, local_path, remote_path, recursive=False, public=False):
    assert remote_path.startswith('gs://')

    args = ['cp']
    if public:
      args += ['-a', 'public-read']
    if recursive:
      args += ['-R']
    args += [local_path, remote_path]
    self.execute(args)

  def remove(self, remote_path, recursive=False):
    assert remote_path.startswith('gs://')

    args = ['rm']
    if recursive:
      args += ['-R']
    args += [remote_path]
    self.execute(args)

def CalculateChecksum(filename):
  """Calculate the MD5 checksum for filename."""

  md5 = hashlib.md5()

  with open(filename, 'rb') as f:
    data = f.read(65536)
    while len(data) > 0:
      md5.update(data)
      data = f.read(65536)

  return md5.hexdigest()

def CreateChecksumFile(filename, mangled_filename=None):
  """Create and upload an MD5 checksum file for filename."""
  if not mangled_filename:
    mangled_filename = os.path.basename(filename)

  checksum = CalculateChecksum(filename)
  checksum_filename = '%s.md5sum' % filename

  with open(checksum_filename, 'w') as f:
    f.write('%s *%s' % (checksum, mangled_filename))

  return checksum_filename
