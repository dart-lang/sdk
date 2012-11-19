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
  # TODO(ahe): Remove this code when the build bots are green again.
  bug_cleanup = os.path.join(target, 'lib')
  if os.path.islink(bug_cleanup):
    print 'Removing %s' % bug_cleanup
    sys.stdout.flush()
    os.unlink(bug_cleanup)
  # End of temporary code.

  if os.path.islink(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.unlink(target)

  if os.path.isdir(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.rmdir(target)

  if utils.GuessOS() == 'win32':
    source = os.path.relpath(source)
    return subprocess.call(['mklink', '/j', target, source], shell=True)
  else:
    source = os.path.relpath(source, start=target)
    return subprocess.call(['ln', '-s', source, target])


def main(argv):
  target = os.path.relpath(argv[1])
  for source in argv[2:]:
    # Assume the source directory is named ".../TARGET_NAME/lib".
    (name, lib) = os.path.split(source)
    if lib != 'lib':
      name = source
    # Remove any addtional path components preceding TARGET_NAME.
    (path, name) = os.path.split(name)
    exit_code = make_link(source, os.path.join(target, name))
    if exit_code != 0:
      return exit_code
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
