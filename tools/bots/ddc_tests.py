#!/usr/bin/env python
#
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import os.path
import shutil
import sys
import subprocess

import bot
import bot_utils

TARGETS = [
  'language_2',
  'corelib_2',
  'lib_2',
  # TODO(rnystrom): Remove these when all tests have been migrated out.
  'language_strong',
  'lib_strong'
]

FLAGS = [
  '--strong'
]

if __name__ == '__main__':
  with bot.BuildStep('Build SDK and dartdevc test packages'):
    bot.RunProcess([sys.executable, './tools/build.py', '--mode=release',
         '--arch=x64', 'dartdevc_test'])

  with bot.BuildStep('Run tests'):
    (bot_name, _) = bot.GetBotName()
    system = bot_utils.GetSystemFromName(bot_name)
    if system == 'linux':
      bot.RunProcess([
        'xvfb-run', sys.executable, './tools/test.py', '--strong', '-mrelease',
        '-cdartdevc', '-rchrome', '-ax64', '--report', '--time', '--checked',
        '--progress=buildbot', '--write-result-log'] + TARGETS )
    else:
      info = bot.BuildInfo('dartdevc', 'chrome', 'release', system,
          arch='x64', checked=True)
      bot.RunTest('dartdevc', info, TARGETS, flags=FLAGS)
