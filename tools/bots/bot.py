#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Shared code for use in the buildbot scripts.
"""

import optparse
import os
from os.path import abspath
from os.path import dirname
import subprocess
import sys

import bot_utils

utils = bot_utils.GetUtils()

BUILD_OS = utils.GuessOS()

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
BUILDER_CLOBBER = 'BUILDBOT_CLOBBER'


class BuildInfo(object):
  """
  Encapsulation of build information.

  - compiler: None or 'dart2js'
  - runtime: 'd8', 'ie', 'ff', 'safari', 'chrome', 'opera', or None.
  - mode: 'debug' or 'release'.
  - system: 'linux', 'mac', or 'win7'.
  - checked: True if we should run in checked mode, otherwise False.
  - host_checked: True if we should run in host checked mode, otherwise False.
  - minified: True if we should minify the code, otherwise False
  - shard_index: The shard we are running, None when not specified.
  - total_shards: The total number of shards, None when not specified.
  - is_buildbot: True if we are on a buildbot (or emulating it).
  - test_set: Specification of a non standard test set or None.
  - csp: This is using csp when running
  - arch: The architecture to build on.
  - dart2js_full: Boolean indicating whether this builder will run dart2js
    on several different runtimes.
  - builder_tag: A tag indicating a special builder setup.
  - cps_ir: Run the compiler with the cps based backend
  """
  def __init__(self, compiler, runtime, mode, system, checked=False,
               host_checked=False, minified=False, shard_index=None,
               total_shards=None, is_buildbot=False, test_set=None,
               csp=None, arch=None, dart2js_full=False, builder_tag=None,
               batch=False, cps_ir=False):
    self.compiler = compiler
    self.runtime = runtime
    self.mode = mode
    self.system = system
    self.checked = checked
    self.host_checked = host_checked
    self.minified = minified
    self.shard_index = shard_index
    self.total_shards = total_shards
    self.is_buildbot = is_buildbot
    self.test_set = test_set
    self.csp = csp
    self.dart2js_full = dart2js_full
    self.builder_tag = builder_tag
    self.batch = batch
    self.cps_ir = cps_ir
    if (arch == None):
      self.arch = 'ia32'
    else:
      self.arch = arch

  def PrintBuildInfo(self):
    shard_description = ""
    if self.shard_index:
      shard_description = " shard %s of %s" % (self.shard_index,
                                               self.total_shards)
    print ("compiler: %s, runtime: %s mode: %s, system: %s,"
           " checked: %s, host-checked: %s, minified: %s, test-set: %s"
           " arch: %s%s"
           ) % (self.compiler, self.runtime, self.mode, self.system,
                self.checked, self.host_checked, self.minified, self.test_set,
                self.arch, shard_description)


class BuildStep(object):
  """
  A context manager for handling build steps.

  When the context manager is entered, it prints the "@@@BUILD_STEP __@@@"
  message. If it exits from an error being raised it displays the
  "@@@STEP_FAILURE@@@" message.

  If swallow_error is True, then this will catch and discard any OSError that
  is thrown. This lets you run later BuildSteps if the current one fails.
  """
  def __init__(self, name, swallow_error=False):
    self.name = name
    self.swallow_error = swallow_error

  def __enter__(self):
    print '@@@BUILD_STEP %s@@@' % self.name
    sys.stdout.flush()

  def __exit__(self, type, value, traceback):
    if value:
      print '@@@STEP_FAILURE@@@'
      sys.stdout.flush()
      if self.swallow_error and isinstance(value, OSError):
        return True


def BuildSDK(build_info):
  """
  Builds the SDK.

  - build_info: the buildInfo object, containing information about what sort of
      build and test to be run.
  """
  with BuildStep('Build SDK'):
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
            '--arch=' + build_info.arch, 'create_sdk']
    print 'Building SDK: %s' % (' '.join(args))
    RunProcess(args)


def RunBot(parse_name, custom_steps, build_step=BuildSDK):
  """
  The main function for running a buildbot.

  A buildbot script should invoke this once. The parse_name function will be
  called with the name of the buildbot and should return an instance of
  BuildInfo. This function will then set up the bot, build the SDK etc. When
  that's done, it will call custom_steps, passing in the BuildInfo object.

  In that, you can perform any bot-specific build steps.

  This function will not return. It will call sys.exit() with an appropriate
  exit code.
  """
  if len(sys.argv) == 0:
    print 'Script pathname not known, giving up.'
    sys.exit(1)

  name, is_buildbot = GetBotName()
  build_info = parse_name(name, is_buildbot)
  if not build_info:
    print 'Could not handle unfamiliar bot name "%s".' % name
    sys.exit(1)

  # Print out the buildinfo for easy debugging.
  build_info.PrintBuildInfo()

  # Make sure we are in the dart directory
  os.chdir(bot_utils.DART_DIR)

  try:
    Clobber()
    if build_step:
      build_step(build_info)

    custom_steps(build_info)
  except OSError as e:
    sys.exit(e.errno)

  sys.exit(0)


def GetBotName():
  """
  Gets the name of the current buildbot.

  Returns a tuple of the buildbot name and a flag to indicate if we are actually
  a buildbot (True), or just a user pretending to be one (False).
  """
  # For testing the bot locally, allow the user to pass in a buildbot name.
  parser = optparse.OptionParser()
  parser.add_option('-n', '--name', dest='name', help='The name of the build'
      'bot you would like to emulate (ex: vm-mac-debug)', default=None)
  args, _ = parser.parse_args()

  if args.name:
    return args.name, False

  name = os.environ.get(BUILDER_NAME)
  if not name:
    print 'Use -n $BUILDBOT_NAME for the bot you would like to emulate.'
    sys.exit(1)

  return name, True


def Clobber(force=None):
  """
  Clobbers the builder before we do the build, if appropriate.

  - mode: either 'debug' or 'release'
  """
  if os.environ.get(BUILDER_CLOBBER) != "1" and not force:
    return
  clobber_string = 'Clobber'
  if force:
    clobber_string = 'Clobber(always)'

  with BuildStep(clobber_string):
    cmd = [sys.executable,
           './tools/clean_output_directory.py']
    print 'Clobbering %s' % (' '.join(cmd))
    RunProcess(cmd)


def RunTest(name, build_info, targets, flags=None, swallow_error=False):
  """
  Runs test.py with the given settings.
  """
  if not flags:
    flags = []

  step_name = GetStepName(name, flags)
  with BuildStep(step_name, swallow_error=swallow_error):
    sys.stdout.flush()

    cmd = [
      sys.executable, os.path.join(os.curdir, 'tools', 'test.py'),
      '--step_name=' + step_name,
      '--mode=' + build_info.mode,
      '--compiler=' + build_info.compiler,
      '--runtime=' + build_info.runtime,
      '--arch=' + build_info.arch,
      '--progress=buildbot',
      '--write-result-log',
      '-v', '--time', '--use-sdk', '--report'
    ]

    if build_info.checked:
      cmd.append('--checked')

    cmd.extend(flags)
    cmd.extend(targets)

    print 'Running: %s' % (' '.join(map(lambda arg: '"%s"' % arg, cmd)))
    sys.stdout.flush()
    RunProcess(cmd)


def RunTestRunner(build_info, path):
  """
  Runs the test package's runner on the package at 'path'.
  """
  sdk_bin = os.path.join(
      bot_utils.DART_DIR,
      utils.GetBuildSdkBin(BUILD_OS, build_info.mode, build_info.arch))

  build_root = utils.GetBuildRoot(
      BUILD_OS, build_info.mode, build_info.arch)

  dart_name = 'dart.exe' if build_info.system == 'windows' else 'dart'
  dart_bin = os.path.join(sdk_bin, dart_name)

  test_bin = os.path.abspath(
      os.path.join('third_party', 'pkg', 'test', 'bin', 'test.dart'))

  with utils.ChangedWorkingDirectory(path):
    args = [dart_bin, test_bin, '--reporter', 'expanded', '--no-color']
    print("Running %s" % ' '.join(args))
    RunProcess(args)


def RunProcess(command, env=None):
  """
  Runs command.

  If a non-zero exit code is returned, raises an OSError with errno as the exit
  code.
  """
  if env is None:
    no_color_env = dict(os.environ)
  else:
    no_color_env = env
  no_color_env['TERM'] = 'nocolor'

  exit_code = subprocess.call(command, env=no_color_env)
  if exit_code != 0:
    raise OSError(exit_code)


def GetStepName(name, flags):
  """
  Filters out flags with '=' as this breaks the /stats feature of the buildbot.
  """
  flags = [x for x in flags if not '=' in x]
  return ('%s tests %s' % (name, ' '.join(flags))).strip()
