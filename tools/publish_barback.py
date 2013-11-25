#!/usr/bin/env python
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Script to push the barback package to pub. Barback is treated specially
# because it is tightly coupled to the SDK. Pub includes its own copy of
# barback but also includes code that is run against the user's copy of barback.
# To ensure that those are in sync, each version of the SDK has a single
# version of barback that it works with.
#
# We enforce this by placing a narrow SDK constraint in each version of barback.
# This ensures the only barback that will be selected is the one that works
# with the user's SDK. Once barback is more stable, we can loosen this.
#
# Usage: publish_barback.py
#
# "pub" must be in PATH.

import os
import os.path
import shutil
import sys
import subprocess
import tempfile

import utils

def Main(argv):
  HOME = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
  BARBACK = os.path.join(HOME, 'pkg', 'barback')

  (channel, major, minor, build, patch) = utils.ReadVersionFile()

  # The bleeding_edge branch has a fixed version number of 0.1.x.y. Don't allow
  # users to publish packages from there.
  if (major == 0 and minor <= 1) or channel == 'be':
    print 'Error: Do not run this script from a bleeding_edge checkout.'
    return -1

  # Convert the version to semver syntax.
  # TODO(rnystrom): Change this when the SDK's version numbering scheme is
  # decided.
  if patch != 0:
    version = '%d.%d.%d+%d' % (major, minor, build, patch)
  else:
    version = '%d.%d.%d' % (major, minor, build)

  # Copy the package to a temp directory so we can fill in the versions in its
  # pubspec.
  tmpDir = tempfile.mkdtemp()
  shutil.copytree(os.path.join(HOME, BARBACK), os.path.join(tmpDir, 'barback'))

  pubspecPath = os.path.join(tmpDir, 'barback', 'pubspec.yaml')
  with open(pubspecPath) as pubspecFile:
    pubspec = pubspecFile.read()

  # Fill in the SDK version constraint. It pins barback to the current version
  # of the SDK with a small amount of wiggle room for hotfixes.
  if major < 1:
    # No breaking changes until after 1.0.
    # TODO(rnystrom): Remove this once 1.0 has shipped.
    constraint = '>=%d.%d.%d <1.1.0' % (major, minor, build)
  else:
    constraint = '>=%d.%d.%d <%d.%d.0' % (major, minor, build, major, minor + 1)

  # Fill in the SDK version constraint.
  pubspec = pubspec.replace('$SDK_CONSTRAINT$', constraint)

  with open(pubspecPath, 'w') as pubspecFile:
    pubspecFile.write(pubspec)

  print ('Publishing barback %s with SDK constraint "%s".' %
      (version, constraint))
  subprocess.call(['pub', 'lish'], cwd=os.path.join(tmpDir, 'barback'))
  shutil.rmtree(tmpDir)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
