#!/usr/bin/env python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# A script that copies a core file and binary to GCS
# We expect the dumps to be located in /tmp/coredump_PID directory
# After we copy out the core files we delete the dumps localy

import os
import shutil
import sys
import subprocess
import tarfile
import utils
import uuid

from glob import glob

GCS_FOLDER = 'dart-temp-crash-archive'
GSUTIL = '/b/build/scripts/slave/gsutil'


def CreateTarball(input_dir, tarname):
    print 'Creating tar file: %s' % tarname
    tar = tarfile.open(tarname, mode='w:gz')
    tar.add(input_dir)
    tar.close()


def CopyToGCS(filename):
    gs_location = 'gs://%s/%s/' % (GCS_FOLDER, uuid.uuid4())
    cmd = [GSUTIL, 'cp', filename, gs_location]
    print 'Running command: %s' % cmd
    subprocess.check_call(cmd)
    archived_filename = '%s%s' % (gs_location, filename.split('/').pop())
    print 'Dump now available in %s' % archived_filename


def TEMPArchiveBuild():
    if not 'PWD' in os.environ:
        return
    pwd = os.environ['PWD']
    print pwd
    if not 'vm-' in pwd:
        return
    if 'win' in pwd or 'release' in pwd:
        return
    files = glob('%s/out/Debug*/dart' % pwd)
    files.extend(glob('%s/xcodebuild/Debug*/dart' % pwd))
    print('Archiving: %s' % files)
    for f in files:
        CopyToGCS(f)


def Main():
    TEMPArchiveBuild()
    if utils.GuessOS() != 'linux':
        print 'Currently only archiving crash dumps on linux'
        return 0
    print 'Looking for crash dumps'
    num_dumps = 0
    for v in os.listdir('/tmp'):
        if v.startswith('coredump'):
            fullpath = '/tmp/%s' % v
            if os.path.isdir(fullpath):
                num_dumps += 1
                tarname = '%s.tar.gz' % fullpath
                CreateTarball(fullpath, tarname)
                CopyToGCS(tarname)
                os.unlink(tarname)
                shutil.rmtree(fullpath)
    print 'Found %s core dumps' % num_dumps


if __name__ == '__main__':
    sys.exit(Main())
