#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import hashlib
import imp
import os
import platform
import string
import subprocess
import sys

DART_DIR = os.path.abspath(
    os.path.normpath(os.path.join(__file__, '..', '..', '..')))


def GetUtils():
    '''Dynamically load the tools/utils.py python module.'''
    return imp.load_source('utils', os.path.join(DART_DIR, 'tools', 'utils.py'))


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
    'ia32': 'ia32',
    'x64': 'x64',
    'arm': 'arm',
    'arm64': 'arm64',
}


class Channel(object):
    BETA = 'beta'
    BLEEDING_EDGE = 'be'
    DEV = 'dev'
    STABLE = 'stable'
    TRY = 'try'
    INTEGRATION = 'integration'
    ALL_CHANNELS = [BETA, BLEEDING_EDGE, DEV, STABLE, TRY, INTEGRATION]


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

    gs://dart-archive/channels/{be,beta,dev,stable,try,integration}
                     /{raw,signed,release}/{revision,latest}/

  Under every base path, the following structure is used:
    - /VERSION
    - /api-docs/dartdocs-gen-api.zip
    - /sdk/dartsdk-{linux,macos,windows}-{ia32,x64}-release.zip
  """

    def __init__(self,
                 channel=Channel.BLEEDING_EDGE,
                 release_type=ReleaseType.RAW,
                 internal=False):
        assert channel in Channel.ALL_CHANNELS
        assert release_type in ReleaseType.ALL_TYPES

        self.channel = channel
        self.release_type = release_type
        if internal:
            self.bucket = 'gs://dart-archive-internal'
        else:
            self.bucket = 'gs://dart-archive'

    # Functions for quering complete gs:// filepaths

    def version_filepath(self, revision):
        return '%s/channels/%s/%s/%s/VERSION' % (self.bucket, self.channel,
                                                 self.release_type, revision)

    def sdk_zipfilepath(self, revision, system, arch, mode):
        return '/'.join([
            self.sdk_directory(revision),
            self.sdk_zipfilename(system, arch, mode)
        ])

    def unstripped_filepath(self, revision, system, arch):
        return '/'.join([
            self._variant_directory('unstripped', revision), system, arch,
            self.unstripped_filename(system)
        ])

    def apidocs_zipfilepath(self, revision):
        return '/'.join(
            [self.apidocs_directory(revision),
             self.dartdocs_zipfilename()])

    # Functions for querying gs:// directories

    def base_directory(self, revision):
        return '%s/channels/%s/%s/%s' % (self.bucket, self.channel,
                                         self.release_type, revision)

    def sdk_directory(self, revision):
        return self._variant_directory('sdk', revision)

    def linux_packages_directory(self, revision):
        return '/'.join([self._variant_directory('linux_packages', revision)])

    def src_directory(self, revision):
        return self._variant_directory('src', revision)

    def apidocs_directory(self, revision):
        return self._variant_directory('api-docs', revision)

    def misc_directory(self, revision):
        return self._variant_directory('misc', revision)

    def _variant_directory(self, name, revision):
        return '%s/%s' % (self.base_directory(revision), name)

    # Functions for quering filenames

    def dartdocs_zipfilename(self):
        return 'dartdocs-gen-api.zip'

    def sdk_zipfilename(self, system, arch, mode):
        assert mode in Mode.ALL_MODES
        return 'dartsdk-%s-%s-%s.zip' % (SYSTEM_RENAMES[system],
                                         ARCH_RENAMES[arch], mode)

    def unstripped_filename(self, system):
        return 'dart.exe' if system.startswith('win') else 'dart'


class GCSNamerApiDocs(object):

    def __init__(self, channel=Channel.BLEEDING_EDGE):
        assert channel in Channel.ALL_CHANNELS

        self.channel = channel
        self.bucket = 'gs://dartlang-api-docs'

    def dartdocs_dirpath(self, revision):
        assert len('%s' % revision) > 0
        if self.channel == Channel.BLEEDING_EDGE:
            return '%s/gen-dartdocs/builds/%s' % (self.bucket, revision)
        return '%s/gen-dartdocs/%s/%s' % (self.bucket, self.channel, revision)

    def docs_latestpath(self, revision):
        assert len('%s' % revision) > 0
        return '%s/channels/%s/latest.txt' % (self.bucket, self.channel)


def run(command, env=None, shell=False, throw_on_error=True):
    print "Running command: ", command

    p = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        shell=shell)
    (stdout, stderr) = p.communicate()
    if throw_on_error and p.returncode != 0:
        print >> sys.stderr, "Failed to execute '%s'. Exit code: %s." % (
            command, p.returncode)
        print >> sys.stderr, "stdout: ", stdout
        print >> sys.stderr, "stderr: ", stderr
        raise Exception("Failed to execute %s." % command)
    return (stdout, stderr, p.returncode)


class GSUtil(object):
    GSUTIL_PATH = None
    USE_DART_REPO_VERSION = False

    def _layzCalculateGSUtilPath(self):
        if not GSUtil.GSUTIL_PATH:
            dart_gsutil = os.path.join(DART_DIR, 'third_party', 'gsutil',
                                       'gsutil')
            if os.path.isfile(dart_gsutil):
                GSUtil.GSUTIL_PATH = dart_gsutil
            elif GSUtil.USE_DART_REPO_VERSION:
                raise Exception("Dart repository version of gsutil required, "
                                "but not found.")
            else:
                # We did not find gsutil, look in path
                possible_locations = list(os.environ['PATH'].split(os.pathsep))
                for directory in possible_locations:
                    location = os.path.join(directory, 'gsutil')
                    if os.path.isfile(location):
                        GSUtil.GSUTIL_PATH = location
                        break
            assert GSUtil.GSUTIL_PATH

    def execute(self, gsutil_args):
        self._layzCalculateGSUtilPath()

        gsutil_command = [sys.executable, GSUtil.GSUTIL_PATH]

        return run(gsutil_command + gsutil_args)

    def upload(self,
               local_path,
               remote_path,
               recursive=False,
               public=False,
               multithread=False):
        assert remote_path.startswith('gs://')

        if multithread:
            args = ['-m', 'cp']
        else:
            args = ['cp']
        if public:
            args += ['-a', 'public-read']
        if recursive:
            args += ['-R']
        args += [local_path, remote_path]
        self.execute(args)

    def cat(self, remote_path):
        assert remote_path.startswith('gs://')

        args = ['cat', remote_path]
        (stdout, _, _) = self.execute(args)
        return stdout

    def setGroupReadACL(self, remote_path, group):
        args = ['acl', 'ch', '-g', '%s:R' % group, remote_path]
        self.execute(args)

    def setContentType(self, remote_path, content_type):
        args = ['setmeta', '-h', 'Content-Type:%s' % content_type, remote_path]
        self.execute(args)

    def remove(self, remote_path, recursive=False):
        assert remote_path.startswith('gs://')

        args = ['rm']
        if recursive:
            args += ['-R']
        args += [remote_path]
        self.execute(args)


def CalculateMD5Checksum(filename):
    """Calculate the MD5 checksum for filename."""

    md5 = hashlib.md5()

    with open(filename, 'rb') as f:
        data = f.read(65536)
        while len(data) > 0:
            md5.update(data)
            data = f.read(65536)

    return md5.hexdigest()


def CalculateSha256Checksum(filename):
    """Calculate the sha256 checksum for filename."""

    sha = hashlib.sha256()

    with open(filename, 'rb') as f:
        data = f.read(65536)
        while len(data) > 0:
            sha.update(data)
            data = f.read(65536)

    return sha.hexdigest()


def CreateMD5ChecksumFile(filename, mangled_filename=None):
    """Create and upload an MD5 checksum file for filename."""
    if not mangled_filename:
        mangled_filename = os.path.basename(filename)

    checksum = CalculateMD5Checksum(filename)
    checksum_filename = '%s.md5sum' % filename

    with open(checksum_filename, 'w') as f:
        f.write('%s *%s' % (checksum, mangled_filename))

    print "MD5 checksum of %s is %s" % (filename, checksum)
    return checksum_filename


def CreateSha256ChecksumFile(filename, mangled_filename=None):
    """Create and upload an sha256 checksum file for filename."""
    if not mangled_filename:
        mangled_filename = os.path.basename(filename)

    checksum = CalculateSha256Checksum(filename)
    checksum_filename = '%s.sha256sum' % filename

    with open(checksum_filename, 'w') as f:
        f.write('%s *%s' % (checksum, mangled_filename))

    print "SHA256 checksum of %s is %s" % (filename, checksum)
    return checksum_filename


def GetChannelFromName(name):
    """Get the channel from the name. Bleeding edge builders don't
      have a suffix."""
    channel_name = string.split(name, '-').pop()
    if channel_name in Channel.ALL_CHANNELS:
        return channel_name
    return Channel.BLEEDING_EDGE


def GetSystemFromName(name):
    """Get the system from the name."""
    for part in string.split(name, '-'):
        if part in SYSTEM_RENAMES: return SYSTEM_RENAMES[part]

    raise ValueError(
        "Bot name '{}' does not have a system name in it.".format(name))
