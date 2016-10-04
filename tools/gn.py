#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import subprocess
import sys
import os
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
HOST_CPUS = utils.GuessCpus()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))

def get_out_dir(args):
  return utils.GetBuildRoot(HOST_OS, args.mode, args.arch, args.os)

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

def target_cpu_for_arch(arch, os):
  if arch in ['ia32', 'simarm', 'simarmv6', 'simarmv5te', 'simmips']:
    return 'x86'
  if arch in ['simarm64']:
    return 'x64'
  if arch == 'mips':
    return 'mipsel'
  if arch == 'simdbc':
    return 'arm' if os == 'android' else 'x86'
  if arch == 'simdbc64':
    return 'arm64' if os == 'android' else 'x64'
  return arch

def host_os_for_gn(os):
  if os.startswith('macos'):
    return 'mac'
  if os.startswith('win'):
    return 'win'
  return os

def to_gn_args(args):
  gn_args = {}

  host_os = host_os_for_gn(HOST_OS)
  if args.os == 'host':
    gn_args['target_os'] = host_os
  else:
    gn_args['target_os'] = args.os

  gn_args['dart_target_arch'] = args.arch
  gn_args['target_cpu'] = target_cpu_for_arch(args.arch, args.os)
  gn_args['host_cpu'] = host_cpu_for_arch(args.arch)

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

  gn_args['dart_use_tcmalloc'] = gn_args['target_os'] == 'linux'

  gn_args['is_debug'] = args.mode == 'debug'
  gn_args['is_release'] = args.mode == 'release'
  gn_args['is_product'] = args.mode == 'product'
  gn_args['dart_debug'] = args.mode == 'debug'

  # This setting is only meaningful for Flutter. Standalone builds of the VM
  # should leave this set to 'develop', which causes the build to defer to
  # 'is_debug', 'is_release' and 'is_product'.
  gn_args['dart_runtime_mode'] = 'develop'

  if host_os == 'win':
    gn_args['is_clang'] = False
  else:
    gn_args['is_clang'] = args.clang and args.os not in ['android']

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

def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(description='A script run` gn gen`.')

  parser.add_argument('--mode', '-m',
      type=str,
      choices=['debug', 'release', 'product'],
      default='debug')
  parser.add_argument('--os',
      type=str,
      choices=['host', 'android'],
      default='host')
  parser.add_argument('--arch', '-a',
      type=str,
      choices=['ia32', 'x64', 'simarm', 'arm', 'simarmv6', 'armv6',
               'simarmv5te', 'armv5te', 'simmips', 'mips', 'simarm64', 'arm64',
               'simdbc', 'simdbc64'],
      default='x64')

  parser.add_argument('--goma', default=True, action='store_true')
  parser.add_argument('--no-goma', dest='goma', action='store_false')

  parser.add_argument('--clang', default=True, action='store_true')
  parser.add_argument('--no-clang', dest='clang', action='store_false')

  parser.add_argument('--target-sysroot', '-s', type=str)
  parser.add_argument('--toolchain-prefix', '-t', type=str)

  return parser.parse_args(args)

def main(argv):
  args = parse_args(argv)

  if sys.platform.startswith(('cygwin', 'win')):
    subdir = 'win'
  elif sys.platform == 'darwin':
    subdir = 'mac'
  elif sys.platform.startswith('linux'):
     subdir = 'linux64'
  else:
    raise Error('Unknown platform: ' + sys.platform)

  command = [
    '%s/buildtools/%s/gn' % (DART_ROOT, subdir),
    'gen',
    '--check'
  ]
  gn_args = to_command_line(to_gn_args(args))
  out_dir = get_out_dir(args)
  print "gn gen --check in %s" % out_dir
  command.append(out_dir)
  command.append('--args=%s' % ' '.join(gn_args))
  return subprocess.call(command, cwd=DART_ROOT)

if __name__ == '__main__':
    sys.exit(main(sys.argv))
