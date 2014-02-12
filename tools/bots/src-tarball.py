#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Buildbot steps for src tarball generation and debian package generation

Package up the src of the dart repo and create a debian package.
Archive tarball and debian package to google cloud storage.
"""

import re
import sys

import bot

SRC_BUILDER = r'src-tarball-linux'

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

def SrcSteps(build_info):
  with bot.BuildStep('Create src tarball'):
    args = [sys.executable, './tools/create_tarball.py']
    print 'Building src tarball'
    bot.RunProcess(args)
    print 'Building Debian packages'
    args = [sys.executable, './tools/create_debian_packages.py']
    bot.RunProcess(args)

if __name__ == '__main__':
  # We pass in None for build_step to avoid building the sdk.
  bot.RunBot(SrcConfig, SrcSteps, build_step=None)
