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
SRC_BUILDER = r'src-tarball-linux-(debian_wheezy|ubuntu_precise)'

def SrcConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, since we only run this on linux, this is just:
  - mode: always "release"
  - system: always "linux"
  """
  src_pattern = re.match(SRC_BUILDER, name)
  if not src_pattern:
    return None
  return bot.BuildInfo('none', 'none', 'release', 'linux',
                       builder_tag=src_pattern.group(1))

def ArchiveArtifacts(tarfile, builddir, channel, linux_system):
  namer = bot_utils.GCSNamer(channel=channel)
  gsutil = bot_utils.GSUtil()
  revision = utils.GetSVNRevision()
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
      package_dir = namer.linux_packages_directory(revision, linux_system)
      remote_file = '/'.join([package_dir,
                              os.path.basename(entry)])
      gsutil.upload(full_path, remote_file, public=True)

def SrcSteps(build_info):
  # We always clobber the bot, to not leave old tarballs and packages
  # floating around the out dir.
  bot.Clobber(force=True)
  version = utils.GetVersion()
  builddir = os.path.join(bot_utils.DART_DIR,
                          utils.GetBuildDir(HOST_OS, HOST_OS),
                          'src_and_installation')
  if not os.path.exists(builddir):
    os.makedirs(builddir)
  tarfilename = 'dart-%s.tar.gz' % version
  tarfile = os.path.join(builddir, tarfilename)

  with bot.BuildStep('Create src tarball'):
    args = [sys.executable, './tools/create_tarball.py', '--tar_filename',
            tarfile]
    print 'Building src tarball'
    bot.RunProcess(args)
    print 'Building Debian packages'
    args = [sys.executable, './tools/create_debian_packages.py',
            '--tar_filename', tarfile,
            '--out_dir', builddir]
    bot.RunProcess(args)
    
  with bot.BuildStep('Upload artifacts'):
    bot_name, _ = bot.GetBotName()
    channel = bot_utils.GetChannelFromName(bot_name)
    if channel != bot_utils.Channel.BLEEDING_EDGE:
      ArchiveArtifacts(tarfile, builddir, channel, build_info.builder_tag)
    else:
      print 'Not uploading artifacts on bleeding edge'

if __name__ == '__main__':
  # We pass in None for build_step to avoid building the sdk.
  bot.RunBot(SrcConfig, SrcSteps, build_step=None)
