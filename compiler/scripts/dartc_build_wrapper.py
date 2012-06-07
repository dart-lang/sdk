#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Wrapper around dartc for use from GYP."""

import optparse
import os
from os import path
import shutil
import subprocess
import sys


def _BuildOptions():
  op = optparse.OptionParser(usage='usage: %prog [options] FILE')
  op.add_option('--out')
  op.add_option('--dartc')
  op.add_option('--dartc-option', action='append', dest='dartc_options',
                default=[])
  op.add_option('--incremental', action='store_false',
                default=os.getenv('DARTC_INCREMENTAL', default=False))
  return op


def _ParseOptions(cmd_line):
  op = _BuildOptions()
  (options, args) = op.parse_args(args=cmd_line)
  if not options.out:
    op.error('Flag "--out" not provided')
  if not options.dartc:
    op.error('Flag "--dartc" not provided')
  return (options, args)


def main():
  (options, args) = _ParseOptions(sys.argv[1:])
  if path.exists(options.out):
    is_out_of_date = path.getmtime(options.dartc) > path.getmtime(options.out)
    if is_out_of_date or not options.incremental:
      print 'Deleting %r.' % options.out
      shutil.rmtree(options.out)
  command_array = [options.dartc]
  command_array.extend(['-out', options.out])
  command_array.extend(options.dartc_options)
  command_array.extend(args)
  print ' '.join([repr(a) for a in command_array])
  proc = subprocess.Popen(command_array)
  proc.communicate()
  sys.exit(proc.wait())


if __name__ == '__main__':
  main()
