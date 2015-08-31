#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart client buildbot steps

Calls a script in tools/bots whose name is based on the name of the bot.

"""

import imp
import os
import re
import socket
import subprocess
import sys

BUILDER_NAME = 'BUILDBOT_BUILDERNAME'
BUILDER_CLOBBER = 'BUILDBOT_CLOBBER'

def GetName():
  """Returns the name of the bot.
  """
  name = None
  # Populate via builder environment variables.
  name = os.environ.get(BUILDER_NAME)

  # Fall back if not on builder.
  if not name:
    name = socket.gethostname().split('.')[0]
  return name

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

def ClobberBuilder():
  """ Clobber the builder before we do the build.
  """
  cmd = [sys.executable,
         './tools/clean_output_directory.py']
  print 'Clobbering %s' % (' '.join(cmd))
  return subprocess.call(cmd)

def GetShouldClobber():
  return os.environ.get(BUILDER_CLOBBER) == "1"

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

  name = GetName()
  if name.startswith('pkg-'):
    status = ProcessBot(name, 'pkg')
  elif name.startswith('pub-'):
    status = ProcessBot(name, 'pub')
  elif name.startswith('vm-android'):
    status = ProcessBot(name, 'android')
  elif name.startswith('dart-sdk'):
    status = ProcessBot(name, 'dart_sdk')
  elif name.startswith('cross') or name.startswith('target'):
    status = ProcessBot(name, 'cross-vm')
  elif name.startswith('linux-distribution-support'):
    status = ProcessBot(name, 'linux_distribution_support')
  elif name.startswith('version-checker'):
    status = ProcessBot(name, 'version_checker')
  elif name.startswith('dart2js-dump-info'):
    status = ProcessBot(name, 'dart2js_dump_info')
  else:
    status = ProcessBot(name, 'compiler')

  if status:
    print '@@@STEP_FAILURE@@@'

  return status


if __name__ == '__main__':
  sys.exit(main())
