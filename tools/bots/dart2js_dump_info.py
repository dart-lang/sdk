#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Buildbot steps for testing dart2js with --dump-info turned on
"""
import os
import shutil
import sys
import bot
import bot_utils

utils = bot_utils.GetUtils()
HOST_OS = utils.GuessOS()

def DumpConfig(name, is_buildbot):
  """Returns info for the current buildbot.
  We only run this bot on linux, so all of this is just hard coded.
  """
  return bot.BuildInfo('none', 'none', 'release', 'linux')

def Run(args):
  print "Running: %s" % ' '.join(args)
  sys.stdout.flush()
  bot.RunProcess(args)

def DumpSteps(build_info):
  build_root = utils.GetBuildRoot(HOST_OS, mode='release', arch='ia32')
  compilations_dir = os.path.join(bot_utils.DART_DIR,
                                  build_root,
                                  'generated_compilations')
  tests = ['html', 'samples']

  with bot.BuildStep('Cleaning out old compilations'):
    print "Cleaning out %s" % compilations_dir
    shutil.rmtree(compilations_dir, ignore_errors=True)

  with utils.TempDir() as temp_dir:
    normal_compilations = os.path.join(temp_dir, 'normal')
    dump_compilations = os.path.join(temp_dir, 'dump')
    normal_compilation_command = [sys.executable, './tools/test.py',
                                  '--mode=' + build_info.mode,
                                  '-cdart2js', '-rnone'] + tests
    with bot.BuildStep('Compiling without dump info'):
      Run(normal_compilation_command)
      pass

    with bot.BuildStep('Store normal compilation artifacts'):
      args = ['mv', compilations_dir, normal_compilations]
      Run(args)

    with bot.BuildStep('Compiling with dump info'):
      args = normal_compilation_command + ['--dart2js-options=--dump-info']
      Run(args)

    with bot.BuildStep('Store normal compilation artifacts'):
      args = ['mv', compilations_dir, dump_compilations]
      Run(args)

    with bot.BuildStep('Compare outputs'):
      args = ['diff', '-rq', '-x', '*\.json',
              normal_compilations, dump_compilations]
      # Diff will return non zero and we will throw if there are any differences
      Run(args)

    with bot.BuildStep('Validate dump files'):
      # Do whatever you like :-), files are in dump_compilations
      pass

if __name__ == '__main__':
  bot.RunBot(DumpConfig, DumpSteps)

