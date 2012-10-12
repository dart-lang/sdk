# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script "touches" the tools/VERSION file.

import os
import sys

# Change into the dart directory as we want to be able to access the VERSION file
# from a simple path.
runtime_src = os.path.join(os.path.dirname(sys.argv[0]), os.pardir)
os.chdir(runtime_src)

if __name__ == '__main__':
  print 'Touching tools/VERSION.'
  os.utime(os.path.join('tools', 'VERSION'), None)
  sys.exit(0)
