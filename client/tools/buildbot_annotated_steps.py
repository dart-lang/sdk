# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/python

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart client buildbot steps

Compiles dart client apps with dartc, and run the client tests both in headless
chromium and headless dartium.
"""

import os
import re
import socket
import subprocess
import sys
import shutil
import glob

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
REVISION = 'BUILDBOT_REVISION'

# latest dartium location
DARTIUM_VERSION_FILE = 'tests/dartium/BUILD_VERSION'
DARTIUM_V_MATCHER = 'gs://dashium-archive/latest/dashium-\w*-full-([0-9]*).zip'

# Patterns are of the form "dart_client-linux-ia32-debug"
BUILDER_PATTERN = r'dart_client-(\w+)-(\w+)-(\w+)'


def GetBuildInfo(srcpath):
  """Returns a tuple (name, version, arch, mode, platform) where:
    - name: A name for the build - the buildbot host if a buildbot.
    - version: A version string corresponding to this build.
    - arch: 'dartium' (default) or 'chromium'
    - mode: 'debug' or 'release' (default)
    - platform: 'linux' or 'mac'
  """
  name = None
  version = None
  mode = 'release'
  arch = 'dartium'
  platform = 'linux'

  # Populate via builder environment variables.
  name = os.environ.get(BUILDER_NAME)
  version = os.environ.get(REVISION)

  if name:
    pattern = re.match(BUILDER_PATTERN, name)
    if pattern:
      platform = pattern.group(1)
      arch = pattern.group(2)
      mode = pattern.group(3)

  # Fall back if not on builder.
  if not name:
    name = socket.gethostname().split('.')[0]
  if not version:
    os.chdir(srcpath)
    pipe = subprocess.Popen(
        ['svnversion', '-n'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output = pipe.communicate()
    if pipe.returncode == 0:
      version = output[0]
    else:
      version = 'unknown'
  return (name, version, arch, mode, platform)


def RunDartcCompiler(client_path, mode, outdir):
  """Compiles the client code to javascript for dartc tests."""
  # Move to the client directory and call the build script
  os.chdir(client_path)
  return subprocess.call(
      [sys.executable, '../tools/build.py', '--arch=dartc', '--mode=' + mode])

def RunBrowserTests(client_path, arch, mode, platform):
  """Runs the Dart client tests."""
  if platform == 'linux':
    cmd = ['xvfb-run']
  else:
    cmd = []
  # Move to the client directory and call the test script
  os.chdir(client_path)
  cmd += [sys.executable, '../tools/test.py',
     '--arch=' + arch, '--mode=' + mode,
     '--time', '--report', '--progress=buildbot', '-v']
  return subprocess.call(cmd)

def GetUtils(srcpath):
  '''
  dynamically get the utils module
  We use a dynamic import for tools/util.py because we derive its location
  dynamically using sys.argv[0]. This allows us to run this script from
  different directories.

  args:
  srcpath - the location of the source code to build
  '''
  sys.path.append(os.path.abspath(os.path.join(srcpath, '..', 'tools')))
  utils = __import__('utils')
  return utils

def GetOutDir(utils, mode, name):
  '''
  get the location to place the output

  args:
  utils - the tools/utils.py module
  mode - the mode release or debug
  name - the name of the builder
  '''
  return utils.GetBuildRoot(utils.GuessOS(), mode, name)

def ProcessDartClientTests(srcpath, arch, mode, platform, name):
  '''
  build and test the dart client applications

  args:
  srcpath - the location of the source code to build
  arch - the architecture we are building for
  mode - the mode release or debug
  platform - the platform we are building for
  '''
  print 'ProcessDartClientTests'
  if arch == 'chromium':
    print ('@@@BUILD_STEP dartc dart clients: %s@@@' % name)

    utils = GetUtils(srcpath)
    outdir = GetOutDir(utils, mode, "dartc")
    status = RunDartcCompiler(srcpath, mode, outdir)
    if status != 0:
      return status

  if arch == 'dartium':
    version_file = os.path.join(srcpath, DARTIUM_VERSION_FILE)
    if os.path.exists(version_file):
      latest = open(version_file, 'r').read()
      print '@@@BUILD_STEP dartium version: r%s@@@' % (
          re.match(DARTIUM_V_MATCHER, latest).group(1))
  print '@@@BUILD_STEP browser unit tests@@@'
  return RunBrowserTests(srcpath, arch, mode, platform)

def ProcessTools(srcpath, mode, name, version):
  '''
  build and test the tools

  args:
  srcpath - the locatio of the source code to build
  mode - the mode release or debug
  version - the svn version of the currently checked out code
  '''
  print 'ProcessTools'

  toolsBuildScript = os.path.join(srcpath, '..', 'editor', 'build', 'build.py')

  #TODO: debug statements to be removed in the future.
  print "srcpath = " + srcpath
  print "mode = " + mode
  print "name = " + name
  print "version = " + version
  print "toolsBuildScript = " + os.path.abspath(toolsBuildScript)

  utils = GetUtils(srcpath)
  outdir = GetOutDir(utils, mode, "tools")
  cmds = [sys.executable, toolsBuildScript,
          '--mode=' + mode, '--revision=' + version,
          '--name=' + name, '--out=' + outdir]
  return subprocess.call(cmds)

def main():
  print 'main'
  if len(sys.argv) == 0:
    print 'Script pathname not known, giving up.'
    return 1

  scriptdir = os.path.dirname(sys.argv[0])
  srcpath = os.path.abspath(os.path.join(scriptdir, '..'))

  (name, version, arch, mode, platform) = GetBuildInfo(srcpath)
  if name == 'dart-editor':
    status = ProcessTools(srcpath, mode, name, version)
  else:
    status = ProcessDartClientTests(srcpath, arch, mode, platform, name)

  if status:
    print '@@@STEP_FAILURE@@@'

  return status


if __name__ == '__main__':
  sys.exit(main())
