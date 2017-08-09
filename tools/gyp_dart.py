#!/usr/bin/env python

# Copyright (c) 2012 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Invoke gyp to generate build files for building the Dart VM.
"""

import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))

def execute(args):
  process = subprocess.Popen(args, cwd=DART_ROOT)
  process.wait()
  return process.returncode

def main():
  component = 'all'
  if len(sys.argv) == 2:
    component = sys.argv[1]

  component_gyp_files = {
    'all' : 'dart.gyp',
    'runtime' : 'runtime/dart-runtime.gyp',
  }
  args = ['python', '-S', 'third_party/gyp/gyp_main.py',
          '--depth=.', '-Itools/gyp/all.gypi',
          component_gyp_files[component]]

  sys.exit(execute(args))

if __name__ == '__main__':
  main()
