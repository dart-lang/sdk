#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


'''Tool for creating symlinks from SOURCES to TARGET.

For each SOURCE in SOURCES create a link from SOURCE to TARGET.  If a
SOURCE ends with .../lib, the lib suffix is ignored when determining
the name of the target link.

Usage:
  python tools/make_links.py TARGET SOURCES...
'''

import os
import subprocess
import sys
import utils


def make_link(source, target):
  if utils.GuessOS() == 'win32':
    return subprocess.call(['mklink', '/j', target, source])
  else:
    return subprocess.call(['ln', '-s', source, target])


def main(argv):
  target = argv[1]
  for source in argv[2:]:
    # Assume the source directory is named ".../TARGET_NAME/lib".
    (name, lib) = os.path.split(source)
    if lib != 'lib':
      name = source
    # Remove any addtional path components preceding TARGET_NAME.
    (path, name) = os.path.split(name)
    exit_code = make_link(os.path.relpath(source, start=target),
                          os.path.join(target, name))
    if exit_code != 0:
      return exit_code
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
