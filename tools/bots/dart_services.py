#!/usr/bin/python

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Buildbot steps for stress testing analysis engine
"""
import os
import shutil
import sys
import bot
import bot_utils

utils = bot_utils.GetUtils()

def ServicesConfig(name, is_buildbot):
  """Returns info for the current buildbot.
  We only run this bot on linux, so all of this is just hard coded.
  """
  return bot.BuildInfo('none', 'none', 'release', 'linux')

def Run(args):
  print "Running: %s" % ' '.join(args)
  sys.stdout.flush()
  bot.RunProcess(args)

def ServicesSteps(build_info):
  build_root = utils.GetBuildRoot('linux')
  sdk_bin = utils.GetBuildSdkBin('linux', mode='release', arch='ia32')
  dart_services = os.path.join('third_party', 'dart-services')
  dart_services_copy = os.path.join(build_root, 'dart-services')

  with bot.BuildStep('Create copy of dart_services'):
    print 'Removing existing copy of dart_services'
    shutil.rmtree(dart_services_copy, ignore_errors=True)
    args = ['cp', '-R', dart_services, dart_services_copy]
    Run(args)

  with bot.BuildStep('Fixing pubspec file'):
    pubspec = os.path.join(dart_services_copy, 'pubspec.yaml')
    # TODO(lukechurch): Actually provide the name of the alternative pubspec
    testing_pubspec = os.path.join(dart_services_copy, 'pubspec.foobar.yaml')
    print 'Fixing pubspec up for stress testing'
    # TODO(lukechurch): change to do the mv of the testing pubspec
    Run(['ls', pubspec])

  with bot.BuildStep('Run pub'):
    print 'Print running pub'
    pub = os.path.join(sdk_bin, 'pub')
    with utils.ChangedWorkingDirectory(dart_services_copy):
      args = [pub, 'get']

  with bot.BuildStep('Stress testing'):
    # Consider doing something more useful here.
    args = ['ls', 'third_party']
    Run(args)


if __name__ == '__main__':
  bot.RunBot(ServicesConfig, ServicesSteps)

