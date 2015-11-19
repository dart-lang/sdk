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

PKG_BUILDER = r'pkg-(linux|mac|win)(-(russian))?(-(debug))?'

def PkgConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - mode: "debug", "release"
  - system: "linux", "mac", or "win"
  """
  pkg_pattern = re.match(PKG_BUILDER, name)
  if not pkg_pattern:
    return None

  system = pkg_pattern.group(1)
  locale = pkg_pattern.group(3)
  mode = pkg_pattern.group(5) or 'release'
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', mode, system, checked=True,
                       builder_tag=locale)

def PkgSteps(build_info):
  common_args = ['--write-test-outcome-log']
  if build_info.builder_tag:
    common_args.append('--builder-tag=%s' % build_info.builder_tag)

  # There are a number of big/integration tests in pkg, run with bigger timeout
  timeout = 300 if build_info.mode == 'debug' else 120
  common_args.append('--timeout=%s' % timeout)
  # We have some unreproducible vm crashes on these bots
  common_args.append('--copy-coredumps')

  # We are seeing issues with pub get calls on the windows bots.
  # Experiment with not running concurrent calls.
  if build_info.system == 'windows':
    common_args.append('-j1')

  bot.RunTest('pkg', build_info,
              common_args + ['pkg', 'docs'],
              swallow_error=True)

  # Pkg tests currently have a lot of timeouts when run in debug mode.
  # See issue 18479
  if build_info.mode != 'release': return

  with bot.BuildStep('third_party pkg tests', swallow_error=True):
    pkg_tested = os.path.join('third_party', 'pkg_tested')
    for entry in os.listdir(pkg_tested):
      path = os.path.join(pkg_tested, entry)
      if os.path.isdir(path): bot.RunTestRunner(build_info, path)

  pkgbuild_build_info = bot.BuildInfo('none', 'vm', build_info.mode,
                                      build_info.system, checked=False)
  bot.RunTest('pkgbuild_repo_pkgs', pkgbuild_build_info,
              common_args + ['--append_logs', '--use-repository-packages',
                             'pkgbuild'],
              swallow_error=True)

  public_args = (common_args +
                 ['--append_logs', '--use-public-packages', 'pkgbuild'])
  bot.RunTest('pkgbuild_public_pkgs', pkgbuild_build_info, public_args)

if __name__ == '__main__':
  bot.RunBot(PkgConfig, PkgSteps)
