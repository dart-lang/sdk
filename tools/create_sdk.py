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
# ......dart2js
# ......dart_analyzer
# ......pub
# ....include/
# ......dart_api.h
# ......dart_debugger_api.h
# ....lib/
# ......_internal/
# ......collection/
# ......core/
# ......coreimpl/
# ......crypto/
# ......html/
# ......io/
# ......isolate/
# ......json/
# ......math/
# ......mirrors/
# ......uri/
# ......utf/
# ......scalarlist/
# ....pkg/
# ......args/
#.......htmlescape/
# ......intl/
# ......logging/
# ......meta/
# ......unittest/
# ......(more will come here)
# ....util/
# ......analyzer/
# ........dart_analyzer.jar
# ........(third-party libraries for dart_analyzer)
# ......pub/
# ......(more will come here)



import os
import re
import sys
import subprocess
import tempfile
import utils

# TODO(dgrove): Only import modules following Google style guide.
from os.path import basename, dirname, join, realpath, exists, isdir

# TODO(dgrove): Only import modules following Google style guide.
from shutil import copyfile, copymode, copytree, ignore_patterns, rmtree, move

def ReplaceInFiles(paths, subs):
  '''Reads a series of files, applies a series of substitutions to each, and
     saves them back out. subs should by a list of (pattern, replace) tuples.'''
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

# TODO(zundel): this excludes the analyzer from the sdk build until builders
# have all prerequisite software installed.  Also update dart.gyp.
def ShouldCopyAnalyzer():
  os = utils.GuessOS()
  return os == 'linux' or os == 'macos'


def CopyShellScript(src_file, dest_dir):
  '''Copies a shell/batch script to the given destination directory. Handles
     using the appropriate platform-specific file extension.'''
  file_extension = ''
  if utils.GuessOS() == 'win32':
    file_extension = '.bat'

  src = src_file + file_extension
  dest = join(dest_dir, basename(src_file) + file_extension)
  Copy(src, dest)


def CopyDartScripts(home, build_dir, sdk_root, version):
  if version:
    ReplaceInFiles([os.path.join(sdk_root, 'lib', '_internal', 'compiler',
                                 'implementation', 'compiler.dart')],
                   [(r"BUILD_ID = 'build number could not be determined'",
                     r"BUILD_ID = '%s'" % version)])
  # TODO(dgrove) - add pub once issue 6619 is fixed
  for executable in ['dart2js', 'dartdoc']:
    CopyShellScript(os.path.join(home, 'sdk', 'bin', executable),
                    os.path.join(sdk_root, 'bin'))

  if utils.GuessOS() != 'win32':
    # TODO(ahe): Enable for Windows as well.
    subprocess.call([os.path.join(build_dir, 'gen_snapshot'),
                     '--script_snapshot=%s' %
                     os.path.join(sdk_root, 'lib', '_internal', 'compiler',
                                  'implementation', 'dart2js.dart.snapshot'),
                     os.path.join(sdk_root, 'lib', '_internal', 'compiler',
                                  'implementation', 'dart2js.dart')])



def Main(argv):
  # Pull in all of the gpyi files which will be munged into the sdk.
  HOME = dirname(dirname(realpath(__file__)))

  SDK = argv[1]
  SDK_tmp = '%s.tmp' % SDK

  # TODO(dgrove) - deal with architectures that are not ia32.

  if exists(SDK):
    rmtree(SDK)

  if exists(SDK_tmp):
    rmtree(SDK_tmp)

  os.makedirs(SDK_tmp)

  # Create and populate sdk/bin.
  BIN = join(SDK_tmp, 'bin')
  os.makedirs(BIN)

  # Copy the Dart VM binary and the Windows Dart VM link library
  # into sdk/bin.
  #
  # TODO(dgrove) - deal with architectures that are not ia32.
  build_dir = os.path.dirname(argv[1])
  dart_file_extension = ''
  analyzer_file_extension = ''
  if utils.GuessOS() == 'win32':
    dart_file_extension = '.exe'
    analyzer_file_extension = '.bat'  # TODO(zundel): test on Windows
    dart_import_lib_src = join(HOME, build_dir, 'dart.lib')
    dart_import_lib_dest = join(BIN, 'dart.lib')
    copyfile(dart_import_lib_src, dart_import_lib_dest)
  dart_src_binary = join(HOME, build_dir, 'dart' + dart_file_extension)
  dart_dest_binary = join(BIN, 'dart' + dart_file_extension)
  copyfile(dart_src_binary, dart_dest_binary)
  copymode(dart_src_binary, dart_dest_binary)
  if utils.GuessOS() != 'win32':
    subprocess.call(['strip', dart_dest_binary])

  if ShouldCopyAnalyzer():
    # Copy analyzer into sdk/bin
    ANALYZER_HOME = join(HOME, build_dir, 'analyzer')
    dart_analyzer_src_binary = join(ANALYZER_HOME, 'bin', 'dart_analyzer')
    dart_analyzer_dest_binary = join(BIN,
        'dart_analyzer' + analyzer_file_extension)
    copyfile(dart_analyzer_src_binary, dart_analyzer_dest_binary)
    copymode(dart_analyzer_src_binary, dart_analyzer_dest_binary)

  # Create pub shell script.
  # TODO(dgrove) - delete this once issue 6619 is fixed
  pub_src_script = join(HOME, 'utils', 'pub', 'sdk', 'pub')
  CopyShellScript(pub_src_script, BIN)

  #
  # Create and populate sdk/include.
  #
  INCLUDE = join(SDK_tmp, 'include')
  os.makedirs(INCLUDE)
  copyfile(join(HOME, 'runtime', 'include', 'dart_api.h'),
           join(INCLUDE, 'dart_api.h'))
  copyfile(join(HOME, 'runtime', 'include', 'dart_debugger_api.h'),
           join(INCLUDE, 'dart_debugger_api.h'))

  #
  # Create and populate sdk/lib.
  #

  LIB = join(SDK_tmp, 'lib')
  os.makedirs(LIB)

  #
  # Create and populate lib/{core, crypto, isolate, json, uri, utf, ...}.
  #

  os.makedirs(join(LIB, 'html'))
  for library in ['_internal', 'collection', 'core', 'coreimpl', 'crypto', 'io',
                  'isolate', join('html', 'dart2js'), join('html', 'dartium'),
                  'json', 'math', 'mirrors', 'scalarlist',
                  join('svg', 'dart2js'), join('svg', 'dartium'), 'uri', 'utf']:
    copytree(join(HOME, 'sdk', 'lib', library), join(LIB, library),
             ignore=ignore_patterns('*.svn', 'doc', '*.py', '*.gypi', '*.sh'))


  # Create and copy pkg.
  PKG = join(SDK_tmp, 'pkg')
  os.makedirs(PKG)

  #
  # Create and populate pkg/{args, intl, logging, meta, unittest}
  #

  for library in ['args', 'htmlescape', 'intl', 'logging',
                  'meta', 'unittest']:
    copytree(join(HOME, 'pkg', library), join(PKG, library),
             ignore=ignore_patterns('*.svn', 'doc', 'docs',
                                    '*.py', '*.gypi', '*.sh'))

  # Create and copy tools.
  UTIL = join(SDK_tmp, 'util')
  os.makedirs(UTIL)

  if ShouldCopyAnalyzer():
    # Create and copy Analyzer library into 'util'
    ANALYZER_DEST = join(UTIL, 'analyzer')
    os.makedirs(ANALYZER_DEST)

    analyzer_src_jar = join(ANALYZER_HOME, 'util', 'analyzer',
                            'dart_analyzer.jar')
    analyzer_dest_jar = join(ANALYZER_DEST, 'dart_analyzer.jar')
    copyfile(analyzer_src_jar, analyzer_dest_jar)

    jarsToCopy = [ join("args4j", "2.0.12", "args4j-2.0.12.jar"),
                   join("guava", "r09", "guava-r09.jar"),
                   join("json", "r2_20080312", "json.jar") ]
    for jarToCopy in jarsToCopy:
      dest_dir = join (ANALYZER_DEST, os.path.dirname(jarToCopy))
      os.makedirs(dest_dir)
      dest_file = join (ANALYZER_DEST, jarToCopy)
      src_file = join(ANALYZER_HOME, 'util', 'analyzer', jarToCopy)
      copyfile(src_file, dest_file)

  # Create and populate util/pub.
  copytree(join(HOME, 'utils', 'pub'), join(UTIL, 'pub'),
           ignore=ignore_patterns('.svn', 'sdk'))

  # Copy in 7zip for Windows.
  if utils.GuessOS() == 'win32':
    copytree(join(HOME, 'third_party', '7zip'),
             join(join(UTIL, 'pub'), '7zip'),
             ignore=ignore_patterns('.svn'))

    ReplaceInFiles([
        join(UTIL, 'pub', 'io.dart'),
      ], [
        ("var pathTo7zip = '../../third_party/7zip/7za.exe';",
         "var pathTo7zip = '7zip/7za.exe';"),
      ])

  version = utils.GetVersion()

  # Copy dart2js/dartdoc/pub.
  CopyDartScripts(HOME, build_dir, SDK_tmp, version)

  # Fix up dartdoc.
  # TODO(dgrove): Remove this once issue 6619 is fixed.
  ReplaceInFiles([join(SDK_tmp, 'lib', '_internal', 'dartdoc',
                       'bin', 'dartdoc.dart')],
                 [("../../../../../pkg/args/lib/args.dart",
                   "../../../../pkg/args/lib/args.dart")])

  # Write the 'version' file
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
  sys.exit(Main(sys.argv))
