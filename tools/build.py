#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import optparse
import os
import re
import shutil
import subprocess
import sys
import time
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
HOST_CPUS = utils.GuessCpus()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
THIRD_PARTY_ROOT = os.path.join(DART_ROOT, 'third_party')

arm_cc_error = """
Couldn't find the arm cross compiler.
To make sure that you have the arm cross compilation tools installed, run:

$ wget http://src.chromium.org/chrome/trunk/src/build/install-build-deps.sh
OR
$ svn co http://src.chromium.org/chrome/trunk/src/build; cd build
Then,
$ chmod u+x install-build-deps.sh
$ ./install-build-deps.sh --arm --no-chromeos-fonts
"""
DEFAULT_ARM_CROSS_COMPILER_PATH = '/usr/bin'

usage = """\
usage: %%prog [options] [targets]

This script runs 'make' in the *current* directory. So, run it from
the Dart repo root,

  %s ,

unless you really intend to use a non-default Makefile.""" % DART_ROOT

DART_USE_GYP = "DART_USE_GYP"


def use_gyp():
  return DART_USE_GYP in os.environ


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
              'simmips,mips,simarm64,arm64,simdbc,armsimdbc]',
      default=utils.GuessArchitecture())
  result.add_option("--os",
    help='Target OSs (comma-separated).',
    metavar='[all,host,android]',
    default='host')
  result.add_option("-t", "--toolchain",
    help='Cross-compiler toolchain path',
    default=None)
  result.add_option("-j",
      help='The number of parallel jobs to run.',
      metavar=HOST_CPUS,
      default=str(HOST_CPUS))
  (vs_directory, vs_executable) = utils.GuessVisualStudioPath()
  result.add_option("--devenv",
      help='Path containing devenv.com on Windows',
      default=vs_directory)
  result.add_option("--executable",
      help='Name of the devenv.com/msbuild executable on Windows (varies for '
           'different versions of Visual Studio)',
      default=vs_executable)
  result.add_option("--gyp",
      help='Build with gyp.',
      default=use_gyp(),
      action='store_true')
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
  if not options.gyp and options.toolchain != None:
    print "The --toolchain flag is only supported by the gyp build."
    print "When using the GN build, set the toolchain and sysroot using gn.py."
    return False
  for mode in options.mode:
    if not mode in ['debug', 'release', 'product']:
      print "Unknown mode %s" % mode
      return False
  for arch in options.arch:
    archs = ['ia32', 'x64', 'simarm', 'arm', 'simarmv6', 'armv6',
             'simarmv5te', 'armv5te', 'simmips', 'mips', 'simarm64', 'arm64',
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
      if not arch in ['ia32', 'x64', 'arm', 'armv6', 'armv5te', 'arm64', 'mips',
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


def GetToolchainPrefix(target_os, arch, options):
  if options.toolchain != None:
    return options.toolchain

  if target_os == 'android':
    android_toolchain = GetAndroidToolchainDir(HOST_OS, arch)
    if arch == 'arm' or arch == 'simdbc':
      return os.path.join(android_toolchain, 'arm-linux-androideabi')
    if arch == 'arm64' or arch == 'simdbc64':
      return os.path.join(android_toolchain, 'aarch64-linux-android')
    if arch == 'ia32':
      return os.path.join(android_toolchain, 'i686-linux-android')
    if arch == 'x64':
      return os.path.join(android_toolchain, 'x86_64-linux-android')

  # If no cross compiler is specified, only try to figure one out on Linux.
  if not HOST_OS in ['linux']:
    raise Exception('Unless --toolchain is used cross-building is only '
                    'supported on Linux.')

  # For ARM Linux, by default use the Linux distribution's cross-compiler.
  if arch == 'arm' or arch == 'armsimdbc':
    # To use a non-hf compiler, specify on the command line with --toolchain.
    return (DEFAULT_ARM_CROSS_COMPILER_PATH + "/arm-linux-gnueabihf")
  if arch == 'arm64':
    return (DEFAULT_ARM_CROSS_COMPILER_PATH + "/aarch64-linux-gnu")

  # TODO(zra): Find default MIPS Linux cross-compiler.

  return None


def SetTools(arch, target_os, options):
  toolsOverride = None

  toolchainprefix = GetToolchainPrefix(target_os, arch, options)

  # Override the Android toolchain's linker to handle some complexity in the
  # linker arguments that gyp has trouble with.
  linker = ""
  if target_os == 'android':
    linker = os.path.join(DART_ROOT, 'tools', 'android_link.py')
  elif toolchainprefix:
    linker = toolchainprefix + "-g++"

  if toolchainprefix:
    toolsOverride = {
      "CC.target"  :  toolchainprefix + "-gcc",
      "CXX.target" :  toolchainprefix + "-g++",
      "AR.target"  :  toolchainprefix + "-ar",
      "LINK.target":  linker,
      "NM.target"  :  toolchainprefix + "-nm",
    }
  return toolsOverride


def CheckDirExists(path, docstring):
  if not os.path.isdir(path):
    raise Exception('Could not find %s directory %s'
          % (docstring, path))


def GetAndroidToolchainDir(host_os, target_arch):
  global THIRD_PARTY_ROOT
  if host_os not in ['linux']:
    raise Exception('Unsupported host os %s' % host_os)
  if target_arch not in ['ia32', 'x64', 'arm', 'arm64', 'simdbc', 'simdbc64']:
    raise Exception('Unsupported target architecture %s' % target_arch)

  # Set up path to the Android NDK.
  CheckDirExists(THIRD_PARTY_ROOT, 'third party tools')
  android_tools = os.path.join(THIRD_PARTY_ROOT, 'android_tools')
  CheckDirExists(android_tools, 'Android tools')
  android_ndk_root = os.path.join(android_tools, 'ndk')
  CheckDirExists(android_ndk_root, 'Android NDK')

  # Set up the directory of the Android NDK cross-compiler toolchain.
  toolchain_arch = 'arm-linux-androideabi-4.9'
  if target_arch == 'arm64' or target_arch == 'simdbc64':
    toolchain_arch = 'aarch64-linux-android-4.9'
  if target_arch == 'ia32':
    toolchain_arch = 'x86-4.9'
  if target_arch == 'x64':
    toolchain_arch = 'x86_64-4.9'
  toolchain_dir = 'linux-x86_64'
  android_toolchain = os.path.join(android_ndk_root,
      'toolchains', toolchain_arch,
      'prebuilt', toolchain_dir, 'bin')
  CheckDirExists(android_toolchain, 'Android toolchain')

  return android_toolchain


def Execute(args):
  process = subprocess.Popen(args)
  process.wait()
  if process.returncode != 0:
    raise Exception(args[0] + " failed")


def CurrentDirectoryBaseName():
  """Returns the name of the current directory"""
  return os.path.relpath(os.curdir, start=os.pardir)


def FilterEmptyXcodebuildSections(process):
  """
  Filter output from xcodebuild so empty sections are less verbose.

  The output from xcodebuild looks like this:

Build settings from command line:
    SYMROOT = .../xcodebuild

=== BUILD TARGET samples OF PROJECT dart WITH CONFIGURATION ...

Check dependencies

=== BUILD AGGREGATE TARGET upload_sdk OF PROJECT dart WITH CONFIGURATION ...

Check dependencies

PhaseScriptExecution "Action \"upload_sdk_py\"" xcodebuild/dart.build/...
    cd ...
    /bin/sh -c .../xcodebuild/dart.build/ReleaseIA32/upload_sdk.build/...


** BUILD SUCCEEDED **

  """

  def is_empty_chunk(input):
    empty_chunk = ['', 'Check dependencies', '']
    return not input or (len(input) == 4 and input[1:] == empty_chunk)

  def unbuffered(callable):
    # Use iter to disable buffering in for-in.
    return iter(callable, '')

  section = None
  chunk = []
  # Is stdout a terminal which supports colors?
  is_fancy_tty = False
  clr_eol = None
  if sys.stdout.isatty():
    term = os.getenv('TERM', 'dumb')
    # The capability "clr_eol" means clear the line from cursor to end
    # of line.  See man pages for tput and terminfo.
    try:
      with open('/dev/null', 'a') as dev_null:
        clr_eol = subprocess.check_output(['tput', '-T' + term, 'el'],
                                          stderr=dev_null)
      if clr_eol:
        is_fancy_tty = True
    except subprocess.CalledProcessError:
      is_fancy_tty = False
    except AttributeError:
      is_fancy_tty = False
  pattern = re.compile(r'=== BUILD.* TARGET (.*) OF PROJECT (.*) WITH ' +
                       r'CONFIGURATION (.*) ===')
  has_interesting_info = False
  for line in unbuffered(process.stdout.readline):
    line = line.rstrip()
    if line.startswith('=== BUILD ') or line.startswith('** BUILD '):
      has_interesting_info = False
      section = line
      if is_fancy_tty:
        match = re.match(pattern, section)
        if match:
          section = '%s/%s/%s' % (
            match.group(3), match.group(2), match.group(1))
        # Truncate to avoid extending beyond 80 columns.
        section = section[:80]
        # If stdout is a terminal, emit "progress" information.  The
        # progress information is the first line of the current chunk.
        # After printing the line, move the cursor back to the
        # beginning of the line.  This has two effects: First, if the
        # chunk isn't empty, the first line will be overwritten
        # (avoiding duplication).  Second, the next segment line will
        # overwrite it too avoid long scrollback.  clr_eol ensures
        # that there is no trailing garbage when a shorter line
        # overwrites a longer line.
        print '%s%s\r' % (clr_eol, section),
      chunk = []
    if not section or has_interesting_info:
      print line
    else:
      length = len(chunk)
      if length == 2 and line != 'Check dependencies':
        has_interesting_info = True
      elif (length == 1 or length == 3) and line:
        has_interesting_info = True
      elif length > 3:
        has_interesting_info = True
      if has_interesting_info:
        print '\n'.join(chunk)
        chunk = []
      else:
        chunk.append(line)
  if not is_empty_chunk(chunk):
    print '\n'.join(chunk)


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
def EnsureGomaStarted(out_dir):
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
  return True



def BuildNinjaCommand(options, target, target_os, mode, arch):
  out_dir = utils.GetBuildRoot(HOST_OS, mode, arch, target_os)
  if ShouldRunGN(out_dir):
    RunGN(target_os, mode, arch)
  command = ['ninja', '-C', out_dir]
  if options.verbose:
    command += ['-v']
  if UseGoma(out_dir):
    if EnsureGomaStarted(out_dir):
      command += ['-j1000']
    else:
      # If we couldn't ensure that goma is started, let the build start, but
      # slowly so we can see any helpful error messages that pop out.
      command += ['-j1']
  command += [target]
  return command


filter_xcodebuild_output = False
def BuildOneConfig(options, target, target_os, mode, arch):
  global filter_xcodebuild_output
  if arch.startswith('mips'):
    bold  = '\033[1m'
    reset = '\033[0m'
    print(bold + "Warning: MIPS architectures are unlikely to be supported in "
          "upcoming releases. Please consider using another architecture "
          "and/or file an issue explaining your specific use of and need for "
          "MIPS support." + reset)
  start_time = time.time()
  args = []
  build_config = utils.GetBuildConf(mode, arch, target_os)
  if not options.gyp:
    args = BuildNinjaCommand(options, target, target_os, mode, arch)
  else:
    os.environ['DART_BUILD_MODE'] = mode
    if HOST_OS == 'macos':
      filter_xcodebuild_output = True
      project_file = 'dart.xcodeproj'
      if os.path.exists('dart-%s.gyp' % CurrentDirectoryBaseName()):
        project_file = 'dart-%s.xcodeproj' % CurrentDirectoryBaseName()
      if target == 'all':
        target = 'All'
      args = ['xcodebuild',
              '-project',
              project_file,
              '-target',
              target,
              '-configuration',
              build_config,
              'SYMROOT=%s' % os.path.abspath('xcodebuild')
              ]
    elif HOST_OS == 'win32':
      project_file = 'dart.sln'
      if os.path.exists('dart-%s.gyp' % CurrentDirectoryBaseName()):
        project_file = 'dart-%s.sln' % CurrentDirectoryBaseName()
      # Select a platform suffix to pass to devenv.
      if arch == 'ia32':
        platform_suffix = 'Win32'
      elif arch == 'x64':
        platform_suffix = 'x64'
      else:
        print 'Unsupported arch for MSVC build: %s' % arch
        return 1
      config_name = '%s|%s' % (build_config, platform_suffix)
      if target == 'all':
        args = [options.devenv + os.sep + options.executable,
                '/build',
                config_name,
                project_file
               ]
      else:
        args = [options.devenv + os.sep + options.executable,
                '/build',
                config_name,
                '/project',
                target,
                project_file
               ]
    else:
      make = 'make'
      if HOST_OS == 'freebsd':
        make = 'gmake'
        # work around lack of flock
        os.environ['LINK'] = '$(CXX)'
      args = [make,
              '-j',
              options.j,
              'BUILDTYPE=' + build_config,
              ]
      if target_os != HOST_OS:
        args += ['builddir_name=' + utils.GetBuildDir(HOST_OS)]
      if options.verbose:
        args += ['V=1']

      args += [target]

    toolsOverride = None
    if override_tools:
      toolsOverride = SetTools(arch, target_os, options)
    if toolsOverride:
      for k, v in toolsOverride.iteritems():
        args.append(  k + "=" + v)
        if options.verbose:
          print k + " = " + v
      if not os.path.isfile(toolsOverride['CC.target']):
        if arch == 'arm':
          print arm_cc_error
        else:
          print "Couldn't find compiler: %s" % toolsOverride['CC.target']
        return 1

  print ' '.join(args)
  process = None
  if filter_xcodebuild_output:
    process = subprocess.Popen(args,
                               stdin=None,
                               bufsize=1, # Line buffered.
                               stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    FilterEmptyXcodebuildSections(process)
  else:
    process = subprocess.Popen(args, stdin=None)
  process.wait()
  if process.returncode != 0:
    NotifyBuildDone(build_config, success=False, start=start_time)
    return 1
  else:
    NotifyBuildDone(build_config, success=True, start=start_time)

  return 0


def Main():
  utils.ConfigureJava()
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
  for target in targets:
    for target_os in options.os:
      for mode in options.mode:
        for arch in options.arch:
          if BuildOneConfig(options, target, target_os,
                            mode, arch) != 0:
            return 1

  return 0


if __name__ == '__main__':
  sys.exit(Main())
