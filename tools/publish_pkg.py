#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Script to push a package to pub. 
#
# Usage: publish_pkg.py pkg_dir


import os
import os.path
import re
import shutil
import sys
import subprocess
import tempfile

def ReplaceInFiles(paths, subs):
  '''Reads a series of files, applies a series of substitutions to each, and
     saves them back out. subs should be a list of (pattern, replace) tuples.'''
  for path in paths:
    contents = open(path).read()
    for pattern, replace in subs:
      contents = re.sub(pattern, replace, contents)

    dest = open(path, 'w')
    dest.write(contents)
    dest.close()


def ReadVersion(file, field):
  for line in open(file).read().split('\n'):
    [k, v] = re.split('\s+', line)
    if field == k:
      return int(v)
  
def Main(argv):
  HOME = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

  versionFile = os.path.join(HOME, 'tools', 'VERSION')
  major = ReadVersion(versionFile, 'MAJOR')
  minor = ReadVersion(versionFile, 'MINOR')
  build = ReadVersion(versionFile, 'BUILD')
  patch = ReadVersion(versionFile, 'PATCH')
  
  if major == 0 and minor <= 1:
    print 'Error: Do not run this script from a bleeding_edge checkout.'
    return -1

  version = '%d.%d.%d+%d' % (major, minor, build, patch)

  tmpDir = tempfile.mkdtemp()
  pkgName = argv[1].split('/').pop()
  shutil.copytree(os.path.join(HOME, argv[1]), 
                  os.path.join(tmpDir, pkgName))

  # Add version to pubspec file.
  pubspec = os.path.join(tmpDir, pkgName, 'pubspec.yaml')
  pubspecFile = open(pubspec)
  lines = pubspecFile.readlines()
  pubspecFile.close()
  pubspecFile = open(pubspec, 'w')
  foundVersion = False
  for line in lines:
    if line.startswith('version:'):
      foundVersion = True
    if line.startswith('description:') and not foundVersion:
      pubspecFile.write('version: ' + version + '\n')
    if not line.startswith('    sdk:'):
      pubspecFile.write(line)
  pubspecFile.close()
      
  # Replace '../*/pkg' imports and parts.
  for root, dirs, files in os.walk(os.path.join(tmpDir, pkgName)):
    for name in files:
      if name.endswith('.dart'):
        ReplaceInFiles([os.path.join(root, name)], 
            [(r'(import|part)(\s+)(\'|")(\.\./)+pkg/', r'\1\2\3package:')])
  
  print 'publishing version ' + version + ' of ' + argv[1] + ' to pub\n'
  print tmpDir
  subprocess.call(['pub', 'publish'], cwd=os.path.join(tmpDir, pkgName))
  shutil.rmtree(tmpDir)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
