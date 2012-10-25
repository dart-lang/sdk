#!/usr/bin/python

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Android buildbot steps.
"""

import re
import sys

import bot

ANDROID_BUILDER = r'vm-android-(linux|mac|win)'

def AndroidConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - mode: always "release" (for now)
  - system: "linux", "mac", or "win"
  """
  android_pattern = re.match(ANDROID_BUILDER, name)
  if not android_pattern:
    return None

  system = android_pattern.group(1)
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', 'release', system, checked=True)


def AndroidSteps(build_info):
  # TODO(efortuna): Here's where we'll run tests.
  #bot.RunTest('android', build_info, ['android'])
  pass

def BuildAndroid(build_info):
  """
  Builds the android target.

  - build_info: the buildInfo object, containing information about what sort of
      build and test to be run.
  """
  with bot.BuildStep('Build Android'):
    targets = ['dart']
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
        '--os=android ' + ' '.join(targets)]
    print 'Building Android: %s' % (' '.join(args))
    bot.RunProcess(args)

if __name__ == '__main__':
  bot.RunBot(AndroidConfig, AndroidSteps, build_step=BuildAndroid)
