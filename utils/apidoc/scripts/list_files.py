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

def main(argv):
  if len(argv) == 1:
    dir = os.curdir
  else:
    dir = argv[1]
  for root, directories, files in os.walk(dir):
    if root == os.curdir:
      directories[0:] = [
        os.path.join('utils', 'apidoc'),
        os.path.join('lib', 'dartdoc')
      ]

    for filename in files:
      if filename.endswith((
          '.css', '.dart', '.ico', '.js', '.json', '.png', '.sh', '.txt')):
        print os.path.relpath(os.path.join(root, filename))

if __name__ == '__main__':
  sys.exit(main(sys.argv))