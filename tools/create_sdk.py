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
# ......dartdoc
# ......dartfmt
# ......dart2js
# ......dartanalyzer
# ......dartdevc
# ......pub
# ......snapshots/
# ........analysis_server.dart.snapshot
# ........dart2js.dart.snapshot
# ........dartanalyzer.dart.snapshot
# ........dartdoc.dart.snapshot
# ........dartfmt.dart.snapshot
# ........dartdevc.dart.snapshot
# ........pub.dart.snapshot
# ........utils_wrapper.dart.snapshot
#.........resources/
#...........dartdoc/
#..............packages
#.............resources/
#.............templates/
# ....include/
# ......dart_api.h
# ......dart_mirrors_api.h
# ......dart_native_api.h
# ......dart_tools_api.h
# ....lib/
# ......dart_client.platform
# ......dart_server.platform
# ......dart_shared.platform
# ......_internal/
#.........spec.sum
#.........strong.sum
#.........dev_compiler/
# ......analysis_server/
# ......analyzer/
# ......async/
# ......collection/
# ......convert/
# ......core/
# ......html/
# ......internal/
# ......io/
# ......isolate/
# ......js/
# ......js_util/
# ......math/
# ......mirrors/
# ......typed_data/
# ......api_readme.md
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

  # If we're copying an SDK-specific shell script, strip off the suffix.
  dest_file = basename(src_file)
  if dest_file.endswith('_sdk'):
    dest_file = dest_file.replace('_sdk', '')

  src = src_file + file_extension
  dest = join(dest_dir, dest_file + file_extension)
  Copy(src, dest)


def CopyDartScripts(home, sdk_root):
  for executable in ['dart2js_sdk', 'dartanalyzer_sdk', 'dartfmt_sdk',
                     'pub_sdk', 'dartdoc', 'dartdevc_sdk']:
    CopyShellScript(os.path.join(home, 'sdk', 'bin', executable),
                    os.path.join(sdk_root, 'bin'))


def CopySnapshots(snapshots, sdk_root):
  for snapshot in ['analysis_server', 'dart2js', 'dartanalyzer', 'dartfmt',
                   'utils_wrapper', 'pub', 'dartdoc', 'dartdevc']:
    snapshot += '.dart.snapshot'
    copyfile(join(snapshots, snapshot),
             join(sdk_root, 'bin', 'snapshots', snapshot))

def CopyAnalyzerSources(home, lib_dir):
  for library in ['analyzer', 'analysis_server']:
    copytree(join(home, 'pkg', library), join(lib_dir, library),
             ignore=ignore_patterns('*.svn', 'doc', '*.py', '*.gypi', '*.sh',
                                    '.gitignore', 'packages'))

def CopyDartdocResources(home, sdk_root):
  RESOURCE_DIR = join(sdk_root, 'bin', 'snapshots', 'resources')
  DARTDOC = join(RESOURCE_DIR, 'dartdoc')

  copytree(join(home, 'third_party', 'pkg', 'dartdoc', 'lib', 'templates'),
           join(DARTDOC, 'templates'))
  copytree(join(home, 'third_party', 'pkg', 'dartdoc', 'lib', 'resources'),
           join(DARTDOC, 'resources'))
  # write the .packages file
  PACKAGES_FILE = join(DARTDOC, '.packages')
  packages_file = open(PACKAGES_FILE, 'w')
  packages_file.write('dartdoc:.')
  packages_file.close()

def CopyAnalysisSummaries(snapshots, lib):
  copyfile(join(snapshots, 'spec.sum'),
           join(lib, '_internal', 'spec.sum'))
  copyfile(join(snapshots, 'strong.sum'),
           join(lib, '_internal', 'strong.sum'))

def CopyDevCompilerSdk(home, lib):
  copytree(join(home, 'pkg', 'dev_compiler', 'lib', 'js'),
           join(lib, '_internal', 'dev_compiler'))

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
  copyfile(join(HOME, 'runtime', 'include', 'dart_mirrors_api.h'),
           join(INCLUDE, 'dart_mirrors_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_native_api.h'),
           join(INCLUDE, 'dart_native_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_tools_api.h'),
           join(INCLUDE, 'dart_tools_api.h'))

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
                  join('_internal', 'js_runtime'),
                  join('_internal', 'sdk_library_metadata'),
                  'async', 'collection', 'convert', 'core', 'developer',
                  'internal', 'io', 'isolate',
                  join('html', 'dart2js'), join('html', 'dartium'),
                  join('html', 'html_common'),
                  join('indexed_db', 'dart2js'), join('indexed_db', 'dartium'),
                  'js', 'js_util', 'math', 'mirrors', 'profiler', 'typed_data',
                  join('svg', 'dart2js'), join('svg', 'dartium'),
                  join('web_audio', 'dart2js'), join('web_audio', 'dartium'),
                  join('web_gl', 'dart2js'), join('web_gl', 'dartium'),
                  join('web_sql', 'dart2js'), join('web_sql', 'dartium')]:
    copytree(join(HOME, 'sdk', 'lib', library), join(LIB, library),
             ignore=ignore_patterns('*.svn', 'doc', '*.py', '*.gypi', '*.sh',
                                    '.gitignore'))

  # Copy the platform descriptors.
  for file_name in ["dart_client.platform",
                    "dart_server.platform",
                    "dart_shared.platform"]:
    copyfile(join(HOME, 'sdk', 'lib', file_name), join(LIB, file_name));

  # Copy libraries.dart to lib/_internal/libraries.dart for backwards
  # compatibility.
  #
  # TODO(sigmund): stop copying libraries.dart. Old versions (<=0.25.1-alpha.4)
  # of the analyzer package do not support the new location of this file. We
  # should be able to remove the old file once we release a newer version of
  # analyzer and popular frameworks have migrated to use it.
  copyfile(join(HOME, 'sdk', 'lib', '_internal',
                'sdk_library_metadata', 'lib', 'libraries.dart'),
           join(LIB, '_internal', 'libraries.dart'))

  # Create and copy tools.
  UTIL = join(SDK_tmp, 'util')
  os.makedirs(UTIL)

  RESOURCE = join(SDK_tmp, 'lib', '_internal', 'pub', 'asset')
  os.makedirs(os.path.dirname(RESOURCE))
  copytree(join(HOME, 'third_party', 'pkg', 'pub', 'lib', 'src',
                'asset'),
           join(RESOURCE),
           ignore=ignore_patterns('.svn'))

  # Copy in 7zip for Windows.
  if HOST_OS == 'win32':
    copytree(join(HOME, 'third_party', '7zip'),
             join(RESOURCE, '7zip'),
             ignore=ignore_patterns('.svn'))

  # Copy dart2js/pub.
  CopyDartScripts(HOME, SDK_tmp)

  CopySnapshots(SNAPSHOT, SDK_tmp)
  CopyDartdocResources(HOME, SDK_tmp)
  CopyAnalyzerSources(HOME, LIB)
  CopyAnalysisSummaries(SNAPSHOT, LIB)
  CopyDevCompilerSdk(HOME, LIB)

  # Write the 'version' file
  version = utils.GetVersion()
  versionFile = open(os.path.join(SDK_tmp, 'version'), 'w')
  versionFile.write(version + '\n')
  versionFile.close()

  # Write the 'revision' file
  revision = utils.GetGitRevision()

  if revision is not None:
    with open(os.path.join(SDK_tmp, 'revision'), 'w') as f:
      f.write('%s\n' % revision)
      f.close()

  Copy(join(HOME, 'README.dart-sdk'), join(SDK_tmp, 'README'))
  Copy(join(HOME, 'LICENSE'), join(SDK_tmp, 'LICENSE'))
  Copy(join(HOME, 'sdk', 'api_readme.md'), join(SDK_tmp, 'lib', 'api_readme.md'))

  move(SDK_tmp, SDK)

if __name__ == '__main__':
  sys.exit(Main())
