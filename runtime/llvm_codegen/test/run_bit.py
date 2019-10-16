# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import subprocess
import argparse

parser = argparse.ArgumentParser(description="A tool to run the bit integration tester")
parser.add_argument("--bit", help="Sets the path to bit")
parser.add_argument("--test", help="Path to test to be run")
parser.add_argument("--out", help="Path to out directory")
args = parser.parse_args()

subprocess.check_call([args.bit, args.test, args.out])

