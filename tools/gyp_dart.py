#!/usr/bin/env python

# Copyright (c) 2012 The Dart Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script is wrapper for Dart that adds some support for how GYP
# is invoked by Dart beyond what can be done in the gclient hooks.

import os
import subprocess
import sys

def Execute(args):
  process = subprocess.Popen(args)
  process.wait()
  return process.returncode

if __name__ == '__main__':
  args = ['python',  "dart/third_party/gyp/gyp", "--depth=dart",
                 "-Idart/tools/gyp/all.gypi", "dart/dart.gyp"]

  if sys.platform == 'win32':
    # Generate Visual Studio 2008 compatible files by default.
    if not os.environ.get('GYP_MSVS_VERSION'):
      args.extend(['-G', 'msvs_version=2008'])

  sys.exit(Execute(args))
