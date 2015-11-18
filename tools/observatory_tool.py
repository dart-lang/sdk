#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Helper for building and deploying Observatory"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
import utils

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
PUB_PATH = os.path.join(DART_ROOT, 'third_party', 'pkg',
                        'pub', 'bin', 'pub.dart')
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

usage = """observatory_tool.py [options]"""

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--package-root", help="package root", default=None)
  result.add_argument("--dart-executable", help="dart executable", default=None)
  result.add_argument("--pub-executable", help="pub executable", default=None)
  result.add_argument("--directory", help="observatory root", default=None)
  result.add_argument("--command", help="[get, build, deploy]", default=None)
  result.add_argument("--silent", help="silence all output", default=False)
  result.add_argument("--sdk", help="Use prebuilt sdk", default=False)
  return result

def ProcessOptions(options, args):
  with open(os.devnull, 'wb') as silent_sink:
    # Required options.
    if options.command is None or options.directory is None:
      return False

    # Set a default value for pub_snapshot.
    options.pub_snapshot = None

    # If we have a working pub executable, try and use that.
    # TODO(whesse): Drop the pub-executable option if it isn't used.
    if options.pub_executable is not None:
      try:
        if 0 == subprocess.call([options.pub_executable, '--version'],
                                stdout=silent_sink,
                                stderr=silent_sink):
          return True
      except OSError as e:
        pass
    options.pub_executable = None

    if options.sdk is not None and utils.CheckedInSdkCheckExecutable():
      # Use the checked in pub executable.
      options.pub_snapshot = os.path.join(utils.CheckedInSdkPath(),
                                          'bin',
                                          'snapshots',
                                          'pub.dart.snapshot');
      try:
        if 0 == subprocess.call([utils.CheckedInSdkExecutable(),
                                 options.pub_snapshot,
                                 '--version'],
                                 stdout=silent_sink,
                                 stderr=silent_sink):
          return True
      except OSError as e:
        pass
    options.pub_snapshot = None

    # We need a dart executable and a package root.
    return (options.package_root is not None and
            options.dart_executable is not None)

def ChangeDirectory(directory):
  os.chdir(directory);

def DisplayBootstrapWarning():
  print """\


WARNING: Your system cannot run the checked-in Dart SDK. Using the
bootstrap Dart executable will make debug builds slow.
Please see the Wiki for instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in--tools

"""

def PubCommand(dart_executable,
               pub_executable,
               pub_snapshot,
               pkg_root,
               command,
               silent):
  with open(os.devnull, 'wb') as silent_sink:
    if pub_executable is not None:
      executable = [pub_executable]
    elif pub_snapshot is not None:
      executable = [utils.CheckedInSdkExecutable(), pub_snapshot]
    else:
      DisplayBootstrapWarning()
      executable = [dart_executable, '--package-root=' + pkg_root, PUB_PATH]
    return subprocess.call(executable + command,
                           stdout=silent_sink if silent else None,
                           stderr=silent_sink if silent else None)

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
    # Always remove pubspec.lock before running 'pub get'.
    try:
      os.remove('pubspec.lock');
    except OSError as e:
      pass
    return PubCommand(options.dart_executable,
                      options.pub_executable,
                      options.pub_snapshot,
                      options.package_root,
                      ['get', '--offline'],
                      options.silent)
  elif (cmd == 'build'):
    return PubCommand(options.dart_executable,
                      options.pub_executable,
                      options.pub_snapshot,
                      options.package_root,
                      ['build',
                       '-DOBS_VER=' + utils.GetVersion(),
                       '--output', args[0]],
                      options.silent)
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
  # Calculate absolute paths before changing directory.
  if (options.package_root != None):
    options.package_root = os.path.abspath(options.package_root)
  if (options.dart_executable != None):
    options.dart_executable = os.path.abspath(options.dart_executable)
  if (options.pub_executable != None):
    options.pub_executable = os.path.abspath(options.pub_executable)
  if (options.pub_snapshot != None):
    options.pub_snapshot = os.path.abspath(options.pub_snapshot)
  if len(args) == 1:
    args[0] = os.path.abspath(args[0])
  # Pub must be run from the project's root directory.
  ChangeDirectory(options.directory)
  return ExecuteCommand(options, args)

if __name__ == '__main__':
  sys.exit(main());
