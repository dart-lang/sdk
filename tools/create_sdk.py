#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
# ......frogc.dart
# ......frogsh (coming later)
# ....lib/
# ......builtin/
# ........builtin_runtime.dart
# ......io/
# ........io_runtime.dart
# ........runtime/
# ......core/
# ........core_{frog, runtime}.dart
# ........{frog, runtime}/
# ......coreimpl/
# ........coreimpl_{frog, runtime}.dart
# ........{frog, runtime}/
# ......dartdoc/
# ......isolate/
# ........isolate_{frog, runtime}.dart
# ........{frog, runtime}/
# ......dom/
# ........dom.dart
# ......frog/
# ......html/
# ........html_frog.dart
# ........html_dartium.dart
# ......json/
# ........json_frog.dart
#.........json.dart
# ........{frog}/
# ......uri/
# ........uri.dart
# ......utf/
# ......(more will come here)
# ....util/
# ......(more will come here)



import os
import re
import sys
import tempfile
import utils

# TODO(dgrove): Only import modules following Google style guide.
from os.path import dirname, join, realpath, exists, isdir

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

def Main(argv):
  # Pull in all of the gpyi files which will be munged into the sdk.
  builtin_runtime_sources = \
    (eval(open("runtime/bin/builtin_sources.gypi").read()))['sources']
  io_runtime_sources = \
    (eval(open("runtime/bin/io_sources.gypi").read()))['sources']
  corelib_sources = \
    (eval(open("corelib/src/corelib_sources.gypi").read()))['sources']
  corelib_frog_sources = \
    (eval(open("frog/lib/frog_corelib_sources.gypi").read()))['sources']
  corelib_runtime_sources = \
    (eval(open("runtime/lib/lib_sources.gypi").read()))['sources']
  coreimpl_sources = \
    (eval(open("corelib/src/implementation/corelib_impl_sources.gypi").read()))\
    ['sources']
  coreimpl_frog_sources = \
    (eval(open("frog/lib/frog_coreimpl_sources.gypi").read()))['sources']
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

  # Copy the Dart VM binary into sdk/bin.
  # TODO(dgrove) - deal with architectures that are not ia32.
  build_dir = os.path.dirname(argv[1])
  frogc_file_extension = ''
  dart_file_extension = ''
  if utils.GuessOS() == 'win32':
    dart_file_extension = '.exe'
    frogc_file_extension = '.bat'
  dart_src_binary = join(HOME, build_dir, 'dart' + dart_file_extension)
  dart_dest_binary = join(BIN, 'dart' + dart_file_extension)
  frogc_src_binary = join(HOME, 'frog', 'scripts', 'bootstrap',
      'frogc' + frogc_file_extension)
  frogc_dest_binary = join(BIN, 'frogc' + frogc_file_extension)
  copyfile(dart_src_binary, dart_dest_binary)
  copymode(dart_src_binary, dart_dest_binary)
  copyfile(frogc_src_binary, frogc_dest_binary)
  copymode(frogc_src_binary, frogc_dest_binary)

  # Create sdk/bin/frogc.dart, and hack as needed.
  frog_src_dir = join(HOME, 'frog')

  # Convert frogc.dart's imports from import('*') -> import('frog/*').
  frogc_contents = open(join(frog_src_dir, 'frogc.dart')).read()
  frogc_dest = open(join(BIN, 'frogc.dart'), 'w')
  frogc_dest.write(
    re.sub(r"#import\('([^.])", r"#import('../lib/frog/\1", frogc_contents))
  frogc_dest.close()

  # TODO(dgrove): copy and fix up frog.dart, minfrogc.dart.

  #
  # Create and populate sdk/lib.
  #

  LIB = join(SDK_tmp, 'lib')
  os.makedirs(LIB)
  corelib_dest_dir = join(LIB, 'core')
  os.makedirs(corelib_dest_dir)
  os.makedirs(join(corelib_dest_dir, 'frog'))
  os.makedirs(join(corelib_dest_dir, 'runtime'))

  coreimpl_dest_dir = join(LIB, 'coreimpl')
  os.makedirs(coreimpl_dest_dir)
  os.makedirs(join(coreimpl_dest_dir, 'frog'))
  os.makedirs(join(coreimpl_dest_dir, 'frog', 'node'))
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
        file_contents = re.sub(r"\.\./frog/", "frog/", file_contents)
        file.write(file_contents)
        file.close()

  #
  # Create and populate lib/frog.
  #
  # TODO(dgrove): Frog is not a dart library and should not live in lib.
  #
  frog_dest_dir = join(LIB, 'frog')
  os.makedirs(frog_dest_dir)

  for filename in os.listdir(frog_src_dir):
    if filename == 'frog_options.dart':
      # change config from 'dev' to 'sdk' in frog_options.dart
      frog_options_contents = open(join(frog_src_dir, filename)).read()
      frog_options_dest = open(join(frog_dest_dir, filename), 'w')
      frog_options_dest.write(re.sub("final config = \'dev\';",
                                     "final config = \'sdk\';",
                                     frog_options_contents))
      frog_options_dest.close()
    elif filename.endswith('.dart'):
      copyfile(join(frog_src_dir, filename), join(frog_dest_dir, filename))


  copytree(join(frog_src_dir, 'server'), join(frog_dest_dir, 'server'),
           ignore=ignore_patterns('.svn'))

  # Remap imports in frog/... .
  for (dirpath, subdirs, filenames) in os.walk(frog_dest_dir):
    for filename in filenames:
      if filename.endswith('.dart'):
        file_contents = open(join(dirpath, filename)).read()
        file = open(join(dirpath, filename), 'w')
        file.write(re.sub(r"\.\./lib/", "../", file_contents))
        file.close()

  #
  # Create and populate lib/html.
  #
  html_src_dir = join(HOME, 'lib', 'html')
  html_dest_dir = join(LIB, 'html')
  os.makedirs(html_dest_dir)

  copyfile(join(html_src_dir, 'frog', 'html_frog.dart'),
           join(html_dest_dir, 'html_frog.dart'))
  copyfile(join(html_src_dir, 'dartium', 'html_dartium.dart'),
           join(html_dest_dir, 'html_dartium.dart'))

  #
  # Create and populate lib/dom.
  #
  dom_src_dir = join(HOME, 'lib', 'dom')
  dom_dest_dir = join(LIB, 'dom')
  os.makedirs(dom_dest_dir)

  copyfile(join(dom_src_dir, 'frog', 'dom_frog.dart'),
           join(dom_dest_dir, 'dom_frog.dart'))

  #
  # Create and populate lib/{json, uri, utf} .
  #

  for library in ['json', 'uri', 'utf']:
    src_dir = join(HOME, 'lib', library)
    dest_dir = join(LIB, library)
    os.makedirs(dest_dir)

    for filename in os.listdir(src_dir):
      if filename.endswith('.dart'):
        copyfile(join(src_dir, filename), join(dest_dir, filename))

  # Create and populate lib/dartdoc
  dartdoc_src_dir = join(HOME, 'lib', 'dartdoc')
  dartdoc_dest_dir = join(LIB, 'dartdoc')
  copytree(dartdoc_src_dir, dartdoc_dest_dir,
           ignore=ignore_patterns('.svn', 'docs'))
  ReplaceInFiles([
      join(LIB, 'dartdoc', 'dartdoc.dart')
    ], [
      ("#import\('../../frog", "#import('../frog"),
      ("joinPaths\(scriptDir, '../../frog/'\)",
          "joinPaths(scriptDir, '../frog/')"),
      ("joinPaths\(frogPath, 'lib'\)", "joinPaths(frogPath, '..')"),
      ("joinPaths\(frogPath, 'minfrog'\)",
          "joinPaths(scriptDir, '../../bin/frogc')")
    ])
  ReplaceInFiles([
      join(LIB, 'dartdoc', 'classify.dart'),
      join(LIB, 'dartdoc', 'client-live-nav.dart'),
      join(LIB, 'dartdoc', 'client-static.dart')
    ], [
      ("#import\('../../frog", "#import('../frog")
    ])

  # Create and populate lib/isolate
  copytree(join(HOME, 'lib', 'isolate'), join(LIB, 'isolate'),
           ignore=ignore_patterns('.svn'))

  #
  # Create and populate lib/core.
  #

  # First, copy corelib/* to lib/{frog, runtime}
  for filename in corelib_sources:
    for target_dir in ['frog', 'runtime']:
      copyfile(join('corelib', 'src', filename),
               join(corelib_dest_dir, target_dir, filename))

  # Next, copy the frog library source on top of core/frog
  # TOOD(dgrove): move json to top-level
  for filename in corelib_frog_sources:
    copyfile(join('frog', 'lib', filename),
             join(corelib_dest_dir, 'frog', filename))

  # Next, copy the runtime library source on top of core/runtime
  for filename in corelib_runtime_sources:
    if filename.endswith('.dart'):
      copyfile(join('runtime', 'lib', filename),
               join(corelib_dest_dir, 'runtime', filename))

  #
  # At this point, it's time to create lib/core/core*dart .
  #
  # munge frog/lib/corelib.dart into lib/core_frog.dart .
  src_file = join('frog', 'lib', 'corelib.dart')
  dest_file = open(join(corelib_dest_dir, 'core_frog.dart'), 'w')
  contents = open(src_file).read()
  contents = re.sub('source\(\"../../corelib/src/', 'source(\"', contents)
  contents = re.sub("source\(\"", "source(\"frog/", contents)
  dest_file.write(contents)
  dest_file.close()

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

  # First, copy corelib/src/implementation to corelib/{frog, runtime}.
  for filename in coreimpl_sources:
    for target_dir in ['frog', 'runtime']:
      copyfile(join('corelib', 'src', 'implementation', filename),
               join(coreimpl_dest_dir, target_dir, filename))

  for filename in coreimpl_frog_sources:
    copyfile(join('frog', 'lib', filename),
             join(coreimpl_dest_dir, 'frog', filename))

  for filename in coreimpl_runtime_sources:
    if filename.endswith('.dart'):
      copyfile(join('runtime', 'lib', filename),
               join(coreimpl_dest_dir, 'runtime', filename))


  # Create and fix up lib/coreimpl/coreimpl_frog.dart .
  src_file = join('frog', 'lib', 'corelib_impl.dart')
  dest_file = open(join(coreimpl_dest_dir, 'coreimpl_frog.dart'), 'w')
  contents = open(src_file).read()
  contents = re.sub('source\(\"../../corelib/src/implementation/',
                    'source(\"', contents)
  contents = re.sub('source\(\"', 'source(\"frog/', contents)
  dest_file.write(contents)
  dest_file.close()

  # Construct lib/coreimpl/coreimpl_runtime.dart from whole cloth.
  dest_file = open(join(coreimpl_dest_dir, 'coreimpl_runtime.dart'), 'w')
  dest_file.write('#library("dart:coreimpl");\n')
  for filename in coreimpl_sources:
    dest_file.write('#source("runtime/' + filename + '");\n')
  for filename in coreimpl_runtime_sources:
    if filename.endswith('.dart'):
      dest_file.write('#source("runtime/' + filename + '");\n')
  dest_file.close()

  # Create and copy tools.

  UTIL = join(SDK_tmp, 'util')
  os.makedirs(UTIL)

  move(SDK_tmp, SDK)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
