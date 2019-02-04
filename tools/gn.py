#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import multiprocessing
import os
import shutil
import subprocess
import sys
import time
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
GN = os.path.join(DART_ROOT, 'buildtools', 'gn')

# Environment variables for default settings.
DART_USE_ASAN = "DART_USE_ASAN"  # Use instead of --asan
DART_USE_MSAN = "DART_USE_MSAN"  # Use instead of --msan
DART_USE_TSAN = "DART_USE_TSAN"  # Use instead of --tsan
DART_USE_TOOLCHAIN = "DART_USE_TOOLCHAIN"  # Use instread of --toolchain-prefix
DART_USE_SYSROOT = "DART_USE_SYSROOT"  # Use instead of --target-sysroot
DART_USE_CRASHPAD = "DART_USE_CRASHPAD"  # Use instead of --use-crashpad
# use instead of --platform-sdk
DART_MAKE_PLATFORM_SDK = "DART_MAKE_PLATFORM_SDK"

DART_GN_ARGS = "DART_GN_ARGS"

def UseASAN():
  return DART_USE_ASAN in os.environ


def UseMSAN():
  return DART_USE_MSAN in os.environ


def UseTSAN():
  return DART_USE_TSAN in os.environ


def ToolchainPrefix(args):
  if args.toolchain_prefix:
    return args.toolchain_prefix
  return os.environ.get(DART_USE_TOOLCHAIN)


def TargetSysroot(args):
  if args.target_sysroot:
    return args.target_sysroot
  return os.environ.get(DART_USE_SYSROOT)


def MakePlatformSDK():
  return DART_MAKE_PLATFORM_SDK in os.environ


def GetGNArgs(args):
  if args.gn_args != None:
    return args.gn_args
  args = os.environ.get(DART_GN_ARGS) or ""
  return args.split()


def GetOutDir(mode, arch, target_os):
  return utils.GetBuildRoot(HOST_OS, mode, arch, target_os)


def ToCommandLine(gn_args):
  def merge(key, value):
    if type(value) is bool:
      return '%s=%s' % (key, 'true' if value else 'false')
    elif type(value) is int:
      return '%s=%d' % (key, value)
    return '%s="%s"' % (key, value)
  return [merge(x, y) for x, y in gn_args.iteritems()]


def HostCpuForArch(arch):
  if arch in ['ia32', 'arm', 'armv6', 'armv5te',
              'simarm', 'simarmv6', 'simarmv5te', 'simdbc',
              'armsimdbc']:
    return 'x86'
  if arch in ['x64', 'arm64', 'simarm64', 'simdbc64', 'armsimdbc64']:
    return 'x64'


# The C compiler's target.
def TargetCpuForArch(arch, target_os):
  if arch in ['ia32', 'simarm', 'simarmv6', 'simarmv5te']:
    return 'x86'
  if arch in ['x64', 'simarm64']:
    return 'x64'
  if arch == 'simdbc':
    return 'arm' if target_os == 'android' else 'x86'
  if arch in ['simdbc64']:
    return 'arm64' if target_os == 'android' else 'x64'
  if arch == 'armsimdbc':
    return 'arm'
  if arch == 'armsimdbc64':
    return 'arm64'
  return arch


# The Dart compiler's target.
def DartTargetCpuForArch(arch):
  if arch in ['ia32']:
    return 'ia32'
  if arch in ['x64']:
    return 'x64'
  if arch in ['arm', 'simarm']:
    return 'arm'
  if arch in ['armv6', 'simarmv6']:
    return 'armv6'
  if arch in ['armv5te', 'simarmv5te']:
    return 'armv5te'
  if arch in ['arm64', 'simarm64']:
    return 'arm64'
  if arch in ['simdbc', 'simdbc64', 'armsimdbc', 'armsimdbc64']:
    return 'dbc'
  return arch


def HostOsForGn(host_os):
  if host_os.startswith('macos'):
    return 'mac'
  if host_os.startswith('win'):
    return 'win'
  return host_os


# Where string_map is formatted as X1=Y1,X2=Y2 etc.
# If key is X1, returns Y1.
def ParseStringMap(key, string_map):
  for m in string_map.split(','):
    l = m.split('=')
    if l[0] == key:
      return l[1]
  return None


def UseSanitizer(args):
  return args.asan or args.msan or args.tsan


def DontUseClang(args, target_os, host_cpu, target_cpu):
  # We don't have clang on Windows.
  return target_os == 'win'


def UseSysroot(args, gn_args):
  # Don't try to use a Linux sysroot if we aren't on Linux.
  if gn_args['target_os'] != 'linux':
    return False
  # Don't use the sysroot if we're given another sysroot.
  if TargetSysroot(args):
    return False
  # Otherwise use the sysroot.
  return True

def ToGnArgs(args, mode, arch, target_os):
  gn_args = {}

  host_os = HostOsForGn(HOST_OS)
  if target_os == 'host':
    gn_args['target_os'] = host_os
  else:
    gn_args['target_os'] = target_os

  gn_args['host_cpu'] = HostCpuForArch(arch)
  gn_args['target_cpu'] = TargetCpuForArch(arch, target_os)
  gn_args['dart_target_arch'] = DartTargetCpuForArch(arch)

  # Configure Crashpad library if it is used.
  gn_args['dart_use_crashpad'] = (args.use_crashpad or
      DART_USE_CRASHPAD in os.environ)
  if gn_args['dart_use_crashpad']:
    # Tell Crashpad's BUILD files which checkout layout to use.
    gn_args['crashpad_dependencies'] = 'dart'

  if arch != HostCpuForArch(arch):
    # Training an app-jit snapshot under a simulator is slow. Use script
    # snapshots instead.
    gn_args['dart_snapshot_kind'] = 'kernel'
  else:
    gn_args['dart_snapshot_kind'] = 'app-jit'

  # We only want the fallback root certs in the standalone VM on
  # Linux and Windows.
  if gn_args['target_os'] in ['linux', 'win']:
    gn_args['dart_use_fallback_root_certificates'] = True

  gn_args['dart_platform_bytecode'] = args.bytecode

  # Use tcmalloc only when targeting Linux and when not using ASAN.
  gn_args['dart_use_tcmalloc'] = ((gn_args['target_os'] == 'linux')
                                  and not UseSanitizer(args))

  if gn_args['target_os'] == 'linux':
    if gn_args['target_cpu'] == 'arm':
      # Default to -mfloat-abi=hard and -mfpu=neon for arm on Linux as we're
      # specifying a gnueabihf compiler in //build/toolchain/linux/BUILD.gn.
      floatabi = 'hard' if args.arm_float_abi == '' else args.arm_float_abi
      gn_args['arm_version'] = 7
      gn_args['arm_float_abi'] = floatabi
      gn_args['arm_use_neon'] = True
    elif gn_args['target_cpu'] == 'armv6':
      floatabi = 'softfp' if args.arm_float_abi == '' else args.arm_float_abi
      gn_args['target_cpu'] = 'arm'
      gn_args['arm_version'] = 6
      gn_args['arm_float_abi'] = floatabi
    elif gn_args['target_cpu'] == 'armv5te':
      raise Exception("GN support for armv5te unimplemented")

  gn_args['is_debug'] = mode == 'debug'
  gn_args['is_release'] = mode == 'release'
  gn_args['is_product'] = mode == 'product'
  gn_args['dart_debug'] = mode == 'debug'

  # This setting is only meaningful for Flutter. Standalone builds of the VM
  # should leave this set to 'develop', which causes the build to defer to
  # 'is_debug', 'is_release' and 'is_product'.
  if mode == 'product':
    gn_args['dart_runtime_mode'] = 'release'
  else:
    gn_args['dart_runtime_mode'] = 'develop'

  gn_args['exclude_kernel_service'] = args.exclude_kernel_service

  dont_use_clang = DontUseClang(args, gn_args['target_os'],
                                      gn_args['host_cpu'],
                                      gn_args['target_cpu'])
  gn_args['is_clang'] = args.clang and not dont_use_clang

  enable_code_coverage = args.code_coverage and gn_args['is_clang']
  gn_args['dart_vm_code_coverage'] = enable_code_coverage

  gn_args['is_asan'] = args.asan and gn_args['is_clang']
  gn_args['is_msan'] = args.msan and gn_args['is_clang']
  gn_args['is_tsan'] = args.tsan and gn_args['is_clang']

  if not args.platform_sdk and not gn_args['target_cpu'].startswith('arm'):
    gn_args['dart_platform_sdk'] = args.platform_sdk
  gn_args['dart_stripped_binary'] = 'exe.stripped/dart'

  # Setup the user-defined sysroot.
  if UseSysroot(args, gn_args):
    gn_args['dart_use_debian_sysroot'] = True
  else:
    sysroot = TargetSysroot(args)
    if sysroot:
      gn_args['target_sysroot'] = ParseStringMap(arch, sysroot)

    toolchain = ToolchainPrefix(args)
    if toolchain:
      gn_args['toolchain_prefix'] = ParseStringMap(arch, toolchain)

  goma_dir = os.environ.get('GOMA_DIR')
  goma_home_dir = os.path.join(os.getenv('HOME', ''), 'goma')
  if args.goma and goma_dir:
    gn_args['use_goma'] = True
    gn_args['goma_dir'] = goma_dir
  elif args.goma and os.path.exists(goma_home_dir):
    gn_args['use_goma'] = True
    gn_args['goma_dir'] = goma_home_dir
  else:
    gn_args['use_goma'] = False
    gn_args['goma_dir'] = None

  # Code coverage requires -O0 to be set.
  if enable_code_coverage:
    gn_args['dart_debug_optimization_level'] = 0
    gn_args['debug_optimization_level'] = 0
  elif args.debug_opt_level:
    gn_args['dart_debug_optimization_level'] = args.debug_opt_level
    gn_args['debug_optimization_level'] = args.debug_opt_level

  return gn_args


def ProcessOsOption(os_name):
  if os_name == 'host':
    return HOST_OS
  return os_name


def ProcessOptions(args):
  if args.arch == 'all':
    args.arch = 'ia32,x64,simarm,simarm64,simdbc64'
  if args.mode == 'all':
    args.mode = 'debug,release,product'
  if args.os == 'all':
    args.os = 'host,android'
  args.mode = args.mode.split(',')
  args.arch = args.arch.split(',')
  args.os = args.os.split(',')
  for mode in args.mode:
    if not mode in ['debug', 'release', 'product']:
      print "Unknown mode %s" % mode
      return False
  for arch in args.arch:
    archs = ['ia32', 'x64', 'simarm', 'arm', 'simarmv6', 'armv6',
             'simarmv5te', 'armv5te', 'simarm64', 'arm64',
             'simdbc', 'simdbc64', 'armsimdbc', 'armsimdbc64']
    if not arch in archs:
      print "Unknown arch %s" % arch
      return False
  oses = [ProcessOsOption(os_name) for os_name in args.os]
  for os_name in oses:
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
  if HOST_OS != 'win' and args.use_crashpad:
    print "Crashpad is only supported on Windows"
    return False
  return True


def os_has_ide(host_os):
  return host_os.startswith('win') or host_os.startswith('mac')


def ide_switch(host_os):
  if host_os.startswith('win'):
    return '--ide=vs'
  elif host_os.startswith('mac'):
    return '--ide=xcode'
  else:
    return '--ide=json'


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to run `gn gen`.',
      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  common_group = parser.add_argument_group('Common Arguments')
  other_group = parser.add_argument_group('Other Arguments')

  common_group.add_argument('--arch', '-a',
      type=str,
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64,simarm,arm,simarmv6,armv6,simarmv5te,armv5te,'
              'simarm64,arm64,simdbc,armsimdbc]',
      default='x64')
  common_group.add_argument('--mode', '-m',
      type=str,
      help='Build variants (comma-separated).',
      metavar='[all,debug,release,product]',
      default='debug')
  common_group.add_argument('--os',
      type=str,
      help='Target OSs (comma-separated).',
      metavar='[all,host,android]',
      default='host')
  common_group.add_argument("-v", "--verbose",
      help='Verbose output.',
      default=False,
      action="store_true")

  other_group.add_argument('--arm-float-abi',
      type=str,
      help='The ARM float ABI (soft, softfp, hard)',
      metavar='[soft,softfp,hard]',
      default='')
  other_group.add_argument('--asan',
      help='Build with ASAN',
      default=UseASAN(),
      action='store_true')
  other_group.add_argument('--no-asan',
      help='Disable ASAN',
      dest='asan',
      action='store_false')
  other_group.add_argument('--bytecode', '-b',
      help='Include bytecode in the VMs platform dill',
      default=False,
      action="store_true")
  other_group.add_argument('--clang',
      help='Use Clang',
      default=True,
      action='store_true')
  other_group.add_argument('--no-clang',
      help='Disable Clang',
      dest='clang',
      action='store_false')
  other_group.add_argument('--code-coverage',
      help='Enable code coverage for the standalone VM',
      default=False,
      dest="code_coverage",
      action='store_true')
  other_group.add_argument('--debug-opt-level',
      '-d',
      help='The optimization level to use for debug builds',
      type=str)
  other_group.add_argument('--goma',
      help='Use goma',
      default=True,
      action='store_true')
  other_group.add_argument('--no-goma',
      help='Disable goma',
      dest='goma',
      action='store_false')
  other_group.add_argument('--ide',
      help='Generate an IDE file.',
      default=os_has_ide(HOST_OS),
      action='store_true')
  other_group.add_argument('--exclude-kernel-service',
      help='Exclude the kernel service.',
      default=False,
      dest='exclude_kernel_service',
      action='store_true')
  other_group.add_argument('--msan',
      help='Build with MSAN',
      default=UseMSAN(),
      action='store_true')
  other_group.add_argument('--no-msan',
      help='Disable MSAN',
      dest='msan',
      action='store_false')
  other_group.add_argument('--gn-args',
      help='Set extra GN args',
      dest='gn_args',
      action='append')
  other_group.add_argument('--platform-sdk',
      help='Directs the create_sdk target to create a smaller "Platform" SDK',
      default=MakePlatformSDK(),
      action='store_true')
  other_group.add_argument('--target-sysroot', '-s',
      type=str,
      help='Comma-separated list of arch=/path/to/sysroot mappings')
  other_group.add_argument('--toolchain-prefix', '-t',
      type=str,
      help='Comma-separated list of arch=/path/to/toolchain-prefix mappings')
  other_group.add_argument('--tsan',
      help='Build with TSAN',
      default=UseTSAN(),
      action='store_true')
  other_group.add_argument('--no-tsan',
      help='Disable TSAN',
      dest='tsan',
      action='store_false')
  other_group.add_argument('--wheezy',
      help='This flag is deprecated.',
      default=True,
      action='store_true')
  other_group.add_argument('--no-wheezy',
      help='This flag is deprecated',
      dest='wheezy',
      action='store_false')
  other_group.add_argument('--workers', '-w',
      type=int,
      help='Number of simultaneous GN invocations',
      dest='workers',
      default=multiprocessing.cpu_count())
  other_group.add_argument('--use-crashpad',
      default=False,
      dest='use_crashpad',
      action='store_true')

  options = parser.parse_args(args)
  if not ProcessOptions(options):
    parser.print_help()
    return None
  return options


# Run the command, if it succeeds returns 0, if it fails, returns the commands
# output as a string.
def RunCommand(command):
  try:
    subprocess.check_output(
        command, cwd=DART_ROOT, stderr=subprocess.STDOUT)
    return 0
  except subprocess.CalledProcessError as e:
    return ("Command failed: " + ' '.join(command) + "\n" +
            "output: " + e.output)


def Main(argv):
  starttime = time.time()
  args = parse_args(argv)

  gn = os.path.join(DART_ROOT, 'buildtools',
      'gn.exe' if utils.IsWindows() else 'gn')
  if not os.path.isfile(gn):
    print "Couldn't find the gn binary at path: " + gn
    return 1

  commands = []
  for target_os in args.os:
    for mode in args.mode:
      for arch in args.arch:
        out_dir = GetOutDir(mode, arch, target_os)
        # TODO(infra): Re-enable --check. Many targets fail to use
        # public_deps to re-expose header files to their dependents.
        # See dartbug.com/32364
        command = [gn, 'gen', out_dir]
        gn_args = ToCommandLine(ToGnArgs(args, mode, arch, target_os))
        gn_args += GetGNArgs(args)
        if args.verbose:
          print "gn gen --check in %s" % out_dir
        if args.ide:
          command.append(ide_switch(HOST_OS))
        command.append('--args=%s' % ' '.join(gn_args))
        commands.append(command)

  pool = multiprocessing.Pool(args.workers)
  results = pool.map(RunCommand, commands, chunksize=1)
  for r in results:
    if r != 0:
      print r.strip()
      return 1

  endtime = time.time()
  if args.verbose:
    print ("GN Time: %.3f seconds" % (endtime - starttime))
  return 0


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
