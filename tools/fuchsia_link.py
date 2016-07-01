#!/usr/bin/env python

# Copyright (c) 2016 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script performs the final link step for Fuchsia NDK executables.
Usage:
./fuchsia_link {arm,arm64,ia32} {executable,library,shared_library}
               {host,target} [linker args]
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
  if target_arch not in ['arm64', 'x64',]:
    raise Exception(sys.argv[0] +
        " first argument must be 'arm64', or 'x64'")
  if link_type not in ['executable', 'library', 'shared_library']:
    raise Exception(sys.argv[0] +
      " second argument must be 'executable' or 'library' or 'shared_library'")
  if link_target not in ['host', 'target']:
    raise Exception(sys.argv[0] + " third argument must be 'host' or 'target'")

  # TODO(zra): Figure out how to link a shared library with the
  # cross-compilers. For now, we disable it by generating empty files
  # for the results. We disable it here to avoid inspecting the OS type in
  # the gyp files.
  if link_type == 'shared_library':
    print "NOT linking shared library for Fuchsia."
    o_index = link_args.index('-o')
    output = os.path.join(DART_ROOT, link_args[o_index + 1])
    open(output, 'a').close()
    sys.exit(0)

  # Set up path to the Fuchsia NDK.
  CheckDirExists(THIRD_PARTY_ROOT, 'third party tools')
  fuchsia_tools = os.path.join(THIRD_PARTY_ROOT, 'fuchsia_tools')
  CheckDirExists(fuchsia_tools, 'Fuchsia tools')

  # Set up the directory of the Fuchsia NDK cross-compiler toolchain.
  toolchain_arch = 'x86_64-elf-5.3.0-Linux-x86_64'
  if target_arch == 'arm64':
    toolchain_arch = 'aarch64-elf-5.3.0-Linux-x86_64'
  fuchsia_toolchain = os.path.join(
      fuchsia_tools, 'toolchains', toolchain_arch, 'bin')
  CheckDirExists(fuchsia_toolchain, 'Fuchsia toolchain')

  # Set up the path to the linker executable.
  fuchsia_linker = os.path.join(fuchsia_toolchain, 'x86_64-elf-g++')
  if target_arch == 'arm64':
    fuchsia_linker = os.path.join(fuchsia_toolchain, 'aarch64-elf-c++')

  # Grab the path to libgcc.a, which we must explicitly add to the link,
  # by invoking the cross-compiler with the -print-libgcc-file-name flag.
  fuchsia_gcc = os.path.join(fuchsia_toolchain, 'x86_64-elf-gcc')
  if target_arch == 'arm64':
    fuchsia_gcc = os.path.join(fuchsia_toolchain, 'aarch64-elf-gcc')
  fuchsia_libgcc = subprocess.check_output(
      [fuchsia_gcc, '-print-libgcc-file-name']).strip()

  # Set up the path to the system root directory, which is where we'll find the
  # Fuchsia specific system includes and libraries.
  fuchsia_sysroot = os.path.join(fuchsia_tools, 'sysroot', 'x86_64')
  if target_arch == 'arm64':
    fuchsia_sysroot = os.path.join(fuchsia_tools, 'sysroot', 'arm64')
  CheckDirExists(fuchsia_sysroot, 'Fuchsia sysroot')
  fuchsia_lib = os.path.join(fuchsia_sysroot, 'usr', 'lib')
  crtn_fuchsia = os.path.join(fuchsia_lib, 'crtn.o')

  if link_target == 'target':
    # Add and remove libraries as listed in configurations_fuchsia.gypi
    libs_to_rm = ['-lrt', '-lpthread', '-ldl']
    libs_to_add = [fuchsia_libgcc, '-lc',]

    # Add crtn_fuchsia to end if we are linking an executable.
    if link_type == 'executable':
      libs_to_add.extend([crtn_fuchsia])

    link_args = [i for i in link_args if i not in libs_to_rm]
    link_args.extend(libs_to_add)

    link_args.insert(0, fuchsia_linker)
  else:
    link_args.extend(['-ldl', '-lrt'])
    link_args.insert(0, 'g++')

  print ' '.join(link_args)
  sys.exit(execute(link_args))

if __name__ == '__main__':
  main()
