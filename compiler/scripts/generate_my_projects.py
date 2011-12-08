#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys


def Main():
  def normjoin(*args):
    return os.path.normpath(os.path.join(*args))

  compiler = normjoin(sys.argv[0], os.pardir, os.pardir)
  tools = normjoin(compiler, os.pardir, 'tools')
  locations = {
    'compiler': compiler,
    'tools': tools,
    }

  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "java %(compiler)s/sources java" % locations)
  if exit_code:
    return exit_code


  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "javatests %(compiler)s/test_sources javatests"
                        % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "corelib %(compiler)s/corelib_sources ../corelib/src"
                        % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_systemlibrary_list.py "
                        "domlib %(compiler)s/domlib_sources ../client/dom dom.dart LICENSE README.google"
                        % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_systemlibrary_list.py "
                        "htmllib %(compiler)s/htmllib_sources ../client/html/release html.dart htmlimpl.dart"
                        % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_systemlibrary_list.py "
                        "jsonlib %(compiler)s/jsonlib_sources ../client/json json.dart"
                        % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "compiler_corelib "
                        "%(compiler)s/compiler_corelib_sources "
                        "lib" % locations)
  if exit_code:
    return exit_code

  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "closure_compiler_src %(compiler)s/closure_compiler_sources "
                        "../third_party/closure_compiler_src "
                        "build javadoc test"
                        % locations)
  if exit_code:
    return exit_code

  if '--no-gyp' in sys.argv:
    print '--no-gyp is deprecated.'

  return exit_code


if __name__ == '__main__':
  sys.exit(Main())
