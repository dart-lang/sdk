#!/usr/bin/env python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# Script to build a tarball of the Dart source.
#
# The tarball includes all the source needed to build Dart. This
# includes source in third_party. As part of creating the tarball the
# files used to build Debian packages are copied to a top-level debian
# directory. This makes it easy to build Debian packages from the
# tarball.
#
# For building a Debian package renaming the tarball to follow the
# Debian is needed.
#
#  $ mv dart-XXX.tar.gz dart_XXX.orig.tar.gz
#  $ tar xf dart_XXX.orig.tar.gz
#  $ cd dart_XXX
#  $ debuild -us -uc

import datetime
import optparse
import sys
import tarfile
import tempfile
import utils

from os import listdir, makedirs, remove, rmdir
from os.path import basename, dirname, join, realpath, exists, isdir, split

HOST_OS = utils.GuessOS()

# TODO (16582): Remove this when the LICENSE file becomes part of
# all checkouts.
license = [
  'This license applies to all parts of Dart that are not externally',
  'maintained libraries. The external maintained libraries used by',
  'Dart are:',
  '',
  '7-Zip - in third_party/7zip',
  'JSCRE - in runtime/third_party/jscre',
  'Ant - in third_party/apache_ant',
  'args4j - in third_party/args4j',
  'bzip2 - in third_party/bzip2',
  'Commons IO - in third_party/commons-io',
  'Commons Lang in third_party/commons-lang',
  'dromaeo - in samples/third_party/dromaeo',
  'Eclipse - in third_party/eclipse',
  'gsutil - in third_party/gsutil',
  'Guava - in third_party/guava',
  'hamcrest - in third_party/hamcrest',
  'Httplib2 - in samples/third_party/httplib2',
  'JSON - in third_party/json',
  'JUnit - in third_party/junit',
  'Oauth - in samples/third_party/oauth2client',
  'weberknecht - in third_party/weberknecht',
  'fest - in third_party/fest',
  'mockito - in third_party/mockito',
  '',
  'The libraries may have their own licenses; we recommend you read them,',
  'as their terms may differ from the terms below.',
  '',
  'Copyright 2012, the Dart project authors. All rights reserved.',
  'Redistribution and use in source and binary forms, with or without',
  'modification, are permitted provided that the following conditions are',
  'met:',
  '    * Redistributions of source code must retain the above copyright',
  '      notice, this list of conditions and the following disclaimer.',
  '    * Redistributions in binary form must reproduce the above',
  '      copyright notice, this list of conditions and the following',
  '      disclaimer in the documentation and/or other materials provided',
  '      with the distribution.',
  '    * Neither the name of Google Inc. nor the names of its',
  '      contributors may be used to endorse or promote products derived',
  '      from this software without specific prior written permission.',
  'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS',
  '"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT',
  'LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR',
  'A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT',
  'OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,',
  'SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT',
  'LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,',
  'DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY',
  'THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT',
  '(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE',
  'OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'
]

# Flags.
verbose = False

# Name of the dart directory when unpacking the tarball.
versiondir = ''

# Ignore Git/SVN files, checked-in binaries, backup files, etc..
ignoredPaths = ['out', 'tools/testing/bin'
                'third_party/7zip', 'third_party/android_tools',
                'third_party/clang', 'third_party/d8',
                'third_party/firefox_jsshell']
ignoredDirs = ['.svn', '.git']
ignoredEndings = ['.mk', '.pyc', 'Makefile', '~']

def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  return result

def Filter(tar_info):
  _, tail = split(tar_info.name)
  if tail in ignoredDirs:
    return None
  for path in ignoredPaths:
    if tar_info.name.startswith(path):
      return None
  for ending in ignoredEndings:
    if tar_info.name.endswith(ending):
      return None
  # Add the dart directory name with version.
  original_name = tar_info.name
  # Place the debian directory one level over the rest which are
  # placed in the directory 'dart'. This enables building the Debian
  # packages out-of-the-box.
  tar_info.name = join(versiondir, 'dart', tar_info.name)
  if verbose:
    print 'Adding %s as %s' % (original_name, tar_info.name)
  return tar_info

def GenerateCopyright(filename):
  license_lines = license
  try:
    # Currently the LICENSE file is part of a svn-root checkout.
    lf = open('../LICENSE', 'r')
    license_lines = lf.read().splitlines()
    print license_lines
    lf.close()
  except:
    pass

  f = open(filename, 'w')
  f.write('Name: dart\n')
  f.write('Maintainer: Dart Team <misc@dartlang.org>\n')
  f.write('Source: https://code.google.com/p/dart/\n')
  f.write('License:\n')
  for line in license_lines:
    f.write(' %s\n' % line)
  f.close()

def GenerateChangeLog(filename, version):
  f = open(filename, 'w')
  f.write('dart (%s-1) UNRELEASED; urgency=low\n' % version)
  f.write('\n')
  f.write('  * Generated file.\n')
  f.write('\n')
  f.write(' -- Dart Team <misc@dartlang.org>  %s\n' %
          datetime.datetime.utcnow().strftime('%a, %d %b %Y %X +0000'))
  f.close()

def GenerateSvnRevision(filename, svn_revision):
  f = open(filename, 'w')
  f.write(svn_revision)
  f.close()


def CreateTarball():
  # Generate the name of the tarfile
  version = utils.GetVersion()
  global versiondir
  versiondir = 'dart-%s' % version
  tarname = '%s.tar.gz' % versiondir
  debian_dir = 'tools/linux_dist_support/debian'
  # Create the tar file in the out directory.
  tardir = utils.GetBuildDir(HOST_OS, HOST_OS)
  if not exists(tardir):
    makedirs(tardir)
  tarfilename = join(tardir, tarname)
  print 'Creating tarball: %s' % (tarfilename)
  with tarfile.open(tarfilename, mode='w:gz') as tar:
    for f in listdir('.'):
      tar.add(f, filter=Filter)
    for f in listdir(debian_dir):
      tar.add(join(debian_dir, f),
              arcname='%s/debian/%s' % (versiondir, f))

    with utils.TempDir() as temp_dir:
      # Generate and add debian/copyright
      copyright = join(temp_dir, 'copyright')
      GenerateCopyright(copyright)
      tar.add(copyright, arcname='%s/debian/copyright' % versiondir)

      # Generate and add debian/changelog
      change_log = join(temp_dir, 'changelog')
      GenerateChangeLog(change_log, version)
      tar.add(change_log, arcname='%s/debian/changelog' % versiondir)

      # For bleeding_edge add the SVN_REVISION file.
      if utils.GetChannel() == 'be':
        svn_revision = join(temp_dir, 'SVN_REVISION')
        GenerateSvnRevision(svn_revision, utils.GetSVNRevision())
        tar.add(svn_revision, arcname='%s/dart/tools/SVN_REVISION' % versiondir)

def Main():
  if HOST_OS != 'linux':
    print 'Tarball can only be created on linux'
    return -1

  # Parse the options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if options.verbose:
    global verbose
    verbose = True

  CreateTarball()

if __name__ == '__main__':
  sys.exit(Main())
