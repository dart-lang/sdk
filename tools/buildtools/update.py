#!/usr/bin/env python
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Pulls down tools required to build Dart."""

import os
import subprocess
import shutil
import sys

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
DART_ROOT = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
BUILDTOOLS = os.path.join(DART_ROOT, 'buildtools')
TOOLS_BUILDTOOLS = os.path.join(DART_ROOT, 'tools', 'buildtools')

sys.path.insert(0, os.path.join(DART_ROOT, 'tools'))
import find_depot_tools

DEPOT_PATH = find_depot_tools.add_depot_tools_to_path()


def Update():
  path = os.path.join(BUILDTOOLS, 'update.sh')
  command = ['/bin/bash', path, '--clang', '--gn']
  return subprocess.call(command, cwd=DART_ROOT)


def UpdateGNOnWindows():
  sha1_file = os.path.join(BUILDTOOLS, 'win', 'gn.exe.sha1')
  downloader_script = os.path.join(
      DEPOT_PATH, 'download_from_google_storage.py')
  download_cmd = [
    'python',
    downloader_script,
    '--no_auth',
    '--no_resume',
    '--quiet',
    '--platform=win*',
    '--bucket',
    'chromium-gn',
    '-s',
    sha1_file
  ]
  return subprocess.call(download_cmd)


def UpdateClangFormatOnWindows():
  sha1_file = os.path.join(TOOLS_BUILDTOOLS, 'win', 'clang-format.exe.sha1')
  output_dir = os.path.join(BUILDTOOLS, 'win', 'clang-format.exe')
  downloader_script = os.path.join(
      DEPOT_PATH, 'download_from_google_storage.py')
  download_cmd = [
    'python',
    downloader_script,
    '--no_auth',
    '--no_resume',
    '--quiet',
    '--platform=win',
    '--bucket',
    'chromium-clang-format',
    '-s',
    sha1_file,
    '-o',
    output_dir
  ]
  return subprocess.call(download_cmd)


# On Mac and Linux we copy clang-format to the place where git cl format
# expects it to be.
def CopyClangFormat():
  if sys.platform == 'darwin':
    platform = 'darwin'
    tools = 'mac'
    toolchain = 'mac-x64'
  elif sys.platform.startswith('linux'):
    platform = 'linux'
    tools = 'linux64'
    toolchain = 'linux-x64'
  else:
    print 'Unknown platform: ' + sys.platform
    return 1

  clang_format = os.path.join(
      BUILDTOOLS, toolchain, 'clang', 'bin', 'clang-format')
  dest = os.path.join(BUILDTOOLS, tools, 'clang-format')
  shutil.copy2(clang_format, dest)
  return 0


def main(argv):
  if sys.platform.startswith('win'):
    result = UpdateGNOnWindows()
    if result != 0:
      return result
    return UpdateClangFormatOnWindows()
  if Update() != 0:
    return 1
  return CopyClangFormat()


if __name__ == '__main__':
  sys.exit(main(sys.argv))
