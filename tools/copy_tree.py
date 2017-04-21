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

  parser.add_argument('--exclude_patterns', '-e',
      type=str,
      help='Patterns to exclude [passed to shutil.copytree]')
  parser.add_argument('--from', '-f',
      dest="copy_from",
      type=str,
      required=True,
      help='Source tree root')
  parser.add_argument('--to', '-t',
      type=str,
      required=True,
      help='Destination')

  return parser.parse_args(args)


def ValidateArgs(args):
  if not os.path.isdir(args.copy_from):
    print "--from argument must refer to a directory"
    return False
  return True


def Main(argv):
  args = ParseArgs(argv)
  if not ValidateArgs(args):
    return -1
  if os.path.exists(args.to):
    shutil.rmtree(args.to)
  if args.exclude_patterns == None:
    shutil.copytree(args.copy_from, args.to)
  else:
    patterns = args.exclude_patterns.split(',')
    shutil.copytree(args.copy_from, args.to,
                    ignore=shutil.ignore_patterns(tuple(patterns)))
  return 0


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
