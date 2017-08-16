#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import gn_helpers
import os
import re
import shutil
import sys

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to copy a file tree somewhere')

  parser.add_argument('--exclude_patterns', '-e',
      type=str,
      help='Patterns to exclude [passed to shutil.copytree]')
  parser.add_argument('--from', '-f',
      dest="copy_from",
      type=str,
      help='Source directory')
  parser.add_argument('--gn', '-g',
      dest='gn',
      default=False,
      action='store_true',
      help='Output for GN for multiple sources, but do not copy anything.')
  parser.add_argument('gn_paths',
      metavar='name path ignore_pattern',
      type=str,
      nargs='*',
      default=None,
      help='When --gn is given, the specification of source paths to list.')
  parser.add_argument('--to', '-t',
      type=str,
      help='Destination directory')

  return parser.parse_args(args)


def ValidateArgs(args):
  if args.gn:
    if args.exclude_patterns or args.copy_from or args.to:
      print "--gn mode does not accept other switches"
      return False
    if not args.gn_paths:
      print "--gn mode requires a list of source specifications"
      return False
    return True
  if not args.copy_from or not os.path.isdir(args.copy_from):
    print "--from argument must refer to a directory"
    return False
  if not args.to:
    print "--to is required"
    return False
  return True


def CopyTree(src, dst, ignore=None):
  names = os.listdir(src)
  if ignore is not None:
    ignored_names = ignore(src, names)
  else:
    ignored_names = set()

  os.makedirs(dst)
  errors = []
  for name in names:
    if name in ignored_names:
      continue
    srcname = os.path.join(src, name)
    dstname = os.path.join(dst, name)
    try:
      if os.path.isdir(srcname):
        CopyTree(srcname, dstname, ignore)
      else:
        shutil.copy(srcname, dstname)
    except (IOError, os.error) as why:
      errors.append((srcname, dstname, str(why)))
    # catch the Error from the recursive CopyTree so that we can
    # continue with other files
    except Error as err:
      errors.extend(err.args[0])
  try:
    shutil.copystat(src, dst)
  except WindowsError:
    # can't copy file access times on Windows
    pass
  except OSError as why:
    errors.extend((src, dst, str(why)))
  if errors:
    raise Error(errors)


def ListTree(src, ignore=None):
  names = os.listdir(src)
  if ignore is not None:
    ignored_names = ignore(src, names)
  else:
    ignored_names = set()

  srcnames = []
  for name in names:
    if name in ignored_names:
      continue
    srcname = os.path.join(src, name)
    if os.path.isdir(srcname):
      srcnames.extend(ListTree(srcname, ignore))
    else:
      srcnames.append(srcname)
  return srcnames


# source_dirs is organized such that sources_dirs[n] is the path for the source
# directory, and source_dirs[n+1] is a list of ignore patterns.
def SourcesToGN(source_dirs):
  if len(source_dirs) % 2 != 0:
    print "--gn list length should be a multiple of 2."
    return False
  data = []
  for i in xrange(0, len(source_dirs), 2):
    path = source_dirs[i]
    ignores = source_dirs[i + 1]
    if ignores in ["{}"]:
      sources = ListTree(path)
    else:
      patterns = ignores.split(',')
      sources = ListTree(path, ignore=shutil.ignore_patterns(*patterns))
    data.append(sources)
  scope_data = {"sources": data}
  print gn_helpers.ToGNString(scope_data)
  return True


def Main(argv):
  args = ParseArgs(argv)
  if not ValidateArgs(args):
    return -1

  if args.gn:
    SourcesToGN(args.gn_paths)
    return 0

  if os.path.exists(args.to):
    shutil.rmtree(args.to)
  if args.exclude_patterns == None:
    CopyTree(args.copy_from, args.to)
  else:
    patterns = args.exclude_patterns.split(',')
    CopyTree(args.copy_from, args.to, ignore=shutil.ignore_patterns(*patterns))
  return 0


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
