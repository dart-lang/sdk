#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import string
import subprocess
import sys

import utils


def Main():
  args = sys.argv[1:]
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  dart_script_name = 'test.dart'
  dart_test_script = string.join([tools_dir, dart_script_name], os.sep)
  command = [utils.DartBinary(), '--checked', dart_test_script] + args
  exit_code = subprocess.call(command)
  utils.DiagnoseExitCode(exit_code, command)
  return exit_code


if __name__ == '__main__':
  sys.exit(Main())
