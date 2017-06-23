#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Buildbot steps for src tarball generation and debian package generation

Package up the src of the dart repo and create a debian package.
Archive tarball and debian package to google cloud storage.
"""

import os
import re
import sys

import bot
import bot_utils

utils = bot_utils.GetUtils()

HOST_OS = utils.GuessOS()
SRC_BUILDER = r'debianpackage-linux'

def SrcConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, since we only run this on linux, this is just:
  - mode: always "release"
  - system: always "linux"
  """
  src_pattern = re.match(SRC_BUILDER, name)
  if not src_pattern:
    return None
  return bot.BuildInfo('none', 'none', 'release', 'linux')

def ArchiveArtifacts(tarfile, builddir, channel):
  namer = bot_utils.GCSNamer(channel=channel)
  gsutil = bot_utils.GSUtil()
  revision = utils.GetArchiveVersion()
  # Archive the src tar to the src dir
  remote_tarfile = '/'.join([namer.src_directory(revision),
                             os.path.basename(tarfile)])
  gsutil.upload(tarfile, remote_tarfile, public=True)
  # Archive all files except the tar file to the linux packages dir
  for entry in os.listdir(builddir):
    full_path = os.path.join(builddir, entry)
    # We expect a flat structure, not subdirectories
    assert(os.path.isfile(full_path))
    if full_path != tarfile:
      package_dir = namer.linux_packages_directory(revision)
      remote_file = '/'.join([package_dir,
                              os.path.basename(entry)])
      gsutil.upload(full_path, remote_file, public=True)

def InstallFromDep(builddir):
  for entry in os.listdir(builddir):
    if entry.endswith("_amd64.deb"):
      path = os.path.join(builddir, entry)
      Run(['sudo', 'dpkg', '-i', path])

def UninstallDart():
  Run(['sudo', 'dpkg', '-r', 'dart'])

def CreateDartTestFile(tempdir):
  filename = os.path.join(tempdir, 'test.dart')
  with open(filename, 'w') as f:
    f.write('import "dart:collection";\n\n')
    f.write('void main() {\n')
    f.write('  print("Hello world");\n')
    f.write('}')
  return filename

def Run(args):
  print "Running: %s" % ' '.join(args)
  sys.stdout.flush()
  bot.RunProcess(args)

def TestInstallation(assume_installed=True):
  paths = ['/usr/bin/dart']
  for tool in ['dart2js', 'pub', 'dart', 'dartanalyzer']:
    paths.append(os.path.join('/usr/lib/dart/bin', tool))
  for path in paths:
    if os.path.exists(path):
      if not assume_installed:
        print 'Assumed not installed, found %s' % path
        sys.exit(1)
    else:
      if assume_installed:
        print 'Assumed installed, but could not find %s' % path
        sys.exit(1)

def SrcSteps(build_info):
  # We always clobber the bot, to not leave old tarballs and packages
  # floating around the out dir.
  bot.Clobber(force=True)

  version = utils.GetVersion()
  builddir = os.path.join(bot_utils.DART_DIR,
                          utils.GetBuildDir(HOST_OS),
                          'src_and_installation')

  if not os.path.exists(builddir):
    os.makedirs(builddir)
  tarfilename = 'dart-%s.tar.gz' % version
  tarfile = os.path.join(builddir, tarfilename)

  with bot.BuildStep('Validating linux system'):
    print 'Validating that we are on debian jessie'
    args = ['cat', '/etc/os-release']
    (stdout, stderr, exitcode) = bot_utils.run(args)
    if exitcode != 0:
      print "Could not find linux system, exiting"
      sys.exit(1)
    if not "jessie" in stdout:
      print "Trying to build debian bits but not on debian Jessie"
      print "You can't fix this, please contact whesse@"
      sys.exit(1)

  with bot.BuildStep('Create src tarball'):
    print 'Building src tarball'
    Run([sys.executable, './tools/create_tarball.py',
         '--tar_filename', tarfile])

    print 'Building Debian packages'
    Run([sys.executable, './tools/create_debian_packages.py',
         '--tar_filename', tarfile,
         '--out_dir', builddir])

  with bot.BuildStep('Sanity check installation'):
    if os.path.exists('/usr/bin/dart') or os.path.exists(
        '/usr/lib/dart/bin/dart2js'):
      print "Dart already installed, removing"
      UninstallDart()
    TestInstallation(assume_installed=False)

    InstallFromDep(builddir)
    TestInstallation(assume_installed=True)

    # We build the runtime target to get everything we need to test the
    # standalone target.
    Run([sys.executable, './tools/build.py', '-mrelease', '-ax64', 'runtime'])
    # Copy in the installed binary to avoid poluting /usr/bin (and having to
    # run as root)
    Run(['cp', '/usr/bin/dart', 'out/ReleaseX64/dart'])

    # We currently can't run the testing script on wheezy since the checked in
    # binary is built on precise, see issue 18742
    # TODO(18742): Run './tools/test.py' '-mrelease' 'standalone'

    # Sanity check dart2js and the analyzer against a hello world program
    with utils.TempDir() as temp_dir:
      test_file = CreateDartTestFile(temp_dir)
      Run(['/usr/lib/dart/bin/dart2js', test_file])
      Run(['/usr/lib/dart/bin/dartanalyzer', test_file])
      Run(['/usr/lib/dart/bin/dart', test_file])

    # Sanity check that pub can start up and print the version
    Run(['/usr/lib/dart/bin/pub', '--version'])

    UninstallDart()
    TestInstallation(assume_installed=False)

  with bot.BuildStep('Upload artifacts'):
    bot_name, _ = bot.GetBotName()
    channel = bot_utils.GetChannelFromName(bot_name)
    if channel != bot_utils.Channel.BLEEDING_EDGE:
     ArchiveArtifacts(tarfile, builddir, channel)
    else:
      print 'Not uploading artifacts on bleeding edge'

if __name__ == '__main__':
  # We pass in None for build_step to avoid building the sdk.
  bot.RunBot(SrcConfig, SrcSteps, build_step=None)
