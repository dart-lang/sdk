#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# A script which will be invoked from gyp to create an SDK.
#
# Usage: create_sdk.py sdk_directory
#
# The SDK will be used either from the command-line or from the editor.
# Top structure is
#
# ..dart-sdk/
# ....bin/
# ......dart or dart.exe (executable)
# ......dart.lib (import library for VM native extensions on Windows)
# ......dartfmt
# ......dart2js
# ......dartanalyzer
# ......pub
# ......snapshots/
# ........analysis_server.dart.snapshot
# ........dart2js.dart.snapshot
# ........dartanalyzer.dart.snapshot
# ........dartfmt.dart.snapshot
# ........pub.dart.snapshot
# ........utils_wrapper.dart.snapshot
# ....include/
# ......dart_api.h
# ......dart_debugger_api.h
# ......dart_mirrors_api.h
# ......dart_native_api.h
# ....lib/
# ......_internal/
# ......async/
# ......collection/
# ......convert/
# ......core/
# ......html/
# ......internal/
# ......io/
# ......isolate/
# ......js/
# ......math/
# ......mirrors/
# ......typed_data/
# ....util/
# ......(more will come here)


import optparse
import os
import re
import sys
import subprocess

import utils


HOST_OS = utils.GuessOS()

# TODO(dgrove): Only import modules following Google style guide.
from os.path import basename, dirname, join, realpath, exists

# TODO(dgrove): Only import modules following Google style guide.
from shutil import copyfile, copymode, copytree, ignore_patterns, rmtree, move


def GetOptions():
  options = optparse.OptionParser(usage='usage: %prog [options]')
  options.add_option("--sdk_output_dir",
      help='Where to output the sdk')
  options.add_option("--snapshot_location",
      help='Location of the snapshots.')
  return options.parse_args()


def ReplaceInFiles(paths, subs):
  """Reads a series of files, applies a series of substitutions to each, and
     saves them back out. subs should by a list of (pattern, replace) tuples."""
  for path in paths:
    contents = open(path).read()
    for pattern, replace in subs:
      contents = re.sub(pattern, replace, contents)

    dest = open(path, 'w')
    dest.write(contents)
    dest.close()


def Copy(src, dest):
  copyfile(src, dest)
  copymode(src, dest)


def CopyShellScript(src_file, dest_dir):
  """Copies a shell/batch script to the given destination directory. Handles
     using the appropriate platform-specific file extension."""
  file_extension = ''
  if HOST_OS == 'win32':
    file_extension = '.bat'

  src = src_file + file_extension
  dest = join(dest_dir, basename(src_file) + file_extension)
  Copy(src, dest)


def CopyDartScripts(home, sdk_root):
  for executable in ['dart2js', 'dartanalyzer', 'dartfmt', 'docgen', 'pub']:
    CopyShellScript(os.path.join(home, 'sdk', 'bin', executable),
                    os.path.join(sdk_root, 'bin'))


def CopySnapshots(snapshots, sdk_root):
  for snapshot in ['analysis_server', 'dart2js', 'dartanalyzer', 'dartfmt', 
                   'utils_wrapper', 'pub']:
    snapshot += '.dart.snapshot'
    copyfile(join(snapshots, snapshot),
             join(sdk_root, 'bin', 'snapshots', snapshot))


def Main():
  # Pull in all of the gypi files which will be munged into the sdk.
  HOME = dirname(dirname(realpath(__file__)))

  (options, args) = GetOptions()

  SDK = options.sdk_output_dir
  SDK_tmp = '%s.tmp' % SDK

  SNAPSHOT = options.snapshot_location

  # TODO(dgrove) - deal with architectures that are not ia32.

  if exists(SDK):
    rmtree(SDK)

  if exists(SDK_tmp):
    rmtree(SDK_tmp)

  os.makedirs(SDK_tmp)

  # Create and populate sdk/bin.
  BIN = join(SDK_tmp, 'bin')
  os.makedirs(BIN)

  os.makedirs(join(BIN, 'snapshots'))

  # Copy the Dart VM binary and the Windows Dart VM link library
  # into sdk/bin.
  #
  # TODO(dgrove) - deal with architectures that are not ia32.
  build_dir = os.path.dirname(SDK)
  dart_file_extension = ''
  if HOST_OS == 'win32':
    dart_file_extension = '.exe'
    dart_import_lib_src = join(HOME, build_dir, 'dart.lib')
    dart_import_lib_dest = join(BIN, 'dart.lib')
    copyfile(dart_import_lib_src, dart_import_lib_dest)
  dart_src_binary = join(HOME, build_dir, 'dart' + dart_file_extension)
  dart_dest_binary = join(BIN, 'dart' + dart_file_extension)
  copyfile(dart_src_binary, dart_dest_binary)
  copymode(dart_src_binary, dart_dest_binary)
  # Strip the binaries on platforms where that is supported.
  if HOST_OS == 'linux':
    subprocess.call(['strip', dart_dest_binary])
  elif HOST_OS == 'macos':
    subprocess.call(['strip', '-x', dart_dest_binary])

  #
  # Create and populate sdk/include.
  #
  INCLUDE = join(SDK_tmp, 'include')
  os.makedirs(INCLUDE)
  copyfile(join(HOME, 'runtime', 'include', 'dart_api.h'),
           join(INCLUDE, 'dart_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_debugger_api.h'),
           join(INCLUDE, 'dart_debugger_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_mirrors_api.h'),
           join(INCLUDE, 'dart_mirrors_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_native_api.h'),
           join(INCLUDE, 'dart_native_api.h'))

  #
  # Create and populate sdk/lib.
  #

  LIB = join(SDK_tmp, 'lib')
  os.makedirs(LIB)

  #
  # Create and populate lib/{async, core, isolate, ...}.
  #

  os.makedirs(join(LIB, 'html'))

  for library in [join('_blink', 'dartium'),
                  join('_chrome', 'dart2js'), join('_chrome', 'dartium'),
                  join('_internal', 'compiler'),
                  join('_internal', 'lib'),
                  'async', 'collection', 'convert', 'core',
                  'internal', 'io', 'isolate',
                  join('html', 'dart2js'), join('html', 'dartium'),
                  join('html', 'html_common'),
                  join('indexed_db', 'dart2js'), join('indexed_db', 'dartium'),
                  'js', 'math', 'mirrors', 'typed_data', 'profiler',
                  join('svg', 'dart2js'), join('svg', 'dartium'),
                  join('web_audio', 'dart2js'), join('web_audio', 'dartium'),
                  join('web_gl', 'dart2js'), join('web_gl', 'dartium'),
                  join('web_sql', 'dart2js'), join('web_sql', 'dartium')]:
    copytree(join(HOME, 'sdk', 'lib', library), join(LIB, library),
             ignore=ignore_patterns('*.svn', 'doc', '*.py', '*.gypi', '*.sh',
                                    '.gitignore'))

  # Copy lib/_internal/libraries.dart.
  copyfile(join(HOME, 'sdk', 'lib', '_internal', 'libraries.dart'),
           join(LIB, '_internal', 'libraries.dart'))

  # Create and copy tools.
  UTIL = join(SDK_tmp, 'util')
  os.makedirs(UTIL)

  RESOURCE = join(SDK_tmp, 'lib', '_internal', 'pub', 'asset')
  os.makedirs(os.path.dirname(RESOURCE))
  copytree(join(HOME, 'sdk', 'lib', '_internal', 'pub', 'asset'),
           join(RESOURCE),
           ignore=ignore_patterns('.svn'))

  copytree(join(SNAPSHOT, 'core_stubs'),
           join(RESOURCE, 'dart', 'core_stubs'))

  # Copy in 7zip for Windows.
  if HOST_OS == 'win32':
    copytree(join(HOME, 'third_party', '7zip'),
             join(RESOURCE, '7zip'),
             ignore=ignore_patterns('.svn'))

  # Copy dart2js/pub.
  CopyDartScripts(HOME, SDK_tmp)
  CopySnapshots(SNAPSHOT, SDK_tmp)

  # Write the 'version' file
  version = utils.GetVersion()
  versionFile = open(os.path.join(SDK_tmp, 'version'), 'w')
  versionFile.write(version + '\n')
  versionFile.close()

  # Write the 'revision' file
  revision = utils.GetSVNRevision()

  if revision is not None:
    with open(os.path.join(SDK_tmp, 'revision'), 'w') as f:
      f.write(revision + '\n')
      f.close()

  Copy(join(HOME, 'README.dart-sdk'), join(SDK_tmp, 'README'))

  move(SDK_tmp, SDK)

if __name__ == '__main__':
  sys.exit(Main())
