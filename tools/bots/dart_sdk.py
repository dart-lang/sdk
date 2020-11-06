#!/usr/bin/env python
#
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import os.path
import shutil
import sys
import subprocess

import bot_utils

utils = bot_utils.GetUtils()

BUILD_OS = utils.GuessOS()
BUILD_ARCHITECTURE = utils.GuessArchitecture()
BUILDER_NAME = os.environ.get('BUILDBOT_BUILDERNAME')
CHANNEL = bot_utils.GetChannelFromName(BUILDER_NAME)


def BuildArchitectures():
    if BUILD_OS == 'linux':
        return ['ia32', 'x64', 'arm', 'arm64']
    elif BUILD_OS == 'macos':
        return ['x64']
    else:
        return ['ia32', 'x64']


def BuildRootPath(path, arch=BUILD_ARCHITECTURE, build_mode='release'):
    return os.path.join(bot_utils.DART_DIR,
                        utils.GetBuildRoot(BUILD_OS, build_mode, arch), path)


def BuildDartdocAPIDocs(dirname):
    dart_sdk = BuildRootPath('dart-sdk')
    dart_exe = os.path.join(dart_sdk, 'bin', 'dart')
    dartdoc_dart = os.path.join(bot_utils.DART_DIR, 'third_party', 'pkg',
                                'dartdoc', 'bin', 'dartdoc.dart')
    footer_text_file = os.path.join(bot_utils.DART_DIR, 'tools', 'bots',
                                    'dartdoc_footer_text.html')
    footer_file = os.path.join(bot_utils.DART_DIR, 'tools', 'bots',
                               'dartdoc_footer.html')
    url = 'https://api.dartlang.org/stable'
    print('Build API docs by dartdoc')
    bot_utils.run([
        dart_exe, dartdoc_dart, '--sdk-docs', '--output', dirname,
        '--footer-text', footer_text_file, '--footer', footer_file,
        '--rel-canonical-prefix=' + url
    ])


def CreateUploadVersionFile():
    file_path = BuildRootPath('VERSION')
    with open(file_path, 'w') as fd:
        fd.write(utils.GetVersionFileContent())
    DartArchiveUploadVersionFile(file_path)


def DartArchiveUploadVersionFile(version_file):
    namer = bot_utils.GCSNamer(CHANNEL, bot_utils.ReleaseType.RAW)
    revision = utils.GetArchiveVersion()
    for revision in [revision, 'latest']:
        destination = namer.version_filepath(revision)
        DartArchiveFile(version_file, destination, checksum_files=False)


def CreateAndUploadSDKZip(arch, sdk_path):
    sdk_zip = BuildRootPath('dartsdk-%s-%s.zip' % (BUILD_OS, arch), arch=arch)
    FileDelete(sdk_zip)
    CreateZip(sdk_path, sdk_zip)
    DartArchiveUploadSDKs(BUILD_OS, arch, sdk_zip)



def DartArchiveUploadSDKs(system, arch, sdk_zip):
    namer = bot_utils.GCSNamer(CHANNEL, bot_utils.ReleaseType.RAW)
    git_number = utils.GetArchiveVersion()
    git_hash = 'hash/%s' % utils.GetGitRevision()
    for revision in [git_number, git_hash, 'latest']:
        path = namer.sdk_zipfilepath(revision, system, arch, 'release')
        DartArchiveFile(sdk_zip, path, checksum_files=True)


def DartArchiveUnstrippedBinaries():
    namer = bot_utils.GCSNamer(CHANNEL, bot_utils.ReleaseType.RAW)
    revision = utils.GetArchiveVersion()
    binary = namer.unstripped_filename(BUILD_OS)
    for arch in BuildArchitectures():
        binary = BuildRootPath(binary, arch=arch)
        gs_path = namer.unstripped_filepath(revision, BUILD_OS, arch)
        DartArchiveFile(binary, gs_path)


def CreateUploadAPIDocs():
    dartdoc_dir = BuildRootPath('gen-dartdocs')
    dartdoc_zip = BuildRootPath('dartdocs-api.zip')
    if CHANNEL == bot_utils.Channel.TRY:
        BuildDartdocAPIDocs(dartdoc_dir)
    else:
        UploadApiLatestFile()
        BuildDartdocAPIDocs(dartdoc_dir)
        UploadDartdocApiDocs(dartdoc_dir)
        CreateZip(dartdoc_dir, dartdoc_zip)
        DartArchiveUploadDartdocAPIDocs(dartdoc_zip)


def DartArchiveUploadDartdocAPIDocs(api_zip):
    namer = bot_utils.GCSNamer(CHANNEL, bot_utils.ReleaseType.RAW)
    revision = utils.GetArchiveVersion()
    for revision in [revision, 'latest']:
        destination = (namer.apidocs_directory(revision) + '/' +
                       namer.dartdocs_zipfilename())
        DartArchiveFile(api_zip, destination, checksum_files=False)


def UploadDartdocApiDocs(dir_name):
    apidocs_namer = bot_utils.GCSNamerApiDocs(CHANNEL)
    revision = utils.GetArchiveVersion()
    dartdocs_destination_gcsdir = apidocs_namer.dartdocs_dirpath(revision)

    # Return early if the documents have already been uploaded.
    # This can happen if a build was forced, or a commit had no changes in the
    # dart repository (e.g. DEPS file update).
    if GsutilExists(dartdocs_destination_gcsdir):
        print("Not uploading api docs, since %s is already present." %
              dartdocs_destination_gcsdir)
        return

    # Upload everything inside the built apidocs directory.
    gsutil = bot_utils.GSUtil()
    gsutil.upload(
        dir_name,
        dartdocs_destination_gcsdir,
        recursive=True,
        public=True,
        multithread=True)


def UploadApiLatestFile():
    apidocs_namer = bot_utils.GCSNamerApiDocs(CHANNEL)
    revision = utils.GetArchiveVersion()
    apidocs_destination_latestfile = apidocs_namer.docs_latestpath(revision)
    # Update latest.txt to contain the newest revision.
    with utils.TempDir('latest_file') as temp_dir:
        latest_file = os.path.join(temp_dir, 'latest.txt')
        with open(latest_file, 'w') as f:
            f.write('%s' % revision)
        DartArchiveFile(latest_file, apidocs_destination_latestfile)


def GsutilExists(gsu_path):
    # This is a little hackish, but it is basically a one off doing very
    # specialized check that we don't use elsewhere.
    gsutilTool = os.path.join(bot_utils.DART_DIR, 'third_party', 'gsutil',
                              'gsutil')
    (_, stderr, returncode) = bot_utils.run([gsutilTool, 'ls', gsu_path],
                                            throw_on_error=False)
    # If the returncode is nonzero and we can find a specific error message,
    # we know there are no objects with a prefix of [gsu_path].
    missing = (
        returncode and
        'CommandException: One or more URLs matched no objects.' in stderr)
    # Either the returncode has to be zero or the object must be missing,
    # otherwise throw an exception.
    if not missing and returncode:
        raise Exception("Failed to determine whether %s exists" % gsu_path)
    return not missing


def CreateZip(directory, target_file):
    if 'win' in BUILD_OS:
        CreateZipWindows(directory, target_file)
    else:
        CreateZipPosix(directory, target_file)


def CreateZipPosix(directory, target_file):
    with utils.ChangedWorkingDirectory(os.path.dirname(directory)):
        command = ['zip', '-yrq9', target_file, os.path.basename(directory)]
        Run(command)


def CreateZipWindows(directory, target_file):
    with utils.ChangedWorkingDirectory(os.path.dirname(directory)):
        zip_win = os.path.join(bot_utils.DART_DIR, 'third_party', '7zip', '7za')
        command = [
            zip_win, 'a', '-tzip', target_file,
            os.path.basename(directory)
        ]
        Run(command)


def FileDelete(f):
    if os.path.exists(f):
        os.remove(f)


def CopyBetween(src_path, dst_path, *relatives):
    try:
        os.makedirs(os.path.join(dst_path, *relatives[:-1]))
    except OSError:
        # This is fine.
        pass
    shutil.copy2(
        os.path.join(src_path, *relatives),
        os.path.join(dst_path, *relatives[:-1]))


def GuessExtension(binary):
    if 'win' in BUILD_OS:
        return binary + '.exe'
    return binary


def DartArchiveFile(local_path, remote_path, checksum_files=False):
    gsutil = bot_utils.GSUtil()
    gsutil.upload(local_path, remote_path, public=True)
    if checksum_files:
        # 'local_path' may have a different filename than 'remote_path'. So we need
        # to make sure the *.md5sum file contains the correct name.
        assert '/' in remote_path and not remote_path.endswith('/')

        mangled_filename = remote_path[remote_path.rfind('/') + 1:]
        local_md5sum = bot_utils.CreateMD5ChecksumFile(local_path,
                                                       mangled_filename)
        gsutil.upload(local_md5sum, remote_path + '.md5sum', public=True)
        local_sha256 = bot_utils.CreateSha256ChecksumFile(
            local_path, mangled_filename)
        gsutil.upload(local_sha256, remote_path + '.sha256sum', public=True)


def Run(command, env=None):
    print "Running %s" % ' '.join(command)
    print "Environment %s" % env
    sys.stdout.flush()
    exit_code = subprocess.call(command)
    if exit_code != 0:
        raise OSError(exit_code)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'api_docs':
        if BUILD_OS == 'linux':
            CreateUploadAPIDocs()
    elif CHANNEL != bot_utils.Channel.TRY:
        for arch in BuildArchitectures():
            sdk_path = BuildRootPath('dart-sdk', arch=arch)
            print('Create and upload sdk zip for ' + arch)
            CreateAndUploadSDKZip(arch, sdk_path)
        DartArchiveUnstrippedBinaries()
        if BUILD_OS == 'linux':
            CreateUploadVersionFile()
