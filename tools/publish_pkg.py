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
  
  # bleeding_edge has a fixed version number of 0.1.x.y . Don't allow users
  # to publish packages from bleeding_edge.
  if major == 0 and minor <= 1:
    print 'Error: Do not run this script from a bleeding_edge checkout.'
    return -1

  if patch != 0:
    version = '%d.%d.%d+%d' % (major, minor, build, patch)
  else:
    version = '%d.%d.%d' % (major, minor, build)

  tmpDir = tempfile.mkdtemp()
  pkgName = argv[1].split('/').pop()

  pubspec = os.path.join(tmpDir, pkgName, 'pubspec.yaml')

  if os.path.exists(os.path.join(HOME, argv[1], 'pubspec.yaml')):
    #
    # If pubspec.yaml exists, add the SDK's version number if
    # no version number is present.
    #
    shutil.copytree(os.path.join(HOME, argv[1]), 
                    os.path.join(tmpDir, pkgName))
    with open(pubspec) as pubspecFile:
      lines = pubspecFile.readlines()
    with open(pubspec, 'w') as pubspecFile:
      foundVersion = False
      inDependencies = False
      for line in lines:
        if line.startswith('dependencies:'):
          inDependencies = True
        elif line[0].isalpha():
          inDependencies = False
        if line.startswith('version:'):
          foundVersion = True
        if inDependencies:
          #
          # Within dependencies, don't print line that start with "    sdk:"
          # and strip out "{ sdk: package_name }".
          #
          if not line.startswith('    sdk:'):
            line = re.sub(r'{(\s*)sdk:(\s+)([a-z0-9_]+)(\s*)}', '', line)
            pubspecFile.write(line)
        else:
          pubspecFile.write(line)
      if not foundVersion:
        pubspecFile.write('\nversion: ' + version + '\n')
  else:
    #
    # If there's a lib/ directory in the package, copy the package.
    # Otherwise, move the package's contents to lib/.
    #
    if os.path.exists(os.path.join(HOME, argv[1], 'lib')):
      shutil.copytree(os.path.join(HOME, argv[1]), 
                      os.path.join(tmpDir, pkgName))
    else:
      os.makedirs(os.path.join(tmpDir, pkgName))
      shutil.copytree(os.path.join(HOME, argv[1]),
                      os.path.join(tmpDir, pkgName, 'lib'))

    # Create pubspec.yaml .
    with open(pubspec, 'w') as pubspecFile:
      pubspecFile.write('name: ' + pkgName + '_unsupported\n')
      pubspecFile.write('version: ' + version + '\n')
      pubspecFile.write("description: >\n")
      pubspecFile.write('  A completely unsupported clone of Dart SDK library\n')
      pubspecFile.write('  ' + argv[1] + ' . This package will change in\n')
      pubspecFile.write('  unpredictable/incompatible ways without warning.\n')
      pubspecFile.write('dependencies:\n')

  # Replace '../*/pkg' imports and parts.
  for root, dirs, files in os.walk(os.path.join(tmpDir, pkgName)):
    for name in files:
      if name.endswith('.dart'):
        ReplaceInFiles([os.path.join(root, name)], 
            [(r'(import|part)(\s+)(\'|")(\.\./)+pkg/', r'\1\2\3package:')])
  
  print 'publishing version ' + version + ' of ' + argv[1] + ' to pub.\n'
  subprocess.call(['pub', 'publish'], cwd=os.path.join(tmpDir, pkgName))
  shutil.rmtree(tmpDir)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
