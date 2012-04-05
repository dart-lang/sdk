#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

  if exit_code:
    return exit_code

  if '--no-gyp' in sys.argv:
    print '--no-gyp is deprecated.'

  return exit_code


if __name__ == '__main__':
  sys.exit(Main())
