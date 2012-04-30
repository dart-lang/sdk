# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  'win32': os.path.join(''),
  'linux': os.path.join('out'),
  'freebsd': os.path.join('out'),
  'macos': os.path.join('xcodebuild'),
}

def GetBuildMode(mode):
  global BUILD_MODES
  return BUILD_MODES[mode]


def GetBuildConf(mode, arch):
  return GetBuildMode(mode) + "_" + arch

ARCH_GUESS = GuessArchitecture()
BASE_DIR = os.path.abspath(os.path.join(os.curdir, '..'))

def GetBuildRoot(target_os, mode=None, arch=None):
  global BUILD_ROOT
  if mode:
    return os.path.join(BUILD_ROOT[target_os], GetBuildConf(mode, arch))
  else:
    return BUILD_ROOT[target_os]

def GetBaseDir():
  return BASE_DIR

def GetSVNRevision():
  p = subprocess.Popen(['svn', 'info'], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows())
  output, not_used = p.communicate()
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


if __name__ == "__main__":
  import sys
  Main(sys.argv)
