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

def execute(args):
  process = subprocess.Popen(args)
  process.wait()
  return process.returncode

def main():
  component = 'all'
  if len(sys.argv) == 2:
    component = sys.argv[1]

  component_gyp_files = {
    'all' : 'dart/dart.gyp',
    'runtime' : 'dart/runtime/dart-runtime.gyp',
  }
  args = ['python', 'dart/third_party/gyp/gyp_main.py',
          '--depth=dart', '-Idart/tools/gyp/all.gypi',
          component_gyp_files[component]]

  if sys.platform == 'win32':
    # Generate Visual Studio 2010 compatible files by default.
    if not os.environ.get('GYP_MSVS_VERSION'):
      args.extend(['-G', 'msvs_version=2010'])

  sys.exit(execute(args))

if __name__ == '__main__':
  main()
