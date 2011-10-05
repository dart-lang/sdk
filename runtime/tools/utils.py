# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities functions used by other Python-based
# scripts.

import platform
import re
import os
import commands


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
def ListDashArgCallback(option, opt_str, value, parser):
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
  'linux': os.path.join('out'),
  'freebsd': os.path.join('out'),
  'macos': os.path.join('xcodebuild'),
}

def GetBuildMode(mode):
  global BUILD_MODES
  return BUILD_MODES[mode]


def GetBuildConf(mode, arch):
  return GetBuildMode(mode) + "_" + arch


def GetBuildRoot(target_os, mode=None, arch=None):
  global BUILD_ROOT
  if mode:
    return os.path.join(BUILD_ROOT[target_os], GetBuildConf(mode, arch))
  else:
    return BUILD_ROOT[target_os]


def Main(argv):
  print "GuessOS() -> ", GuessOS()
  print "GuessArchitecture() -> ", GuessArchitecture()
  print "GuessCpus() -> ", GuessCpus()
  print "IsWindows() -> ", IsWindows()


if __name__ == "__main__":
  import sys
  Main(sys.argv)
