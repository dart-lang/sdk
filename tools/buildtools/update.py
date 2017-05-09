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
  return subprocess.call(['/bin/bash', path, '--toolchain', '--gn'], cwd=DART_ROOT)


def UpdateGNOnWindows():
  sha1_file = os.path.join(BUILDTOOLS, 'win', 'gn.exe.sha1')
  downloader_script = os.path.join(DEPOT_PATH, 'download_from_google_storage.py')
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
  downloader_script = os.path.join(DEPOT_PATH, 'download_from_google_storage.py')
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


def CopyClangFormatScripts():
  linux_script = os.path.join(TOOLS_BUILDTOOLS, 'linux64', 'clang-format')
  mac_script = os.path.join(TOOLS_BUILDTOOLS, 'mac', 'clang-format')
  linux_dest = os.path.join(BUILDTOOLS, 'linux64', 'clang-format')
  mac_dest = os.path.join(BUILDTOOLS, 'mac', 'clang-format')
  shutil.copy2(linux_script, linux_dest)
  shutil.copy2(mac_script, mac_dest)


def main(argv):
  if sys.platform.startswith('win'):
    result = UpdateGNOnWindows()
    if result != 0:
      return result
    return UpdateClangFormatOnWindows()
  CopyClangFormatScripts()
  return Update()


if __name__ == '__main__':
  sys.exit(main(sys.argv))
