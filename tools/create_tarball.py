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
# For building a Debian package one need to the tarball to follow the
# Debian naming rules upstream tar files.
#
#  $ mv dart-XXX.tar.gz dart_XXX.orig.tar.gz
#  $ tar xf dart_XXX.orig.tar.gz
#  $ cd dart_XXX
#  $ debuild -us -uc

import datetime
import optparse
import sys
import tarfile
from os import listdir
from os.path import join, split, abspath

import utils


HOST_OS = utils.GuessOS()
DART_DIR = abspath(join(__file__, '..', '..'))
# Flags.
verbose = False

# Name of the dart directory when unpacking the tarball.
versiondir = ''

# Ignore Git/SVN files, checked-in binaries, backup files, etc..
ignoredPaths = ['tools/testing/bin',
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
  result.add_option("--tar_filename",
                    default=None,
                    help="The output file.")

  return result

def Filter(tar_info):
  # Get the name of the file relative to the dart directory. Note the
  # name from the TarInfo does not include a leading slash.
  assert tar_info.name.startswith(DART_DIR[1:])
  original_name = tar_info.name[len(DART_DIR):]
  _, tail = split(original_name)
  if tail in ignoredDirs:
    return None
  for path in ignoredPaths:
    if original_name.startswith(path):
      return None
  for ending in ignoredEndings:
    if original_name.endswith(ending):
      return None
  # Add the dart directory name with version. Place the debian
  # directory one level over the rest which are placed in the
  # directory 'dart'. This enables building the Debian packages
  # out-of-the-box.
  tar_info.name = join(versiondir, 'dart', original_name)
  if verbose:
    print 'Adding %s as %s' % (original_name, tar_info.name)
  return tar_info

def GenerateCopyright(filename):
  with open(join(DART_DIR, 'LICENSE')) as lf:
    license_lines = lf.readlines()

  with open(filename, 'w') as f:
    f.write('Name: dart\n')
    f.write('Maintainer: Dart Team <misc@dartlang.org>\n')
    f.write('Source: https://code.google.com/p/dart/\n')
    f.write('License:\n')
    for line in license_lines:
      f.write(' %s' % line)  # Line already contains trailing \n.

def GenerateChangeLog(filename, version):
  with open(filename, 'w') as f:
    f.write('dart (%s-1) UNRELEASED; urgency=low\n' % version)
    f.write('\n')
    f.write('  * Generated file.\n')
    f.write('\n')
    f.write(' -- Dart Team <misc@dartlang.org>  %s\n' %
            datetime.datetime.utcnow().strftime('%a, %d %b %Y %X +0000'))

def GenerateSvnRevision(filename, svn_revision):
  with open(filename, 'w') as f:
    f.write(svn_revision)


def CreateTarball(tarfilename):
  global ignoredPaths  # Used for adding the output directory.
  # Generate the name of the tarfile
  version = utils.GetVersion()
  global versiondir
  versiondir = 'dart-%s' % version
  debian_dir = 'tools/linux_dist_support/debian'
  # Don't include the build directory in the tarball (ignored paths
  # are relative to DART_DIR).
  builddir = utils.GetBuildDir(HOST_OS)
  ignoredPaths.append(builddir)

  print 'Creating tarball: %s' % tarfilename
  with tarfile.open(tarfilename, mode='w:gz') as tar:
    for f in listdir(DART_DIR):
      tar.add(join(DART_DIR, f), filter=Filter)
    for f in listdir(join(DART_DIR, debian_dir)):
      tar.add(join(DART_DIR, debian_dir, f),
              arcname='%s/debian/%s' % (versiondir, f))

    with utils.TempDir() as temp_dir:
      # Generate and add debian/copyright
      copyright_file = join(temp_dir, 'copyright')
      GenerateCopyright(copyright_file)
      tar.add(copyright_file, arcname='%s/debian/copyright' % versiondir)

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

  tar_filename = options.tar_filename
  if not tar_filename:
    tar_filename = join(DART_DIR,
                        utils.GetBuildDir(HOST_OS),
                        'dart-%s.tar.gz' % utils.GetVersion())

  CreateTarball(tar_filename)

if __name__ == '__main__':
  sys.exit(Main())
