#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Dart2js buildbot steps

Runs tests for the  dart2js compiler.
"""

import platform
import os
import re
import shutil
import subprocess
import sys

import bot

DART2JS_BUILDER = (
    r'dart2js-(linux|mac|windows)(-(jsshell))?-(debug|release)(-(checked|host-checked))?(-(host-checked))?(-(minified))?-?(\d*)-?(\d*)')
WEB_BUILDER = (
    r'dart2js-(ie9|ie10|ff|safari|chrome|opera)-(win7|win8|mac|linux)(-(all|html))?')


def GetBuildInfo(builder_name, is_buildbot):
  """Returns a BuildInfo object for the current buildbot based on the
     name of the builder.
  """
  compiler = None
  runtime = None
  mode = None
  system = None
  checked = False
  host_checked = False
  minified = False
  shard_index = None
  total_shards = None
  test_set = None

  dart2js_pattern = re.match(DART2JS_BUILDER, builder_name)
  web_pattern = re.match(WEB_BUILDER, builder_name)

  if web_pattern:
    compiler = 'dart2js'
    runtime = web_pattern.group(1)
    system = web_pattern.group(2)
    mode = 'release'
    test_set = web_pattern.group(4)
  elif dart2js_pattern:
    compiler = 'dart2js'
    system = dart2js_pattern.group(1)
    runtime = 'd8'
    if dart2js_pattern.group(3) == 'jsshell':
      runtime = 'jsshell'
    mode = dart2js_pattern.group(4)
    # The valid naming parts for checked and host-checked are:
    # Empty: checked=False, host_checked=False
    # -checked: checked=True, host_checked=False
    # -host-checked: checked=False, host_checked=True
    # -checked-host-checked: checked=True, host_checked=True
    if dart2js_pattern.group(6) == 'checked':
      checked = True
    if dart2js_pattern.group(6) == 'host-checked':
      host_checked = True
    if dart2js_pattern.group(8) == 'host-checked':
      host_checked = True
    if dart2js_pattern.group(10) == 'minified':
      minified = True
    shard_index = dart2js_pattern.group(11)
    total_shards = dart2js_pattern.group(12)
  else :
    return None

  if system == 'windows':
    system = 'win7'

  if (system == 'win7' and platform.system() != 'Windows') or (
      system == 'mac' and platform.system() != 'Darwin') or (
      system == 'linux' and platform.system() != 'Linux'):
    print ('Error: You cannot emulate a buildbot with a platform different '
        'from your own.')
    return None

  return bot.BuildInfo(compiler, runtime, mode, system, checked, host_checked,
                       minified, shard_index, total_shards, is_buildbot,
                       test_set)


def NeedsXterm(compiler, runtime):
  return runtime in ['ie9', 'ie10', 'chrome', 'safari', 'opera', 'ff', 'drt']


def TestStepName(name, flags):
  # Filter out flags with '=' as this breaks the /stats feature of the
  # build bot.
  flags = [x for x in flags if not '=' in x]
  return ('%s tests %s' % (name, ' '.join(flags))).strip()


def TestStep(name, mode, system, compiler, runtime, targets, flags):
  step_name = TestStepName(name, flags)
  with bot.BuildStep(step_name, swallow_error=True):
    sys.stdout.flush()
    if NeedsXterm(compiler, runtime) and system == 'linux':
      cmd = ['xvfb-run', '-a']
    else:
      cmd = []

    user_test = os.environ.get('USER_TEST', 'no')

    cmd.extend([sys.executable,
                os.path.join(os.curdir, 'tools', 'test.py'),
                '--step_name=' + step_name,
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
    bot.RunProcess(cmd)


def TestCompiler(runtime, mode, system, flags, is_buildbot, test_set):
  """ test the compiler.
   Args:
     - runtime: either 'd8', 'jsshell', or one of the browsers, see GetBuildInfo
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', 'win7', or 'win8'
     - flags: extra flags to pass to test.dart
     - is_buildbot: true if we are running on a real buildbot instead of
       emulating one.
     - test_set: Specification of a non standard test set, default None
  """

  if system.startswith('win') and runtime.startswith('ie'):
    # There should not be more than one InternetExplorerDriver instance
    # running at a time. For details, see
    # http://code.google.com/p/selenium/wiki/InternetExplorerDriver.
    flags += ['-j1']

  def GetPath(runtime):
    """ Helper to get the path to the Chrome or Firefox executable for a
    particular platform on the buildbot. Throws a KeyError if runtime is not
    either 'chrome' or 'ff'."""
    if system == 'mac':
      partDict = {'chrome': 'Google\\ Chrome', 'ff': 'Firefox'}
      mac_path = '/Applications/%s.app/Contents/MacOS/%s'
      path_dict = {'chrome': mac_path % (partDict[runtime], partDict[runtime]),
          'ff': mac_path % (partDict[runtime], partDict[runtime].lower())}
    elif system == 'linux':
      path_dict = {'ff': 'firefox', 'chrome': 'google-chrome'}
    else:
      # Windows.
      path_dict = {'ff': os.path.join('C:/', 'Program Files (x86)',
          'Mozilla Firefox', 'firefox.exe'),
          'chrome': os.path.join('C:/', 'Users', 'chrome-bot', 'AppData',
          'Local', 'Google', 'Chrome', 'Application', 'chrome.exe')}
    return path_dict[runtime]

  if system == 'linux' and runtime == 'chrome':
    # TODO(ngeoffray): We should install selenium on the buildbot.
    runtime = 'drt'
  elif (runtime == 'ff' or runtime == 'chrome') and is_buildbot:
    # Print out browser version numbers if we're running on the buildbot (where
    # we know the paths to these browser installations).
    version_query_string = '"%s" --version' % GetPath(runtime)
    if runtime == 'ff' and system.startswith('win'):
      version_query_string += '| more'
    elif runtime == 'chrome' and system.startswith('win'):
      version_query_string = ('''reg query "HKCU\\Software\\Microsoft\\''' +
          '''Windows\\CurrentVersion\\Uninstall\\Google Chrome" /v Version''')
    p = subprocess.Popen(version_query_string,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, stderr = p.communicate()
    output = output.split()
    try:
      print 'Version of %s: %s' % (runtime, output[-1])
    except IndexError:
      # Failed to obtain version information. Continue running tests.
      pass

  if runtime == 'd8':
    # The dart2js compiler isn't self-hosted (yet) so we run its
    # unit tests on the VM. We avoid doing this on the builders
    # that run the browser tests to cut down on the cycle time.
    TestStep("dart2js_unit", mode, system, 'none', 'vm', ['dart2js'], flags)

  if not (system.startswith('win') and runtime.startswith('ie')):
    # Run the default set of test suites.
    TestStep("dart2js", mode, system, 'dart2js', runtime, [], flags)

    # TODO(kasperl): Consider running peg and css tests too.
    extras = ['dart2js_extra', 'dart2js_native', 'dart2js_foreign']
    TestStep("dart2js_extra", mode, system, 'dart2js', runtime, extras, flags)
  else:
    # TODO(ricow): Enable standard sharding for IE bots when we have more vms.
    if test_set == 'html':
      TestStep("dart2js", mode, system, 'dart2js', runtime, ['html'], flags)
    elif test_set == 'all':
      TestStep("dart2js", mode, system, 'dart2js', runtime, ['dartc',
          'samples', 'standalone', 'corelib', 'co19', 'language', 'isolate',
          'vm', 'json', 'benchmark_smoke', 'dartdoc', 'utils', 'pub', 'lib'],
          flags)
      extras = ['dart2js_extra', 'dart2js_native', 'dart2js_foreign']
      TestStep("dart2js_extra", mode, system, 'dart2js', runtime, extras,
               flags)


def _DeleteTempWebdriverProfiles(directory):
  """Find all the firefox profiles in a particular directory and delete them."""
  for f in os.listdir(directory):
    item = os.path.join(directory, f)
    if os.path.isdir(item) and (f.startswith('tmp') or f.startswith('opera')):
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
     - system: either 'linux', 'mac', 'win7', or 'win8'
     - browser: one of the browsers, see GetBuildInfo
  """
  if system.startswith('win'):
    shutil.rmtree('C:\\Users\\chrome-bot\\AppData\\Local\\Temp',
        ignore_errors=True)
  elif browser == 'ff' or 'opera':
    # Note: the buildbots run as root, so we can do this without requiring a
    # password. The command won't actually work on regular machines without
    # root permissions.
    _DeleteTempWebdriverProfiles('/tmp')
    _DeleteTempWebdriverProfiles('/var/tmp')


def GetHasHardCodedCheckedMode(build_info):
  # TODO(ricow): We currently run checked mode tests on chrome on linux and
  # on the slow (all) IE windows bots. This is a hack and we should use the
  # normal sharding and checked splitting functionality when we get more
  # vms for testing this.
  if (build_info.system == 'linux' and build_info.runtime == 'chrome'):
    return True
  if build_info.runtime.startswith('ie') and build_info.test_set == 'all':
    return True
  return False


def RunCompilerTests(build_info):
  test_flags = []
  if build_info.shard_index:
    test_flags = ['--shards=%s' % build_info.total_shards,
                  '--shard=%s' % build_info.shard_index]

  if build_info.checked: test_flags += ['--checked']

  if build_info.host_checked: test_flags += ['--host-checked']

  if build_info.minified: test_flags += ['--minified']

  TestCompiler(build_info.runtime, build_info.mode, build_info.system,
               list(test_flags), build_info.is_buildbot, build_info.test_set)

  # See comment in GetHasHardCodedCheckedMode, this is a hack.
  if (GetHasHardCodedCheckedMode(build_info)):
    TestCompiler(build_info.runtime, build_info.mode, build_info.system,
                 test_flags + ['--checked'], build_info.is_buildbot,
                 build_info.test_set)

  if build_info.runtime != 'd8':
    CleanUpTemporaryFiles(build_info.system, build_info.runtime)


def BuildCompiler(build_info):
  """
  Builds the SDK.

  - build_info: the buildInfo object, containing information about what sort of
      build and test to be run.
  """
  with BuildStep('Build SDK and d8'):
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
            'dart2js_bot']
    print 'Build SDK and d8: %s' % (' '.join(args))
    RunProcess(args)


if __name__ == '__main__':
  bot.RunBot(GetBuildInfo, RunCompilerTests, build_step=BuildCompiler)
