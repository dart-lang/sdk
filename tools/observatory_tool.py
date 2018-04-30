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
DART2JS_PATH = os.path.join(DART_ROOT, 'pkg', 'compiler', 'bin', 'dart2js.dart')
IGNORE_PATTERNS = shutil.ignore_patterns(
    '$sdk',
    '*.concat.js',
    '*.dart',
    '*.log',
    '*.map',
    '*.precompiled.js',
    '*.scriptUrls',
    '*_buildLogs*',
    '*~',
    'CustomElements.*',
    'HTMLImports.*',
    'MutationObserver.*',
    'ShadowDOM.*',
    'bower.json',
    'dart_support.*',
    'interop_support.*',
    'package.json',
    'unittest*',
    'webcomponents-lite.js',
    'webcomponents.*')

usage = """observatory_tool.py [options]"""

def DisplayBootstrapWarning():
  print """\

WARNING: Your system cannot run the checked-in Dart SDK. Using the
bootstrap Dart executable will make debug builds slow.
Please see the Wiki for instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools

To use the dart_bootstrap binary please update the Build function
in the tools/observatory_tool.py script.

"""

def DisplayFailureMessage():
  print """\

ERROR: Observatory failed to build. What should you do?

1. Revert to a working revision of the Dart VM
2. Contact zra@, rmacnak@, dart-vm-team@
3. File a bug: https://github.com/dart-lang/sdk/issues/new

"""

# Run |command|. If its return code is 0, return 0 and swallow its output.
# If its return code is non-zero, emit its output unless |always_silent| is
# True, and return the return code.
def RunCommand(command, always_silent=False):
  try:
    subprocess.check_output(command,
                            stderr=subprocess.STDOUT)
    return 0
  except subprocess.CalledProcessError as e:
    if not always_silent:
      print ("Command failed: " + ' '.join(command) + "\n" +
              "output: " + e.output)
      DisplayFailureMessage()
    return e.returncode

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--dart-executable", help="dart executable", default=None)
  result.add_argument("--dart2js-executable", help="dart2js executable",
                      default=None)
  result.add_argument("--directory", help="observatory root", default=None)
  result.add_argument("--command", help="[build, deploy]", default=None)
  result.add_argument("--silent", help="silence all output", default=None)
  result.add_argument("--sdk", help="Use prebuilt sdk", default=None)
  return result

def ProcessOptions(options, args):
  # Fix broken boolean parsing in argparse, where False ends up being True.
  if (options.silent is not None) and (options.silent == "True"):
    options.silent = True
  elif (options.silent is None) or (options.silent == "False"):
    options.silent = False
  else:
    print "--silent expects 'True' or 'False' argument."
    return False

  if (options.sdk is not None) and (options.sdk == "True"):
    options.sdk = True
  elif (options.sdk is None) or (options.sdk == "False"):
    options.sdk = False
  else:
    print "--sdk expects 'True' or 'False' argument."
    return False

  # Required options.
  if options.command is None or options.directory is None:
    return False

  # If a dart2js execuble was provided, try and use that.
  # TODO(whesse): Drop the dart2js-executable option if it isn't used.
  if options.dart2js_executable is not None:
    try:
      if 0 == RunCommand([options.dart2js_executable, '--version'],
                         always_silent=True):
        return True
    except OSError as e:
      pass
  options.dart2js_executable = None

  # Use the checked in dart2js executable.
  if options.sdk and utils.CheckedInSdkCheckExecutable():
    dart2js_binary = 'dart2js.bat' if utils.IsWindows() else 'dart2js'
    options.dart2js_executable = os.path.join(utils.CheckedInSdkPath(),
                                             'bin',
                                             dart2js_binary)
    try:
      if 0 == RunCommand([options.dart2js_executable, '--version'],
                         always_silent=True):
        return True
    except OSError as e:
      pass
  options.dart2js_executable = None

  # We need a dart executable and will run from source
  return (options.dart_executable is not None)

def ChangeDirectory(directory):
  os.chdir(directory);

# - Copy over the filtered web directory
# - Merge in the .js file
# - Copy over the filtered dependency lib directories
# - Copy over the filtered observatory package
def Deploy(output_dir, web_dir, observatory_lib, js_file, pub_packages_dir):
  shutil.rmtree(output_dir)
  os.makedirs(output_dir)

  output_web_dir = os.path.join(output_dir, 'web')
  shutil.copytree(web_dir, output_web_dir, ignore=IGNORE_PATTERNS)
  os.utime(os.path.join(output_web_dir, 'index.html'), None)

  shutil.copy(js_file, output_web_dir)

  packages_dir = os.path.join(output_web_dir, 'packages')
  os.makedirs(packages_dir)
  for subdir in os.listdir(pub_packages_dir):
    libdir = os.path.join(pub_packages_dir, subdir, 'lib')
    if os.path.isdir(libdir):
      shutil.copytree(libdir, os.path.join(packages_dir, subdir),
                      ignore=IGNORE_PATTERNS)
  shutil.copytree(observatory_lib, os.path.join(packages_dir, 'observatory'),
                  ignore=IGNORE_PATTERNS)

def Build(dart_executable,
          dart2js_executable,
          script_path,
          output_path,
          packages_path,
          silent):
  if dart2js_executable is not None:
    command = [dart2js_executable]
  else:
    if not silent:
      DisplayBootstrapWarning()
    command = [dart_executable, DART2JS_PATH]
  command += ['-DOBS_VER=' + utils.GetVersion(no_git_hash=True)]
  command += [script_path, '-o', output_path, '--packages=%s' % packages_path]
  # Add the defaults pub used
  command += ['--minify']
  if not silent:
    print >> sys.stderr, 'Running command "%s"' % command
  return RunCommand(command)

def ExecuteCommand(options, args):
  cmd = options.command
  if (cmd == 'build'):
    return Build(options.dart_executable,
                 options.dart2js_executable,
                 args[0],
                 args[1],
                 args[2],
                 options.silent)
  elif (cmd == 'deploy'):
    Deploy(args[0], args[1], args[2], args[3], args[4])
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
  if (options.dart_executable != None):
    options.dart_executable = os.path.abspath(options.dart_executable)
  if (options.dart2js_executable != None):
    options.dart2js_executable = os.path.abspath(options.dart2js_executable)
  if len(args) == 1:
    args[0] = os.path.abspath(args[0])
  try:
    # Pub must be run from the project's root directory.
    ChangeDirectory(options.directory)
    return ExecuteCommand(options, args)
  except:
    DisplayFailureMessage()

if __name__ == '__main__':
  sys.exit(main());
