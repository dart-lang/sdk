#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a version string in a C++ file.

from __future__ import print_function

import argparse
import hashlib
import os
import sys
import time
import utils

# When these files change, snapshots created by the VM are potentially no longer
# backwards-compatible.
VM_SNAPSHOT_FILES = [
    # Header files.
    'clustered_snapshot.h',
    'datastream.h',
    'image_snapshot.h',
    'object.h',
    'raw_object.h',
    'snapshot.h',
    'snapshot_ids.h',
    'symbols.h',
    # Source files.
    'clustered_snapshot.cc',
    'dart.cc',
    'dart_api_impl.cc',
    'image_snapshot.cc',
    'object.cc',
    'raw_object.cc',
    'raw_object_snapshot.cc',
    'snapshot.cc',
    'symbols.cc',
]


def MakeSnapshotHashString():
    vmhash = hashlib.md5()
    for vmfilename in VM_SNAPSHOT_FILES:
        vmfilepath = os.path.join(utils.DART_DIR, 'runtime', 'vm', vmfilename)
        with open(vmfilepath, 'rb') as vmfile:
            vmhash.update(vmfile.read())
    return vmhash.hexdigest()


def GetSemanticVersionFormat(no_git_hash):
    version_format = '{{SEMANTIC_SDK_VERSION}}'
    return version_format


def FormatVersionString(version,
                        no_git_hash,
                        no_sdk_hash,
                        version_file=None,
                        git_revision_file=None):
    semantic_sdk_version = utils.GetSemanticSDKVersion(no_git_hash,
                                                       version_file,
                                                       git_revision_file)
    semantic_version_format = GetSemanticVersionFormat(no_git_hash)
    version_str = (semantic_sdk_version
                   if version_file else semantic_version_format)

    version = version.replace('{{VERSION_STR}}', version_str)

    version = version.replace('{{SEMANTIC_SDK_VERSION}}', semantic_sdk_version)

    git_hash = None
    # If we need SDK hash and git usage is not suppressed then try to get it.
    if not no_sdk_hash and not no_git_hash:
        git_hash = utils.GetShortGitHash()
    if git_hash is None or len(git_hash) != 10:
        git_hash = '0000000000'
    version = version.replace('{{GIT_HASH}}', git_hash)

    channel = utils.GetChannel()
    version = version.replace('{{CHANNEL}}', channel)

    version_time = None
    if not no_git_hash:
        version_time = utils.GetGitTimestamp()
    if version_time == None:
        version_time = 'Unknown timestamp'
    version = version.replace('{{COMMIT_TIME}}', version_time.decode('utf-8'))

    snapshot_hash = MakeSnapshotHashString()
    version = version.replace('{{SNAPSHOT_HASH}}', snapshot_hash)

    return version


def main():
    try:
        # Parse input.
        parser = argparse.ArgumentParser()
        parser.add_argument('--input', help='Input template file.')
        parser.add_argument(
            '--no_git_hash',
            action='store_true',
            default=False,
            help=('Don\'t try to call git to derive things like '
                  'git revision hash.'))
        parser.add_argument(
            '--no_sdk_hash',
            action='store_true',
            default=False,
            help='Use null SDK hash to disable SDK verification in the VM')
        parser.add_argument('--output', help='output file name')
        parser.add_argument('-q',
                            '--quiet',
                            action='store_true',
                            default=False,
                            help='DEPRECATED: Does nothing!')
        parser.add_argument('--version-file', help='Path to the VERSION file.')
        parser.add_argument('--git-revision-file',
                            help='Path to the GIT_REVISION file.')
        parser.add_argument(
            '--format',
            default='{{VERSION_STR}}',
            help='Version format used if no input template is given.')

        args = parser.parse_args()

        # If there is no input template, then write the bare version string to
        # args.output. If there is no args.output, then write the version
        # string to stdout.

        version_template = ''
        if args.input:
            version_template = open(args.input).read()
        elif not args.format is None:
            version_template = args.format
        else:
            raise 'No version template given! Set either --input or --format.'

        version = FormatVersionString(version_template, args.no_git_hash,
                                      args.no_sdk_hash, args.version_file,
                                      args.git_revision_file)

        if args.output:
            with open(args.output, 'w') as fh:
                fh.write(version)
        else:
            sys.stdout.write(version)

        return 0

    except Exception as inst:
        sys.stderr.write('make_version.py exception\n')
        sys.stderr.write(str(inst))
        sys.stderr.write('\n')

        return -1


if __name__ == '__main__':
    sys.exit(main())
