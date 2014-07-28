#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Script to push a package to pub.
#
# Usage: publish_pkg.py pkg_dir
#
# "pub" must be in PATH.


import os
import os.path
import shutil
import sys
import subprocess
import tempfile

def Main(argv):
  HOME = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

  pkgName = os.path.basename(os.path.normpath(argv[1]))

  pubspec = os.path.join(HOME, argv[1], 'pubspec.yaml')
  if not os.path.exists(pubspec):
    print 'Error: did not find pubspec.yaml at ' + pubspec
    return -1

  with open(pubspec) as pubspecFile:
    lines = pubspecFile.readlines()

  version = None
  foundSdkConstraint = False
  inDependencies = False
  for line in lines:
    if line.startswith('dependencies:'):
      inDependencies = True
    elif line.startswith('environment:'):
      foundSdkConstraint = True
    elif line[0].isalpha():
      inDependencies = False
    if line.startswith('version:'):
      version = line[len('version:'):].strip()
    if inDependencies:
      if line.endswith(': any'):
        print 'Error in %s: should not use "any" version constraint: %s' % (
            pubspec, line)
        return -1

  if not version:
    print 'Error in %s: did not find package version.' % pubspec
    return -1

  if not foundSdkConstraint:
    print 'Error in %s: did not find SDK version constraint.' % pubspec
    return -1

  tmpDir = tempfile.mkdtemp()

  #
  # If pubspec.yaml exists, check that the SDK's version constraint is valid
  #
  shutil.copytree(os.path.join(HOME, argv[1]),
                  os.path.join(tmpDir, pkgName))

  if not os.path.exists(os.path.join(tmpDir, pkgName, 'LICENSE')):
    with open(os.path.join(tmpDir, pkgName, 'LICENSE'), 'w') as licenseFile:
      licenseFile.write(
'''Copyright 2014, the Dart project authors. All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
''')

  print 'publishing version ' + version + ' of ' + argv[1] + ' to pub.\n'

  # TODO(jmesserly): this code puts things in the pub cache. Useful for testing
  # without actually uploading.
  #cacheDir = os.path.join(
  #    os.path.expanduser('~/.pub-cache/hosted/pub.dartlang.org'),
  #    pkgName + '-' + version)
  #print 'Moving to ' + cacheDir
  #shutil.move(os.path.join(tmpDir, pkgName), cacheDir)

  subprocess.call(['pub', 'publish'], cwd=os.path.join(tmpDir, pkgName))
  shutil.rmtree(tmpDir)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
