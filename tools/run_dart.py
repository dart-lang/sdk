#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import utils

usage = """run_dart.py [--dart=<path>] <script> args..."""

def DisplayBootstrapWarning():
  print """\


WARNING: Your system cannot run the checked-in Dart SDK. Using the
bootstrap Dart executable will make debug builds slow.
Please see the Wiki for instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools

"""

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--dart",
                      help="dart executable",
                      default=None)
  result.add_argument("-q", "--quiet",
                      help="emit no output",
                      default=False,
                      action="store_true")
  return result

def main():
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if utils.CheckedInSdkCheckExecutable():
    options.dart_executable = utils.CheckedInSdkExecutable()
  elif options.dart_executable is not None:
    DisplayBootstrapWarning()
    options.dart_executable = os.path.abspath(options.dart_executable)
  else:
    print >> sys.stderr, 'ERROR: cannot locate dart executable'
    return -1

  if options.quiet:
    # Pipe output to /dev/null. See https://stackoverflow.com/a/14736249/9457.
    out = open(os.devnull, 'w')
  else:
    out = None

  return subprocess.call([options.dart_executable] + args,
      stdout=out, stderr=out)

if __name__ == '__main__':
  sys.exit(main())
