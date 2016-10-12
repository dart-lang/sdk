#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import multiprocessing
import os
import subprocess
import sys
import time
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))


def get_out_dir(mode, arch, target_os):
  return utils.GetBuildRoot(HOST_OS, mode, arch, target_os)


def to_command_line(gn_args):
  def merge(key, value):
    if type(value) is bool:
      return '%s=%s' % (key, 'true' if value else 'false')
    return '%s="%s"' % (key, value)
  return [merge(x, y) for x, y in gn_args.iteritems()]


def host_cpu_for_arch(arch):
  if arch in ['ia32', 'arm', 'armv6', 'armv5te', 'mips',
              'simarm', 'simarmv6', 'simarmv5te', 'simmips', 'simdbc']:
    return 'x86'
  if arch in ['x64', 'arm64', 'simarm64', 'simdbc64']:
    return 'x64'


def target_cpu_for_arch(arch, target_os):
  if arch in ['ia32', 'simarm', 'simarmv6', 'simarmv5te', 'simmips']:
    return 'x86'
  if arch in ['simarm64']:
    return 'x64'
  if arch == 'mips':
    return 'mipsel'
  if arch == 'simdbc':
    return 'arm' if target_os == 'android' else 'x86'
  if arch == 'simdbc64':
    return 'arm64' if target_os == 'android' else 'x64'
  return arch


def host_os_for_gn(host_os):
  if host_os.startswith('macos'):
    return 'mac'
  if host_os.startswith('win'):
    return 'win'
  return host_os


def to_gn_args(args, mode, arch, target_os):
  gn_args = {}

  host_os = host_os_for_gn(HOST_OS)
  if target_os == 'host':
    gn_args['target_os'] = host_os
  else:
    gn_args['target_os'] = target_os

  gn_args['dart_target_arch'] = arch
  gn_args['target_cpu'] = target_cpu_for_arch(arch, target_os)
  gn_args['host_cpu'] = host_cpu_for_arch(arch)

  # TODO(zra): This is for the observatory, which currently builds using the
  # checked-in sdk. If/when the observatory no longer builds with the
  # checked-in sdk, this can be removed.
  pub = 'pub'
  if host_os == 'win':
    pub = pub + ".bat"
  gn_args['dart_host_pub_exe'] = os.path.join(
      DART_ROOT, 'tools', 'sdks', host_os, 'dart-sdk', 'bin', pub)

  # For Fuchsia support, the default is to not compile in the root
  # certificates.
  gn_args['dart_use_fallback_root_certificates'] = True

  gn_args['dart_zlib_path'] = "//runtime/bin/zlib"

  # Use tcmalloc only when targeting Linux and when not using ASAN.
  gn_args['dart_use_tcmalloc'] = (gn_args['target_os'] == 'linux'
                                  and not args.asan)

  gn_args['is_debug'] = mode == 'debug'
  gn_args['is_release'] = mode == 'release'
  gn_args['is_product'] = mode == 'product'
  gn_args['dart_debug'] = mode == 'debug'

  # This setting is only meaningful for Flutter. Standalone builds of the VM
  # should leave this set to 'develop', which causes the build to defer to
  # 'is_debug', 'is_release' and 'is_product'.
  gn_args['dart_runtime_mode'] = 'develop'

  # TODO(zra): Investigate using clang with these configurations.
  # Clang compiles tcmalloc's inline assembly for ia32 on Linux wrong, so we
  # don't use clang in that configuration.
  has_clang = (host_os != 'win'
               and args.os not in ['android']
               and not (gn_args['target_os'] == 'linux' and
                        gn_args['host_cpu'] == 'x86')
               and not gn_args['target_cpu'].startswith('arm')
               and not gn_args['target_cpu'].startswith('mips'))
  gn_args['is_clang'] = args.clang and has_clang

  gn_args['is_asan'] = args.asan and gn_args['is_clang']

  if args.target_sysroot:
    gn_args['target_sysroot'] = args.target_sysroot

  if args.toolchain_prefix:
    gn_args['toolchain_prefix'] = args.toolchain_prefix

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

  return gn_args


def process_os_option(os_name):
  if os_name == 'host':
    return HOST_OS
  return os_name


def process_options(args):
  if args.arch == 'all':
    args.arch = 'ia32,x64,simarm,simarm64,simmips,simdbc64'
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
             'simarmv5te', 'armv5te', 'simmips', 'mips', 'simarm64', 'arm64',
             'simdbc', 'simdbc64', 'armsimdbc']
    if not arch in archs:
      print "Unknown arch %s" % arch
      return False
  oses = [process_os_option(os_name) for os_name in args.os]
  for os_name in oses:
    if not os_name in ['android', 'freebsd', 'linux', 'macos', 'win32']:
      print "Unknown os %s" % os_name
      return False
    if os_name != HOST_OS:
      if os_name != 'android':
        print "Unsupported target os %s" % os_name
        return False
      if not HOST_OS in ['linux']:
        print ("Cross-compilation to %s is not supported on host os %s."
               % (os_name, HOST_OS))
        return False
      if not arch in ['ia32', 'x64', 'arm', 'armv6', 'armv5te', 'arm64', 'mips',
                      'simdbc', 'simdbc64']:
        print ("Cross-compilation to %s is not supported for architecture %s."
               % (os_name, arch))
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
  parser = argparse.ArgumentParser(description='A script to run `gn gen`.')

  parser.add_argument("-v", "--verbose",
      help='Verbose output.',
      default=False, action="store_true")
  parser.add_argument('--mode', '-m',
      type=str,
      help='Build variants (comma-separated).',
      metavar='[all,debug,release,product]',
      default='debug')
  parser.add_argument('--os',
      type=str,
      help='Target OSs (comma-separated).',
      metavar='[all,host,android]',
      default='host')
  parser.add_argument('--arch', '-a',
      type=str,
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64,simarm,arm,simarmv6,armv6,simarmv5te,armv5te,'
              'simmips,mips,simarm64,arm64,simdbc,armsimdbc]',
      default='x64')
  parser.add_argument('--asan',
      help='Build with ASAN',
      default=False,
      action='store_true')
  parser.add_argument('--goma',
      help='Use goma',
      default=True,
      action='store_true')
  parser.add_argument('--no-goma',
      help='Disable goma',
      dest='goma',
      action='store_false')
  parser.add_argument('--clang',
      help='Use Clang',
      default=True,
      action='store_true')
  parser.add_argument('--no-clang',
      help='Disable Clang',
      dest='clang',
      action='store_false')
  parser.add_argument('--ide',
      help='Generate an IDE file.',
      default=os_has_ide(HOST_OS),
      action='store_true')
  parser.add_argument('--target-sysroot', '-s',
      type=str,
      help='Path to the toolchain sysroot')
  parser.add_argument('--toolchain-prefix', '-t',
      type=str,
      help='Path to the toolchain prefix')
  parser.add_argument('--workers', '-w',
      type=int,
      help='Number of simultaneous GN invocations',
      dest='workers',
      default=multiprocessing.cpu_count())

  options = parser.parse_args(args)
  if not process_options(options):
    parser.print_help()
    return None
  return options


def run_command(command):
  try:
    subprocess.check_output(
        command, cwd=DART_ROOT, stderr=subprocess.STDOUT)
    return 0
  except subprocess.CalledProcessError as e:
    return ("Command failed: " + ' '.join(command) + "\n" +
            "output: " + e.output)


def main(argv):
  starttime = time.time()
  args = parse_args(argv)

  if sys.platform.startswith(('cygwin', 'win')):
    subdir = 'win'
  elif sys.platform == 'darwin':
    subdir = 'mac'
  elif sys.platform.startswith('linux'):
     subdir = 'linux64'
  else:
    print 'Unknown platform: ' + sys.platform
    return 1

  commands = []
  for target_os in args.os:
    for mode in args.mode:
      for arch in args.arch:
        command = [
          '%s/buildtools/%s/gn' % (DART_ROOT, subdir),
          'gen',
          '--check'
        ]
        gn_args = to_command_line(to_gn_args(args, mode, arch, target_os))
        out_dir = get_out_dir(mode, arch, target_os)
        if args.verbose:
          print "gn gen --check in %s" % out_dir
        if args.ide:
          command.append(ide_switch(HOST_OS))
        command.append(out_dir)
        command.append('--args=%s' % ' '.join(gn_args))
        commands.append(command)

  pool = multiprocessing.Pool(args.workers)
  results = pool.map(run_command, commands, chunksize=1)
  for r in results:
    if r != 0:
      print r.strip()
      return 1

  endtime = time.time()
  if args.verbose:
    print ("GN Time: %.3f seconds" % (endtime - starttime))
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
