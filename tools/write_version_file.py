#!/usr/bin/env python
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import argparse
import os
import sys
import utils

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to write the version string to a file')

  parser.add_argument('--output', '-o',
      type=str,
      required=True,
      help='File to write')

  return parser.parse_args(args)


def Main(argv):
  args = ParseArgs(argv)
  version = utils.GetVersion()
  with open(args.output, 'w') as versionFile:
    versionFile.write(version + '\n')
  return 0

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
