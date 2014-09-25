#!/usr/bin/env python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import re
import subprocess
import sys

def main():
  job = subprocess.Popen(['xcodebuild', '-version'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
  stdout, stderr = job.communicate()
  if job.returncode != 0:
    print >>sys.stderr, stdout
    print >>sys.stderr, stderr
    raise Exception('Error %d running xcodebuild!' % job.returncode)
  matches = re.findall('^Xcode (\d+)\.(\d+)(\.(\d+))?$', stdout, re.MULTILINE)
  if len(matches) > 0:
    major = int(matches[0][0])
    minor = int(matches[0][1])

    if major == 3 and minor >= 1:
      return '4.2'
    elif major == 4 and minor < 5:
      return 'com.apple.compilers.llvmgcc42'
    elif (major == 4 and minor >= 5) or major == 5 or major == 6:
      # XCode seems to select the specific clang version automatically
      return 'com.apple.compilers.llvm.clang.1_0'
    else:
      raise Exception('Unknown XCode Version "%s"' % stdout)
  else:
    raise Exception('Could not parse output of xcodebuild "%s"' % stdout)

if __name__ == '__main__':
  if sys.platform != 'darwin':
    #raise Exception("This script only runs on Mac")
    # If we aren't on Mac, print out a dummy version string; it won't be used.
    print 'X.X'
  else:
    print main()
