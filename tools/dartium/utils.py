# Copyright 2010 Google Inc. All Rights Reserved.

# This file contains a set of utilities functions used
# by both SConstruct and other Python-based scripts.

import commands
import os
import platform
import re
import subprocess

class ChangedWorkingDirectory(object):
  def __init__(self, new_dir):
    self._new_dir = new_dir

  def __enter__(self):
    self._old_dir = os.getcwd()
    os.chdir(self._new_dir)
    return self._new_dir

  def __exit__(self, *_):
    os.chdir(self._old_dir)

# Try to guess the host operating system.
def guessOS():
  id = platform.system()
  if id == "Linux":
    return "linux"
  elif id == "Darwin":
    return "mac"
  elif id == "Windows" or id == "Microsoft":
    # On Windows Vista platform.system() can return "Microsoft" with some
    # versions of Python, see http://bugs.python.org/issue1082 for details.
    return "win"
  else:
    return None


# Try to guess the host architecture.
def guessArchitecture():
  id = platform.machine()
  if id.startswith('arm'):
    return 'arm'
  elif (not id) or (not re.match('(x|i[3-6])86', id) is None):
    return 'x86'
  elif id == 'i86pc':
    return 'x86'
  else:
    return None


# Try to guess the number of cpus on this machine.
def guessCpus():
  if os.path.exists("/proc/cpuinfo"):
    return int(commands.getoutput("grep -E '^processor' /proc/cpuinfo | wc -l"))
  if os.path.exists("/usr/bin/hostinfo"):
    return int(commands.getoutput('/usr/bin/hostinfo | grep "processors are logically available." | awk "{ print \$1 }"'))
  win_cpu_count = os.getenv("NUMBER_OF_PROCESSORS")
  if win_cpu_count:
    return int(win_cpu_count)
  return int(os.getenv("PARFAIT_NUMBER_OF_CORES", 2))


# Returns true if we're running under Windows.
def isWindows():
  return guessOS() == 'win32'

# Reads a text file into an array of strings - one for each
# line. Strips comments in the process.
def readLinesFrom(name):
  result = []
  for line in open(name):
    if '#' in line:
      line = line[:line.find('#')]
    line = line.strip()
    if len(line) == 0:
      continue
    result.append(line)
  return result

def listArgCallback(option, opt_str, value, parser):
   if value is None:
     value = []

   for arg in parser.rargs:
     if arg[:2].startswith('--'):
       break
     value.append(arg)

   del parser.rargs[:len(value)]
   setattr(parser.values, option.dest, value)


def getCommandOutput(cmd):
  print cmd
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = pipe.communicate()
  if pipe.returncode == 0:
    return output[0]
  else:
    print output[1]
    raise Exception('Failed to run command. return code=%s' % pipe.returncode)

def runCommand(cmd, env_update=None):
  if env_update is None:
    env_update = {}
  print 'Running: ' + ' '.join(["%s='%s'" % (k, v) for k, v in env_update.iteritems()]) + ' ' + ' '.join(cmd)
  env_copy = dict(os.environ.items())
  env_copy.update(env_update)
  p = subprocess.Popen(cmd, env=env_copy)
  if p.wait() != 0:
    raise Exception('Failed to run command. return code=%s' % p.returncode)

def main(argv):
  print "GuessOS() -> ", guessOS()
  print "GuessArchitecture() -> ", guessArchitecture()
  print "GuessCpus() -> ", guessCpus()
  print "IsWindows() -> ", isWindows()


if __name__ == "__main__":
  import sys
  main(sys.argv)
