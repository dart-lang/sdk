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
# ......builtin/
# ........builtin_runtime.dart
# ......io/
# ........io_runtime.dart
# ........runtime/
# ......compiler/
# ......core/
# ........core_runtime.dart
# ........runtime/
# ......coreimpl/
# ........coreimpl_runtime.dart
# ........runtime/
# ......dart2js/
# ......isolate/
# ........isolate_{frog, runtime}.dart
# ........{frog, runtime}/
# ......dom/
# ........dom.dart
# ......html/
# ........html_dart2js.dart
# ........html_dartium.dart
# ......crypto/
# ........crypto.dart
# ........(implementation files)
# ......json/
# ........json_frog.dart
#.........json.dart
# ........{frog}/
# ......uri/
# ........uri.dart
# ......utf/
# ......web/
# ........web.dart
# ....pkg/
# ......args/
# ......dartdoc/
# ......i18n/
# ......logging/
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
  os = utils.GuessOS();
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


def CopyDart2Js(build_dir, sdk_root):
  '''
  Install dart2js in SDK/lib/dart2js.

  Currently, we copy too much stuff to this location, but the SDK's
  layout matches the the layout of the part of the repository we're
  dealing with here which frees us from rewriting files. The long term
  plan is to align the layout of the repository and the SDK, at which
  point we should be able to simplify Main below and share the dart
  files between the various components to minimize SDK download size.
  '''
  copytree('lib', os.path.join(sdk_root, 'lib', 'dart2js', 'lib'),
           ignore=ignore_patterns('.svn'))
  copytree(os.path.join('corelib', 'src'),
           os.path.join(sdk_root, 'lib', 'dart2js', 'corelib', 'src'),
           ignore=ignore_patterns('.svn'))
  copytree(os.path.join('runtime', 'lib'),
           os.path.join(sdk_root, 'lib', 'dart2js', 'runtime', 'lib'),
           ignore=ignore_patterns('.svn'))
  copytree(os.path.join('runtime', 'bin'),
           os.path.join(sdk_root, 'lib', 'dart2js', 'runtime', 'bin'),
           ignore=ignore_patterns('.svn'))
  if utils.GuessOS() == 'win32':
    dart2js = os.path.join(sdk_root, 'bin', 'dart2js.bat')
    Copy(os.path.join(build_dir, 'dart2js.bat'), dart2js)
    ReplaceInFiles([dart2js],
                   [(r'%SCRIPTPATH%\.\.\\lib',
                     r'%SCRIPTPATH%..\lib\dart2js\lib')])
    dartdoc = os.path.join(sdk_root, 'bin', 'dartdoc.bat')
    Copy(os.path.join(build_dir, 'dartdoc.bat'), dartdoc)
  else:
    dart2js = os.path.join(sdk_root, 'bin', 'dart2js')
    Copy(os.path.join(build_dir, 'dart2js'), dart2js)
    ReplaceInFiles([dart2js],
                   [(r'\$BIN_DIR/\.\./\.\./lib',
                     r'$BIN_DIR/../lib/dart2js/lib')])
    dartdoc = os.path.join(sdk_root, 'bin', 'dartdoc')
    Copy(os.path.join(build_dir, 'dartdoc'), dartdoc)


def Main(argv):
  # Pull in all of the gpyi files which will be munged into the sdk.
  builtin_runtime_sources = \
    (eval(open("runtime/bin/builtin_sources.gypi").read()))['sources']
  io_runtime_sources = \
    (eval(open("runtime/bin/io_sources.gypi").read()))['sources']
  corelib_sources = \
    (eval(open("corelib/src/corelib_sources.gypi").read()))['sources']
  corelib_runtime_sources = \
    (eval(open("runtime/lib/lib_sources.gypi").read()))['sources']
  coreimpl_sources = \
    (eval(open("corelib/src/implementation/corelib_impl_sources.gypi").read()))\
    ['sources']
  coreimpl_runtime_sources = \
    (eval(open("runtime/lib/lib_impl_sources.gypi").read()))['sources']

  HOME = dirname(dirname(realpath(__file__)))

  SDK_tmp = tempfile.mkdtemp()
  SDK = argv[1]

  # TODO(dgrove) - deal with architectures that are not ia32.

  if exists(SDK):
    rmtree(SDK)

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

  if ShouldCopyAnalyzer():
    # Copy analyzer into sdk/bin
    ANALYZER_HOME = join(HOME, build_dir, 'analyzer')
    dart_analyzer_src_binary = join(ANALYZER_HOME, 'bin', 'dart_analyzer')
    dart_analyzer_dest_binary = join(BIN,
        'dart_analyzer' + analyzer_file_extension)
    copyfile(dart_analyzer_src_binary, dart_analyzer_dest_binary)
    copymode(dart_analyzer_src_binary, dart_analyzer_dest_binary)

  # Create pub shell script.
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
  corelib_dest_dir = join(LIB, 'core')
  os.makedirs(corelib_dest_dir)
  os.makedirs(join(corelib_dest_dir, 'runtime'))

  coreimpl_dest_dir = join(LIB, 'coreimpl')
  os.makedirs(coreimpl_dest_dir)
  os.makedirs(join(coreimpl_dest_dir, 'runtime'))


  #
  # Create and populate lib/builtin.
  #
  builtin_dest_dir = join(LIB, 'builtin')
  os.makedirs(builtin_dest_dir)
  assert len(builtin_runtime_sources) == 1
  assert builtin_runtime_sources[0] == 'builtin.dart'
  copyfile(join(HOME, 'runtime', 'bin', 'builtin.dart'),
           join(builtin_dest_dir, 'builtin_runtime.dart'))
  #
  # rename the print function in dart:builtin
  # so that it does not conflict with the print function in dart:core
  #
  ReplaceInFiles([
      join(builtin_dest_dir, 'builtin_runtime.dart')
    ], [
      ('void print\(', 'void builtinPrint(')
    ])

  #
  # Create and populate lib/io.
  #
  io_dest_dir = join(LIB, 'io')
  os.makedirs(io_dest_dir)
  os.makedirs(join(io_dest_dir, 'runtime'))
  for filename in io_runtime_sources:
    assert filename.endswith('.dart')
    if filename == 'io.dart':
      copyfile(join(HOME, 'runtime', 'bin', filename),
               join(io_dest_dir, 'io_runtime.dart'))
    else:
      copyfile(join(HOME, 'runtime', 'bin', filename),
               join(io_dest_dir, 'runtime', filename))

  # Construct lib/io/io_runtime.dart from whole cloth.
  dest_file = open(join(io_dest_dir, 'io_runtime.dart'), 'a')
  for filename in io_runtime_sources:
    assert filename.endswith('.dart')
    if filename == 'io.dart':
      continue
    dest_file.write('#source("runtime/' + filename + '");\n')
  dest_file.close()

  #
  # Create and populate lib/compiler.
  #
  compiler_src_dir = join(HOME, 'lib', 'compiler')
  compiler_dest_dir = join(LIB, 'compiler')

  copytree(compiler_src_dir, compiler_dest_dir, ignore=ignore_patterns('.svn'))

  # Remap imports in lib/compiler/* .
  for (dirpath, subdirs, filenames) in os.walk(compiler_dest_dir):
    for filename in filenames:
      if filename.endswith('.dart'):
        filename = join(dirpath, filename)
        file_contents = open(filename).read()
        file = open(filename, 'w')
        file_contents = re.sub(r"\.\./lib", "..", file_contents)
        file.write(file_contents)
        file.close()

  #
  # Create and populate lib/html.
  #
  html_src_dir = join(HOME, 'lib', 'html')
  html_dest_dir = join(LIB, 'html')
  os.makedirs(html_dest_dir)

  copyfile(join(html_src_dir, 'dart2js', 'html_dart2js.dart'),
           join(html_dest_dir, 'html_dart2js.dart'))
  copyfile(join(html_src_dir, 'dartium', 'html_dartium.dart'),
           join(html_dest_dir, 'html_dartium.dart'))
  copyfile(join(html_src_dir, 'dartium', 'nativewrappers.dart'),
           join(html_dest_dir, 'nativewrappers.dart'))

  #
  # Create and populate lib/dom.
  #
  dom_src_dir = join(HOME, 'lib', 'dom')
  dom_dest_dir = join(LIB, 'dom')
  os.makedirs(dom_dest_dir)

  copyfile(join(dom_src_dir, 'dart2js', 'dom_dart2js.dart'),
           join(dom_dest_dir, 'dom_dart2js.dart'))

  #
  # Create and populate lib/{crypto, json, uri, utf, ...}.
  #

  for library in ['crypto', 'json', 'math', 'uri', 'utf', 'web']:
    src_dir = join(HOME, 'lib', library)
    dest_dir = join(LIB, library)
    os.makedirs(dest_dir)

    for filename in os.listdir(src_dir):
      if filename.endswith('.dart'):
        copyfile(join(src_dir, filename), join(dest_dir, filename))

  # Create and populate lib/isolate
  copytree(join(HOME, 'lib', 'isolate'), join(LIB, 'isolate'),
           ignore=ignore_patterns('.svn'))

  #
  # Create and populate lib/core.
  #

  # First, copy corelib/* to lib/runtime
  for filename in corelib_sources:
    for target_dir in ['runtime']:
      copyfile(join('corelib', 'src', filename),
               join(corelib_dest_dir, target_dir, filename))

  # Next, copy the runtime library source on top of core/runtime
  for filename in corelib_runtime_sources:
    if filename.endswith('.dart'):
      copyfile(join('runtime', 'lib', filename),
               join(corelib_dest_dir, 'runtime', filename))

  #
  # At this point, it's time to create lib/core/core*dart .
  #
  # construct lib/core_runtime.dart from whole cloth.
  dest_file = open(join(corelib_dest_dir, 'core_runtime.dart'), 'w')
  dest_file.write('#library("dart:core");\n')
  dest_file.write('#import("dart:coreimpl");\n')
  for filename in corelib_sources:
    dest_file.write('#source("runtime/' + filename + '");\n')
  for filename in corelib_runtime_sources:
    if filename.endswith('.dart'):
      dest_file.write('#source("runtime/' + filename + '");\n')
  # include the missing print function
  dest_file.write('void print(Object arg) { /* native */ }\n')
  dest_file.close()

  #
  # Create and populate lib/coreimpl.
  #

  # First, copy corelib/src/implementation to corelib/runtime.
  for filename in coreimpl_sources:
    for target_dir in ['runtime']:
      copyfile(join('corelib', 'src', 'implementation', filename),
               join(coreimpl_dest_dir, target_dir, filename))

  for filename in coreimpl_runtime_sources:
    if filename.endswith('.dart') and not filename.endswith('_patch.dart'):
      copyfile(join('runtime', 'lib', filename),
               join(coreimpl_dest_dir, 'runtime', filename))

  # Construct lib/coreimpl/coreimpl_runtime.dart from whole cloth.
  dest_file = open(join(coreimpl_dest_dir, 'coreimpl_runtime.dart'), 'w')
  dest_file.write('#library("dart:coreimpl");\n')
  for filename in coreimpl_sources:
    dest_file.write('#source("runtime/' + filename + '");\n')
  for filename in coreimpl_runtime_sources:
    if filename.endswith('.dart') and not filename.endswith('_patch.dart'):
      dest_file.write('#source("runtime/' + filename + '");\n')
  dest_file.close()


  # Create and copy pkg.
  PKG = join(SDK_tmp, 'pkg')
  os.makedirs(PKG)

  #
  # Create and populate pkg/{args, i18n, logging, unittest}
  #

  for library in ['args', 'i18n', 'logging', 'unittest']:
    src_dir = join(HOME, 'pkg', library)
    dest_dir = join(PKG, library)
    os.makedirs(dest_dir)

    for filename in os.listdir(src_dir):
      if filename.endswith('.dart'):
        copyfile(join(src_dir, filename), join(dest_dir, filename))

  # Create and populate pkg/dartdoc.
  dartdoc_src_dir = join(HOME, 'pkg', 'dartdoc')
  dartdoc_dest_dir = join(PKG, 'dartdoc')
  copytree(dartdoc_src_dir, dartdoc_dest_dir,
           ignore=ignore_patterns('.svn', 'docs'))

  # Fixup dart2js dependencies.
  ReplaceInFiles([
      join(PKG, 'dartdoc', 'dartdoc.dart'),
    ], [
      ("final bool IN_SDK = false;",
       "final bool IN_SDK = true;"),
    ])


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
  pub_src_dir = join(HOME, 'utils', 'pub')
  pub_dst_dir = join(UTIL, 'pub')
  copytree(pub_src_dir, pub_dst_dir,
           ignore=ignore_patterns('.svn', 'sdk'))

  # Copy import maps.
  PLATFORMS = ['any', 'vm', 'dartium', 'dart2js' ]
  os.makedirs(join(LIB, 'config'))
  for platform in PLATFORMS:
    import_src = join(HOME, 'lib', 'config', 'import_' + platform + '.config')
    import_dst = join(LIB, 'config', 'import_' + platform + '.config')
    copyfile(import_src, import_dst);

  # Copy dart2js.
  CopyDart2Js(build_dir, SDK_tmp)

  # Write the 'revision' file
  revision = utils.GetSVNRevision()
  if revision is not None:
    with open(os.path.join(SDK_tmp, 'revision'), 'w') as f:
      f.write(revision + '\n')
      f.close()

  move(SDK_tmp, SDK)
  utils.Touch(os.path.join(SDK, 'create.stamp'))

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
