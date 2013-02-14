#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# A script which will be invoked from gyp to print the current version of the
# SDK.
#
# Usage: print_version
#

import sys
import utils

def Main(argv):
  print(utils.GetVersion())

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
