#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart frog buildbot steps

Runs tests for the frog or dart2js compiler.
"""

import platform
import optparse
import os
import re
import shutil
import subprocess
import sys

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'

DART_PATH = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DART2JS_BUILDER = (
    r'dart2js-(linux|mac|windows)-(debug|release)(-([a-z]+))?-?(\d*)-?(\d*)')
FROG_BUILDER = (
    r'(frog)-(linux|mac|windows)-(debug|release)')
WEB_BUILDER = (
    r'web-(ie|ff|safari|chrome|opera)-(win7|win8|mac|linux)-?(\d*)-?(\d*)')

NO_COLOR_ENV = dict(os.environ)
NO_COLOR_ENV['TERM'] = 'nocolor'

def GetBuildInfo():
  """Returns a tuple (compiler, runtime, mode, system, option) where:
    - compiler: 'dart2js', 'frog', or None when the builder has an
      incorrect name
    - runtime: 'd8', 'ie', 'ff', 'safari', 'chrome', 'opera'
    - mode: 'debug' or 'release'
    - system: 'linux', 'mac', or 'win7'
    - option: 'checked'
  """
  parser = optparse.OptionParser()
  parser.add_option('-n', '--name', dest='name', help='The name of the build'
      'bot you would like to emulate (ex: web-chrome-win7)', default=None)
  args, _ = parser.parse_args()

  compiler = None
  runtime = None
  mode = None
  system = None
  builder_name = os.environ.get(BUILDER_NAME)
  option = None
  shard_index = None
  total_shards = None
  if not builder_name:
    # We are not running on a buildbot.
    if args.name:
      builder_name = args.name
    else:
      print 'Use -n $BUILDBOT_NAME for the bot you would like to emulate.'
      sys.exit(1)

  if builder_name:
    dart2js_pattern = re.match(DART2JS_BUILDER, builder_name)
    frog_pattern = re.match(FROG_BUILDER, builder_name)
    web_pattern = re.match(WEB_BUILDER, builder_name)

    if dart2js_pattern:
      compiler = 'dart2js'
      runtime = 'd8'
      system = dart2js_pattern.group(1)
      mode = dart2js_pattern.group(2)
      option = dart2js_pattern.group(4)
      shard_index = dart2js_pattern.group(5)
      total_shards = dart2js_pattern.group(6)

    elif frog_pattern:
      compiler = frog_pattern.group(1)
      runtime = 'd8'
      system = frog_pattern.group(2)
      mode = frog_pattern.group(3)

    elif web_pattern:
      compiler = 'dart2js'
      runtime = web_pattern.group(1)
      system = web_pattern.group(2)
      mode = 'release'
      shard_index = web_pattern.group(3)
      total_shards = web_pattern.group(4)

  if system == 'windows':
    system = 'win7'

  if (system == 'win7' and platform.system() != 'Windows') or (
      system == 'mac' and platform.system() != 'Darwin') or (
      system == 'linux' and platform.system() != 'Linux'):
    print ('Error: You cannot emulate a buildbot with a platform different '
        'from your own.')
    sys.exit(1)
  return (compiler, runtime, mode, system, option, shard_index, total_shards)


def NeedsXterm(compiler, runtime):
  return runtime in ['ie', 'chrome', 'safari', 'opera', 'ff', 'drt']

def TestStep(name, mode, system, compiler, runtime, targets, flags):
  print '@@@BUILD_STEP %s %s tests: %s %s@@@' % (name, compiler, runtime,
      ' '.join(flags))
  sys.stdout.flush()
  if NeedsXterm(compiler, runtime) and system == 'linux':
    cmd = ['xvfb-run', '-a']
  else:
    cmd = []

  user_test = os.environ.get('USER_TEST', 'no')

  cmd.extend([sys.executable,
              os.path.join(os.curdir, 'tools', 'test.py'),
              '--mode=' + mode,
              '--compiler=' + compiler,
              '--runtime=' + runtime,
              '--time',
              '--use-sdk',
              '--report'])

  if user_test == 'yes':
    cmd.append('--progress=color')
  else:
    cmd.extend(['--progress=buildbot', '-v'])

  if flags:
    cmd.extend(flags)
  cmd.extend(targets)

  print 'running %s' % (' '.join(cmd))
  exit_code = subprocess.call(cmd, env=NO_COLOR_ENV)
  if exit_code != 0:
    print '@@@STEP_FAILURE@@@'
  return exit_code


def BuildSDK(mode, system):
  """ build the SDK.
   Args:
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', or 'win7'
  """
  # TODO(efortuna): Currently we always clobber Windows builds. The VM
  # team thinks there's a problem with dependency tracking on Windows that
  # is leading to occasional build failures. Remove when this gyp issue has
  # been ironed out.
  if system == 'win7':
    for build in ['Release_', 'Debug_']:
      for arch in ['ia32', 'x64']:
        outdir = build + arch
        shutil.rmtree(outdir, ignore_errors=True)
        shutil.rmtree('frog/%s' % outdir, ignore_errors=True)
        shutil.rmtree('runtime/%s' % outdir, ignore_errors=True)

  os.chdir(DART_PATH)

  args = [sys.executable, './tools/build.py', '--mode=' + mode, 'create_sdk']
  print 'running %s' % (' '.join(args))
  return subprocess.call(args, env=NO_COLOR_ENV)


def TestCompiler(compiler, runtime, mode, system, option, flags):
  """ test the compiler.
   Args:
     - compiler: either 'dart2js' or 'frog'
     - runtime: either 'd8', or one of the browsers, see GetBuildInfo
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', or 'win7'
     - option: 'checked'
     - flags: extra flags to pass to test.dart
  """

  # Make sure we are in the frog directory
  os.chdir(DART_PATH)

  if system.startswith('win') and runtime == 'ie':
    # There should not be more than one InternetExplorerDriver instance
    # running at a time. For details, see
    # http://code.google.com/p/selenium/wiki/InternetExplorerDriver.
    flags = flags + ['-j1']

  if system == 'linux' and runtime == 'chrome':
    # TODO(ngeoffray): We should install selenium on the buildbot.
    runtime = 'drt'

  if compiler == 'dart2js':
    if option == 'checked': flags = flags + ['--host-checked']

    if runtime == 'd8':
      # The dart2js compiler isn't self-hosted (yet) so we run its
      # unit tests on the VM. We avoid doing this on the builders
      # that run the browser tests to cut down on the cycle time.
      TestStep("dart2js_unit", mode, system, 'none', 'vm', ['leg'], flags)

    # Run the default set of test suites.
    TestStep("dart2js", mode, system, 'dart2js', runtime, [], flags)

    # TODO(kasperl): Consider running peg and css tests too.
    extras = ['leg_only', 'frog_native']
    TestStep("dart2js_extra", mode, system, 'dart2js', runtime, extras, flags)

  elif compiler == 'frog':
    TestStep("frog", mode, system, compiler, runtime, [], flags)
    extras = ['frog', 'frog_native', 'peg', 'css']
    TestStep("frog_extra", mode, system, compiler, runtime, extras, flags)

  return 0

def _DeleteFirefoxProfiles(directory):
  """Find all the firefox profiles in a particular directory and delete them."""
  for f in os.listdir(directory):
    item = os.path.join(directory, f)
    if os.path.isdir(item) and f.startswith('tmp'):
      subprocess.Popen('rm -rf %s' % item, shell=True)

def CleanUpTemporaryFiles(system, browser):
  """For some browser (selenium) tests, the browser creates a temporary profile
  on each browser session start. On Windows, generally these files are
  automatically deleted when all python processes complete. However, since our
  buildbot slave script also runs on python, we never get the opportunity to
  clear out the temp files, so we do so explicitly here. Our batch browser
  testing will make this problem occur much less frequently, but will still
  happen eventually unless we do this.

  This problem also occurs with batch tests in Firefox. For some reason selenium
  automatically deletes the temporary profiles for Firefox for one browser,
  but not multiple ones when we have many open batch tasks running. This
  behavior has not been reproduced outside of the buildbots.

  Args:
     - system: either 'linux', 'mac', or 'win7'
     - browser: one of the browsers, see GetBuildInfo
  """
  if system == 'win7':
    shutil.rmtree('C:\\Users\\chrome-bot\\AppData\\Local\\Temp',
        ignore_errors=True)
  elif browser == 'ff':
    # Note: the buildbots run as root, so we can do this without requiring a
    # password. The command won't actually work on regular machines without
    # root permissions.
    _DeleteFirefoxProfiles('/tmp')
    _DeleteFirefoxProfiles('/var/tmp')

def main():
  print '@@@BUILD_STEP build sdk@@@'

  if len(sys.argv) == 0:
    print 'Script pathname not known, giving up.'
    return 1

  compiler, runtime, mode, system, option, shard_index, total_shards = (
      GetBuildInfo())
  shard_description = ""
  if shard_index:
    shard_description = " shard %s of %s" % (shard_index, total_shards)
  print "compiler: %s, runtime: %s mode: %s, system: %s, option: %s%s" % (
      compiler, runtime, mode, system, option, shard_description)
  if compiler is None:
    return 1

  status = BuildSDK(mode, system)
  if status != 0:
    print '@@@STEP_FAILURE@@@'
    return status

  test_flags = []
  if shard_index:
    test_flags = ['--shards=%s' % total_shards, '--shard=%s' % shard_index]

  # First we run all the regular tests.
  status = TestCompiler(compiler, runtime, mode, system, option, test_flags)

  # We only run checked mode tests when the host is not in checked mode.
  if status == 0 and option != 'checked' and runtime == 'd8':
    status = TestCompiler(compiler, runtime, mode, system, option,
                          test_flags + ['--checked'])

  if runtime != 'd8': CleanUpTemporaryFiles(system, runtime)
  if status != 0: print '@@@STEP_FAILURE@@@'
  return status

if __name__ == '__main__':
  sys.exit(main())
