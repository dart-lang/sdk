#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""
Android buildbot steps.
"""

import os
import os.path
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
        # TODO(vsm): A temporary hack until we figure out why incremental builds are
        # broken on Android.
        if os.path.exists('./out/lastHooksTargetOS.txt'):
            os.remove('./out/lastHooksTargetOS.txt')
        targets = ['runtime']
        args = [
            sys.executable, './tools/build.py', '--arch=' + build_info.arch,
            '--mode=' + build_info.mode, '--os=android'
        ] + targets
        print 'Building Android: %s' % (' '.join(args))
        bot.RunProcess(args)


if __name__ == '__main__':
    bot.RunBot(AndroidConfig, AndroidSteps, build_step=BuildAndroid)
