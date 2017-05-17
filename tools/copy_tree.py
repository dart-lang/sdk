#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import os
import re
import shutil
import sys

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to copy a file tree somewhere')

  parser.add_argument('--dry-run', '-d',
      dest='dryrun',
      default=False,
      action='store_true',
      help='Print the paths of the source files, but do not copy anything.')
  parser.add_argument('--exclude_patterns', '-e',
      type=str,
      help='Patterns to exclude [passed to shutil.copytree]')
  parser.add_argument('--from', '-f',
      dest="copy_from",
      type=str,
      required=True,
      help='Source directory')
  parser.add_argument('--to', '-t',
      type=str,
      required=True,
      help='Destination directory')

  return parser.parse_args(args)


def ValidateArgs(args):
  if not os.path.isdir(args.copy_from):
    print "--from argument must refer to a directory"
    return False
  return True


def CopyTree(src, dst, dryrun=False, symlinks=False, ignore=None):
  names = os.listdir(src)
  if ignore is not None:
    ignored_names = ignore(src, names)
  else:
    ignored_names = set()

  if not dryrun:
    os.makedirs(dst)
  errors = []
  for name in names:
    if name in ignored_names:
      continue
    srcname = os.path.join(src, name)
    dstname = os.path.join(dst, name)
    try:
      if os.path.isdir(srcname):
        CopyTree(srcname, dstname, dryrun, symlinks, ignore)
      else:
        if dryrun:
          print srcname
        else:
          shutil.copy(srcname, dstname)
    except (IOError, os.error) as why:
      errors.append((srcname, dstname, str(why)))
    # catch the Error from the recursive CopyTree so that we can
    # continue with other files
    except Error as err:
      errors.extend(err.args[0])
  try:
    if not dryrun:
      shutil.copystat(src, dst)
  except WindowsError:
    # can't copy file access times on Windows
    pass
  except OSError as why:
    errors.extend((src, dst, str(why)))
  if errors:
    raise Error(errors)


def Main(argv):
  args = ParseArgs(argv)
  if not ValidateArgs(args):
    return -1

  if os.path.exists(args.to) and not args.dryrun:
    shutil.rmtree(args.to)
  if args.exclude_patterns == None:
    CopyTree(args.copy_from, args.to, dryrun=args.dryrun)
  else:
    patterns = args.exclude_patterns.split(',')
    CopyTree(args.copy_from, args.to, dryrun=args.dryrun,
             ignore=shutil.ignore_patterns(*patterns))
  return 0


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
