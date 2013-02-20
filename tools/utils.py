# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities functions used by other Python-based
# scripts.

import commands
import os
import platform
import re
import subprocess
import sys


# Try to guess the host operating system.
def GuessOS():
  id = platform.system()
  if id == "Linux":
    return "linux"
  elif id == "Darwin":
    return "macos"
  elif id == "Windows" or id == "Microsoft":
    # On Windows Vista platform.system() can return "Microsoft" with some
    # versions of Python, see http://bugs.python.org/issue1082 for details.
    return "win32"
  elif id == 'FreeBSD':
    return 'freebsd'
  elif id == 'OpenBSD':
    return 'openbsd'
  elif id == 'SunOS':
    return 'solaris'
  else:
    return None


# Try to guess the host architecture.
def GuessArchitecture():
  id = platform.machine()
  if id.startswith('arm'):
    return 'arm'
  elif (not id) or (not re.match('(x|i[3-6])86', id) is None):
    return 'ia32'
  elif id == 'i86pc':
    return 'ia32'
  elif '64' in id:
    return 'x64'
  else:
    return None


# Try to guess the number of cpus on this machine.
def GuessCpus():
  if os.path.exists("/proc/cpuinfo"):
    return int(commands.getoutput("grep -E '^processor' /proc/cpuinfo | wc -l"))
  if os.path.exists("/usr/bin/hostinfo"):
    return int(commands.getoutput('/usr/bin/hostinfo | grep "processors are logically available." | awk "{ print \$1 }"'))
  win_cpu_count = os.getenv("NUMBER_OF_PROCESSORS")
  if win_cpu_count:
    return int(win_cpu_count)
  return int(os.getenv("DART_NUMBER_OF_CORES", 2))

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
  defaultPath = r"C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7" \
                r"\IDE"
  defaultExecutable = "devenv.com"

  if not IsWindows():
    return (defaultPath, defaultExecutable)

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
          subkeyCounter = subkeyCounter + 1
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
            if not isExpress and subkeyName == '10.0':
              # Stop search since if we found non-Express VS2010 version
              # installed, which is preferred version.
              return (installDir, executable)
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
def ListArgCallback(option, opt_str, value, parser):
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
def ListDartArgCallback(option, opt_str, value, parser):
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
}


# Mapping table between OS and build output location.
BUILD_ROOT = {
  'win32': os.path.join('build'),
  'linux': os.path.join('out'),
  'freebsd': os.path.join('out'),
  'macos': os.path.join('xcodebuild'),
}

def GetBuildMode(mode):
  global BUILD_MODES
  return BUILD_MODES[mode]


def GetBuildConf(mode, arch):
  return '%s%s' % (GetBuildMode(mode), arch.upper())

ARCH_GUESS = GuessArchitecture()
BASE_DIR = os.path.abspath(os.path.join(os.curdir, '..'))


def GetBuildDir(host_os, target_os):
  global BUILD_ROOT
  build_dir = BUILD_ROOT[host_os]
  if target_os and target_os != host_os:
    build_dir = os.path.join(build_dir, target_os)
  return build_dir

def GetBuildRoot(host_os, mode=None, arch=None, target_os=None):
  build_root = GetBuildDir(host_os, target_os)
  if mode:
    build_root = os.path.join(build_root, GetBuildConf(mode, arch))
  return build_root

def GetBaseDir():
  return BASE_DIR

def GetVersion():
  dartbin = DartBinary()
  version_script = VersionScript()
  p = subprocess.Popen([dartbin, version_script], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows())
  output, not_used = p.communicate()
  return output.strip()

def GetSVNRevision():
  p = subprocess.Popen(['svn', 'info'], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows())
  output, not_used = p.communicate()
  revision = ParseSvnInfoOutput(output)
  if revision:
    return revision

  # maybe the builder is using git-svn, try that
  p = subprocess.Popen(['git', 'svn', 'info'], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows())
  output, not_used = p.communicate()
  revision = ParseSvnInfoOutput(output)
  if revision:
    return revision

  return None

def ParseSvnInfoOutput(output):
  for line in output.split('\n'):
    if 'Revision' in line:
      return (line.strip().split())[1]
  return None

def RewritePathSeparator(path, workspace):
  # Paths in test files are always specified using '/'
  # as the path separator. Replace with the actual
  # path separator before use.
  if ('/' in path):
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
            [RewritePathSeparator(o, workspace) for o in match.split(' ')]);
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
      raise ToolError('non-zero exit code from ' + java_home)
    new = stdout.strip()
    current = os.getenv('JAVA_HOME', default=new)
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
    os._exit(0)
    raise
  return True


def PrintError(str):
  """Writes and flushes a string to stderr."""
  sys.stderr.write(str)
  sys.stderr.write('\n')


def CheckedUnlink(name):
  """Unlink a file without throwing an exception."""
  try:
    os.unlink(name)
  except OSError, e:
    PrintError("os.unlink() " + str(e))


def Main(argv):
  print "GuessOS() -> ", GuessOS()
  print "GuessArchitecture() -> ", GuessArchitecture()
  print "GuessCpus() -> ", GuessCpus()
  print "IsWindows() -> ", IsWindows()
  print "GuessVisualStudioPath() -> ", GuessVisualStudioPath()


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


def VersionScript():
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  return os.path.join(tools_dir, 'version.dart')


def DartBinary():
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  dart_binary_prefix = os.path.join(tools_dir, 'testing', 'bin')
  if IsWindows():
    return os.path.join(dart_binary_prefix, 'windows', 'dart.exe')
  else:
    return os.path.join(dart_binary_prefix, GuessOS(), 'dart')


def DartSdkBinary():
  tools_dir = os.path.dirname(os.path.realpath(__file__))
  dart_binary_prefix = os.path.join(tools_dir, '..', 'sdk' , 'bin')
  return os.path.join(dart_binary_prefix, 'dart')


if __name__ == "__main__":
  import sys
  Main(sys.argv)
