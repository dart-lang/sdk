#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Used to run pub before the SDK has been built"""

import argparse
import os
import platform
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
PUB_PATH = os.path.join(DART_ROOT, 'third_party/pkg/pub/bin/pub.dart')
CANARY_PATH = os.path.join(DART_ROOT, 'tools', 'canary.dart')

usage = """run_pub.py --package-root=<package root>"""

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--package-root", help="package root", default=None)
  result.add_argument("--dart-executable", help="dart binary", default=None)
  return result

def ProcessOptions(options, args):
  return ((options.package_root != None) and
          (options.dart_executable != None))

def GetPrebuiltDartExecutablePath(suffix):
  osdict = {'Darwin':'macos', 'Linux':'linux', 'Windows':'windows'}
  system = platform.system()
  executable_name = 'dart'
  if system == 'Windows':
    executable_name = 'dart.exe'
  try:
    osname = osdict[system]
  except KeyError:
    print >>sys.stderr, ('WARNING: platform "%s" not supported') % (system)
    return None;
  return os.path.join(DART_ROOT,
                      'tools',
                      'testing',
                      'bin',
                      osname,
                      executable_name + suffix)

def RunPub(dart, pkg_root, args):
  return subprocess.call([dart, '--package-root=' + pkg_root, PUB_PATH] + args)

def TryRunningExecutable(dart_executable, pkg_root):
  try:
    return subprocess.call([dart_executable,
                            '--package-root=' + pkg_root,
                            CANARY_PATH]) == 42
  except:
    return False;

def DisplayBootstrapWarning():
  print """\


WARNING: Your system cannot run the prebuilt Dart executable. Using the
bootstrap Dart executable will make Debug builds long.
Please see Wiki for instructions on replacing prebuilt Dart executable.

https://code.google.com/p/dart/wiki/ReplacingPrebuiltDartExecutable

"""

def FindDartExecutable(fallback_executable, package_root):
  # If requested, use the bootstrap binary instead of the prebuilt
  # executable.
  if os.getenv('DART_USE_BOOTSTRAP_BIN') != None:
    return fallback_executable
  # Try to find a working prebuilt dart executable.
  dart_executable = GetPrebuiltDartExecutablePath('')
  if TryRunningExecutable(dart_executable, package_root):
    return dart_executable
  dart_executable = GetPrebuiltDartExecutablePath('-arm')
  if TryRunningExecutable(dart_executable, package_root):
    return dart_executable
  dart_executable = GetPrebuiltDartExecutablePath('-mips')
  if TryRunningExecutable(dart_executable, package_root):
    return dart_executable
  # If the system cannot execute a prebuilt dart executable, use the bootstrap
  # executable instead.
  DisplayBootstrapWarning()
  return fallback_executable

def main():
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if not ProcessOptions(options, args):
    parser.print_help()
    return 1
  dart_executable = FindDartExecutable(options.dart_executable,
                                       options.package_root)
  return RunPub(dart_executable, options.package_root, args)


if __name__ == '__main__':
  sys.exit(main())
