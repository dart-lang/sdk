#!/usr/bin/env python
#
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script runs the parser which is generated using ANTLR 3 from
# docs/language/Dart.g. It relies on a certain environment and is hence
# usable locally where this environment can be obtained, but it may not be
# possible to run it, e.g., on build bots. The requirements are as follows:
#
#   - `make parser` in spec_parser has been executed successfully.
#   - A suitable JVM is in the PATH and may be executed as 'java'.
#   - the ANTLR3 jar is available as /usr/share/java/antlr3-runtime.jar.

import os
import string
import subprocess
import sys

import utils


def Help(missing):
  print('Execution of the spec parser failed. Missing: ' + missing)
  print('Please read the comment near the top of spec_parse.py.\n')
  sys.exit(1)


def Main():
  args = sys.argv[1:]
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  spec_parser_dir = os.path.join(tools_dir, 'spec_parser')
  spec_parser_file = os.path.join(spec_parser_dir, 'SpecParser.class')
  antlr_jar = '/usr/share/java/antlr3-runtime.jar'
  class_path = string.join([spec_parser_dir, antlr_jar], ':')
  command = ['java', '-cp', class_path, 'SpecParser'] + args

  if not os.path.exists(antlr_jar): Help(antlr_jar)
  if not os.path.exists(spec_parser_file): Help('"make parser" in spec_parser')

  with utils.CoreDumpArchiver(args):
    exit_code = subprocess.call(command)

  utils.DiagnoseExitCode(exit_code, command)
  return exit_code


if __name__ == '__main__':
  sys.exit(Main())
