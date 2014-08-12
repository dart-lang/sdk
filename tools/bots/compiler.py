#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Dart2js buildbot steps

Runs tests for the  dart2js compiler.
"""

import os
import platform
import re
import shutil
import socket
import string
import subprocess
import sys

import bot

DARTIUM_BUILDER = r'none-dartium-(linux|mac|windows)'
DART2JS_BUILDER = (
    r'dart2js-(linux|mac|windows)(-(jsshell))?-(debug|release)(-(checked|host-checked))?(-(host-checked))?(-(minified))?(-(x64))?(-(batch))?-?(\d*)-?(\d*)')
DART2JS_FULL_BUILDER = r'full-(linux|mac|win7|win8)(-(ie10|ie11))?(-checked)?(-minified)?-(\d+)-(\d+)'
WEB_BUILDER = (
    r'dart2js-(ie9|ie10|ie11|ff|safari|chrome|chromeOnAndroid|safarimobilesim|opera|drt)-(win7|win8|mac10\.8|mac10\.7|linux)(-(all|html))?(-(csp))?(-(\d+)-(\d+))?')

IE_VERSIONS = ['ie10', 'ie11']

DART2JS_FULL_CONFIGURATIONS = {
  'linux' : [ ],
  'mac' : [ ],
  'windows-ie10' : [
    {'runtime' : 'ie10'},
    {'runtime' : 'ie10', 'additional_flags' : ['--checked']},
    {'runtime' : 'chrome'},
  ],
  'windows-ie11' : [
    {'runtime' : 'ie11'},
    {'runtime' : 'ie11', 'additional_flags' : ['--checked']},
    {'runtime' : 'ff'},
  ],
}


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
  csp = None
  arch = None
  dart2js_full = False
  batch = False
  builder_tag = None

  dart2js_pattern = re.match(DART2JS_BUILDER, builder_name)
  dart2js_full_pattern = re.match(DART2JS_FULL_BUILDER, builder_name)
  web_pattern = re.match(WEB_BUILDER, builder_name)
  dartium_pattern = re.match(DARTIUM_BUILDER, builder_name)

  if web_pattern:
    compiler = 'dart2js'
    runtime = web_pattern.group(1)
    system = web_pattern.group(2)
    mode = 'release'
    test_set = web_pattern.group(4)
    if web_pattern.group(6) == 'csp':
      csp = True
    shard_index = web_pattern.group(8)
    total_shards = web_pattern.group(9)
  elif dart2js_full_pattern:
    mode = 'release'
    compiler = 'dart2js'
    dart2js_full = True
    system = dart2js_full_pattern.group(1)
    # windows-ie10 or windows-ie11 means a windows machine with that respective
    # version of ie installed. There is no difference in how we handle testing.
    # We use the builder tag to pass along this information.
    if system.startswith('win'):
      ie =  dart2js_full_pattern.group(3)
      assert ie in IE_VERSIONS
      builder_tag = 'windows-%s' % ie
      system = 'windows'
    if dart2js_full_pattern.group(4):
      checked = True
    if dart2js_full_pattern.group(5):
      minified = True
    shard_index = dart2js_full_pattern.group(6)
    total_shards = dart2js_full_pattern.group(7)
  elif dart2js_pattern:
    compiler = 'dart2js'
    system = dart2js_pattern.group(1)
    runtime = 'd8'
    arch = 'ia32'
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
    if dart2js_pattern.group(12) == 'x64':
      arch = 'x64'
    if dart2js_pattern.group(14) == 'batch':
      batch = True

    shard_index = dart2js_pattern.group(15)
    total_shards = dart2js_pattern.group(16)
  elif dartium_pattern:
    compiler = 'none'
    runtime = 'dartium'
    mode = 'release'
    system = dartium_pattern.group(1)
  else :
    return None

  # We have both win7 and win8 bots, functionality is the same.
  if system.startswith('win'):
    system = 'windows'

  # We have both 10.8 and 10.7 bots, functionality is the same.
  if system == 'mac10.8' or system == 'mac10.7':
    system = 'mac'

  # This is temporary, slowly enabling this.
  if system == 'linux' or system == 'mac':
    batch = True

  if (system == 'windows' and platform.system() != 'Windows') or (
      system == 'mac' and platform.system() != 'Darwin') or (
      system == 'linux' and platform.system() != 'Linux'):
    print ('Error: You cannot emulate a buildbot with a platform different '
        'from your own.')
    return None
  return bot.BuildInfo(compiler, runtime, mode, system, checked, host_checked,
                       minified, shard_index, total_shards, is_buildbot,
                       test_set, csp, arch, dart2js_full, batch=batch,
                       builder_tag=builder_tag)


def NeedsXterm(compiler, runtime):
  return runtime in ['ie9', 'ie10', 'ie11', 'chrome', 'safari', 'opera',
                     'ff', 'drt', 'dartium']


def TestStepName(name, runtime, flags):
  # Filter out flags with '=' as this breaks the /stats feature of the
  # build bot.
  flags = [x for x in flags if not '=' in x]
  step_name = '%s-%s tests %s' % (name, runtime, ' '.join(flags))
  return step_name.strip()


IsFirstTestStepCall = True
def TestStep(name, mode, system, compiler, runtime, targets, flags, arch):
  step_name = TestStepName(name, runtime, flags)
  with bot.BuildStep(step_name, swallow_error=True):
    sys.stdout.flush()
    if NeedsXterm(compiler, runtime) and system == 'linux':
      cmd = ['xvfb-run', '-a', '--server-args=-screen 0 1024x768x24']
    else:
      cmd = []

    user_test = os.environ.get('USER_TEST', 'no')

    cmd.extend([sys.executable,
                os.path.join(os.curdir, 'tools', 'test.py'),
                '--step_name=' + step_name,
                '--mode=' + mode,
                '--compiler=' + compiler,
                '--runtime=' + runtime,
                '--arch=' + arch,
                '--time',
                '--use-sdk',
                '--report',
                '--write-debug-log',
                '--write-test-outcome-log'])

    if user_test == 'yes':
      cmd.append('--progress=color')
    else:
      cmd.extend(['--progress=buildbot', '-v'])

    cmd.append('--clear_browser_cache')

    global IsFirstTestStepCall
    if IsFirstTestStepCall:
      IsFirstTestStepCall = False
    else:
      cmd.append('--append_logs')

    if flags:
      cmd.extend(flags)
    cmd.extend(targets)

    print 'Running: %s' % (' '.join(map(lambda arg: '"%s"' % arg, cmd)))
    sys.stdout.flush()
    bot.RunProcess(cmd)


def TestCompiler(runtime, mode, system, flags, is_buildbot, arch,
                 compiler=None, dart2js_full=False):
  """ test the compiler.
   Args:
     - runtime: either 'd8', 'jsshell', or one of the browsers, see GetBuildInfo
     - mode: either 'debug' or 'release'
     - system: either 'linux', 'mac', 'windows'
     - flags: extra flags to pass to test.dart
     - is_buildbot: true if we are running on a real buildbot instead of
       emulating one.
     - arch: The architecture to run on.
     - compiler: The compiler to use for test.py (default is 'dart2js').
  """

  if not compiler:
    compiler = 'dart2js'

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

  if (compiler == 'dart2js' and (runtime == 'ff' or runtime == 'chrome')
      and is_buildbot):
    # Print out browser version numbers if we're running on the buildbot (where
    # we know the paths to these browser installations).
    version_query_string = '"%s" --version' % GetPath(runtime)
    if runtime == 'ff' and system == 'windows':
      version_query_string += '| more'
    elif runtime == 'chrome' and system == 'windows':
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
    unit_test_flags = [flag for flag in flags if flag.startswith('--shard')]
    # Run the unit tests in checked mode (the VM's checked mode).
    unit_test_flags.append('--checked')
    TestStep("dart2js_unit", mode, system, 'none', 'vm', ['dart2js', 'try'],
             unit_test_flags, arch)

  if compiler == 'dart2js' and runtime in ['ie10', 'ie11']:
    TestStep(compiler, mode, system, compiler, runtime,
             ['html', 'pkg', 'samples'], flags, arch)
  else:
    # Run the default set of test suites.
    TestStep(compiler, mode, system, compiler,
             runtime, [], flags, arch)

    if compiler == 'dart2js':
      # TODO(kasperl): Consider running peg and css tests too.
      extras = ['dart2js_extra', 'dart2js_native']
      extras_flags = flags
      if (system == 'linux'
          and runtime == 'd8'
          and not '--host-checked' in extras_flags):
        # Run the extra tests in checked mode, but only on linux/d8.
        # Other systems have less resources and tend to time out.
        extras_flags = extras_flags + ['--host-checked']
      TestStep('dart2js_extra', mode, system, 'dart2js', runtime, extras,
               extras_flags, arch)
      if mode == 'release':
        TestStep('try_dart', mode, system, 'dart2js', runtime, ['try'],
                 extras_flags, arch)


def GetHasHardCodedCheckedMode(build_info):
  # TODO(ricow): We currently run checked mode tests on chrome on linux and
  # on the slow (all) IE windows bots. This is a hack and we should use the
  # normal sharding and checked splitting functionality when we get more
  # vms for testing this.
  if (build_info.system == 'linux' and build_info.runtime == 'drt'):
    return True
  if build_info.runtime.startswith('ie') and build_info.test_set == 'all':
    return True
  return False


def GetLocalIPAddress():
  hostname = socket.gethostname()
  # '$ host chromeperf02' results for example in
  # 'chromeperf02.perf.chromium.org has address 172.22.28.55'
  output = subprocess.check_output(["host", hostname])
  match = re.match(r'.*\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s+.*', output)
  if not match:
    raise Exception("Could not determine local ip address "
                    "(hostname: '%s', host command output: '%s')."
                    % (hostname, output))
  return match.group(1)

def AddAndroidToolsToPath():
  par_dir = os.path.pardir
  join = os.path.join

  dart_dir = join(os.path.dirname(__file__), par_dir, par_dir)
  android_sdk = join(dart_dir, 'third_party', 'android_tools', 'sdk')
  tools_dir = os.path.abspath(join(android_sdk, 'tools'))
  platform_tools_dir = os.path.abspath(join(android_sdk, 'platform-tools'))
  os.environ['PATH'] = os.pathsep.join(
      [os.environ['PATH'], tools_dir, platform_tools_dir])

def RunCompilerTests(build_info):
  test_flags = []
  if build_info.shard_index:
    test_flags = ['--shards=%s' % build_info.total_shards,
                  '--shard=%s' % build_info.shard_index]
  if build_info.checked: test_flags += ['--checked']
  if build_info.minified: test_flags += ['--minified']
  if build_info.host_checked: test_flags += ['--host-checked']
  if build_info.batch: test_flags += ['--dart2js-batch']

  if build_info.dart2js_full:
    compiler = build_info.compiler
    assert compiler == 'dart2js'
    system = build_info.system
    arch = build_info.arch
    mode = build_info.mode
    is_buildbot = build_info.is_buildbot

    config = build_info.builder_tag if system == 'windows' else system
    for configuration in DART2JS_FULL_CONFIGURATIONS[config]:
      additional_flags = configuration.get('additional_flags', [])
      TestCompiler(configuration['runtime'], mode, system,
                   test_flags + additional_flags, is_buildbot, arch,
                   compiler=compiler, dart2js_full=True)
  else:
    if build_info.csp: test_flags += ['--csp']

    if build_info.runtime == 'chromeOnAndroid':
      test_flags.append('--local_ip=%s' % GetLocalIPAddress())
      # test.py expects the android tools directories to be in PATH
      # (they contain for example 'adb')
      AddAndroidToolsToPath()

    TestCompiler(build_info.runtime, build_info.mode, build_info.system,
                 list(test_flags), build_info.is_buildbot,
                 build_info.arch, compiler=build_info.compiler)

    # See comment in GetHasHardCodedCheckedMode, this is a hack.
    if (GetHasHardCodedCheckedMode(build_info)):
      TestCompiler(build_info.runtime, build_info.mode, build_info.system,
                   test_flags + ['--checked'], build_info.is_buildbot,
                   build_info.arch,  compiler=build_info.compiler)


def BuildCompiler(build_info):
  """
  Builds the SDK.

  - build_info: the buildInfo object, containing information about what sort of
      build and test to be run.
  """
  with bot.BuildStep('Build SDK'):
    target = 'dart2js_bot'
    # Try-dart takes more than 20 min in debug mode and makes the bot time out.
    # We use the debug target which does not include try
    if build_info.mode == 'debug':
      target = 'dart2js_bot_debug'
    args = [sys.executable, './tools/build.py', '--mode=' + build_info.mode,
            '--arch=' + build_info.arch, target]
    print 'Build SDK and d8: %s' % (' '.join(args))
    bot.RunProcess(args)


if __name__ == '__main__':
  bot.RunBot(GetBuildInfo, RunCompilerTests, build_step=BuildCompiler)
