#!/usr/bin/env python

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import sys

# Change into the dart directory as we want the project to be rooted here.
runtime_src = os.path.join(os.path.dirname(sys.argv[0]), os.pardir)
gclient_src = os.path.join(runtime_src, os.pardir)
project_src = os.path.join(gclient_src, sys.argv[1])
os.chdir(project_src)

# Add gyp to the imports and if needed get it from the third_party location
# inside the standalone dart gclient checkout.
try:
  import gyp
except ImportError, e:
  sys.path.append(os.path.join(os.pardir, 'third_party', 'gyp', 'pylib'))
  import gyp

if __name__ == '__main__':
  args = ['--depth', '..']
  args += ['dart-runtime.gyp']

  # Generate the projects.
  sys.exit(gyp.main(args))
