#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart client buildbot steps

Compiles dart client apps with dartc, and run the client tests both in headless
chromium and headless dartium.
"""

import imp
import os
import re
import socket
import subprocess
import sys

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
BUILDER_CLOBBER = 'BUILDBOT_CLOBBER'
REVISION = 'BUILDBOT_REVISION'

# latest dartium location
DARTIUM_VERSION_FILE = 'client/tests/drt/LAST_VERSION'
DARTIUM_V_MATCHER = (
    'gs://dartium-archive/[^/]*/dartium-\w*-inc-([0-9]*).([0-9]*).zip')

def GetUtils():
  '''Dynamically load the tools/utils.py python module.'''
  dart_dir = os.path.abspath(os.path.join(__file__, '..', '..', '..'))
  return imp.load_source('utils', os.path.join(dart_dir, 'tools', 'utils.py'))

utils = GetUtils()

def GetBuildInfo():
  """Returns a tuple (name, version, mode) where:
    - name: A name for the build - the buildbot host if a buildbot.
    - version: A version string corresponding to this build.
  """
  name = None
  version = None

  # Populate via builder environment variables.
  name = os.environ.get(BUILDER_NAME)
  version = os.environ.get(REVISION)

  # Fall back if not on builder.
  if not name:
    name = socket.gethostname().split('.')[0]
  if not version:
    # In Windows we need to run in the shell, so that we have all the
    # environment variables available.
    pipe = subprocess.Popen(
        ['svnversion', '-n'], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        shell=True)
    output = pipe.communicate()
    if pipe.returncode == 0:
      version = output[0]
    else:
      version = 'unknown'
  return (name, version)

def GetOutDir(mode):
  '''
  get the location to place the output

  args:
  utils - the tools/utils.py module
  mode - the mode release or debug
  '''
  return utils.GetBuildRoot(utils.GuessOS(), mode, utils.ARCH_GUESS)

def ProcessTools(mode, name, version):
  '''
  build and test the tools

  args:
  srcpath - the location of the source code to build
  mode - the mode release or debug
  version - the svn version of the currently checked out code
  '''
  print 'ProcessTools'

  toolsBuildScript = os.path.join('.', 'editor', 'build', 'build.py')

  build_installer = name.startswith('dart-editor-installer')

  # TODO(devoncarew): should we move this into GetBuildInfo()?
  # get the latest changed revision from the current repository sub-tree
  version = GetLatestChangedRevision()

  outdir = GetOutDir(mode)
  cmds = [sys.executable, toolsBuildScript,
          '--mode=' + mode, '--revision=' + version,
          '--name=' + name, '--out=' + outdir]
  if build_installer:
    cmds.append('--build-installer')
  local_env = EnvironmentWithoutBotoConfig()
  #if 'linux' in name:
  #  javahome = os.path.join(os.path.expanduser('~'), 'jdk1.6.0_25')
  #  local_env['JAVA_HOME'] = javahome
  #  local_env['PATH'] = (os.path.join(javahome, 'bin') +
  #                       os.pathsep + local_env['PATH'])

  return subprocess.call(cmds, env=local_env)

def EnvironmentWithoutBotoConfig(environment=None):
  # The buildbot sets AWS_CREDENTIAL_FILE/BOTO_CONFIG to the chromium specific
  # file, we use the one in home.
  custom_env = dict(environment or os.environ)
  if 'BOTO_CONFIG' in custom_env:
    del custom_env['BOTO_CONFIG']
  if 'AWS_CREDENTIAL_FILE' in custom_env:
    del custom_env['AWS_CREDENTIAL_FILE']
  return custom_env

def ProcessBot(name, target, custom_env=None):
  '''
  Build and test the named bot target (compiler, android, pub). We look for
  the supporting script in tools/bots/ to run the tests and build.
  '''
  print 'Process%s' % target.capitalize()
  has_shell = False
  environment = custom_env or os.environ
  if '-win' in name:
    # In Windows we need to run in the shell, so that we have all the
    # environment variables available.
    has_shell = True
  return subprocess.call([sys.executable,
      os.path.join('tools', 'bots', target + '.py')],
      env=environment, shell=has_shell)

def FixJavaHome():
  buildbot_javahome = os.getenv('BUILDBOT_JAVA_HOME')
  if buildbot_javahome:
    current_pwd = os.getenv('PWD')
    java_home = os.path.join(current_pwd, buildbot_javahome)
    java_bin = os.path.join(java_home, 'bin')
    os.environ['JAVA_HOME'] = java_home
    os.environ['PATH'] = '%s;%s' % (java_bin, os.environ['PATH'])

    print 'Setting java home to ', java_home
    sys.stdout.flush()

def ClobberBuilder():
  """ Clobber the builder before we do the build.
  """
  cmd = [sys.executable,
         './tools/clean_output_directory.py']
  print 'Clobbering %s' % (' '.join(cmd))
  return subprocess.call(cmd)

def GetShouldClobber():
  return os.environ.get(BUILDER_CLOBBER) == "1"

def GetLatestChangedRevision():
  revision = utils.GetSVNRevision()
  if not revision:
    raise Exception("Couldn't determine last changed revision.")
  return revision

def main():
  if len(sys.argv) == 0:
    print 'Script pathname not known, giving up.'
    return 1

  scriptdir = os.path.dirname(sys.argv[0])
  # Get at the top-level directory. This script is in client/tools
  os.chdir(os.path.abspath(os.path.join(scriptdir, os.pardir, os.pardir)))

  if GetShouldClobber():
    print '@@@BUILD_STEP Clobber@@@'
    status = ClobberBuilder()
    if status != 0:
      print '@@@STEP_FAILURE@@@'
      return status


  #TODO(sigmund): remove this indirection once we update our bots
  (name, version) = GetBuildInfo()
  # The buildbot will set a BUILDBOT_JAVA_HOME relative to the dart
  # root directory, set JAVA_HOME based on that.
  FixJavaHome()
  if name.startswith('dart-editor'):
    # Run the old annotated steps script
    status = ProcessTools('release', name, version)
  elif name.startswith('pub-'):
    status = ProcessBot(name, 'pub')
  elif name.startswith('vm-android'):
    status = ProcessBot(name, 'android')
  elif name.startswith('cross') or name.startswith('target'):
    status = ProcessBot(name, 'cross-vm',
                        custom_env=EnvironmentWithoutBotoConfig())
  elif name.startswith('linux-distribution-support'):
    status = ProcessBot(name, 'linux_distribution_support')
  elif name.startswith('ft'):
    status = ProcessBot(name, 'functional_testing')
  elif name.startswith('version-checker'):
    status = ProcessBot(name, 'version_checker')
  else:
    status = ProcessBot(name, 'compiler')

  if status:
    print '@@@STEP_FAILURE@@@'

  return status


if __name__ == '__main__':
  sys.exit(main())
