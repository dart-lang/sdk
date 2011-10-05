# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Wraps jscoverage to instrument a single file more efficently.

JScoverage crawls directories recursively to copy and instrument everything
under a directory. This turns out to be too slow for our use, because our
generated .js files live in directories with > 100K files. Even though
jscoverage has a flag ('--exclude') to skip some files for
instrumentation/copying, it stills crawls recursively everything under the
directory.

This script is a simple wrap on top of jscoverage. It creates a temporary
directory, copies the file we want to instrument alone, and runs jscoverage
within this small directory.
"""

import os
import subprocess
import sys

def main():
  if len(sys.argv) < 3:
    print "usage: %s <jscoverage-path> filepath outdir" 
    return 1
  
  jscoveragecmd = sys.argv[1]
  filepath = sys.argv[2]
  outdir = sys.argv[3]

  tmpdir = filepath + "_"
  copypath = os.path.join(tmpdir, os.path.basename(filepath))
  try:
    os.mkdir(tmpdir)
  except Exception:
    if not os.path.exists(tmpdir):
      raise
  with open(filepath, 'r') as f1:
    with open(copypath, 'w') as f2:
      f2.write(f1.read())
  status = subprocess.call([jscoveragecmd, tmpdir, outdir])
  os.remove(copypath)
  os.rmdir(tmpdir)
  return status

if __name__ == '__main__':
  sys.exit(main())
