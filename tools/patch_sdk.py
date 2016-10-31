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

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--dart-executable", help="dart executable", default=None)
  return result

def main():
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if options.dart_executable is not None:
    options.dart_executable = os.path.abspath(options.dart_executable)
  else:
    options.dart_executable = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
  dart_file = os.path.join(os.path.dirname(__file__), 'patch_sdk.dart')
  subprocess.check_call([options.dart_executable, dart_file] + args);

if __name__ == '__main__':
  main()
