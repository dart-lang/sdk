#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import re
import sys

import bot
import bot_utils

utils = bot_utils.GetUtils()

PACKAGES_BUILDER = r'packages-(windows|linux|mac)-(core-elements|polymer)'

def PackagesConfig(name, is_buildbot):
  packages_pattern = re.match(PACKAGES_BUILDER, name)
  if not packages_pattern:
    return None
  system = packages_pattern.group(1)
  
  return bot.BuildInfo('none', 'vm', 'release', system, checked=True)

def PackagesSteps(build_info):
  with bot.BuildStep('Testing packages'):
    bot_name, _ = bot.GetBotName()
    print bot_name

if __name__ == '__main__':
  bot.RunBot(PackagesConfig, PackagesSteps)
