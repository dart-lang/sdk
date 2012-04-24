#!/usr/bin/env python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Traverses apidoc and dartdoc and lists all possible input files that are
# used when building API documentation. Used by gyp to determine when apidocs
# need to be regenerated (see `apidoc.gyp`).

# TODO(rnystrom): Port this to dart. It can be run before dart has been built
# (which is when this script is invoked by gyp) by using the prebuild dart in
# tools/testing/bin.

import os
import sys

def handle_walk(root, directories, files, start):
  for filename in files:
    if filename.endswith((
        '.css', '.dart', '.ico', '.js', '.json', '.png', '.sh', '.txt')):
      print os.path.relpath(os.path.join(root, filename), start=start)


def main(argv):
  if len(argv) == 1:
    dir = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                       os.pardir, os.pardir, os.pardir)
  else:
    dir = argv[1]
  start = os.path.join(dir, 'utils', 'apidoc')
  for root, directories, files in os.walk(os.path.join(dir, 'utils', 'apidoc')):
    handle_walk(root, directories, files, start)
  for root, directories, files in os.walk(os.path.join(dir, 'lib', 'dartdoc')):
    handle_walk(root, directories, files, start)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
