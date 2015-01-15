#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Helper for building and deploying Observatory"""

import argparse
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
RUN_PUB = os.path.join(DART_ROOT, 'tools/run_pub.py')
IGNORE_PATTERNS = shutil.ignore_patterns(
    '*.map',
    '*.concat.js',
    '*.scriptUrls',
    '*.precompiled.js',
    'main.*',
    'unittest*',
    '*_buildLogs*',
    '*.log',
    '*~')

usage = """obs_tool.py [options]"""

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--package-root", help="package root", default=None)
  result.add_argument("--dart-executable", help="dart executable", default=None)
  result.add_argument("--directory", help="observatory root", default=None)
  result.add_argument("--command", help="[get, build, deploy]", default=None)
  return result

def ProcessOptions(options, args):
  return ((options.package_root != None) and
          (options.directory != None) and
          (options.command != None) and
          (options.dart_executable != None))

def ChangeDirectory(directory):
  os.chdir(directory);

def PubGet(dart_executable, pkg_root):
  return subprocess.call(['python',
                          RUN_PUB,
                          '--package-root=' + pkg_root,
                          '--dart-executable=' + dart_executable,
                          'get',
                          '--offline'])

def PubBuild(dart_executable, pkg_root, output_dir):
  return subprocess.call(['python',
                          RUN_PUB,
                          '--package-root=' + pkg_root,
                          '--dart-executable=' + dart_executable,
                          'build',
                          '--output',
                          output_dir])

def Deploy(input_dir, output_dir):
  shutil.rmtree(output_dir)
  shutil.copytree(input_dir, output_dir, ignore=IGNORE_PATTERNS)
  return 0

def ExecuteCommand(options, args):
  cmd = options.command
  if (cmd == 'get'):
    return PubGet(options.dart_executable, options.package_root)
  elif (cmd == 'build'):
    return PubBuild(options.dart_executable, options.package_root, args[0])
  elif (cmd == 'deploy'):
    Deploy('build', 'deployed')
  else:
    print >> sys.stderr, ('ERROR: command "%s" not supported') % (cmd)
    return -1;

def main():
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if not ProcessOptions(options, args):
    parser.print_help()
    return 1
  if os.getenv('DART_USE_BOOTSTRAP_BIN') != None:
    dart_executable = options.dart_executable
  # Calculate absolute paths before changing directory.
  options.package_root = os.path.abspath(options.package_root)
  options.dart_executable = os.path.abspath(options.dart_executable)
  if len(args) == 1:
    args[0] = os.path.abspath(args[0])
  # Pub must be run from the project's root directory.
  ChangeDirectory(options.directory)
  return ExecuteCommand(options, args)

if __name__ == '__main__':
  sys.exit(main());