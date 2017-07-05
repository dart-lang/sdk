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
  'language_strong',
  'corelib_strong',
  'lib_strong'
]

FLAGS = [
  '--strong'
]

if __name__ == '__main__':
  (bot_name, _) = bot.GetBotName()
  system = bot_utils.GetSystemFromName(bot_name)
  info = bot.BuildInfo('dartdevc', 'drt', 'release', system,
      arch='x64', checked=True)
  bot.RunTest('dartdevc', info, TARGETS, flags=FLAGS)
