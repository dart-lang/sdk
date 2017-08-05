#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys
import utils

HOST_OS = utils.GuessOS()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
DART_DISABLE_BUILDFILES = "DART_DISABLE_BUILDFILES"


def DisableBuildfiles():
  return DART_DISABLE_BUILDFILES in os.environ


def Execute(args):
  process = subprocess.Popen(args, cwd=DART_ROOT)
  process.wait()
  return process.returncode


def RunAndroidGn(options):
  if not HOST_OS in ['linux', 'macos']:
    return 0
  gn_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gn.py'),
    '-m', 'all',
    '-a', 'arm,arm64',
    '--os', 'android',
  ]
  if options.verbose:
    gn_command.append('-v')
    print ' '.join(gn_command)
  return Execute(gn_command)


def RunCrossGn(options):
  if HOST_OS != 'linux':
    return 0
  gn_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gn.py'),
    '-m', 'all',
    '-a', 'arm,arm64',
  ]
  if options.verbose:
    gn_command.append('-v')
    print ' '.join(gn_command)
  return Execute(gn_command)


def RunHostGn(options):
  gn_command = [
    'python',
    os.path.join(DART_ROOT, 'tools', 'gn.py'),
    '-m', 'all',
    '-a', 'all',
  ]
  if options.verbose:
    gn_command.append('-v')
    print ' '.join(gn_command)
  return Execute(gn_command)


def RunGn(options):
  status = RunHostGn(options)
  if status != 0:
    return status
  status = RunCrossGn(options)
  if status != 0:
    return status
  return RunAndroidGn(options)


def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description="A script to generate Dart's build files.")

  parser.add_argument("-v", "--verbose",
      help='Verbose output.',
      default=False,
      action="store_true")

  return parser.parse_args(args)


def main(argv):
  # Check the environment and become a no-op if directed.
  if DisableBuildfiles():
    return 0
  options = ParseArgs(argv)
  RunGn(options)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
