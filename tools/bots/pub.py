#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Pub buildbot steps.

Runs tests for pub and the pub packages that are hosted in the main Dart repo.
"""

import os
import re
import shutil
import sys

import bot
import bot_utils

utils = bot_utils.GetUtils()

BUILD_OS = utils.GuessOS()

PUB_BUILDER = r'pub-(linux|mac|win)'

def PubConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - mode: always release, we don't run pub in debug mode
  - system: "linux", "mac", or "win"
  - checked: always true
  """
  pub_pattern = re.match(PUB_BUILDER, name)
  if not pub_pattern:
    return None

  system = pub_pattern.group(1)
  mode = 'release'
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', mode, system, checked=True)

def Run(command):
  print "Running %s" % ' '.join(command)
  return bot.RunProcess(command)

def PubSteps(build_info):
  sdk_bin = os.path.join(
      bot_utils.DART_DIR,
      utils.GetBuildSdkBin(BUILD_OS, build_info.mode, build_info.arch))
  pub_script_name = 'pub.bat' if build_info.system == 'windows' else 'pub'
  pub_bin = os.path.join(sdk_bin, pub_script_name)

  pub_copy = os.path.join(utils.GetBuildRoot(BUILD_OS), 'pub_copy')
  pub_location = os.path.join('third_party', 'pkg', 'pub')

  with bot.BuildStep('Make copy of pub for testing'):
    print 'Removing old copy %s' % pub_copy
    shutil.rmtree(pub_copy, ignore_errors=True)
    print 'Copying %s to %s' % (pub_location, pub_copy)
    shutil.copytree(pub_location, pub_copy)

  # TODO(nweiz): add logic for testing pub.
  with bot.BuildStep('Doing the magic ls'):
    with utils.ChangedWorkingDirectory(pub_copy):
      Run(['ls', '-l'])

  with bot.BuildStep('Running pub'):
    Run([pub_bin, '--version'])


if __name__ == '__main__':
  bot.RunBot(PubConfig, PubSteps)
