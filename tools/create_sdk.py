#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# A script which will be invoked from gyp to create an SDK. The SDK will be
# used either from the command-line or from the editor. Top structure is
# 
# ..sdk/
# ....bin/
# ......dart or dart.exe (executable)
# ......frogc.dart
# ......frogsh (coming later)
# ....lib/
# ......builtin/
# ........builtin_runtime.dart
# ........runtime/
# ......core/
# ........core_{compiler, frog, runtime}.dart
# ........{compiler, frog, runtime}/ 
# ......coreimpl/
# ........coreimpl_{compiler, frog, runtime}.dart
# ........{compiler, frog, runtime}/ 
# ......dom/
# ........dom.dart
# ......frog/
# ......html/ 
# ........html.dart
# ......htmlimpl/ 
# ........htmlimpl.dart
# ......json/
# ........json_{compiler, frog}.dart
# ........{compiler, frog}/
# ......(more will come here - io, etc)
# ....tools/
# ......dartdoc/
# ......(more will come here)



import os
import re
import sys
import utils

from os.path import dirname, join, realpath, exists, isdir
from shutil import copyfile, copymode, copytree, ignore_patterns, rmtree

def Main(argv):
  # Pull in all of the gpyi files which will be munged into the sdk.
  builtin_runtime_sources = \
    (eval(open("runtime/bin/builtin_sources.gypi").read()))['sources']
  corelib_sources = \
    (eval(open("corelib/src/corelib_sources.gypi").read()))['sources']
  corelib_frog_sources = \
    (eval(open("frog/lib/frog_corelib_sources.gypi").read()))['sources']
  corelib_runtime_sources = \
    (eval(open("runtime/lib/lib_sources.gypi").read()))['sources']
  corelib_compiler_sources =  \
    (eval(open("compiler/compiler_corelib_sources.gypi").read())) \
    ['variables']['compiler_corelib_resources']
  coreimpl_sources = \
    (eval(open("corelib/src/implementation/corelib_impl_sources.gypi").read()))\
    ['sources']
  coreimpl_frog_sources = \
    (eval(open("frog/lib/frog_coreimpl_sources.gypi").read()))['sources']
  coreimpl_runtime_sources = \
    (eval(open("runtime/lib/lib_impl_sources.gypi").read()))['sources']
  json_compiler_sources = \
    (eval(open("compiler/jsonlib_sources.gypi").read())) \
    ['variables']['jsonlib_resources']
  json_frog_sources = \
    (eval(open("frog/lib/frog_json_sources.gypi").read()))['sources']

  HOME = dirname(dirname(realpath(__file__)))

  SDK = argv[1]

  # TODO(dgrove) - deal with architectures that are not ia32.
  if (os.path.basename(os.path.dirname(SDK)) != 
      utils.GetBuildConf('release', 'ia32')):
    print "SDK is not built in Debug mode."
    # leave empty dir behind
    os.makedirs(SDK)
    exit(0)

  if exists(SDK):
    rmtree(SDK)

  # Create and populate sdk/bin.
  BIN = join(SDK, 'bin')
  os.makedirs(BIN)

  # Copy the Dart VM binary into sdk/bin.
  # TODO(dgrove) - deal with architectures that are not ia32.
  build_dir = utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')
  if utils.GuessOS() == 'win32':
    dart_src_binary = join(join(HOME, build_dir), 'dart.exe')
    dart_dest_binary = join(BIN, 'dart.exe')
  else:
    dart_src_binary = join(join(HOME, build_dir), 'dart')
    dart_dest_binary = join(BIN, 'dart')
  copyfile(dart_src_binary, dart_dest_binary)
  copymode(dart_src_binary, dart_dest_binary)

  # Create sdk/bin/frogc.dart, and hack as needed.
  frog_src_dir = join(HOME, 'frog')

  # Convert frogc.dart's imports from import('*') -> import('frog/*').
  frogc_contents = open(join(frog_src_dir, 'frogc.dart')).read()
  frogc_dest = open(join(BIN, 'frogc.dart'), 'w')
  frogc_dest.write(
    re.sub("#import\('", "#import('../lib/frog/", frogc_contents))
  frogc_dest.close()

  # TODO(dgrove): copy and fix up frog.dart, minfrogc.dart.

  #
  # Create and populate sdk/lib.
  #

  LIB = join(SDK, 'lib')
  os.makedirs(LIB)
  corelib_dest_dir = join(LIB, 'core')
  os.makedirs(corelib_dest_dir)
  os.makedirs(join(corelib_dest_dir, 'compiler'))
  os.makedirs(join(corelib_dest_dir, 'frog'))
  os.makedirs(join(corelib_dest_dir, 'runtime'))

  coreimpl_dest_dir = join(LIB, 'coreimpl')
  os.makedirs(coreimpl_dest_dir)
  os.makedirs(join(coreimpl_dest_dir, 'compiler'))
  os.makedirs(join(coreimpl_dest_dir, 'frog'))
  os.makedirs(join(coreimpl_dest_dir, 'frog', 'node'))
  os.makedirs(join(coreimpl_dest_dir, 'runtime'))


  #
  # Create and populate lib/runtime.
  #
  builtin_dest_dir = join(LIB, 'builtin')
  os.makedirs(builtin_dest_dir)
  os.makedirs(join(builtin_dest_dir, 'runtime'))
  for filename in builtin_runtime_sources:
    if filename.endswith('.dart'):
      copyfile(join(HOME, 'runtime', 'bin', filename), 
               join(builtin_dest_dir, 'runtime', filename))

  # Construct lib/builtin/builtin_runtime.dart from whole cloth.
  dest_file = open(join(builtin_dest_dir, 'builtin_runtime.dart'), 'w')
  dest_file.write('#library("dart:builtin");\n')
  for filename in builtin_runtime_sources:
    if filename.endswith('.dart'):
      dest_file.write('#source("runtime/' + filename + '");\n')
  dest_file.close()

  #
  # Create and populate lib/frog.
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

  copytree(join(frog_src_dir, 'leg'), join(frog_dest_dir, 'leg'), 
           ignore=ignore_patterns('.svn'))

  #
  # Create and populate lib/html and lib/htmlimpl.
  #
  html_src_dir = join(HOME, 'client', 'html')
  html_dest_dir = join(LIB, 'html')
  os.makedirs(html_dest_dir)
  htmlimpl_dest_dir = join(LIB, 'htmlimpl')
  os.makedirs(htmlimpl_dest_dir)

  copyfile(join(html_src_dir, 'release', 'html.dart'), 
           join(html_dest_dir, 'html.dart'))
  copyfile(join(html_src_dir, 'release', 'htmlimpl.dart'), 
           join(htmlimpl_dest_dir, 'htmlimpl.dart'))

  # TODO(dgrove): prune the correct files in html and htmlimpl.
  for target_dir in [html_dest_dir, htmlimpl_dest_dir]:
    copytree(join(html_src_dir, 'src'), join(target_dir, 'src'),
             ignore=ignore_patterns('.svn'))
    copytree(join(html_src_dir, 'generated'), join(target_dir, 'generated'),
             ignore=ignore_patterns('.svn'))


  #
  # Create and populate lib/json.
  #

  json_frog_dest_dir = join(LIB, 'json', 'frog')
  json_compiler_dest_dir = join(LIB, 'json', 'compiler')
  os.makedirs(json_frog_dest_dir)
  os.makedirs(json_compiler_dest_dir)

  for filename in json_frog_sources:
    copyfile(join(HOME, 'frog', 'lib', filename), 
             join(json_frog_dest_dir, filename))

  for filename in json_compiler_sources:
    copyfile(join(HOME, 'compiler', filename),
             join(json_compiler_dest_dir, os.path.basename(filename)))

  # Create json_compiler.dart and json_frog.dart from whole cloth.
  dest_file = open(join(LIB, 'json', 'json_compiler.dart'), 'w')
  dest_file.write('#library("dart:json");\n')
  dest_file.write('#import("compiler/json.dart");\n')
  dest_file.close()
  dest_file = open(join(LIB, 'json', 'json_frog.dart'), 'w')
  dest_file.write('#library("dart:json");\n')
  dest_file.write('#import("frog/json.dart");\n')
  dest_file.close()
      
  #
  # Create and populate lib/dom.
  #
  dom_src_dir = join(HOME, 'client', 'dom')
  dom_dest_dir = join(LIB, 'dom')
  os.makedirs(dom_dest_dir)

  for filename in os.listdir(dom_src_dir):
    src_file = join(dom_src_dir, filename)
    dest_file = join(dom_dest_dir, filename)
    if filename.endswith('.dart') or filename.endswith('.js'):
      copyfile(src_file, dest_file)
    elif isdir(src_file):
      if filename not in ['benchmarks', 'idl', 'scripts', 'snippets', '.svn']:
        copytree(src_file, dest_file, 
                 ignore=ignore_patterns('.svn', 'interface', 'wrapping', 
                                        '*monkey*'))

  #
  # Create and populate lib/core.
  #

  # First, copy corelib/* to lib/{compiler, frog, runtime}
  for filename in corelib_sources:
    for target_dir in ['compiler', 'frog', 'runtime']:
      copyfile(join('corelib', 'src', filename), 
               join(corelib_dest_dir, target_dir, filename))

  # Next, copy the compiler sources on top of {core,coreimpl}/compiler
  for filename in corelib_compiler_sources:
    if (filename.endswith(".dart")):
      filename = re.sub("lib/","", filename)
      if not filename.startswith("implementation/"):
        copyfile(join('compiler', 'lib', filename), 
                 join(corelib_dest_dir, 'compiler', filename))

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
  dest_file.close()

  # TODO(dgrove) - create lib/core/core_compiler.dart .

  #
  # Create and populate lib/coreimpl.
  #

  # First, copy corelib/src/implementation to corelib/{compiler, frog, runtime}.
  for filename in coreimpl_sources:
    for target_dir in ['compiler', 'frog', 'runtime']:
      copyfile(join('corelib', 'src', 'implementation', filename), 
               join(coreimpl_dest_dir, target_dir, filename))

  # Next, copy {compiler, frog, runtime}-specific implementations.
  for filename in corelib_compiler_sources:
    if (filename.endswith(".dart")):
      if filename.startswith("lib/implementation/"):
        filename = os.path.basename(filename)
        copyfile(join('compiler', 'lib', 'implementation', filename), 
                 join(coreimpl_dest_dir, 'compiler', filename))

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

  # TODO(dgrove) - create lib/coreimpl/coreimpl_compiler.dart .

  # Create and copy tools.

  UTIL = join(SDK, 'tools')
  os.makedirs(UTIL)

  copytree(join(HOME, 'utils', 'dartdoc'), join(UTIL, 'dartdoc'), 
           ignore=ignore_patterns('.svn'))

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
