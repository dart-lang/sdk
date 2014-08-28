#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Pub buildbot steps.

Runs tests for pub and the pub packages that are hosted in the main Dart repo.
"""

import re
import sys

import bot

PUB_BUILDER = r'pub-(linux|mac|win)(-(russian))?(-(debug))?'

def PubConfig(name, is_buildbot):
  """Returns info for the current buildbot based on the name of the builder.

  Currently, this is just:
  - mode: "debug", "release"
  - system: "linux", "mac", or "win"
  """
  pub_pattern = re.match(PUB_BUILDER, name)
  if not pub_pattern:
    return None

  system = pub_pattern.group(1)
  locale = pub_pattern.group(3)
  mode = pub_pattern.group(5) or 'release'
  if system == 'win': system = 'windows'

  return bot.BuildInfo('none', 'vm', mode, system, checked=True,
                       builder_tag=locale)

def PubSteps(build_info):
  with bot.BuildStep('Build package-root'):
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
            'packages']
    print 'Building package-root: %s' % (' '.join(args))
    bot.RunProcess(args)

  common_args = ['--write-test-outcome-log']
  if build_info.builder_tag:
    common_args.append('--builder-tag=%s' % build_info.builder_tag)

  # There are a number of big/integration tests in pkg, run with bigger timeout
  common_args.append('--timeout=120')

  if build_info.system == 'windows':
    common_args.append('-j1')
  opt_threshold = '--vm-options=--optimization-counter-threshold=5'
  if build_info.mode == 'release':
    bot.RunTest('pub and pkg ', build_info,
                common_args + ['pub', 'pkg', 'docs'],
                swallow_error=True)
    bot.RunTest('pub and pkg optimization counter thresshold 5', build_info,
                common_args + ['--append_logs', opt_threshold,
                               'pub', 'pkg', 'docs'],
                swallow_error=True)
  else:
    # Pub tests currently have a lot of timeouts when run in debug mode.
    # See issue 18479
    bot.RunTest('pub and pkg', build_info, common_args + ['pkg', 'docs'],
                swallow_error=True)
    bot.RunTest('pub and pkg optimization counter threshold 5', build_info,
                common_args + ['--append_logs', opt_threshold, 'pkg', 'docs'],
                swallow_error=True)

  if build_info.mode == 'release':
    pkgbuild_build_info = bot.BuildInfo('none', 'vm', build_info.mode,
                                        build_info.system, checked=False)
    bot.RunTest('pkgbuild_repo_pkgs', pkgbuild_build_info,
                common_args + ['--append_logs', '--use-repository-packages',
                               'pkgbuild'],
                swallow_error=True)

    # We are seeing issues with pub get calls on the windows bots.
    # Experiment with not running concurrent calls.
    public_args = (common_args +
                   ['--append_logs', '--use-public-packages', 'pkgbuild'])
    bot.RunTest('pkgbuild_public_pkgs', pkgbuild_build_info, public_args)

if __name__ == '__main__':
  bot.RunBot(PubConfig, PubSteps)
