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

import bot

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

  return bot.BuildInfo('none', 'vm', mode, system, checked=True, arch='x64')

def PubSteps(build_info):
  pub_location = os.path.join('third_party', 'pkg', 'pub')
  with bot.BuildStep('Running pub tests'):
    bot.RunTestRunner(build_info, pub_location)

  dartdoc_location = os.path.join('third_party', 'pkg', 'dartdoc')
  with bot.BuildStep('Running dartdoc tests'):
    bot.RunTestRunner(build_info, dartdoc_location)

if __name__ == '__main__':
  bot.RunBot(PubConfig, PubSteps)
