#!/usr/bin/python

# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""
Buildbot steps for src tarball generation and debian package generation

Package up the src of the dart repo and create a debian package.
Archive tarball and debian package to google cloud storage.
"""

import os
import re
import subprocess
import sys

import bot_utils

utils = bot_utils.GetUtils()

HOST_OS = utils.GuessOS()

def InstallFromDep(builddir):
    for entry in os.listdir(builddir):
        if entry.endswith("_amd64.deb"):
            path = os.path.join(builddir, entry)
            Run(['dpkg', '-i', path])


def UninstallDart():
    Run(['dpkg', '-r', 'dart'])


def CreateDartTestFile(tempdir):
    filename = os.path.join(tempdir, 'test.dart')
    with open(filename, 'w') as f:
        f.write('import "dart:collection";\n\n')
        f.write('void main() {\n')
        f.write('  print("Hello world");\n')
        f.write('}')
    return filename


def Run(command):
    print "Running: %s" % ' '.join(command)
    sys.stdout.flush()
    no_color_env = dict(os.environ)
    no_color_env['TERM'] = 'nocolor'
    exit_code = subprocess.call(command, env=no_color_env)
    if exit_code != 0:
        raise OSError(exit_code)


def TestInstallation(assume_installed=True):
    paths = ['/usr/bin/dart']
    for tool in ['dart2js', 'pub', 'dart', 'dartanalyzer']:
        paths.append(os.path.join('/usr/lib/dart/bin', tool))
    for path in paths:
        if os.path.exists(path):
            if not assume_installed:
                print 'Assumed not installed, found %s' % path
                sys.exit(1)
        else:
            if assume_installed:
                print 'Assumed installed, but could not find %s' % path
                sys.exit(1)


def SrcSteps():
    version = utils.GetVersion()
    builddir = os.path.join(bot_utils.DART_DIR, utils.GetBuildDir(HOST_OS),
                            'src_and_installation')

    if not os.path.exists(builddir):
        os.makedirs(builddir)
    tarfilename = 'dart-%s.tar.gz' % version
    tarfile = os.path.join(builddir, tarfilename)

    print 'Validating that we are on debian jessie'
    args = ['cat', '/etc/os-release']
    (stdout, stderr, exitcode) = bot_utils.run(args)
    if exitcode != 0:
        print "Could not find linux system, exiting"
        sys.exit(1)
    if not "jessie" in stdout:
        print "Trying to build debian bits but not on debian Jessie"
        print "You can't fix this, please contact dart-engprod@"
        sys.exit(1)

    print 'Building src tarball'
    Run([
        sys.executable, './tools/create_tarball.py', '--tar_filename', tarfile
    ])

    print 'Building Debian packages'
    Run([
        sys.executable, './tools/create_debian_packages.py', '--tar_filename',
        tarfile, '--out_dir', builddir
    ])

    if os.path.exists('/usr/bin/dart') or os.path.exists(
            '/usr/lib/dart/bin/dart2js'):
        print "Dart already installed, removing"
        UninstallDart()
    TestInstallation(assume_installed=False)

    InstallFromDep(builddir)
    TestInstallation(assume_installed=True)

    # We build the runtime target to get everything we need to test the
    # standalone target.
    Run([sys.executable, './tools/build.py', '-mrelease', '-ax64', 'runtime'])
    # Copy in the installed binary to avoid poluting /usr/bin (and having to
    # run as root)
    Run(['cp', '/usr/bin/dart', 'out/ReleaseX64/dart'])

    # Sanity check dart2js and the analyzer against a hello world program
    with utils.TempDir() as temp_dir:
        test_file = CreateDartTestFile(temp_dir)
        Run(['/usr/lib/dart/bin/dart2js', test_file])
        Run(['/usr/lib/dart/bin/dartanalyzer', test_file])
        Run(['/usr/lib/dart/bin/dart', test_file])

    # Sanity check that pub can start up and print the version
    Run(['/usr/lib/dart/bin/pub', '--version'])

    UninstallDart()
    TestInstallation(assume_installed=False)


if __name__ == '__main__':
    SrcSteps()
