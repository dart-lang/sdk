#!/usr/bin/python

# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os

import bot_utils

utils = bot_utils.GetUtils()

HOST_OS = utils.GuessOS()


def ArchiveArtifacts(tarfile, builddir, channel):
    namer = bot_utils.GCSNamer(channel=channel)
    gsutil = bot_utils.GSUtil()
    revision = utils.GetArchiveVersion()
    # Archive the src tar to the src dir
    remote_tarfile = '/'.join(
        [namer.src_directory(revision),
         os.path.basename(tarfile)])
    gsutil.upload(tarfile, remote_tarfile, public=True)
    # Archive all files except the tar file to the linux packages dir
    for entry in os.listdir(builddir):
        full_path = os.path.join(builddir, entry)
        # We expect a flat structure, not subdirectories
        assert (os.path.isfile(full_path))
        if full_path != tarfile:
            package_dir = namer.linux_packages_directory(revision)
            remote_file = '/'.join([package_dir, os.path.basename(entry)])
            gsutil.upload(full_path, remote_file, public=True)


if __name__ == '__main__':
    bot_name = os.environ.get('BUILDBOT_BUILDERNAME')
    channel = bot_utils.GetChannelFromName(bot_name)
    if channel != bot_utils.Channel.BLEEDING_EDGE:
        builddir = os.path.join(bot_utils.DART_DIR, utils.GetBuildDir(HOST_OS),
                                'src_and_installation')
        version = utils.GetVersion()
        tarfilename = 'dart-%s.tar.gz' % version
        tarfile = os.path.join(builddir, tarfilename)
        ArchiveArtifacts(tarfile, builddir, channel)
    else:
        print 'Not uploading artifacts on bleeding edge'
