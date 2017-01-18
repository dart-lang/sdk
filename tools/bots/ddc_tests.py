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
    dart_exe = utils.CheckedInSdkExecutable()

    # These two calls mirror pkg/dev_compiler/tool/test.sh.
    bot.RunProcess([dart_exe, 'tool/build_pkgs.dart', 'test'])
    bot.RunProcess([dart_exe, 'test/all_tests.dart'])

    # These mirror pkg/dev_compiler/tool/browser_test.sh.
    bot.RunProcess(['npm', 'install'])
    bot.RunProcess(['npm', 'test'], {'CHROME_BIN': 'chrome'})
