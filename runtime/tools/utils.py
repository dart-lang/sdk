# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains a set of utilities functions used by other Python-based
# scripts.

import commands
import os
import platform
import Queue
import re
import StringIO
import subprocess
import sys
import threading
import time


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
  return GetBuildMode(mode) + arch.upper()


def GetBuildRoot(host_os, mode=None, arch=None):
  global BUILD_ROOT
  if mode:
    return os.path.join(BUILD_ROOT[host_os], GetBuildConf(mode, arch))
  else:
    return BUILD_ROOT[host_os]


def RunCommand(command, input=None, pollFn=None, outStream=None, errStream=None,
               killOnEarlyReturn=True, verbose=False, debug=False,
               printErrorInfo=False):
  """
  Run a command, with optional input and polling function.

  Args:
    command: list of the command and its arguments.
    input: optional string of input to feed to the command, it should be
        short enough to fit in an i/o pipe buffer.
    pollFn: if present will be called occasionally to check if the command
        should be finished early. If pollFn() returns true then the command
        will finish early.
    outStream: if present, the stdout output of the command will be written to
        outStream.
    errStream: if present, the stderr output of the command will be written to
        errStream.
    killOnEarlyReturn: if true and pollFn returns true, then the subprocess will
        be killed, otherwise the subprocess will be detached.
    verbose: if true, the command is echoed to stderr.
    debug: if true, prints debugging information to stderr.
    printErrorInfo: if true, prints error information when the subprocess
    returns a non-zero exit code.
  Returns: the output of the subprocess.

  Exceptions:
    Raises Error if the subprocess returns an error code.
    Raises ValueError if called with invalid arguments.
  """
  if verbose:
    sys.stderr.write("command %s\n" % command)
  stdin = None
  if input:
    stdin = subprocess.PIPE
  try:
    process = subprocess.Popen(args=command,
                               stdin=stdin,
                               bufsize=1,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
  except OSError as e:
    if not isinstance(command, basestring):
      command = ' '.join(command)
    if printErrorInfo:
      sys.stderr.write("Command failed: '%s'\n" % command)
    raise Error(e)

  def StartThread(out):
    queue = Queue.Queue()
    def EnqueueOutput(out, queue):
      for line in iter(out.readline, b''):
        queue.put(line)
      out.close()
    thread = threading.Thread(target=EnqueueOutput, args=(out, queue))
    thread.daemon = True
    thread.start()
    return queue
  outQueue = StartThread(process.stdout)
  errQueue = StartThread(process.stderr)

  def ReadQueue(queue, out, out2):
    try:
      while True:
        line = queue.get(False)
        out.write(line)
        if out2 != None:
          out2.write(line)
    except Queue.Empty:
      pass

  outBuf = StringIO.StringIO()
  errorBuf = StringIO.StringIO()
  if input:
    process.stdin.write(input)
  while True:
    returncode = process.poll()
    if returncode != None:
      break
    ReadQueue(errQueue, errorBuf, errStream)
    ReadQueue(outQueue, outBuf, outStream)
    if pollFn != None and pollFn():
      returncode = 0
      if killOnEarlyReturn:
        process.kill()
      break
    time.sleep(0.1)
  # Drain queue
  ReadQueue(errQueue, errorBuf, errStream)
  ReadQueue(outQueue, outBuf, outStream)

  out = outBuf.getvalue();
  error = errorBuf.getvalue();
  if returncode:
    if not isinstance(command, basestring):
      command = ' '.join(command)
    if printErrorInfo:
      sys.stderr.write("Command failed: '%s'\n" % command)
      sys.stderr.write("        stdout: '%s'\n" % out)
      sys.stderr.write("        stderr: '%s'\n" % error)
      sys.stderr.write("    returncode: %d\n" % returncode)
    raise Error("Command failed: %s" % command)
  if debug:
    sys.stderr.write("output: %s\n" % out)
  return out


def Main(argv):
  print "GuessOS() -> ", GuessOS()
  print "GuessArchitecture() -> ", GuessArchitecture()
  print "GuessCpus() -> ", GuessCpus()
  print "IsWindows() -> ", IsWindows()


class Error(Exception):
  pass


if __name__ == "__main__":
  import sys
  Main(sys.argv)
