#!/usr/bin/env python
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import subprocess
import sys
import utils

def main():
  dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
  dart_file = os.path.join(os.path.dirname(__file__), 'patch_sdk.dart')
  subprocess.check_call([dart, dart_file] + sys.argv[1:]);

if __name__ == '__main__':
  main()
