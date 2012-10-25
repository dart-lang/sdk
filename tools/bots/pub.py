#!/usr/bin/python

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Pub buildbot steps.

Runs tests for pub and the pub packages that are hosted in the main Dart repo.
"""

import re
import sys

import bot

PUB_BUILDER = r'pub-(linux|mac|win)'

def PubConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - mode: always "release"
  - system: "linux", "mac", or "win"
  """
  pub_pattern = re.match(PUB_BUILDER, name)
  if not pub_pattern:
    return None

  system = pub_pattern.group(1)
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', 'release', system, checked=True)


def PubSteps(build_info):
  with bot.BuildStep('Build API Docs'):
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
            'api_docs']
    print 'Generating API Docs: %s' % (' '.join(args))
    bot.RunProcess(args)

  # TODO(rnystrom): Eventually test other targets here like 'utils'?
  bot.RunTest('pub', build_info, ['pub'])


if __name__ == '__main__':
  bot.RunBot(PubConfig, PubSteps)
