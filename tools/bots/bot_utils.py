#!/usr/bin/env python3
#
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import hashlib
import imp
import os
import subprocess
import sys

DART_DIR = os.path.abspath(
    os.path.normpath(os.path.join(__file__, '..', '..', '..')))


def GetUtils():
    '''Dynamically load the tools/utils.py python module.'''
    return imp.load_source('utils', os.path.join(DART_DIR, 'tools', 'utils.py'))


def run(command, env=None, shell=False, throw_on_error=True):
    print("Running command: ", command)

    p = subprocess.Popen(command,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         env=env,
                         shell=shell,
                         universal_newlines=True)
    (stdout, stderr) = p.communicate()
    if throw_on_error and p.returncode != 0:
        print("Failed to execute '%s'. Exit code: %s." %
              (command, p.returncode),
              file=sys.stderr)
        print("stdout: ", stdout, file=sys.stderr)
        print("stderr: ", stderr, file=sys.stderr)
        raise Exception("Failed to execute %s." % command)
    return (stdout, stderr, p.returncode)


class GSUtil(object):
    GSUTIL_PATH = None
    USE_DART_REPO_VERSION = False

    def _layzCalculateGSUtilPath(self):
        if not GSUtil.GSUTIL_PATH:
            dart_gsutil = os.path.join(DART_DIR, 'third_party', 'gsutil',
                                       'gsutil')
            if os.path.isfile(dart_gsutil):
                GSUtil.GSUTIL_PATH = dart_gsutil
            elif GSUtil.USE_DART_REPO_VERSION:
                raise Exception("Dart repository version of gsutil required, "
                                "but not found.")
            else:
                # We did not find gsutil, look in path
                possible_locations = list(os.environ['PATH'].split(os.pathsep))
                for directory in possible_locations:
                    location = os.path.join(directory, 'gsutil')
                    if os.path.isfile(location):
                        GSUtil.GSUTIL_PATH = location
                        break
            assert GSUtil.GSUTIL_PATH

    def execute(self, gsutil_args):
        self._layzCalculateGSUtilPath()

        gsutil_command = [sys.executable, GSUtil.GSUTIL_PATH]

        return run(gsutil_command + gsutil_args)

    def upload(self,
               local_path,
               remote_path,
               recursive=False,
               multithread=False):
        assert remote_path.startswith('gs://')

        if multithread:
            args = ['-m', 'cp']
        else:
            args = ['cp']
        if recursive:
            args += ['-R']
        args += [local_path, remote_path]
        self.execute(args)

    def cat(self, remote_path):
        assert remote_path.startswith('gs://')

        args = ['cat', remote_path]
        (stdout, _, _) = self.execute(args)
        return stdout

    def setGroupReadACL(self, remote_path, group):
        args = ['acl', 'ch', '-g', '%s:R' % group, remote_path]
        self.execute(args)

    def setContentType(self, remote_path, content_type):
        args = ['setmeta', '-h', 'Content-Type:%s' % content_type, remote_path]
        self.execute(args)

    def remove(self, remote_path, recursive=False):
        assert remote_path.startswith('gs://')

        args = ['rm']
        if recursive:
            args += ['-R']
        args += [remote_path]
        self.execute(args)
