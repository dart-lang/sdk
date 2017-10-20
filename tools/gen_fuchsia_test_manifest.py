#!/usr/bin/env python
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script creates a qemu image manifest for Fuchsia that contains the
# Dart tree. In particular in contains Dart's test suite, and test harness.

import argparse
import json
import os
import sys
import utils

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
FUCHSIA_ROOT= os.path.realpath(os.path.join(DART_ROOT, '..', '..'))

FUCHSIA_TEST_MANIFEST_PREFIX = os.path.join('test', 'dart')

EXCLUDE_DIRS = [ '.git', 'out', '.jiri' ]

BINARY_FILES = [ 'dart', 'run_vm_tests', 'process_test' ]

def parse_args(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script that generates Dart/Fuchsia test commands.')

  parser.add_argument('--arch', '-a',
      type=str,
      help='Target architectures (comma-separated).',
      metavar='[x64]',
      default='x64')
  parser.add_argument('--mode', '-m',
      type=str,
      help='Build variant',
      metavar='[debug,release]',
      default='debug')
  parser.add_argument('--output', '-o',
      type=str,
      help='Path to output file prefix.')
  parser.add_argument('--user-manifest', '-u',
      type=str,
      help='Path to base userspace manifest.')
  parser.add_argument("-v", "--verbose",
      help='Verbose output.',
      default=False,
      action="store_true")

  return parser.parse_args(args)


def fuchsia_arch(arch):
  if arch is 'x64':
    return 'x86-64'
  return None


def main(argv):
  args = parse_args(argv)

  manifest_output = args.output + '.manifest'
  with open(manifest_output, 'w') as manifest:
    # First copy the main user manifest.
    with open(args.user_manifest, 'r') as user_manifest:
      for line in user_manifest:
        if '=' in line:
          manifest.write(line)

    # Now, write the Dart tree.
    for root, dirs, files in os.walk(DART_ROOT):
      dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
      for file in files:
        filepath = os.path.join(root, file)
        relpath = filepath[len(DART_ROOT) + 1:]
        fuchsiapath = os.path.join(FUCHSIA_TEST_MANIFEST_PREFIX, relpath)
        manifest.write('%s=%s\n' % (fuchsiapath, os.path.join(root, file)))

    dart_conf = utils.GetBuildConf(args.mode, args.arch)
    dart_out = os.path.join(FUCHSIA_TEST_MANIFEST_PREFIX, 'out', dart_conf)
    fuchsia_conf = '%s-%s' % (args.mode, fuchsia_arch(args.arch))
    fuchsia_out = os.path.join(FUCHSIA_ROOT, 'out', fuchsia_conf)
    for file in BINARY_FILES:
      manifest.write('%s=%s\n' % (os.path.join(dart_out, file),
                                  os.path.join(fuchsia_out, file)))

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
