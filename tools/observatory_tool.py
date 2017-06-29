#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Helper for building and deploying Observatory"""

import argparse
import os
import platform
import shutil
import socket
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
    'bower.json',
    'package.json',
    'CustomElements.*',
    'dart_support.*',
    'interop_support.*',
    'HTMLImports.*',
    'MutationObserver.*',
    'ShadowDOM.*',
    'webcomponents.*',
    'webcomponents-lite.js',
    'unittest*',
    '*_buildLogs*',
    '*.log',
    '*~')

usage = """observatory_tool.py [options]"""

def DisplayBootstrapWarning():
  print """\

WARNING: Your system cannot run the checked-in Dart SDK. Using the
bootstrap Dart executable will make debug builds slow.
Please see the Wiki for instructions on replacing the checked-in Dart SDK.

https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools

To use the dart_bootstrap binary please update the PubCommand function
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
    # Dart IO respects the following environment variables to configure the
    # HttpClient proxy: https://api.dartlang.org/stable/1.22.1/dart-io/HttpClient/findProxyFromEnvironment.html
    # We strip these to avoid problems with pub build and transformers.
    no_http_proxy_env = os.environ.copy()
    no_http_proxy_env.pop('http_proxy', None)
    no_http_proxy_env.pop('HTTP_PROXY', None)
    no_http_proxy_env.pop('https_proxy', None)
    no_http_proxy_env.pop('HTTPS_PROXY', None)
    subprocess.check_output(command,
                            stderr=subprocess.STDOUT,
                            env=no_http_proxy_env)
    return 0
  except subprocess.CalledProcessError as e:
    if not always_silent:
      print ("Command failed: " + ' '.join(command) + "\n" +
              "output: " + e.output)
      DisplayFailureMessage()
    return e.returncode

def CreateTimestampFile(options):
  if options.stamp != '':
    dir_name = os.path.dirname(options.stamp)
    if dir_name != '':
      if not os.path.exists(dir_name):
        os.mkdir(dir_name)
    open(options.stamp, 'w').close()

def BuildArguments():
  result = argparse.ArgumentParser(usage=usage)
  result.add_argument("--dart-executable", help="dart executable", default=None)
  result.add_argument("--pub-executable", help="pub executable", default=None)
  result.add_argument("--directory", help="observatory root", default=None)
  result.add_argument("--command", help="[get, build, deploy]", default=None)
  result.add_argument("--silent", help="silence all output", default=None)
  result.add_argument("--sdk", help="Use prebuilt sdk", default=None)
  result.add_argument("--stamp", help="Write a stamp file", default='')
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

  # Set a default value for pub_snapshot.
  options.pub_snapshot = None

  # If we have a working pub executable, try and use that.
  # TODO(whesse): Drop the pub-executable option if it isn't used.
  if options.pub_executable is not None:
    try:
      if 0 == RunCommand([options.pub_executable, '--version'],
                         always_silent=True):
        return True
    except OSError as e:
      pass
  options.pub_executable = None

  if options.sdk and utils.CheckedInSdkCheckExecutable():
    # Use the checked in pub executable.
    options.pub_snapshot = os.path.join(utils.CheckedInSdkPath(),
                                        'bin',
                                        'snapshots',
                                        'pub.dart.snapshot');
    try:
      if 0 == RunCommand([utils.CheckedInSdkExecutable(),
                          options.pub_snapshot,
                          '--version'], always_silent=True):
        return True
    except OSError as e:
      pass
  options.pub_snapshot = None

  # We need a dart executable.
  return (options.dart_executable is not None)

def ChangeDirectory(directory):
  os.chdir(directory);

def PubCommand(dart_executable,
               pub_executable,
               pub_snapshot,
               command,
               silent):
  if pub_executable is not None:
    executable = [pub_executable]
  elif pub_snapshot is not None:
    executable = [utils.CheckedInSdkExecutable(), pub_snapshot]
  else:
    if not silent:
      DisplayBootstrapWarning()
    executable = [dart_executable, PUB_PATH]
    # Prevent the bootstrap Dart executable from running in regular
    # development flow.
    # REMOVE THE FOLLOWING LINE TO USE the dart_bootstrap binary.
    # return False
  if not silent:
    print >> sys.stderr, ('Running command "%s"') % (executable + command)
  return RunCommand(executable + command)

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
                      ['get', '--offline'],
                      options.silent)
  elif (cmd == 'build'):
    return PubCommand(options.dart_executable,
                      options.pub_executable,
                      options.pub_snapshot,
                      ['build',
                       '-DOBS_VER=' + utils.GetVersion(ignore_svn_revision=True),
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
  # Sanity check that localhost can be resolved.
  try:
    socket.gethostbyname('localhost')
  except:
    print("The hostname 'localhost' could not be resolved. Please fix your"
          "/etc/hosts file and try again")
    return -1
  # Parse the options.
  parser = BuildArguments()
  (options, args) = parser.parse_known_args()
  if not ProcessOptions(options, args):
    parser.print_help()
    return 1
  # Calculate absolute paths before changing directory.
  if (options.dart_executable != None):
    options.dart_executable = os.path.abspath(options.dart_executable)
  if (options.pub_executable != None):
    options.pub_executable = os.path.abspath(options.pub_executable)
  if (options.pub_snapshot != None):
    options.pub_snapshot = os.path.abspath(options.pub_snapshot)
  if (options.stamp != ''):
    options.stamp = os.path.abspath(options.stamp)
  if len(args) == 1:
    args[0] = os.path.abspath(args[0])
  try:
    # Pub must be run from the project's root directory.
    ChangeDirectory(options.directory)
    result = ExecuteCommand(options, args)
    if result == 0:
      CreateTimestampFile(options)
    return result
  except:
    DisplayFailureMessage()


if __name__ == '__main__':
  sys.exit(main());
