#!/usr/bin/env python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# Script to build a Debian packages from a Dart tarball. The script
# will build a source package and a 32-bit (i386) and 64-bit (amd64)
# binary packages.

import optparse
import sys
import tarfile
import subprocess
import utils
from os.path import join, exists, abspath
from shutil import copyfile

HOST_OS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
DART_DIR = abspath(join(__file__, '..', '..'))

def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("--tar_filename",
                    default=None,
                    help="The tar file to build from.")
  result.add_option("--out_dir",
                    default=None,
                    help="Where to put the packages.")
  result.add_option("-a", "--arch",
      help='Target architectures (comma-separated).',
      metavar='[all,ia32,x64]',
      default='x64')

  return result

def RunBuildPackage(opt, cwd):
  cmd = ['dpkg-buildpackage', '-j%d' % HOST_CPUS]
  cmd.extend(opt)
  process = subprocess.Popen(cmd,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             cwd=cwd)
  (stdout, stderr) = process.communicate()
  if process.returncode != 0:
    raise Exception('Command \'%s\' failed: %s\nSTDOUT: %s' %
                    (' '.join(cmd), stderr, stdout))

def BuildDebianPackage(tarball, out_dir, arch):
  version = utils.GetVersion()
  tarroot = 'dart-%s' % version
  origtarname = 'dart_%s.orig.tar.gz' % version

  if not exists(tarball):
    print 'Source tarball not found'
    return -1

  with utils.TempDir() as temp_dir:
    origtarball = join(temp_dir, origtarname)
    copyfile(tarball, origtarball)

    with tarfile.open(origtarball) as tar:
      tar.extractall(path=temp_dir)

    # Build source package.
    print "Building source package"
    RunBuildPackage(['-S', '-us', '-uc'], join(temp_dir, tarroot))

    # Build 32-bit binary package.
    if 'ia32' in arch:
      print "Building i386 package"
      RunBuildPackage(['-B', '-ai386', '-us', '-uc'], join(temp_dir, tarroot))

    # Build 64-bit binary package.
    if 'x64' in arch:
      print "Building amd64 package"
      RunBuildPackage(['-B', '-aamd64', '-us', '-uc'], join(temp_dir, tarroot))

    # Copy the Debian package files to the build directory.
    debbase = 'dart_%s' % version
    source_package = [
      '%s-1.dsc' % debbase,
      '%s.orig.tar.gz' % debbase,
      '%s-1.debian.tar.gz' % debbase
    ]
    i386_package = [
      '%s-1_i386.deb' % debbase
    ]
    amd64_package = [
      '%s-1_amd64.deb' % debbase
    ]

    for name in source_package:
      copyfile(join(temp_dir, name), join(out_dir, name))
    if 'ia32' in arch:
      for name in i386_package:
        copyfile(join(temp_dir, name), join(out_dir, name))
    if 'x64' in arch:
      for name in amd64_package:
        copyfile(join(temp_dir, name), join(out_dir, name))

def Main():
  if HOST_OS != 'linux':
    print 'Debian build only supported on linux'
    return -1

  options, args = BuildOptions().parse_args()
  out_dir = options.out_dir
  tar_filename = options.tar_filename
  if options.arch == 'all':
    options.arch = 'ia32,x64'
  arch = options.arch.split(',')

  if not options.out_dir:
    out_dir = join(DART_DIR, utils.GetBuildDir(HOST_OS))

  if not tar_filename:
    tar_filename = join(DART_DIR,
                        utils.GetBuildDir(HOST_OS),
                        'dart-%s.tar.gz' % utils.GetVersion())

  BuildDebianPackage(tar_filename, out_dir, arch)

if __name__ == '__main__':
  sys.exit(Main())
