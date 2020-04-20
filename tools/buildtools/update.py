#!/usr/bin/env python
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Pulls down tools required to build Dart."""

import errno
import os
import platform
import subprocess
import sys

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
DART_ROOT = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
BUILDTOOLS = os.path.join(DART_ROOT, 'buildtools')
TOOLS_BUILDTOOLS = os.path.join(DART_ROOT, 'tools', 'buildtools')

sys.path.insert(0, os.path.join(DART_ROOT, 'tools'))
import find_depot_tools

DEPOT_PATH = find_depot_tools.add_depot_tools_to_path()


def UpdateClangFormatOnWindows():
    sha1_file = os.path.join(TOOLS_BUILDTOOLS, 'win', 'clang-format.exe.sha1')
    output_dir = os.path.join(BUILDTOOLS, 'win', 'clang-format.exe')
    downloader_script = os.path.join(DEPOT_PATH,
                                     'download_from_google_storage.py')
    download_cmd = [
        'python', downloader_script, '--no_auth', '--no_resume', '--quiet',
        '--platform=win', '--bucket', 'chromium-clang-format', '-s', sha1_file,
        '-o', output_dir
    ]
    return subprocess.call(download_cmd)


def CreateSymlink(symlink, link_name):
    try:
        os.symlink(symlink, link_name)
    except OSError, e:
        if e.errno == errno.EEXIST:
            os.remove(link_name)
            os.symlink(symlink, link_name)
        else:
            raise e


# On Mac and Linux we symlink clang-format and gn to the place where
# 'git cl format' expects them to be.
def LinksForGitCLFormat():
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

    clang_format = os.path.join(BUILDTOOLS, toolchain, 'clang', 'bin',
                                'clang-format')
    gn = os.path.join(BUILDTOOLS, 'gn')
    dest_dir = os.path.join(BUILDTOOLS, tools)
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    clang_format_dest = os.path.join(dest_dir, 'clang-format')
    gn_dest = os.path.join(dest_dir, 'gn')
    CreateSymlink(clang_format, clang_format_dest)
    CreateSymlink(gn, gn_dest)
    return 0


def main(argv):
    arch_id = platform.machine()
    # Don't try to download binaries if we're on an arm machine.
    if arch_id.startswith('arm') or arch_id.startswith('aarch64'):
        print('Not downloading buildtools binaries for ' + arch_id)
        return 0
    if sys.platform.startswith('win'):
        return UpdateClangFormatOnWindows()
    return LinksForGitCLFormat()


if __name__ == '__main__':
    sys.exit(main(sys.argv))
