#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


'''Tool for creating symlinks from SOURCES to TARGET.

For each SOURCE in SOURCES create a link from SOURCE to TARGET.  If a
SOURCE ends with .../lib, the lib suffix is ignored when determining
the name of the target link.

Before creating any links, the old entries of the TARGET directory will be
removed.

Usage:
  python tools/make_links.py OPTIONS TARGET SOURCES...
'''

import optparse
import os
import shutil
import subprocess
import sys
import utils


def get_options():
  result = optparse.OptionParser()
  result.add_option("--timestamp_file", "",
      help='Create a timestamp file when done creating the links.',
      default='')
  return result.parse_args()

def make_link(source, target):
  if os.path.islink(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.unlink(target)

  if os.path.isdir(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.rmdir(target)

  print 'Creating link from %s to %s' % (source, target)
  sys.stdout.flush()

  if utils.GuessOS() == 'win32':
    return subprocess.call(['mklink', '/j', target, source], shell=True)
  else:
    return subprocess.call(['ln', '-s', source, target])

def create_timestamp_file(options):
  if options.timestamp_file != '':
    dir_name = os.path.dirname(options.timestamp_file)
    if not os.path.exists(dir_name):
      os.mkdir(dir_name)
    open(options.timestamp_file, 'w').close()


def main(argv):
  (options, args) = get_options()
  target = os.path.relpath(args[0])
  if os.path.exists(target):
    # Remove the packages directory if it already exists.
    # This is necessary, otherwise we can end up having links in there
    # pointing to directories which no longer exist (on incremental builds).
    print 'Removing %s' % target
    shutil.rmtree(target)
  os.makedirs(target)
  for source in args[1:]:
    # Assume the source directory is named ".../NAME/lib".
    (name, lib) = os.path.split(source)
    if lib != 'lib':
      name = source
    # Remove any addtional path components preceding NAME.
    (path, name) = os.path.split(name)
    if utils.GuessOS() == 'win32':
      source = os.path.relpath(source)
    else:
      source = os.path.relpath(source, start=target)
    exit_code = make_link(source, os.path.join(target, name))
    if exit_code != 0:
      return exit_code
  create_timestamp_file(options)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
