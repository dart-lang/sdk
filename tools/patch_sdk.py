#!/usr/bin/env python
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import utils

usage = """patch_sdk.py [options]"""

def DisplayBootstrapWarning():
  print """\


WARNING: Your system cannot run the checked-in Dart SDK. Using the
bootstrap Dart executable will make debug builds slow.
Please see the Wiki for instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools

"""

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("-q", "--quiet",
                      help="emit no output",
                      default=False,
                      action="store_true")
  result.add_argument("--dart-executable",
                      help="dart executable",
                      default=None)
  result.add_argument("--script",
                      help="patch script to run",
                      default=None)
  return result

def main():
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if utils.CheckedInSdkCheckExecutable():
    options.dart_executable = utils.CheckedInSdkExecutable()
  elif options.dart_executable is not None:
    if not options.quiet:
      DisplayBootstrapWarning()
    options.dart_executable = os.path.abspath(options.dart_executable)
  else:
    print >> sys.stderr, 'ERROR: cannot locate dart executable'
    return -1

  if options.script is not None:
    dart_file = options.script
  else:
    dart_file = os.path.join(os.path.dirname(__file__), 'patch_sdk.dart')

  subprocess.check_call([options.dart_executable, dart_file] + args)
  return 0

if __name__ == '__main__':
  sys.exit(main())
