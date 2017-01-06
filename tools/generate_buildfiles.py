#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import utils

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DART_USE_GYP = "DART_USE_GYP"
DART_DISABLE_BUILDFILES = "DART_DISABLE_BUILDFILES"


def use_gyp():
  return DART_USE_GYP in os.environ


def disable_buildfiles():
  return DART_DISABLE_BUILDFILES in os.environ


def execute(args):
  process = subprocess.Popen(args, cwd=DART_ROOT)
  process.wait()
  return process.returncode


def run_gn(options):
  gn_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gn.py'),
    '-m', 'all',
    '-a', 'all',
  ]
  if options.verbose:
    gn_command.append('-v')
    print ' '.join(gn_command)
  return execute(gn_command)


def run_gyp(options):
  gyp_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gyp_dart.py'),
  ]
  if options.verbose:
    print ' '.join(gyp_command)
  return execute(gyp_command)


def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description="A script to generate Dart's build files.")

  parser.add_argument("-v", "--verbose",
      help='Verbose output.',
      default=False,
      action="store_true")
  parser.add_argument("--gn",
      help='Use GN',
      default=not use_gyp(),
      action='store_true')
  parser.add_argument("--gyp",
      help='Use gyp',
      default=use_gyp(),
      action='store_true')

  options = parser.parse_args(args)
  # If gyp is enabled one way or another, then disable gn
  if options.gyp:
    options.gn = False
  return options


def main(argv):
  # Check the environment and become a no-op if directed.
  if disable_buildfiles():
    return 0
  options = parse_args(argv)
  if options.gn:
    return run_gn(options)
  else:
    return run_gyp(options)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
