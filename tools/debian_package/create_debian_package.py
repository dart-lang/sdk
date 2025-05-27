#!/usr/bin/env python3
#
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import os
import shutil
import subprocess
import sys
from os.path import join, split, abspath, dirname

sys.path.append(join(dirname(__file__), '..'))
import utils

DART_DIR = abspath(join(dirname(__file__), '..', '..'))


def BuildOptions():
    result = optparse.OptionParser()
    result.add_option("--version", default=None)
    result.add_option("--arch", default=None)
    result.add_option("--lib_dir", default=None)
    return result


def GenerateCopyright(filename):
    with open(join(DART_DIR, 'LICENSE')) as lf:
        license_lines = lf.readlines()

    with open(filename, 'w') as f:
        f.write('Name: dart\n')
        f.write('Maintainer: Dart Team <misc@dartlang.org>\n')
        f.write('Source: https://dart.googlesource.com/sdk\n')
        f.write('License:\n')
        for line in license_lines:
            f.write(' %s' % line)  # Line already contains trailing \n.


def GenerateChangeLog(filename, version):
    with open(filename, 'w') as f:
        f.write('dart (%s-1) UNRELEASED; urgency=low\n' % version)
        f.write('\n')
        f.write('  * Generated file.\n')
        f.write('\n')
        f.write(' -- Dart Team <misc@dartlang.org>\n')


def Main():
    parser = BuildOptions()
    (options, args) = parser.parse_args()

    version = options.version
    versiondir = 'dart-%s' % version
    shutil.copytree(join(DART_DIR, 'tools', 'debian_package', 'debian'),
                    join(versiondir, 'debian'),
                    dirs_exist_ok=True)
    GenerateCopyright(join(versiondir, 'debian', 'copyright'))
    GenerateChangeLog(join(versiondir, 'debian', 'changelog'), version)

    # Explicitly choose xz compression because newer versions dpkg-buildpackage
    # (on our bots) default to zstd, which is not supported by older versions
    # of dpkg (on users machines).
    cmd = ['dpkg-buildpackage', '-B', '-a', options.arch, '-us', '-uc', '-Zxz']
    env = os.environ.copy()
    env["LIB_DIR"] = options.lib_dir
    process = subprocess.check_call(cmd, cwd=versiondir, env=env)


if __name__ == '__main__':
    sys.exit(Main())
