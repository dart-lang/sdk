#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Pkg buildbot steps.

Runs tests for packages that are hosted in the main Dart repo and in
third_party/pkg_tested.
"""

import os
import re
import sys

import bot

PKG_BUILDER = r'pkg-(linux|mac|win)(-(russian))?'

def PkgConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - system: "linux", "mac", or "win"
  """
  pkg_pattern = re.match(PKG_BUILDER, name)
  if not pkg_pattern:
    return None

  system = pkg_pattern.group(1)
  locale = pkg_pattern.group(3)
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', 'release', system, checked=True,
                       builder_tag=locale)

def PkgSteps(build_info):
  common_args = ['--write-test-outcome-log']
  if build_info.builder_tag:
    common_args.append('--builder-tag=%s' % build_info.builder_tag)

  # There are a number of big/integration tests in pkg, run with bigger timeout
  common_args.append('--timeout=120')
  # We have some unreproducible vm crashes on these bots
  common_args.append('--copy-coredumps')

  bot.RunTest('pkg', build_info,
              common_args + ['pkg', 'docs'],
              swallow_error=True)

  with bot.BuildStep('third_party pkg tests', swallow_error=True):
    pkg_tested = os.path.join('third_party', 'pkg_tested')
    for entry in os.listdir(pkg_tested):
      path = os.path.join(pkg_tested, entry)
      if os.path.isdir(path):
        bot.RunTestRunner(build_info, path)


if __name__ == '__main__':
  bot.RunBot(PkgConfig, PkgSteps)
