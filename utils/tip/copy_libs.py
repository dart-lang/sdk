#!/usr/local/evn python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# TODO(jimhug): THIS IS CURRENTLY BROKEN - NEEDS FIX BEFORE EXTENSIONS WORK!

# A script that copies dart/frog/lib under dart/frog/tip/lib/. This script
# internally uses copy_dart to resolve relative paths used in the libraries and
# merge source files together.

# Note: The current setup assumes that all libraries used by frog (except some
# sources) are within the frog/lib. If frog/lib contains a #import outside that
# directory, we need to update this script to contain a deeper hierarchy of
# directories.

import os
import fileinput
import re
import subprocess
import sys

TIP_PATH = os.path.dirname(os.path.abspath(__file__))
FROG_PATH = os.path.dirname(TIP_PATH)
LIB_PATH = os.path.join(FROG_PATH, 'lib')

re_library = re.compile(r'^#library\([\'"]([^\'"]*)[\'"]\);$')

def find_libraries(path):
  """ finds .dart files containing the #library directive. """
  libs = []
  for root, dirs, files in os.walk(path):
    for fname in files:
      if fname.endswith('.dart') and not root.endswith('lib/node'):
        relpath = os.path.relpath(os.path.join(root, fname))
        for line in fileinput.input(relpath):
          if re_library.match(line):
            libs.append(relpath)
            break
        fileinput.close()
  return libs

def main():
  os.chdir(LIB_PATH)
  libs = find_libraries(LIB_PATH)
  return subprocess.call([sys.executable,
      '../../tools/copy_dart.py', os.path.join(TIP_PATH, 'lib')] + libs)

if __name__ == '__main__':
  sys.exit(main())
