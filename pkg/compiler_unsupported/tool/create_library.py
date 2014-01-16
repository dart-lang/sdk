#!/usr/bin/env python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Create the compiler_unsupported package. This will copy the
# sdk/lib/_internal/compiler directory and the libraries.dart file into lib/.
#
# Usage: create_library.py

import os
import re
import shutil
import sys

from os.path import dirname, join


def ReplaceInFiles(paths, subs):
  '''Reads a series of files, applies a series of substitutions to each, and
     saves them back out. subs should be a list of (pattern, replace) tuples.'''
  for path in paths:
    contents = open(path).read()
    for pattern, replace in subs:
      contents = re.sub(pattern, replace, contents)
    dest = open(path, 'w')
    dest.write(contents)
    dest.close()


def RemoveFile(f):
  if os.path.exists(f):
    os.remove(f)


def Main(argv):
  # pkg/compiler_unsupported
  HOME = dirname(dirname(os.path.realpath(__file__)))

  # pkg/compiler_unsupported/lib
  TARGET = join(HOME, 'lib')

  # sdk/lib/_internal
  SOURCE = join(dirname(dirname(HOME)), 'sdk', 'lib', '_internal')

  # clean compiler_unsupported/lib
  if not os.path.exists(TARGET):
    os.mkdir(TARGET)
  shutil.rmtree(join(TARGET, 'implementation'), True)
  RemoveFile(join(TARGET, 'compiler.dart'))
  RemoveFile(join(TARGET, 'libraries.dart'))

  # copy dart2js code
  shutil.copy(join(SOURCE, 'compiler', 'compiler.dart'), TARGET)
  shutil.copy(join(SOURCE, 'libraries.dart'), TARGET)
  shutil.copytree(
      join(SOURCE, 'compiler', 'implementation'),
      join(TARGET, 'implementation'))

  # patch up the libraries.dart references
  replace = [(r'\.\./\.\./libraries\.dart', r'\.\./libraries\.dart')]

  for root, dirs, files in os.walk(join(TARGET, 'implementation')):
    for name in files:
      if name.endswith('.dart'):
        ReplaceInFiles([join(root, name)], replace)


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
