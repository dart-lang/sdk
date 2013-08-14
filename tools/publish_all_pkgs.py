#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Upload all packages in pkg/ (other than a few that should be explicitly
# excluded), plus sdk/lib/_internal/compiler .
#
# Usage: publish_all_pkgs.py
#
# "pub" must be in PATH.


import os
import os.path
import subprocess
import sys

def Main(argv):
  for pkgdir in ['pkg', 'pkg/third_party']:
    for name in os.listdir(pkgdir):
      if os.path.isdir(os.path.join(pkgdir, name)):
        if (name != '.svn' and name != 'expect' and name != 'third_party'):
          pkgs_to_publish.append(os.path.join(pkgdir, name))

  for pkg in pkgs_to_publish:
    print "\n\nPublishing [32m%s[0m:\n-------------------------------" % pkg
    subprocess.call(['python', 'tools/publish_pkg.py', pkg])

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
