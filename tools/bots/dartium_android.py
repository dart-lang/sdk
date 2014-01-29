#!/usr/bin/python
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Dartium on Android buildbot steps.

Runs steps after the buildbot builds Dartium on Android,
which should upload the APK to an attached device, and run
Dart and chromium tests on it.
"""

import sys
import optparse

def GetOptionsParser():
  parser = optparse.OptionParser("usage: %prog [options]")
  parser.add_option("--build-products-dir",
                    help="The directory containing the products of the build.")
  return parser

def main():
  if sys.platform != 'linux2':
    print "This script was only tested on linux. Please run it on linux!"
    sys.exit(1)

  parser = GetOptionsParser()
  (options, args) = parser.parse_args()

  if not options.build_products_dir:
    die("No build products directory given.")
  sys.exit(0)

if __name__ == '__main__':
  main()
