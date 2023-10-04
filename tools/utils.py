# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities functions used by other Python-based
# scripts.

from __future__ import print_function

import contextlib
import datetime
from functools import total_ordering
import glob
import imp
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import uuid

try:
    # Not available on Windows.
    import resource
except:
    pass

SEMANTIC_VERSION_PATTERN = r'^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'


# To eliminate clashing with older archived builds on bleeding edge we add
# a base number bigger the largest svn revision (this also gives us an easy
# way of seeing if an archive comes from git based or svn based commits).
GIT_NUMBER_BASE = 100000

# Mapping table between build mode and build configuration.
BUILD_MODES = {
    'debug': 'Debug',
    'release': 'Release',
    'product': 'Product',
}

# Mapping table between build mode and build configuration.
BUILD_SANITIZERS = {
    None: '',
    'none': '',
    'asan': 'ASAN',
    'lsan': 'LSAN',
    'msan': 'MSAN',
    'tsan': 'TSAN',
    'ubsan': 'UBSAN',
}

# Mapping table between OS and build output location.
BUILD_ROOT = {
    'win32': 'out',
    'linux': 'out',
    'freebsd': 'out',
    'macos': 'xcodebuild',
}

# Note: gn expects these to be lower case.
ARCH_FAMILY = {
    'ia32': 'ia32',
    'x64': 'ia32',
    'arm': 'arm',
    'arm64': 'arm',
    'arm_x64': 'arm',
    'arm_arm64': 'arm',
    'simarm': 'ia32',
    'simarm64': 'ia32',
    'simarm_x64': 'ia32',
    'simarm_arm64': 'arm',
    'x64c': 'ia32',
    'arm64c': 'arm',
    'simarm64c': 'ia32',
    'simriscv32': 'ia32',
    'simriscv64': 'ia32',
    'simx64': 'arm',
    'simx64c': 'arm',
    'riscv32': 'riscv',
    'riscv64': 'riscv',
}

BASE_DIR = os.path.abspath(os.path.join(os.curdir, '..'))
DART_DIR = os.path.abspath(os.path.join(__file__, '..', '..'))
VERSION_FILE = os.path.join(DART_DIR, 'tools', 'VERSION')


def GetArchFamily(arch):
    return ARCH_FAMILY[arch]


def GetBuildDir(host_os):
    return BUILD_ROOT[host_os]


def GetBuildMode(mode):
    return BUILD_MODES[mode]


def GetBuildSanitizer(sanitizer):
    return BUILD_SANITIZERS[sanitizer]


def GetBaseDir():
    return BASE_DIR


def GetBotUtils(repo_path=DART_DIR):
    '''Dynamically load the tools/bots/bot_utils.py python module.'''
    return imp.load_source(
        'bot_utils', os.path.join(repo_path, 'tools', 'bots', 'bot_utils.py'))


def GetMinidumpUtils(repo_path=DART_DIR):
    '''Dynamically load the tools/minidump.py python module.'''
    return imp.load_source('minidump',
                           os.path.join(repo_path, 'tools', 'minidump.py'))


@total_ordering
class Version(object):

    def __init__(self,
                 channel=None,
                 major=None,
                 minor=None,
                 patch=None,
                 prerelease=None,
                 prerelease_patch=None,
                 version=None):
        self.channel = channel
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.prerelease_patch = prerelease_patch
        if version:
            self.set_version(version)

    def set_version(self, version):
        match = re.match(SEMANTIC_VERSION_PATTERN, version)
        assert match, '%s must be a valid version' % version
        self.channel = 'stable'
        self.major = match['major']
        self.minor = match['minor']
        self.patch = match['patch']
        self.prerelease = '0'
        self.prerelease_patch = '0'
        if match['prerelease']:
            subversions = match['prerelease'].split('.')
            self.prerelease = subversions[0]
            self.prerelease_patch = subversions[1]
            self.channel = subversions[2]

    def __str__(self):
        result = '%s.%s.%s' % (self.major, self.minor, self.patch)
        if self.channel != 'stable':
            result += '-%s.%s.%s' % (self.prerelease, self.prerelease_patch,
                                     self.channel)
        return result

    def __eq__(self, other):
        return self.channel == other.channel and \
               self.major == other.major and \
               self.minor == other.minor and \
               self.patch == other.patch and \
               self.prerelease == other.prerelease and \
               self.prerelease_patch == other.prerelease_patch

    def __lt__(self, other):
        if int(self.major) < int(other.major):
            return True
        if int(self.major) > int(other.major):
            return False
        if int(self.minor) < int(other.minor):
            return True
        if int(self.minor) > int(other.minor):
            return False
        if int(self.patch) < int(other.patch):
            return True
        if int(self.patch) > int(other.patch):
            return False
        # The stable channel is ahead of the other channels on the same triplet.
        if self.channel != 'stable' and other.channel == 'stable':
            return True
        if self.channel == 'stable' and other.channel != 'stable':
            return False
        # The main channel is ahead of the other channels on the same triplet.
        if self.channel != 'main' and other.channel == 'main':
            return True
        if self.channel == 'main' and other.channel != 'main':
            return False
        # The be channel existed before it was renamed to main.
        if self.channel != 'be' and other.channel == 'be':
            return True
        if self.channel == 'be' and other.channel != 'be':
            return False
        if int(self.prerelease) < int(other.prerelease):
            return True
        if int(self.prerelease) > int(other.prerelease):
            return False
        if int(self.prerelease_patch) < int(other.prerelease_patch):
            return True
        if int(self.prerelease_patch) > int(other.prerelease_patch):
            return False
        return False


# Try to guess the host operating system.
def GuessOS():
    os_id = platform.system()
    if os_id == 'Linux':
        return 'linux'
    elif os_id == 'Darwin':
        return 'macos'
    elif os_id == 'Windows' or os_id == 'Microsoft':
        # On Windows Vista platform.system() can return 'Microsoft' with some
        # versions of Python, see http://bugs.python.org/issue1082 for details.
        return 'win32'
    elif os_id == 'FreeBSD':
        return 'freebsd'
    elif os_id == 'OpenBSD':
        return 'openbsd'
    elif os_id == 'SunOS':
        return 'solaris'

    return None


# Runs true if the currently executing python interpreter is running under
# Rosetta. I.e., python3 is an x64 executable and we're on an arm64 Mac.
def IsRosetta():
    if platform.system() == 'Darwin':
        p = subprocess.Popen(['sysctl', '-in', 'sysctl.proc_translated'],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
        output, _ = p.communicate()
        return output.decode('utf-8').strip() == '1'
    return False


# Returns the architectures that can run on the current machine.
def HostArchitectures():
    m = platform.machine()
    if platform.system() == 'Darwin':
        if m == 'arm64' or IsRosetta():
            # ARM64 Macs also support X64.
            return ['arm64', 'x64']
        if m == 'x86_64':
            # X64 Macs no longer support IA32.
            return ['x64']
    # Icky use of CIPD_ARCHITECTURE should be effectively dead whenever the
    # Python on bots becomes native ARM64.
    if ((platform.system() == 'Windows') and
        (os.environ.get("CIPD_ARCHITECTURE") == "arm64")):
        # ARM64 Windows also can emulate X64.
        return ['arm64', 'x64']

    if m in ['aarch64', 'arm64', 'arm64e', 'ARM64']:
        return ['arm64']
    if m in ['armv7l', 'armv8l']:
        return ['arm']
    if m in ['i386', 'i686', 'ia32', 'x86']:
        return ['x86', 'ia32']
    if m in ['x64', 'x86-64', 'x86_64', 'amd64', 'AMD64']:
        return ['x64', 'x86', 'ia32']
    raise Exception('Failed to determine host architectures for %s %s',
                    platform.machine(), platform.system())


# Try to guess the host architecture.
def GuessArchitecture():
    return HostArchitectures()[0]

# Try to guess the number of cpus on this machine.
def GuessCpus():
    if os.getenv('DART_NUMBER_OF_CORES') is not None:
        return int(os.getenv('DART_NUMBER_OF_CORES'))
    if os.path.exists('/proc/cpuinfo'):
        return int(
            subprocess.check_output(
                'grep -E \'^processor\' /proc/cpuinfo | wc -l', shell=True))
    if os.path.exists('/usr/bin/hostinfo'):
        return int(
            subprocess.check_output(
                '/usr/bin/hostinfo |'
                ' grep "processors are logically available." |'
                ' awk "{ print \$1 }"',
                shell=True))
    win_cpu_count = os.getenv("NUMBER_OF_PROCESSORS")
    if win_cpu_count:
        return int(win_cpu_count)
    return 2


# Returns true if we're running under Windows.
def IsWindows():
    return GuessOS() == 'win32'


def IsCrossBuild(target_os, arch):
    if (target_os not in [None, 'host']) and (target_os != GuessOS()):
        return True
    if arch.startswith('sim'):
        return False
    if arch.endswith('c'):
        # Strip 'compressed' suffix.
        arch = arch[:-1]
    if arch in HostArchitectures():
        return False
    return True


def GetBuildConf(mode, arch, conf_os=None, sanitizer=None):
    if conf_os is not None and conf_os != GuessOS() and conf_os != 'host':
        return '{}{}{}'.format(GetBuildMode(mode), conf_os.title(),
                               arch.upper())

    # Ask for a cross build if the host and target architectures don't match.
    cross_build = ''
    if IsCrossBuild(conf_os, arch):
        cross_build = 'X'
    return '{}{}{}{}'.format(GetBuildMode(mode), GetBuildSanitizer(sanitizer),
                             cross_build, arch.upper())


def GetBuildRoot(host_os, mode=None, arch=None, target_os=None, sanitizer=None):
    build_root = GetBuildDir(host_os)
    if mode:
        build_root = os.path.join(
            build_root, GetBuildConf(mode, arch, target_os, sanitizer))
    return build_root


def GetVersion(no_git_hash=False, version_file=None, git_revision_file=None):
    version = ReadVersionFile(version_file)
    if not version:
        return None

    suffix = ''
    if version.channel in ['main', 'be']:
        suffix = '-edge' if no_git_hash else '-edge.{}'.format(
            GetGitRevision(git_revision_file))
    elif version.channel in ('beta', 'dev'):
        suffix = '-{}.{}.{}'.format(version.prerelease,
                                    version.prerelease_patch, version.channel)
    else:
        assert version.channel == 'stable'

    return '{}.{}.{}{}'.format(version.major, version.minor, version.patch,
                               suffix)


def GetChannel(version_file=None):
    version = ReadVersionFile(version_file)
    return version.channel


def ReadVersionFile(version_file=None):

    def match_against(pattern, file_content):
        match = re.search(pattern, file_content, flags=re.MULTILINE)
        if match:
            return match.group(1)
        return None

    if version_file == None:
        version_file = VERSION_FILE

    content = None
    try:
        with open(version_file) as fd:
            content = fd.read()
    except:
        print('Warning: Could not read VERSION file ({})'.format(version_file))
        return None

    channel = match_against('^CHANNEL ([A-Za-z0-9]+)$', content)
    major = match_against('^MAJOR (\d+)$', content)
    minor = match_against('^MINOR (\d+)$', content)
    patch = match_against('^PATCH (\d+)$', content)
    prerelease = match_against('^PRERELEASE (\d+)$', content)
    prerelease_patch = match_against('^PRERELEASE_PATCH (\d+)$', content)

    if (channel and major and minor and prerelease and prerelease_patch):
        return Version(channel, major, minor, patch, prerelease,
                       prerelease_patch)

    print('Warning: VERSION file ({}) has wrong format'.format(version_file))
    return None


def GetGitRevision(git_revision_file=None, repo_path=DART_DIR):
    # When building from tarball use tools/GIT_REVISION
    if git_revision_file is None:
        git_revision_file = os.path.join(repo_path, 'tools', 'GIT_REVISION')
    try:
        with open(git_revision_file) as fd:
            return fd.read().strip()
    except:
        pass
    p = subprocess.Popen(['git', 'rev-parse', 'HEAD'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=IsWindows(),
                         cwd=repo_path)
    out, err = p.communicate()
    # TODO(https://github.com/dart-lang/sdk/issues/51865): Don't ignore errors.
    # if p.wait() != 0:
    #    raise Exception('git rev-parse failed: ' + str(err))
    revision = out.decode('utf-8').strip()
    # We expect a full git hash
    if len(revision) != 40:
        print('Warning: Could not parse git commit, output was {}'.format(
            revision),
              file=sys.stderr)
        return None
    return revision


def GetShortGitHash(repo_path=DART_DIR):
    p = subprocess.Popen(['git', 'rev-parse', '--short=10', 'HEAD'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=IsWindows(),
                         cwd=repo_path)
    out, err = p.communicate()
    if p.wait() != 0:
        # TODO(https://github.com/dart-lang/sdk/issues/51865): Don't ignore errors.
        # raise Exception('git rev-parse failed: ' + str(err))
        return None
    revision = out.decode('utf-8').strip()
    return revision


def GetGitTimestamp(git_timestamp_file=None, repo_path=DART_DIR):
    # When building from tarball use tools/GIT_TIMESTAMP
    if git_timestamp_file is None:
        git_timestamp_file = os.path.join(repo_path, 'tools', 'GIT_TIMESTAMP')
    try:
        with open(git_timestamp_file) as fd:
            return fd.read().strip()
    except:
        pass
    p = subprocess.Popen(['git', 'log', '-n', '1', '--pretty=format:%cd'],
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE,
                         shell=IsWindows(),
                         cwd=repo_path)
    out, err = p.communicate()
    if p.wait() != 0:
        # TODO(https://github.com/dart-lang/sdk/issues/51865): Don't ignore errors.
        # raise Exception('git log failed: ' + str(err))
        return None
    timestamp = out.decode('utf-8').strip()
    return timestamp


# TODO(42528): Can we remove this? It's basically just an alias for Exception.
class Error(Exception):
    pass


def IsCrashExitCode(exit_code):
    if IsWindows():
        return 0x80000000 & exit_code
    return exit_code < 0


def DiagnoseExitCode(exit_code, command):
    if IsCrashExitCode(exit_code):
        sys.stderr.write(
            'Command: {}\nCRASHED with exit code {} (0x{:x})\n'.format(
                ' '.join(command), exit_code, exit_code & 0xffffffff))


def CheckedInSdkPath():
    tools_dir = os.path.dirname(os.path.realpath(__file__))
    return os.path.join(tools_dir, 'sdks', 'dart-sdk')


def CheckedInSdkExecutable():
    name = 'dart'
    if IsWindows():
        name = 'dart.exe'
    return os.path.join(CheckedInSdkPath(), 'bin', name)


def CheckLinuxCoreDumpPattern(fatal=False):
    core_pattern_file = '/proc/sys/kernel/core_pattern'
    core_pattern = open(core_pattern_file).read()

    expected_core_pattern = 'core.%p'
    if core_pattern.strip() != expected_core_pattern:
        message = (
            'Invalid core_pattern configuration. '
            'The configuration of core dump handling is *not* correct for '
            'a buildbot. The content of {0} must be "{1}" instead of "{2}".'.
            format(core_pattern_file, expected_core_pattern, core_pattern))
        if fatal:
            raise Exception(message)
        print(message)
        return False
    return True


class TempDir(object):

    def __init__(self, prefix=''):
        self._temp_dir = None
        self._prefix = prefix

    def __enter__(self):
        self._temp_dir = tempfile.mkdtemp(self._prefix)
        return self._temp_dir

    def __exit__(self, *_):
        shutil.rmtree(self._temp_dir, ignore_errors=True)


class UnexpectedCrash(object):

    def __init__(self, test, pid, *binaries):
        self.test = test
        self.pid = pid
        self.binaries = binaries

    def __str__(self):
        return 'Crash({}: {} {})'.format(self.test, self.pid,
                                         ', '.join(self.binaries))


class PosixCoreDumpEnabler(object):

    def __init__(self):
        self._old_limits = None

    def __enter__(self):
        self._old_limits = resource.getrlimit(resource.RLIMIT_CORE)
        resource.setrlimit(resource.RLIMIT_CORE, (-1, -1))

    def __exit__(self, *_):
        if self._old_limits != None:
            resource.setrlimit(resource.RLIMIT_CORE, self._old_limits)


class LinuxCoreDumpEnabler(PosixCoreDumpEnabler):

    def __enter__(self):
        # Bump core limits to unlimited if core_pattern is correctly configured.
        if CheckLinuxCoreDumpPattern(fatal=False):
            super(LinuxCoreDumpEnabler, self).__enter__()

    def __exit__(self, *args):
        CheckLinuxCoreDumpPattern(fatal=False)
        super(LinuxCoreDumpEnabler, self).__exit__(*args)


class WindowsCoreDumpEnabler(object):
    """This enabler assumes that Dart binary was built with Crashpad support.
    In this case DART_CRASHPAD_CRASHES_DIR environment variable allows to
    specify the location of Crashpad crashes database. Actual minidumps will
    be written into reports subfolder of the database.
    """
    CRASHPAD_DB_FOLDER = os.path.join(DART_DIR, 'crashes')
    DUMPS_FOLDER = os.path.join(CRASHPAD_DB_FOLDER, 'reports')

    def __init__(self):
        pass

    def __enter__(self):
        print('INFO: Enabling coredump archiving into {}'.format(
            WindowsCoreDumpEnabler.CRASHPAD_DB_FOLDER))
        os.environ[
            'DART_CRASHPAD_CRASHES_DIR'] = WindowsCoreDumpEnabler.CRASHPAD_DB_FOLDER

    def __exit__(self, *_):
        del os.environ['DART_CRASHPAD_CRASHES_DIR']


def TryUnlink(file):
    try:
        os.unlink(file)
    except Exception as error:
        print('ERROR: Failed to remove {}: {}'.format(file, error))


class BaseCoreDumpArchiver(object):
    """This class reads coredumps file written by UnexpectedCrashDumpArchiver
    into the current working directory and uploads all cores and binaries
    listed in it into Cloud Storage (see
    pkg/test_runner/lib/src/test_progress.dart).
    """

    # test.dart will write a line for each unexpected crash into this file.
    _UNEXPECTED_CRASHES_FILE = 'unexpected-crashes'

    def __init__(self, search_dir, output_directory):
        self._bucket = 'dart-temp-crash-archive'
        self._binaries_dir = os.getcwd()
        self._search_dir = search_dir
        self._output_directory = output_directory

    def _safe_cleanup(self):
        try:
            return self._cleanup()
        except Exception as error:
            print('ERROR: Failure during cleanup: {}'.format(error))
            return False

    def __enter__(self):
        print('INFO: Core dump archiving is activated')

        # Cleanup any stale files
        if self._safe_cleanup():
            print('WARNING: Found and removed stale coredumps')

    def __exit__(self, *_):
        try:
            crashes = self._find_unexpected_crashes()
            if crashes:
                # If we get a ton of crashes, only archive 10 dumps.
                archive_crashes = crashes[:10]
                print('Archiving coredumps for crash (if possible):')
                for crash in archive_crashes:
                    print('----> {}'.format(crash))

                sys.stdout.flush()

                self._archive(archive_crashes)
            else:
                print('INFO: No unexpected crashes recorded')
                dumps = self._find_all_coredumps()
                if dumps:
                    print('INFO: However there are {} core dumps found'.format(
                        len(dumps)))
                    for dump in dumps:
                        print('INFO:        -> {}'.format(dump))
                    print()
        except Exception as error:
            print('ERROR: Failed to archive crashes: {}'.format(error))
            raise

        finally:
            self._safe_cleanup()

    def _archive(self, crashes):
        files = set()
        missing = []
        for crash in crashes:
            files.update(crash.binaries)
            core = self._find_coredump_file(crash)
            if core:
                files.add(core)
            else:
                missing.append(crash)
        if self._output_directory is not None and self._is_shard():
            print(
                "INFO: Moving collected dumps and binaries into output directory\n"
                "INFO: They will be uploaded to isolate server. Look for \"isolated"
                " out\" under the failed step on the build page.\n"
                "INFO: For more information see runtime/docs/infra/coredumps.md"
            )
            self._move(files)
        else:
            print(
                "INFO: Uploading collected dumps and binaries into Cloud Storage\n"
                "INFO: Use `gsutil.py cp from-url to-path` to download them.\n"
                "INFO: For more information see runtime/docs/infra/coredumps.md"
            )
            self._upload(files)

        if missing:
            self._report_missing_crashes(missing, throw=False)

    # todo(athom): move the logic to decide where to copy core dumps into the recipes.
    def _is_shard(self):
        return 'BUILDBOT_BUILDERNAME' not in os.environ

    def _report_missing_crashes(self, missing, throw=False):
        missing_as_string = ', '.join([str(c) for c in missing])
        other_files = list(glob.glob(os.path.join(self._search_dir, '*')))
        sys.stderr.write(
            "Could not find crash dumps for '{}' in search directory '{}'.\n"
            "Existing files which *did not* match the pattern inside the search "
            "directory are are:\n  {}\n".format(missing_as_string,
                                                self._search_dir,
                                                '\n  '.join(other_files)))
        # TODO: Figure out why windows coredump generation does not work.
        # See http://dartbug.com/36469
        if throw and GuessOS() != 'win32':
            raise Exception(
                'Missing crash dumps for: {}'.format(missing_as_string))

    def _get_file_name(self, file):
        # Sanitize the name: actual cores follow 'core.%d' pattern, crashed
        # binaries are copied next to cores and named
        # 'binary.<mode>_<arch>_<binary_name>'.
        # This should match the code in testing/dart/test_progress.dart
        name = os.path.basename(file)
        (prefix, suffix) = name.split('.', 1)
        is_binary = prefix == 'binary'
        if is_binary:
            (mode, arch, binary_name) = suffix.split('_', 2)
            name = binary_name
        return (name, is_binary)

    def _move(self, files):
        for file in files:
            print('+++ Moving {} to output_directory ({})'.format(
                file, self._output_directory))
            (name, is_binary) = self._get_file_name(file)
            destination = os.path.join(self._output_directory, name)
            shutil.move(file, destination)
            if is_binary and os.path.exists(file + '.pdb'):
                # Also move a PDB file if there is one.
                pdb = os.path.join(self._output_directory, name + '.pdb')
                shutil.move(file + '.pdb', pdb)

    def _tar(self, file):
        (name, is_binary) = self._get_file_name(file)
        tarname = '{}.tar.gz'.format(name)

        # Compress the file.
        tar = tarfile.open(tarname, mode='w:gz')
        tar.add(file, arcname=name)
        if is_binary and os.path.exists(file + '.pdb'):
            # Also add a PDB file if there is one.
            tar.add(file + '.pdb', arcname=name + '.pdb')
        tar.close()
        return tarname

    def _upload(self, files):
        bot_utils = GetBotUtils()
        gsutil = bot_utils.GSUtil()
        storage_path = '{}/{}/'.format(self._bucket, uuid.uuid4())
        gs_prefix = 'gs://{}'.format(storage_path)
        http_prefix = 'https://storage.cloud.google.com/{}'.format(storage_path)

        print('\n--- Uploading into {} ({}) ---'.format(gs_prefix, http_prefix))
        for file in files:
            tarname = self._tar(file)

            # Remove / from absolute path to not have // in gs path.
            gs_url = '{}{}'.format(gs_prefix, tarname)
            http_url = '{}{}'.format(http_prefix, tarname)

            try:
                gsutil.upload(tarname, gs_url)
                print('+++ Uploaded {} ({})'.format(gs_url, http_url))
            except Exception as error:
                print('!!! Failed to upload {}, error: {}'.format(
                    tarname, error))

            TryUnlink(tarname)

        print('--- Done ---\n')

    def _find_all_coredumps(self):
        """Return coredumps that were recorded (if supported by the platform).
        This method will be overridden by concrete platform specific implementations.
        """
        return []

    def _find_unexpected_crashes(self):
        """Load coredumps file. Each line has the following format:

        test-name,pid,binary-file1,binary-file2,...
        """
        try:
            with open(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE) as f:
                return [
                    UnexpectedCrash(*ln.strip('\n').split(','))
                    for ln in f.readlines()
                ]
        except:
            return []

    def _cleanup(self):
        found = False
        if os.path.exists(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE):
            os.unlink(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE)
            found = True
        for binary in glob.glob(os.path.join(self._binaries_dir, 'binary.*')):
            found = True
            TryUnlink(binary)

        return found


class PosixCoreDumpArchiver(BaseCoreDumpArchiver):

    def __init__(self, search_dir, output_directory):
        super(PosixCoreDumpArchiver, self).__init__(search_dir,
                                                    output_directory)

    def _cleanup(self):
        found = super(PosixCoreDumpArchiver, self)._cleanup()
        for core in glob.glob(os.path.join(self._search_dir, 'core.*')):
            found = True
            TryUnlink(core)
        return found

    def _find_coredump_file(self, crash):
        core_filename = os.path.join(self._search_dir,
                                     'core.{}'.format(crash.pid))
        if os.path.exists(core_filename):
            return core_filename


class LinuxCoreDumpArchiver(PosixCoreDumpArchiver):

    def __init__(self, output_directory):
        super(LinuxCoreDumpArchiver, self).__init__(os.getcwd(),
                                                    output_directory)


class MacOSCoreDumpArchiver(PosixCoreDumpArchiver):

    def __init__(self, output_directory):
        super(MacOSCoreDumpArchiver, self).__init__('/cores', output_directory)


class WindowsCoreDumpArchiver(BaseCoreDumpArchiver):

    def __init__(self, output_directory):
        super(WindowsCoreDumpArchiver, self).__init__(
            WindowsCoreDumpEnabler.DUMPS_FOLDER, output_directory)
        self._dumps_by_pid = None

    # Find CDB.exe in the win_toolchain that we are using.
    def _find_cdb(self):
        win_toolchain_json_path = os.path.join(DART_DIR, 'build',
                                               'win_toolchain.json')
        if not os.path.exists(win_toolchain_json_path):
            return None

        with open(win_toolchain_json_path, 'r') as f:
            win_toolchain_info = json.loads(f.read())

        win_sdk_path = win_toolchain_info['win_sdk']

        # We assume that we are running on 64-bit Windows.
        # Note: x64 CDB can work with both X64 and IA32 dumps.
        cdb_path = os.path.join(win_sdk_path, 'Debuggers', 'x64', 'cdb.exe')
        if not os.path.exists(cdb_path):
            return None

        return cdb_path

    CDBG_PROMPT_RE = re.compile(r'^\d+:\d+>')

    def _dump_all_stacks(self):
        # On Windows due to crashpad integration crashes do not produce any
        # stacktraces. Dump stack traces from dumps Crashpad collected using
        # CDB (if available).
        cdb_path = self._find_cdb()
        if cdb_path is None:
            return

        dumps = self._find_all_coredumps()
        if not dumps:
            return

        print('### Collected {} crash dumps'.format(len(dumps)))
        for dump in dumps:
            print()
            print('### Dumping stacks from {} using CDB'.format(dump))
            cdb_output = subprocess.check_output(
                '"{}" -z "{}" -kqm -c "!uniqstack -b -v -p;qd"'.format(
                    cdb_path, dump),
                stderr=subprocess.STDOUT)
            # Extract output of uniqstack from the whole output of CDB.
            output = False
            for line in cdb_output.split('\n'):
                if re.match(WindowsCoreDumpArchiver.CDBG_PROMPT_RE, line):
                    output = True
                elif line.startswith('quit:'):
                    break
                elif output:
                    print(line)
        print()
        print('#############################################')
        print()

    def __exit__(self, *args):
        try:
            self._dump_all_stacks()
        except Exception as error:
            print('ERROR: Unable to dump stacks from dumps: {}'.format(error))

        super(WindowsCoreDumpArchiver, self).__exit__(*args)

    def _cleanup(self):
        found = super(WindowsCoreDumpArchiver, self)._cleanup()
        for core in glob.glob(os.path.join(self._search_dir, '*')):
            found = True
            TryUnlink(core)
        return found

    def _find_all_coredumps(self):
        pattern = os.path.join(self._search_dir, '*.dmp')
        return [core_filename for core_filename in glob.glob(pattern)]

    def _find_coredump_file(self, crash):
        if self._dumps_by_pid is None:
            # If this function is invoked the first time then look through the directory
            # that contains crashes for all dump files and collect pid -> filename
            # mapping.
            self._dumps_by_pid = {}
            minidump = GetMinidumpUtils()
            pattern = os.path.join(self._search_dir, '*.dmp')
            for core_filename in glob.glob(pattern):
                pid = minidump.GetProcessIdFromDump(core_filename)
                if pid != -1:
                    self._dumps_by_pid[str(pid)] = core_filename
        if crash.pid in self._dumps_by_pid:
            return self._dumps_by_pid[crash.pid]

    def _report_missing_crashes(self, missing, throw=False):
        # Let's only print the debugging information and not throw. We'll do more
        # validation for werfault.exe and throw afterwards.
        super(WindowsCoreDumpArchiver, self)._report_missing_crashes(
            missing, throw=False)

        if throw:
            missing_as_string = ', '.join([str(c) for c in missing])
            raise Exception(
                'Missing crash dumps for: {}'.format(missing_as_string))


class IncreasedNumberOfFileDescriptors(object):

    def __init__(self, nofiles):
        self._old_limits = None
        self._limits = (nofiles, nofiles)

    def __enter__(self):
        self._old_limits = resource.getrlimit(resource.RLIMIT_NOFILE)
        resource.setrlimit(resource.RLIMIT_NOFILE, self._limits)

    def __exit__(self, *_):
        resource.setrlimit(resource.RLIMIT_CORE, self._old_limits)


@contextlib.contextmanager
def NooptContextManager():
    yield


def CoreDumpArchiver(args):
    enabled = '--copy-coredumps' in args
    prefix = '--output-directory='
    output_directory = next(
        (arg[len(prefix):] for arg in args if arg.startswith(prefix)), None)

    if not enabled:
        return (NooptContextManager(),)

    osname = GuessOS()
    if osname == 'linux':
        return (LinuxCoreDumpEnabler(), LinuxCoreDumpArchiver(output_directory))
    elif osname == 'macos':
        return (PosixCoreDumpEnabler(), MacOSCoreDumpArchiver(output_directory))
    elif osname == 'win32':
        return (WindowsCoreDumpEnabler(),
                WindowsCoreDumpArchiver(output_directory))

    # We don't have support for MacOS yet.
    return (NooptContextManager(),)


def FileDescriptorLimitIncreaser():
    osname = GuessOS()
    if osname == 'macos':
        return IncreasedNumberOfFileDescriptors(nofiles=10000)

    assert osname in ('linux', 'win32')
    # We don't have support for MacOS yet.
    return NooptContextManager()


def Main():
    print('GuessOS() -> ', GuessOS())
    print('GuessArchitecture() -> ', GuessArchitecture())
    print('GuessCpus() -> ', GuessCpus())
    print('IsWindows() -> ', IsWindows())
    print('GetGitRevision() -> ', GetGitRevision())
    print('GetGitTimestamp() -> ', GetGitTimestamp())


if __name__ == '__main__':
    Main()
