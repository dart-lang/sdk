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
  result.add_argument("--pub-executable", help="pub executable", default=None)
  result.add_argument("--directory", help="observatory root", default=None)
  result.add_argument("--command", help="[get, build, deploy]", default=None)
  result.add_argument("--silent", help="silence all output", default=False)
  return result

def ProcessOptions(options, args):
  # Required options.
  if (options.command == None) or (options.directory == None):
    return False
  # If we have a pub executable, we are running from the dart-sdk.
  if (options.pub_executable != None):
    return True
  # Otherwise, we need a dart executable and a package root.
  return ((options.package_root != None) and
          (options.dart_executable != None))

def ChangeDirectory(directory):
  os.chdir(directory);

def PubGet(dart_executable, pub_executable, pkg_root, silent):
  # Always remove pubspec.lock before running 'pub get'.
  try:
    os.remove('pubspec.lock');
  except OSError as e:
    pass
  with open(os.devnull, 'wb') as silent_sink:
    if (pub_executable != None):
      return subprocess.call([pub_executable,
                              'get',
                              '--offline'],
                              stdout=silent_sink if silent else None,
                              stderr=silent_sink if silent else None)
    else:
      return subprocess.call(['python',
                              RUN_PUB,
                              '--package-root=' + pkg_root,
                              '--dart-executable=' + dart_executable,
                              'get',
                              '--offline'],
                              stdout=silent_sink if silent else None,
                              stderr=silent_sink if silent else None,)

def PubBuild(dart_executable, pub_executable, pkg_root, silent, output_dir):
  with open(os.devnull, 'wb') as silent_sink:
    if (pub_executable != None):
      return subprocess.call([pub_executable,
                              'build',
                              '--output',
                              output_dir],
                              stdout=silent_sink if silent else None,
                              stderr=silent_sink if silent else None,)
    else:
      return subprocess.call(['python',
                              RUN_PUB,
                              '--package-root=' + pkg_root,
                              '--dart-executable=' + dart_executable,
                              'build',
                              '--output',
                              output_dir],
                              stdout=silent_sink if silent else None,
                              stderr=silent_sink if silent else None,)

def Deploy(input_dir, output_dir):
  shutil.rmtree(output_dir)
  shutil.copytree(input_dir, output_dir, ignore=IGNORE_PATTERNS)
  index_file = os.path.join(output_dir, 'web', 'index.html')
  os.utime(index_file, None)
  return 0

def RewritePubSpec(input_path, output_path, search, replace):
  with open(input_path, 'rb') as input_file:
    input_data = input_file.read()
    input_data = input_data.replace(search, replace)
    with open(output_path, 'wb+') as output_file:
      output_file.write(input_data)

def ExecuteCommand(options, args):
  cmd = options.command
  if (cmd == 'get'):
    return PubGet(options.dart_executable,
                  options.pub_executable,
                  options.package_root,
                  options.silent)
  elif (cmd == 'build'):
    return PubBuild(options.dart_executable,
                    options.pub_executable,
                    options.package_root,
                    options.silent,
                    args[0])
  elif (cmd == 'deploy'):
    Deploy('build', 'deployed')
  elif (cmd == 'rewrite'):
    RewritePubSpec(args[0], args[1], args[2], args[3])
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
  if (options.package_root != None):
    options.package_root = os.path.abspath(options.package_root)
  if (options.dart_executable != None):
    options.dart_executable = os.path.abspath(options.dart_executable)
  if (options.pub_executable != None):
    options.pub_executable = os.path.abspath(options.pub_executable)
  if len(args) == 1:
    args[0] = os.path.abspath(args[0])
  # Pub must be run from the project's root directory.
  ChangeDirectory(options.directory)
  return ExecuteCommand(options, args)

if __name__ == '__main__':
  sys.exit(main());