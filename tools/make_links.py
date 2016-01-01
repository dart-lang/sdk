#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


"""Tool for creating symlinks from SOURCES to TARGET.

For each SOURCE in SOURCES create a link from SOURCE to TARGET.  If a
SOURCE ends with .../lib, the lib suffix is ignored when determining
the name of the target link.

If a SOURCE contains ":", the left side is the path and the right side is the
name of the package symlink.

Before creating any links, the old entries of the TARGET directory will be
removed.

Usage:
  python tools/make_links.py OPTIONS TARGET SOURCES...

"""

import optparse
import os
import shutil
import subprocess
import sys
import utils

# Useful messages when we find orphaned checkouts.
old_directories = {
    'package_config': 'Please remove third_party/pkg/package_config.',
    'analyzer_cli': 'Please remove third_party/pkg/analyzer_cli.'}

def get_options():
  result = optparse.OptionParser()
  result.add_option("--timestamp_file", "",
      help='Create a timestamp file when done creating the links.',
      default='')
  return result.parse_args()

def make_link(source, target, orig_source):
  if os.path.islink(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.unlink(target)

  if os.path.isdir(target):
    print 'Removing %s' % target
    sys.stdout.flush()
    os.rmdir(target)

  if os.path.isfile(orig_source):
    print 'Copying file from %s to %s' % (orig_source, target)
    sys.stdout.flush()
    shutil.copyfile(orig_source, target)
    return 0
  else:
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
    # If the packages directory already exists, delete the current links inside
    # it. This is necessary, otherwise we can end up having links in there
    # pointing to directories which no longer exist (on incremental builds).
    for link in os.listdir(target):
      full_link = os.path.join(target, link)
      if os.path.isdir(full_link) and utils.IsWindows():
        # It seems like python on Windows is treating pseudo symlinks to
        # directories as directories.
        os.rmdir(full_link)
      else:
        os.remove(full_link)
  else:
    os.makedirs(target)
  linked_names = {}; 
  for source in args[1:]:
    # Assume the source directory is named ".../NAME/lib".
    split = source.split(':')
    name = None
    if len(split) == 2: (source, name) = split

    (path, lib) = os.path.split(source)
    if lib != 'lib':
      path = source
    # Remove any additional path components preceding NAME, if one wasn't
    # specified explicitly.
    if not name: (_, name) = os.path.split(path)
    # We have an issue with left-behind checkouts in third_party/pkg and
    # third_party/pkg_tested when we move entries in DEPS. This reports them.
    if name in linked_names:
      print 'Duplicate directory %s is linked to both %s and %s.' % (
          name, linked_names[name], path)
      if name in old_directories:
        print old_directories[name]
      return 1
    linked_names[name] = path
    orig_source = source
    if utils.GuessOS() == 'win32':
      source = os.path.relpath(source)
    else:
      source = os.path.relpath(source, start=target)
    exit_code = make_link(source, os.path.join(target, name), orig_source)
    if exit_code != 0:
      return exit_code
  create_timestamp_file(options)
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
