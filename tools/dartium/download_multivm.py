#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Download archived multivm or dartium builds.

  Usage: download_multivm.py revision target_directory
"""

import imp
import os
import platform
import shutil
import subprocess
import sys
import tempfile

# We are in [checkout dir]/src/dart/tools/dartium in a dartium/multivm checkout
TOOLS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.dirname(os.path.dirname(TOOLS_DIR))
GS_BUCKET = 'gs://dartium-archive'
if platform.system() == 'Windows':
  GSUTIL = 'e:\\b\\build\\scripts\\slave\\gsutil.bat'
  if not os.path.exists(GSUTIL):
    GSUTIL = 'c:\\b\\build\\scripts\\slave\\gsutil.bat'
else:
  GSUTIL = '/b/build/scripts/slave/gsutil'
if not os.path.exists(GSUTIL):
  GSUTIL = 'gsutil'

class TempDir(object):
  def __init__(self, prefix=''):
    self._temp_dir = None
    self._prefix = prefix

  def __enter__(self):
    self._temp_dir = tempfile.mkdtemp(self._prefix)
    return self._temp_dir

  def __exit__(self, *_):
    shutil.rmtree(self._temp_dir, ignore_errors=True)

def ExecuteCommand(cmd):
  print 'Executing: ' + ' '.join(cmd)
  subprocess.check_output(cmd)

def main():
  revision = sys.argv[1]
  target_dir = sys.argv[2]
  archive_dir = (os.environ['BUILDBOT_BUILDERNAME']
                   .replace('linux', 'lucid64')
                   .replace('multivm', 'multivm-dartium')
                   .replace('perf', 'build'))
  with TempDir() as temp_dir:
    archive_file = archive_dir + '-' + revision + '.zip'
    gs_source = '/'.join([GS_BUCKET, archive_dir, archive_file])
    zip_file = os.path.join(temp_dir, archive_file)
    ExecuteCommand([GSUTIL, 'cp', gs_source, zip_file])

    unzip_dir = zip_file.replace('.zip', '')
    if platform.system() == 'Windows':
      executable = os.path.join(SRC_DIR, 'third_party', 'lzma_sdk',
                                'Executable', '7za.exe')
      ExecuteCommand([executable, 'x', '-aoa', '-o' + temp_dir, zip_file])
    else:
      ExecuteCommand(['unzip', zip_file, '-d', temp_dir])

    if os.path.exists(target_dir):
      shutil.rmtree(target_dir)
    shutil.move(unzip_dir, target_dir)

if __name__ == '__main__':
  sys.exit(main())
