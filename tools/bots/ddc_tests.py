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

utils = bot_utils.GetUtils()

BUILD_OS = utils.GuessOS()

(bot_name, _) = bot.GetBotName()
CHANNEL = bot_utils.GetChannelFromName(bot_name)

if __name__ == '__main__':
  with utils.ChangedWorkingDirectory('pkg/dev_compiler'):
    with bot.BuildStep('npm install'):
      bot.RunProcess(['npm', 'install'])

    with bot.BuildStep('Compile tests and run unit tests'):
      bot.RunProcess([utils.CheckedInSdkExecutable(), 'test/all_tests.dart'])

    with bot.BuildStep('Execute compiled tests'):
      bot.RunProcess(['npm', 'test'])
