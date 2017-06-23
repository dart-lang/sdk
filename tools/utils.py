# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities functions used by other Python-based
# scripts.

import commands
import contextlib
import datetime
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

DART_DIR = os.path.abspath(
    os.path.normpath(os.path.join(__file__, '..', '..')))

def GetBotUtils():
  '''Dynamically load the tools/bots/bot_utils.py python module.'''
  return imp.load_source('bot_utils', os.path.join(DART_DIR, 'tools', 'bots', 'bot_utils.py'))

class Version(object):
  def __init__(self, channel, major, minor, patch, prerelease,
               prerelease_patch):
    self.channel = channel
    self.major = major
    self.minor = minor
    self.patch = patch
    self.prerelease = prerelease
    self.prerelease_patch = prerelease_patch

# Try to guess the host operating system.
def GuessOS():
  os_id = platform.system()
  if os_id == "Linux":
    return "linux"
  elif os_id == "Darwin":
    return "macos"
  elif os_id == "Windows" or os_id == "Microsoft":
    # On Windows Vista platform.system() can return "Microsoft" with some
    # versions of Python, see http://bugs.python.org/issue1082 for details.
    return "win32"
  elif os_id == 'FreeBSD':
    return 'freebsd'
  elif os_id == 'OpenBSD':
    return 'openbsd'
  elif os_id == 'SunOS':
    return 'solaris'
  else:
    return None


# Try to guess the host architecture.
def GuessArchitecture():
  os_id = platform.machine()
  if os_id.startswith('armv5te'):
    return 'armv5te'
  elif os_id.startswith('armv6'):
    return 'armv6'
  elif os_id.startswith('arm'):
    return 'arm'
  elif os_id.startswith('aarch64'):
    return 'arm64'
  elif '64' in os_id:
    return 'x64'
  elif (not os_id) or (not re.match('(x|i[3-6])86', os_id) is None):
    return 'ia32'
  elif os_id == 'i86pc':
    return 'ia32'
  else:
    guess_os = GuessOS()
    print "Warning: Guessing architecture %s based on os %s\n"\
          % (os_id, guess_os)
    if guess_os == 'win32':
      return 'ia32'
    return None


# Try to guess the number of cpus on this machine.
def GuessCpus():
  if os.getenv("DART_NUMBER_OF_CORES") is not None:
    return int(os.getenv("DART_NUMBER_OF_CORES"))
  if os.path.exists("/proc/cpuinfo"):
    return int(commands.getoutput("grep -E '^processor' /proc/cpuinfo | wc -l"))
  if os.path.exists("/usr/bin/hostinfo"):
    return int(commands.getoutput('/usr/bin/hostinfo |'
        ' grep "processors are logically available." |'
        ' awk "{ print \$1 }"'))
  win_cpu_count = os.getenv("NUMBER_OF_PROCESSORS")
  if win_cpu_count:
    return int(win_cpu_count)
  return 2

def GetWindowsRegistryKeyName(name):
  import win32process
  # Check if python process is 64-bit or if it's 32-bit running in 64-bit OS.
  # We need to know whether host is 64-bit so that we are looking in right
  # registry for Visual Studio path.
  if sys.maxsize > 2**32 or win32process.IsWow64Process():
    wow6432Node = 'Wow6432Node\\'
  else:
    wow6432Node = ''
  return r'SOFTWARE\%s%s' % (wow6432Node, name)

# Try to guess Visual Studio location when buiding on Windows.
def GuessVisualStudioPath():
  defaultPath = r"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7" \
                r"\IDE"
  defaultExecutable = "devenv.com"

  if not IsWindows():
    return defaultPath, defaultExecutable

  keyNamesAndExecutables = [
    # Pair for non-Express editions.
    (GetWindowsRegistryKeyName(r'Microsoft\VisualStudio'), 'devenv.com'),
    # Pair for 2012 Express edition.
    (GetWindowsRegistryKeyName(r'Microsoft\VSWinExpress'), 'VSWinExpress.exe'),
    # Pair for pre-2012 Express editions.
    (GetWindowsRegistryKeyName(r'Microsoft\VCExpress'), 'VCExpress.exe')]

  bestGuess = (0.0, (defaultPath, defaultExecutable))

  import _winreg
  for (keyName, executable) in keyNamesAndExecutables:
    try:
      key = _winreg.OpenKey(_winreg.HKEY_LOCAL_MACHINE, keyName)
    except WindowsError:
      # Can't find this key - moving on the next one.
      continue

    try:
      subkeyCounter = 0
      while True:
        try:
          subkeyName = _winreg.EnumKey(key, subkeyCounter)
          subkeyCounter += 1
        except WindowsError:
          # Reached end of enumeration. Moving on the next key.
          break

        match = re.match(r'^\d+\.\d+$', subkeyName)
        if match:
          with _winreg.OpenKey(key, subkeyName) as subkey:
            try:
              (installDir, registrytype) = _winreg.QueryValueEx(subkey,
                                                                'InstallDir')
            except WindowsError:
              # Can't find value under the key - continue to the next key.
              continue
            isExpress = executable != 'devenv.com'
            if not isExpress and subkeyName == '14.0':
              # Stop search since if we found non-Express VS2015 version
              # installed, which is preferred version.
              return installDir, executable
            else:
              version = float(subkeyName)
              # We prefer higher version of Visual Studio and given equal
              # version numbers we prefer non-Express edition.
              if version > bestGuess[0]:
                bestGuess = (version, (installDir, executable))
    finally:
      _winreg.CloseKey(key)
  return bestGuess[1]


# Returns true if we're running under Windows.
def IsWindows():
  return GuessOS() == 'win32'


# Reads a text file into an array of strings - one for each
# line. Strips comments in the process.
def ReadLinesFrom(name):
  result = []
  for line in open(name):
    if '#' in line:
      line = line[:line.find('#')]
    line = line.strip()
    if len(line) == 0:
      continue
    result.append(line)
  return result

# Filters out all arguments until the next '--' argument
# occurs.
def ListArgCallback(option, value, parser):
   if value is None:
     value = []

   for arg in parser.rargs:
     if arg[:2].startswith('--'):
       break
     value.append(arg)

   del parser.rargs[:len(value)]
   setattr(parser.values, option.dest, value)


# Filters out all argument until the first non '-' or the
# '--' argument occurs.
def ListDartArgCallback(option, value, parser):
   if value is None:
     value = []

   for arg in parser.rargs:
     if arg[:2].startswith('--') or arg[0] != '-':
       break
     value.append(arg)

   del parser.rargs[:len(value)]
   setattr(parser.values, option.dest, value)


# Mapping table between build mode and build configuration.
BUILD_MODES = {
  'debug': 'Debug',
  'release': 'Release',
  'product': 'Product',
}


# Mapping table between OS and build output location.
BUILD_ROOT = {
  'win32': os.path.join('out'),
  'linux': os.path.join('out'),
  'freebsd': os.path.join('out'),
  'macos': os.path.join('xcodebuild'),
}

ARCH_FAMILY = {
  'ia32': 'ia32',
  'x64': 'ia32',
  'arm': 'arm',
  'armv6': 'arm',
  'armv5te': 'arm',
  'arm64': 'arm',
  'simarm': 'ia32',
  'simarmv6': 'ia32',
  'simarmv5te': 'ia32',
  'simarm64': 'ia32',
  'simdbc': 'ia32',
  'simdbc64': 'ia32',
  'armsimdbc': 'arm',
  'armsimdbc64': 'arm',
}

ARCH_GUESS = GuessArchitecture()
BASE_DIR = os.path.abspath(os.path.join(os.curdir, '..'))
DART_DIR = os.path.abspath(os.path.join(__file__, '..', '..'))
VERSION_FILE = os.path.join(DART_DIR, 'tools', 'VERSION')

def GetBuildbotGSUtilPath():
  gsutil = '/b/build/scripts/slave/gsutil'
  if platform.system() == 'Windows':
    gsutil = 'e:\\\\b\\build\\scripts\\slave\\gsutil'
  return gsutil

def GetBuildMode(mode):
  return BUILD_MODES[mode]

def GetArchFamily(arch):
  return ARCH_FAMILY[arch]

def IsCrossBuild(target_os, arch):
  host_arch = ARCH_GUESS
  return ((GetArchFamily(host_arch) != GetArchFamily(arch)) or
          (target_os != GuessOS()))

def GetBuildConf(mode, arch, conf_os=None):
  if conf_os == 'android':
    return '%s%s%s' % (GetBuildMode(mode), conf_os.title(), arch.upper())
  else:
    # Ask for a cross build if the host and target architectures don't match.
    host_arch = ARCH_GUESS
    cross_build = ''
    if GetArchFamily(host_arch) != GetArchFamily(arch):
      cross_build = 'X'
    return '%s%s%s' % (GetBuildMode(mode), cross_build, arch.upper())

def GetBuildDir(host_os):
  return BUILD_ROOT[host_os]

def GetBuildRoot(host_os, mode=None, arch=None, target_os=None):
  build_root = GetBuildDir(host_os)
  if mode:
    build_root = os.path.join(build_root, GetBuildConf(mode, arch, target_os))
  return build_root

def GetBuildSdkBin(host_os, mode=None, arch=None, target_os=None):
  build_root = GetBuildRoot(host_os, mode, arch, target_os)
  return os.path.join(build_root, 'dart-sdk', 'bin')

def GetBaseDir():
  return BASE_DIR

def GetShortVersion():
  version = ReadVersionFile()
  return ('%s.%s.%s.%s.%s' % (
      version.major, version.minor, version.patch, version.prerelease,
      version.prerelease_patch))

def GetSemanticSDKVersion(ignore_svn_revision=False):
  version = ReadVersionFile()
  if not version:
    return None

  if version.channel == 'be':
    postfix = '-edge' if ignore_svn_revision else '-edge.%s' % GetGitRevision()
  elif version.channel == 'dev':
    postfix = '-dev.%s.%s' % (version.prerelease, version.prerelease_patch)
  else:
    assert version.channel == 'stable'
    postfix = ''

  return '%s.%s.%s%s' % (version.major, version.minor, version.patch, postfix)

def GetVersion(ignore_svn_revision=False):
  return GetSemanticSDKVersion(ignore_svn_revision)

# The editor used to produce the VERSION file put on gcs. We now produce this
# in the bots archiving the sdk.
# The content looks like this:
#{
#  "date": "2015-05-28",
#  "version": "1.11.0-edge.131653",
#  "revision": "535394c2657ede445142d8a92486d3899bbf49b5"
#}
def GetVersionFileContent():
  result = {"date": str(datetime.date.today()),
            "version": GetVersion(),
            "revision": GetGitRevision()}
  return json.dumps(result, indent=2)

def GetChannel():
  version = ReadVersionFile()
  return version.channel

def GetUserName():
  key = 'USER'
  if sys.platform == 'win32':
    key = 'USERNAME'
  return os.environ.get(key, '')

def ReadVersionFile():
  def match_against(pattern, file_content):
    match = re.search(pattern, file_content, flags=re.MULTILINE)
    if match:
      return match.group(1)
    return None

  try:
    fd = open(VERSION_FILE)
    content = fd.read()
    fd.close()
  except:
    print "Warning: Couldn't read VERSION file (%s)" % VERSION_FILE
    return None

  channel = match_against('^CHANNEL ([A-Za-z0-9]+)$', content)
  major = match_against('^MAJOR (\d+)$', content)
  minor = match_against('^MINOR (\d+)$', content)
  patch = match_against('^PATCH (\d+)$', content)
  prerelease = match_against('^PRERELEASE (\d+)$', content)
  prerelease_patch = match_against('^PRERELEASE_PATCH (\d+)$', content)

  if channel and major and minor and prerelease and prerelease_patch:
    return Version(
        channel, major, minor, patch, prerelease, prerelease_patch)
  else:
    print "Warning: VERSION file (%s) has wrong format" % VERSION_FILE
    return None


# Our schema for releases and archiving is based on an increasing
# sequence of numbers. In the svn world this was simply the revision of a
# commit, which would always give us a one to one mapping between the number
# and the commit. This was true across branches as well, so a number used
# to archive a build was always unique and unambiguous.
# In git there is no such global number, so we loosen the requirement a bit.
# We only use numbers on the master branch (bleeding edge). On branches
# we use the version number instead for archiving purposes.
# The number on master is the count of commits on the master branch.
def GetArchiveVersion():
  version = ReadVersionFile()
  if not version:
    raise 'Could not get the archive version, parsing the version file failed'
  if version.channel in ['be', 'integration']:
    return GetGitNumber()
  return GetSemanticSDKVersion()


def GetGitRevision():
  # When building from tarball use tools/GIT_REVISION
  git_revision_file = os.path.join(DART_DIR, 'tools', 'GIT_REVISION')
  try:
    with open(git_revision_file) as fd:
      return fd.read()
  except:
    pass

  p = subprocess.Popen(['git', 'log', '-n', '1', '--pretty=format:%H'],
                       stdout = subprocess.PIPE,
                       stderr = subprocess.STDOUT, shell=IsWindows(),
                       cwd = DART_DIR)
  output, _ = p.communicate()
  # We expect a full git hash
  if len(output) != 40:
    print "Warning: could not parse git commit, output was %s" % output
    return None
  return output

# To eliminate clashing with older archived builds on bleeding edge we add
# a base number bigger the largest svn revision (this also gives us an easy
# way of seeing if an archive comes from git based or svn based commits).
GIT_NUMBER_BASE = 100000
def GetGitNumber():
  p = subprocess.Popen(['git', 'rev-list', 'HEAD', '--count'],
                       stdout = subprocess.PIPE,
                       stderr = subprocess.STDOUT, shell=IsWindows(),
                       cwd = DART_DIR)
  output, _ = p.communicate()
  try:
    number = int(output)
    return number + GIT_NUMBER_BASE
  except:
    print "Warning: could not parse git count, output was %s" % output
  return None

def ParseGitInfoOutput(output):
  """Given a git log, determine the latest corresponding svn revision."""
  for line in output.split('\n'):
    tokens = line.split()
    if len(tokens) > 0 and tokens[0] == 'git-svn-id:':
      return tokens[1].split('@')[1]
  return None

def ParseSvnInfoOutput(output):
  revision_match = re.search('Last Changed Rev: (\d+)', output)
  if revision_match:
    return revision_match.group(1)
  return None

def RewritePathSeparator(path, workspace):
  # Paths in test files are always specified using '/'
  # as the path separator. Replace with the actual
  # path separator before use.
  if '/' in path:
    split_path = path.split('/')
    path = os.sep.join(split_path)
    path = os.path.join(workspace, path)
    if not os.path.exists(path):
      raise Exception(path)
  return path


def ParseTestOptions(pattern, source, workspace):
  match = pattern.search(source)
  if match:
    return [RewritePathSeparator(o, workspace) for o in match.group(1).split(' ')]
  else:
    return None


def ParseTestOptionsMultiple(pattern, source, workspace):
  matches = pattern.findall(source)
  if matches:
    result = []
    for match in matches:
      if len(match) > 0:
        result.append(
            [RewritePathSeparator(o, workspace) for o in match.split(' ')])
      else:
        result.append([])
    return result
  else:
    return None


def ConfigureJava():
  java_home = '/usr/libexec/java_home'
  if os.path.exists(java_home):
    proc = subprocess.Popen([java_home, '-v', '1.6+'],
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    (stdout, stderr) = proc.communicate()
    if proc.wait() != 0:
      return None
    new = stdout.strip()
    current = os.getenv('JAVA_HOME', new)
    if current != new:
      sys.stderr.write('Please set JAVA_HOME to %s\n' % new)
      os.putenv('JAVA_HOME', new)


def Daemonize():
  """
  Create a detached background process (daemon). Returns True for
  the daemon, False for the parent process.
  See: http://www.faqs.org/faqs/unix-faq/programmer/faq/
  "1.7 How do I get my program to act like a daemon?"
  """
  if os.fork() > 0:
    return False
  os.setsid()
  if os.fork() > 0:
    exit(0)
    raise
  return True


def PrintError(string):
  """Writes and flushes a string to stderr."""
  sys.stderr.write(string)
  sys.stderr.write('\n')


def CheckedUnlink(name):
  """Unlink a file without throwing an exception."""
  try:
    os.unlink(name)
  except OSError, e:
    PrintError("os.unlink() " + str(e))


def Main():
  print "GuessOS() -> ", GuessOS()
  print "GuessArchitecture() -> ", GuessArchitecture()
  print "GuessCpus() -> ", GuessCpus()
  print "IsWindows() -> ", IsWindows()
  print "GuessVisualStudioPath() -> ", GuessVisualStudioPath()
  print "GetGitRevision() -> ", GetGitRevision()
  print "GetVersionFileContent() -> ", GetVersionFileContent()
  print "GetGitNumber() -> ", GetGitNumber()

class Error(Exception):
  pass


class ToolError(Exception):
  """Deprecated exception, use Error instead."""

  def __init__(self, value):
    self.value = value

  def __str__(self):
    return repr(self.value)


def IsCrashExitCode(exit_code):
  if IsWindows():
    return 0x80000000 & exit_code
  else:
    return exit_code < 0


def DiagnoseExitCode(exit_code, command):
  if IsCrashExitCode(exit_code):
    sys.stderr.write('Command: %s\nCRASHED with exit code %d (0x%x)\n' % (
        ' '.join(command), exit_code, exit_code & 0xffffffff))


def Touch(name):
  with file(name, 'a'):
    os.utime(name, None)


def ExecuteCommand(cmd):
  """Execute a command in a subprocess."""
  print 'Executing: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
      shell=IsWindows())
  output = pipe.communicate()
  if pipe.returncode != 0:
    raise Exception('Execution failed: ' + str(output))
  return pipe.returncode, output


# The checked-in SDKs are documented at
#     https://github.com/dart-lang/sdk/wiki/The-checked-in-SDK-in-tools
def CheckedInSdkPath():
  # We don't use the normal macos, linux, win32 directory names here, instead,
  # we use the names that the download_from_google_storage script uses.
  osdict = {'Darwin':'mac', 'Linux':'linux', 'Windows':'win'}
  system = platform.system()
  try:
    osname = osdict[system]
  except KeyError:
    print >>sys.stderr, ('WARNING: platform "%s" not supported') % (system)
    return None
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  return os.path.join(tools_dir,
                      'sdks',
                      osname,
                      'dart-sdk')


def CheckedInSdkExecutable():
  name = 'dart'
  if IsWindows():
    name = 'dart.exe'
  elif GuessOS() == 'linux':
    arch = GuessArchitecture()
    if arch == 'arm':
      name = 'dart-arm'
    elif arch == 'arm64':
      name = 'dart-arm64'
    elif arch == 'armv5te':
      # TODO(zra): This binary does not exist, yet. Check one in once we have
      # sufficient stability.
      name = 'dart-armv5te'
    elif arch == 'armv6':
      # TODO(zra): Ditto.
      name = 'dart-armv6'
  return os.path.join(CheckedInSdkPath(), 'bin', name)


def CheckedInSdkCheckExecutable():
  executable = CheckedInSdkExecutable()
  canary_script = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                               'canary.dart')
  try:
    with open(os.devnull, 'wb') as silent_sink:
      if 0 == subprocess.call([executable, canary_script], stdout=silent_sink):
        return True
  except OSError as e:
    pass
  return False


def CheckLinuxCoreDumpPattern(fatal=False):
  core_pattern_file = '/proc/sys/kernel/core_pattern'
  core_pattern = open(core_pattern_file).read()

  expected_core_pattern = 'core.%p'
  if core_pattern.strip() != expected_core_pattern:
    if fatal:
      message = ('Invalid core_pattern configuration. '
          'The configuration of core dump handling is *not* correct for '
          'a buildbot. The content of {0} must be "{1}" instead of "{2}".'
          .format(core_pattern_file, expected_core_pattern, core_pattern))
      raise Exception(message)
    else:
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

class ChangedWorkingDirectory(object):
  def __init__(self, working_directory):
    self._working_directory = working_directory

  def __enter__(self):
    self._old_cwd = os.getcwd()
    print "Enter directory = ", self._working_directory
    os.chdir(self._working_directory)

  def __exit__(self, *_):
    print "Enter directory = ", self._old_cwd
    os.chdir(self._old_cwd)


class UnexpectedCrash(object):
  def __init__(self, test, pid, binary):
    self.test = test
    self.pid = pid
    self.binary = binary

  def __str__(self):
    return "Crash(%s: %s %s)" % (self.test, self.binary, self.pid)

class SiteConfigBotoFileDisabler(object):
  def __init__(self):
    self._old_aws = None
    self._old_boto = None

  def __enter__(self):
    self._old_aws = os.environ.get('AWS_CREDENTIAL_FILE', None)
    self._old_boto = os.environ.get('BOTO_CONFIG', None)

    if self._old_aws:
      del os.environ['AWS_CREDENTIAL_FILE']
    if self._old_boto:
      del os.environ['BOTO_CONFIG']

  def __exit__(self, *_):
    if self._old_aws:
      os.environ['AWS_CREDENTIAL_FILE'] = self._old_aws
    if self._old_boto:
      os.environ['BOTO_CONFIG'] = self._old_boto

class PosixCoreDumpEnabler(object):
  def __init__(self):
    self._old_limits = None

  def __enter__(self):
    self._old_limits = resource.getrlimit(resource.RLIMIT_CORE)
    resource.setrlimit(resource.RLIMIT_CORE, (-1, -1))

  def __exit__(self, *_):
    resource.setrlimit(resource.RLIMIT_CORE, self._old_limits)

class LinuxCoreDumpEnabler(PosixCoreDumpEnabler):
  def __enter__(self):
    # Bump core limits to unlimited if core_pattern is correctly configured.
    if CheckLinuxCoreDumpPattern(fatal=False):
      super(LinuxCoreDumpEnabler, self).__enter__()

  def __exit__(self, *args):
    CheckLinuxCoreDumpPattern(fatal=True)
    super(LinuxCoreDumpEnabler, self).__exit__(*args)

class WindowsCoreDumpEnabler(object):
  """Configure Windows Error Reporting to store crash dumps.

  The documentation can be found here:
  https://msdn.microsoft.com/en-us/library/windows/desktop/bb787181.aspx
  """

  WINDOWS_COREDUMP_FOLDER = r'crashes'

  WER_NAME = r'SOFTWARE\Microsoft\Windows\Windows Error Reporting'
  WER_LOCALDUMPS_NAME = r'%s\LocalDumps' % WER_NAME
  IMGEXEC_NAME = (r'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
                  r'\Image File Execution Options\WerFault.exe')

  def __init__(self):
    # Depending on whether we're in cygwin or not we use a different import.
    try:
      import winreg
    except ImportError:
      import _winreg as winreg
    self.winreg = winreg

  def __enter__(self):
    # We want 32 and 64 bit coredumps to land in the same coredump directory.
    for sam in [self.winreg.KEY_WOW64_64KEY, self.winreg.KEY_WOW64_32KEY]:
      # In case WerFault.exe was prevented from executing, we fix it here.
      # TODO(kustermann): Remove this once https://crbug.com/691971 is fixed.
      self._prune_existing_key(
          self.winreg.HKEY_LOCAL_MACHINE, self.IMGEXEC_NAME, sam)

      # Create (or open) the WER keys.
      with self.winreg.CreateKeyEx(
            self.winreg.HKEY_LOCAL_MACHINE, self.WER_NAME, 0,
            self.winreg.KEY_ALL_ACCESS | sam) as wer:
        with self.winreg.CreateKeyEx(
            self.winreg.HKEY_LOCAL_MACHINE, self.WER_LOCALDUMPS_NAME, 0,
            self.winreg.KEY_ALL_ACCESS | sam) as wer_localdumps:
          # Prevent any modal UI dialog & disable normal windows error reporting
          # TODO(kustermann): Remove this once https://crbug.com/691971 is fixed
          self.winreg.SetValueEx(wer, "DontShowUI", 0, self.winreg.REG_DWORD, 1)
          self.winreg.SetValueEx(wer, "Disabled", 0, self.winreg.REG_DWORD, 1)

          coredump_folder = os.path.join(
              os.getcwd(), WindowsCoreDumpEnabler.WINDOWS_COREDUMP_FOLDER)

          # Create the directory which will contain the dumps
          if not os.path.exists(coredump_folder):
            os.mkdir(coredump_folder)

          # Do full dumps (not just mini dumps), keep max 100 dumps and specify
          # folder.
          self.winreg.SetValueEx(
              wer_localdumps, "DumpType", 0, self.winreg.REG_DWORD, 2)
          self.winreg.SetValueEx(
              wer_localdumps, "DumpCount", 0, self.winreg.REG_DWORD, 200)
          self.winreg.SetValueEx(
              wer_localdumps, "DumpFolder", 0, self.winreg.REG_EXPAND_SZ,
              coredump_folder)

  def __exit__(self, *_):
    # We remove the local dumps settings after running the tests.
    for sam in [self.winreg.KEY_WOW64_64KEY, self.winreg.KEY_WOW64_32KEY]:
      with self.winreg.CreateKeyEx(
          self.winreg.HKEY_LOCAL_MACHINE, self.WER_LOCALDUMPS_NAME, 0,
          self.winreg.KEY_ALL_ACCESS | sam) as wer_localdumps:
        self.winreg.DeleteValue(wer_localdumps, 'DumpType')
        self.winreg.DeleteValue(wer_localdumps, 'DumpCount')
        self.winreg.DeleteValue(wer_localdumps, 'DumpFolder')

  def _prune_existing_key(self, key, subkey, wowbit):
    handle = None

    # If the open fails, the key doesn't exist and it's fine.
    try:
      handle = self.winreg.OpenKey(
          key, subkey, 0, self.winreg.KEY_READ | wowbit)
    except OSError:
      pass

    # If the key exists then we delete it. If the deletion does not work, we
    # let the exception through.
    if handle:
      handle.Close()
      self.winreg.DeleteKeyEx(key, subkey, wowbit, 0)

class BaseCoreDumpArchiver(object):
  """This class reads coredumps file written by UnexpectedCrashDumpArchiver
  into the current working directory and uploads all cores and binaries
  listed in it into Cloud Storage (see tools/testing/dart/test_progress.dart).
  """

  # test.dart will write a line for each unexpected crash into this file.
  _UNEXPECTED_CRASHES_FILE = "unexpected-crashes"

  def __init__(self, search_dir):
    self._bucket = 'dart-temp-crash-archive'
    self._binaries_dir = os.getcwd()
    self._search_dir = search_dir

  def __enter__(self):
    # Cleanup any stale files
    if self._cleanup():
      print "WARNING: Found and removed stale coredumps"

  def __exit__(self, *_):
    try:
      crashes = self._find_unexpected_crashes()
      if crashes:
        # If we get a ton of crashes, only archive 10 dumps.
        archive_crashes = crashes[:10]
        print 'Archiving coredumps for crash (if possible):'
        for crash in archive_crashes:
          print '----> %s' % crash

        sys.stdout.flush()

        # We disable usage of the boto file installed on the bots due to an
        # issue introduced by
        # https://chrome-internal-review.googlesource.com/c/331136
        with SiteConfigBotoFileDisabler():
          self._archive(archive_crashes)
    finally:
      self._cleanup()

  def _archive(self, crashes):
    files = set()
    missing = []
    for crash in crashes:
      files.add(crash.binary)
      core = self._find_coredump_file(crash)
      if core:
        files.add(core)
      else:
        missing.append(crash)
    self._upload(files)

    if missing:
      self._report_missing_crashes(missing, throw=True)

  def _report_missing_crashes(self, missing, throw=True):
    missing_as_string = ', '.join([str(c) for c in missing])
    other_files = list(glob.glob(os.path.join(self._search_dir, '*')))
    print >> sys.stderr, (
        "Could not find crash dumps for '%s' in search directory '%s'.\n"
        "Existing files which *did not* match the pattern inside the search "
        "directory are are:\n  %s"
        % (missing_as_string, self._search_dir, '\n  '.join(other_files)))
    if throw:
      raise Exception('Missing crash dumps for: %s' % missing_as_string)

  def _upload(self, files):
    bot_utils = GetBotUtils()
    gsutil = bot_utils.GSUtil()
    storage_path = '%s/%s/' % (self._bucket, uuid.uuid4())
    gs_prefix = 'gs://%s' % storage_path
    http_prefix = 'https://storage.cloud.google.com/%s' % storage_path

    print '\n--- Uploading into %s (%s) ---' % (gs_prefix, http_prefix)
    for file in files:
      # Sanitize the name: actual cores follow 'core.%d' pattern, crashed
      # binaries are copied next to cores and named 'binary.<binary_name>'.
      name = os.path.basename(file)
      (prefix, suffix) = name.split('.', 1)
      if prefix == 'binary':
        name = suffix

      tarname = '%s.tar.gz' % name

      # Compress the file.
      tar = tarfile.open(tarname, mode='w:gz')
      tar.add(file, arcname=name)
      tar.close()

      # Remove / from absolute path to not have // in gs path.
      gs_url = '%s%s' % (gs_prefix, tarname)
      http_url = '%s%s' % (http_prefix, tarname)

      try:
        gsutil.upload(tarname, gs_url)
        print '+++ Uploaded %s (%s)' % (gs_url, http_url)
      except Exception as error:
        print '!!! Failed to upload %s, error: %s' % (tarname, error)

      os.unlink(tarname)
    print '--- Done ---\n'

  def _find_unexpected_crashes(self):
    """Load coredumps file. Each line has the following format:

        test-name,pid,binary-file
    """
    try:
      with open(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE) as f:
        return [UnexpectedCrash(*ln.strip('\n').split(',')) for ln in f.readlines()]
    except:
      return []

  def _cleanup(self):
    found = False
    if os.path.exists(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE):
      os.unlink(BaseCoreDumpArchiver._UNEXPECTED_CRASHES_FILE)
      found = True
    for binary in glob.glob(os.path.join(self._binaries_dir, 'binary.*')):
      found = True
      os.unlink(binary)
    return found

class PosixCoreDumpArchiver(BaseCoreDumpArchiver):
  def __init__(self, search_dir):
    super(PosixCoreDumpArchiver, self).__init__(search_dir)

  def _cleanup(self):
    found = super(PosixCoreDumpArchiver, self)._cleanup()
    for core in glob.glob(os.path.join(self._search_dir, 'core.*')):
      found = True
      try:
        os.unlink(core)
      except:
        pass
    return found

  def _find_coredump_file(self, crash):
    core_filename = os.path.join(self._search_dir, 'core.%s' % crash.pid)
    if os.path.exists(core_filename):
      return core_filename

class LinuxCoreDumpArchiver(PosixCoreDumpArchiver):
  def __init__(self):
    super(LinuxCoreDumpArchiver, self).__init__(os.getcwd())

class MacOSCoreDumpArchiver(PosixCoreDumpArchiver):
  def __init__(self):
    super(MacOSCoreDumpArchiver, self).__init__('/cores')

class WindowsCoreDumpArchiver(BaseCoreDumpArchiver):
  def __init__(self):
    super(WindowsCoreDumpArchiver, self).__init__(os.path.join(
        os.getcwd(), WindowsCoreDumpEnabler.WINDOWS_COREDUMP_FOLDER))

  def _cleanup(self):
    found = super(WindowsCoreDumpArchiver, self)._cleanup()
    for core in glob.glob(os.path.join(self._search_dir, '*')):
      found = True
      os.unlink(core)
    return found

  def _find_coredump_file(self, crash):
    pattern = os.path.join(self._search_dir, '*.%s.*' % crash.pid)
    for core_filename in glob.glob(pattern):
      return core_filename

  def _report_missing_crashes(self, missing, throw=True):
    # Let's only print the debugging information and not throw. We'll do more
    # validation for werfault.exe and throw afterwards.
    super(WindowsCoreDumpArchiver, self)._report_missing_crashes(missing, throw=False)

    # Let's check again for the image execution options for werfault. Maybe
    # puppet came a long during testing and reverted our change.
    try:
      import winreg
    except ImportError:
      import _winreg as winreg
    for wowbit in [winreg.KEY_WOW64_64KEY, winreg.KEY_WOW64_32KEY]:
      try:
         with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                             WindowsCoreDumpEnabler.IMGEXEC_NAME,
                             0,
                             winreg.KEY_READ | wowbit) as handle:
          raise Exception(
              "Found werfault.exe was disabled. Probably by puppet. Too bad! "
              "(For more information see https://crbug.com/691971)")
      except OSError:
        # If the open did not work the werfault.exe execution setting is as it
        # should be.
        pass

    if throw:
      missing_as_string = ', '.join([str(c) for c in missing])
      raise Exception('Missing crash dumps for: %s' % missing_as_string)

@contextlib.contextmanager
def NooptCoreDumpArchiver():
  yield

def CoreDumpArchiver(args):
  enabled = '--copy-coredumps' in args

  if not enabled:
    return NooptCoreDumpArchiver()

  osname = GuessOS()
  if osname == 'linux':
    return contextlib.nested(LinuxCoreDumpEnabler(),
                             LinuxCoreDumpArchiver())
  elif osname == 'macos':
    return contextlib.nested(PosixCoreDumpEnabler(),
                             MacOSCoreDumpArchiver())
  elif osname == 'win32':
    return contextlib.nested(WindowsCoreDumpEnabler(),
                             WindowsCoreDumpArchiver())
  else:
    # We don't have support for MacOS yet.
    assert osname == 'macos'
    return NooptCoreDumpArchiver()

if __name__ == "__main__":
  import sys
  Main()
