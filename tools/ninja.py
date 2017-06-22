#!/usr/bin/env python
#
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import multiprocessing
import optparse
import os
import subprocess
import sys
import time
import utils

HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))

usage = """\
usage: %%prog [options] [targets]

This script runs 'make' in the *current* directory. So, run it from
the Dart repo root,

  %s ,

unless you really intend to use a non-default Makefile.""" % DART_ROOT


def BuildOptions():
  result = optparse.OptionParser(usage=usage)
  result.add_option("-m", "--mode",
      help='Build variants (comma-separated).',
      metavar='[all,debug,release,product]',
      default='debug')
  result.add_option("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  result.add_option("-a", "--arch",
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64,simarm,arm,simarmv6,armv6,simarmv5te,armv5te,'
              'simarm64,arm64,simdbc,armsimdbc]',
      default=utils.GuessArchitecture())
  result.add_option("--os",
      help='Target OSs (comma-separated).',
      metavar='[all,host,android]',
      default='host')
  result.add_option("-j",
      type=int,
      help='Ninja -j option for Goma builds.',
      metavar=1000,
      default=1000)
  return result


def ProcessOsOption(os_name):
  if os_name == 'host':
    return HOST_OS
  return os_name


def ProcessOptions(options, args):
  if options.arch == 'all':
    options.arch = 'ia32,x64,simarm,simarm64,simdbc64'
  if options.mode == 'all':
    options.mode = 'debug,release,product'
  if options.os == 'all':
    options.os = 'host,android'
  options.mode = options.mode.split(',')
  options.arch = options.arch.split(',')
  options.os = options.os.split(',')
  for mode in options.mode:
    if not mode in ['debug', 'release', 'product']:
      print "Unknown mode %s" % mode
      return False
  for arch in options.arch:
    archs = ['ia32', 'x64', 'simarm', 'arm', 'simarmv6', 'armv6',
             'simarmv5te', 'armv5te', 'simarm64', 'arm64',
             'simdbc', 'simdbc64', 'armsimdbc', 'armsimdbc64']
    if not arch in archs:
      print "Unknown arch %s" % arch
      return False
  options.os = [ProcessOsOption(os_name) for os_name in options.os]
  for os_name in options.os:
    if not os_name in ['android', 'freebsd', 'linux', 'macos', 'win32']:
      print "Unknown os %s" % os_name
      return False
    if os_name != HOST_OS:
      if os_name != 'android':
        print "Unsupported target os %s" % os_name
        return False
      if not HOST_OS in ['linux', 'macos']:
        print ("Cross-compilation to %s is not supported on host os %s."
               % (os_name, HOST_OS))
        return False
      if not arch in ['ia32', 'x64', 'arm', 'armv6', 'armv5te', 'arm64',
                      'simdbc', 'simdbc64']:
        print ("Cross-compilation to %s is not supported for architecture %s."
               % (os_name, arch))
        return False
      # We have not yet tweaked the v8 dart build to work with the Android
      # NDK/SDK, so don't try to build it.
      if not args:
        print "For android builds you must specify a target, such as 'runtime'."
        return False
  return True


def NotifyBuildDone(build_config, success, start):
  if not success:
    print "BUILD FAILED"

  sys.stdout.flush()

  # Display a notification if build time exceeded DART_BUILD_NOTIFICATION_DELAY.
  notification_delay = float(
    os.getenv('DART_BUILD_NOTIFICATION_DELAY', sys.float_info.max))
  if (time.time() - start) < notification_delay:
    return

  if success:
    message = 'Build succeeded.'
  else:
    message = 'Build failed.'
  title = build_config

  command = None
  if HOST_OS == 'macos':
    # Use AppleScript to display a UI non-modal notification.
    script = 'display notification  "%s" with title "%s" sound name "Glass"' % (
      message, title)
    command = "osascript -e '%s' &" % script
  elif HOST_OS == 'linux':
    if success:
      icon = 'dialog-information'
    else:
      icon = 'dialog-error'
    command = "notify-send -i '%s' '%s' '%s' &" % (icon, message, title)
  elif HOST_OS == 'win32':
    if success:
      icon = 'info'
    else:
      icon = 'error'
    command = ("powershell -command \""
      "[reflection.assembly]::loadwithpartialname('System.Windows.Forms')"
        "| Out-Null;"
      "[reflection.assembly]::loadwithpartialname('System.Drawing')"
        "| Out-Null;"
      "$n = new-object system.windows.forms.notifyicon;"
      "$n.icon = [system.drawing.systemicons]::information;"
      "$n.visible = $true;"
      "$n.showballoontip(%d, '%s', '%s', "
      "[system.windows.forms.tooltipicon]::%s);\"") % (
        5000, # Notification stays on for this many milliseconds
        message, title, icon)

  if command:
    # Ignore return code, if this command fails, it doesn't matter.
    os.system(command)


def RunGN(target_os, mode, arch):
  gn_os = 'host' if target_os == HOST_OS else target_os
  gn_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gn.py'),
    '-m', mode,
    '-a', arch,
    '--os', gn_os,
    '-v',
  ]
  process = subprocess.Popen(gn_command)
  process.wait()
  if process.returncode != 0:
    print ("Tried to run GN, but it failed. Try running it manually: \n\t$ " +
           ' '.join(gn_command))


def ShouldRunGN(out_dir):
  return (not os.path.exists(out_dir) or
          not os.path.isfile(os.path.join(out_dir, 'args.gn')))


def UseGoma(out_dir):
  args_gn = os.path.join(out_dir, 'args.gn')
  return 'use_goma = true' in open(args_gn, 'r').read()


# Try to start goma, but don't bail out if we can't. Instead print an error
# message, and let the build fail with its own error messages as well.
goma_started = False
def EnsureGomaStarted(out_dir):
  global goma_started
  if goma_started:
    return True
  args_gn_path = os.path.join(out_dir, 'args.gn')
  goma_dir = None
  with open(args_gn_path, 'r') as fp:
    for line in fp:
      if 'goma_dir' in line:
        words = line.split()
        goma_dir = words[2][1:-1]  # goma_dir = "/path/to/goma"
  if not goma_dir:
    print 'Could not find goma for ' + out_dir
    return False
  if not os.path.exists(goma_dir) or not os.path.isdir(goma_dir):
    print 'Could not find goma at ' + goma_dir
    return False
  goma_ctl = os.path.join(goma_dir, 'goma_ctl.py')
  goma_ctl_command = [
    'python',
    goma_ctl,
    'ensure_start',
  ]
  process = subprocess.Popen(goma_ctl_command)
  process.wait()
  if process.returncode != 0:
    print ("Tried to run goma_ctl.py, but it failed. Try running it manually: "
           + "\n\t" + ' '.join(goma_ctl_command))
    return False
  goma_started = True
  return True


# Returns a tuple (build_config, command to run, whether goma is used)
def BuildOneConfig(options, targets, target_os, mode, arch):
  build_config = utils.GetBuildConf(mode, arch, target_os)
  out_dir = utils.GetBuildRoot(HOST_OS, mode, arch, target_os)
  using_goma = False
  if ShouldRunGN(out_dir):
    RunGN(target_os, mode, arch)
  command = ['ninja', '-C', out_dir]
  if options.verbose:
    command += ['-v']
  if UseGoma(out_dir):
    if EnsureGomaStarted(out_dir):
      using_goma = True
      command += [('-j%s' % str(options.j))]
    else:
      # If we couldn't ensure that goma is started, let the build start, but
      # slowly so we can see any helpful error messages that pop out.
      command += ['-j1']
  command += targets
  return (build_config, command, using_goma)


def RunOneBuildCommand(build_config, args):
  start_time = time.time()
  print ' '.join(args)
  process = subprocess.Popen(args, stdin=None)
  process.wait()
  if process.returncode != 0:
    NotifyBuildDone(build_config, success=False, start=start_time)
    return 1
  else:
    NotifyBuildDone(build_config, success=True, start=start_time)

  return 0


def RunOneGomaBuildCommand(args):
  try:
    print ' '.join(args)
    process = subprocess.Popen(args, stdin=None)
    process.wait()
    print (' '.join(args) + " done.")
    return process.returncode
  except KeyboardInterrupt:
    return 1


def Main():
  starttime = time.time()
  # Parse the options.
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options, args):
    parser.print_help()
    return 1
  # Determine which targets to build. By default we build the "all" target.
  if len(args) == 0:
    targets = ['all']
  else:
    targets = args

  # Build all targets for each requested configuration.
  configs = []
  for target_os in options.os:
    for mode in options.mode:
      for arch in options.arch:
        configs.append(BuildOneConfig(options, targets, target_os, mode, arch))

  # Build regular configs.
  goma_builds = []
  for (build_config, args, goma) in configs:
    if args is None:
      return 1
    if goma:
      goma_builds.append(args)
    elif RunOneBuildCommand(build_config, args) != 0:
      return 1

  # Run goma builds in parallel.
  pool = multiprocessing.Pool(multiprocessing.cpu_count())
  results = pool.map(RunOneGomaBuildCommand, goma_builds, chunksize=1)
  for r in results:
    if r != 0:
      return 1

  endtime = time.time()
  print ("The build took %.3f seconds" % (endtime - starttime))
  return 0


if __name__ == '__main__':
  sys.exit(Main())
