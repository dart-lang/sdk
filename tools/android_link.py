#!/usr/bin/env python

# Copyright (c) 2012 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script performs the final link step for Android NDK executables.
Usage:
./android_link {arm,ia32} {executable,library,shared_library} {host,target}
               [linker args]
"""

import os
import subprocess
import sys

# Figure out where we are.
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
THIRD_PARTY_ROOT = os.path.join(DART_ROOT, 'third_party')


def CheckDirExists(path, docstring):
  if not os.path.isdir(path):
    raise Exception('Could not find %s directory %s'
          % (docstring, path))


def execute(args):
  process = subprocess.Popen(args)
  process.wait()
  return process.returncode


def main():
  if len(sys.argv) < 5:
    raise Exception(sys.argv[0] + " failed: not enough arguments")

  # gyp puts -shared first in a shared_library link. Remove it.
  if sys.argv[1] == '-shared':
    sys.argv.remove('-shared')

  # Grab the command line arguments.
  target_arch = sys.argv[1]
  link_type = sys.argv[2]
  link_target = sys.argv[3]
  link_args = sys.argv[4:]

  # Check arguments.
  if target_arch not in ['arm', 'ia32']:
    raise Exception(sys.argv[0] + " first argument must be 'arm' or 'ia32'")
  if link_type not in ['executable', 'library', 'shared_library']:
    raise Exception(sys.argv[0] +
                    " second argument must be 'executable' or 'library'")
  if link_target not in ['host', 'target']:
    raise Exception(sys.argv[0] + " third argument must be 'host' or 'target'")

  # TODO(zra): Figure out how to link a shared library with the NDK
  # cross-compilers. For now, we disable it by generating empty files
  # for the results. We disable it here to avoid inspecting the OS type in
  # the gyp files.
  if link_type == 'shared_library':
    print "NOT linking shared library for Android."
    o_index = link_args.index('-o')
    output = os.path.join(DART_ROOT, link_args[o_index + 1])
    open(output, 'a').close()
    sys.exit(0)

  # Set up path to the Android NDK.
  CheckDirExists(THIRD_PARTY_ROOT, 'third party tools')
  android_tools = os.path.join(THIRD_PARTY_ROOT, 'android_tools')
  CheckDirExists(android_tools, 'Android tools')
  android_ndk_root = os.path.join(android_tools, 'ndk')
  CheckDirExists(android_ndk_root, 'Android NDK')

  # Set up the directory of the Android NDK cross-compiler toolchain.
  toolchain_arch = 'arm-linux-androideabi-4.6'
  if target_arch == 'ia32':
    toolchain_arch = 'x86-4.6'
  toolchain_dir = 'linux-x86_64'
  android_toolchain = os.path.join(android_ndk_root,
      'toolchains', toolchain_arch,
      'prebuilt', toolchain_dir, 'bin')
  CheckDirExists(android_toolchain, 'Android toolchain')

  # Set up the path to the linker executable.
  android_linker = os.path.join(android_toolchain, 'arm-linux-androideabi-g++')
  if target_arch == 'ia32':
    android_linker = os.path.join(android_toolchain, 'i686-linux-android-g++')

  # Grab the path to libgcc.a, which we must explicitly add to the link,
  # by invoking the cross-compiler with the -print-libgcc-file-name flag.
  android_gcc = os.path.join(android_toolchain, 'arm-linux-androideabi-gcc')
  if target_arch == 'ia32':
    android_gcc = os.path.join(android_toolchain, 'i686-linux-android-gcc')
  android_libgcc = subprocess.check_output(
      [android_gcc, '-print-libgcc-file-name']).strip()

  # Set up the path to the system root directory, which is where we'll find the
  # Android specific system includes and libraries.
  android_ndk_sysroot = os.path.join(android_ndk_root,
      'platforms', 'android-14', 'arch-arm')
  if target_arch == 'ia32':
    android_ndk_sysroot = os.path.join(android_ndk_root,
        'platforms', 'android-14', 'arch-x86')
  CheckDirExists(android_ndk_sysroot, 'Android sysroot')
  android_ndk_lib = os.path.join(android_ndk_sysroot,'usr','lib')
  android_ndk_include = os.path.join(android_ndk_sysroot, 'usr', 'include')
  crtend_android = os.path.join(android_ndk_lib, 'crtend_android.o')

  if link_target == 'target':
    # Add and remove libraries as listed in configurations_android.gypi
    libs_to_rm = ['-lrt', '-lpthread', '-lnss3', '-lnssutil3', '-lsmime3',
                  '-lplds4', '-lplc4', '-lnspr4',]
    libs_to_add = ['-lstlport_static', android_libgcc, '-lc', '-ldl',
                   '-lstdc++', '-lm',]

    # Add crtend_android to end if we are linking an executable.
    if link_type == 'executable':
      libs_to_add.extend(['-llog', '-lz', crtend_android])

    link_args = [i for i in link_args if i not in libs_to_rm]
    link_args.extend(libs_to_add)

    link_args.insert(0, android_linker)
  else:
    link_args.extend(['-ldl', '-lrt'])
    link_args.insert(0, 'g++')

  sys.exit(execute(link_args))

if __name__ == '__main__':
  main()
