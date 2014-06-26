#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

# A script to kill hanging processs. The tool will return non-zero if any
# process was actually found.
#

import optparse
import os
import signal
import shutil
import string
import subprocess
import sys
import utils

os_name = utils.GuessOS()

POSIX_INFO = 'ps -p %s -o args'

EXECUTABLE_NAMES = {
  'win32': {
    'chrome': 'chrome.exe',
    'content_shell': 'content_shell.exe',
    'dart': 'dart.exe',
    'editor': 'DartEditor.exe',
    'iexplore': 'iexplore.exe',
    'firefox': 'firefox.exe',
    'git': 'git.exe',
    'svn': 'svn.exe'
  },
  'linux': {
    'chrome': 'chrome',
    'content_shell': 'content_shell',
    'dart': 'dart',
    'editor': 'DartEditor',
    'java': 'java',
    'eggplant': 'Eggplant',
    'firefox': 'firefox.exe',
    'git': 'git',
    'svn': 'svn'
  },
  'macos': {
    'chrome': 'Chrome',
    'content_shell': 'Content Shell',
    'dart': 'dart',
    'editor': 'DartEditor',
    'firefox': 'firefox',
    'safari': 'Safari',
    'git': 'git',
    'svn': 'svn'
  }
}

INFO_COMMAND = {
  'win32': 'wmic process where Processid=%s get CommandLine',
  'macos': POSIX_INFO,
  'linux': POSIX_INFO,
}

def GetOptions():
  parser = optparse.OptionParser("usage: %prog [options]")
  parser.add_option("--kill_dart", default=True,
                    help="Kill all dart processes")
  parser.add_option("--kill_vc", default=True,
                    help="Kill all git and svn processes")
  parser.add_option("--kill_browsers", default=False,
                     help="Kill all browser processes")
  parser.add_option("--kill_editor", default=True,
                     help="Kill all editor processes")
  (options, args) = parser.parse_args()
  return options


def GetPidsPosix(process_name):
  # This is to have only one posix command, on linux we could just do:
  # pidof process_name
  cmd = 'ps -e -o pid= -o comm='
  # Sample output:
  # 1 /sbin/launchd
  # 80943 /Applications/Safari.app/Contents/MacOS/Safari
  p = subprocess.Popen(cmd,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,
                       shell=True)
  output, stderr = p.communicate()
  results = []
  lines = output.splitlines()
  for line in lines:
    split = line.split()
    # On mac this ps commands actually gives us the full path to non
    # system binaries.
    if len(split) >= 2 and " ".join(split[1:]).endswith(process_name):
      results.append(split[0])
  return results


def GetPidsWindows(process_name):
  cmd = 'tasklist /FI "IMAGENAME eq %s" /NH' % process_name
  # Sample output:
  # dart.exe    4356 Console            1      6,800 K
  p = subprocess.Popen(cmd,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,
                       shell=True)
  output, stderr = p.communicate()
  results = []
  lines = output.splitlines()

  for line in lines:
    split = line.split()
    if len(split) > 2 and split[0] == process_name:
      results.append(split[1])
  return results

def GetPids(process_name):
  if (os_name == "win32"):
    return GetPidsWindows(process_name)
  else:
    return GetPidsPosix(process_name)

def PrintPidInfo(pid):
  # We asume that the list command will return lines in the format:
  # EXECUTABLE_PATH ARGS
  # There may be blank strings in the output
  p = subprocess.Popen(INFO_COMMAND[os_name] % pid,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,
                       shell=True)
  output, stderr = p.communicate()
  lines = output.splitlines()

  # Pop the header
  lines.pop(0)
  for line in lines:
    # wmic will output a bunch of empty strings, we ignore these
    if len(line) >= 1:
      print("Hanging process info:")
      print("  PID: %s" % pid)
      print("  Command line: %s" % line)


def KillPosix(pid):
  try:
    os.kill(int(pid), signal.SIGKILL);
  except:
    # Ignore this, the process is already dead from killing another process.
    pass

def KillWindows(pid):
  # os.kill is not available until python 2.7
  cmd = "taskkill /F /PID %s" % pid
  p = subprocess.Popen(cmd,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,
                       shell=True)
  p.communicate()

def Kill(name):
  if (name not in EXECUTABLE_NAMES[os_name]):
    return 0
  print("***************** Killing %s *****************" % name)
  platform_name = EXECUTABLE_NAMES[os_name][name]
  pids = GetPids(platform_name)
  for pid in pids:
    PrintPidInfo(pid);
    if (os_name == "win32"):
      KillWindows(pid)
    else:
      KillPosix(pid)
    print("Killed pid: %s" % pid)
  if (len(pids) == 0):
    print("  No %s processes found." % name)
  return len(pids)

def KillBrowsers():
  status = Kill('firefox')
  status += Kill('chrome')
  status += Kill('iexplore')
  status += Kill('safari')
  status += Kill('content_shell')
  return status

def KillVCSystems():
  status = Kill('git')
  status += Kill('svn')
  return status

def KillDart():
  status = Kill("dart")
  return status

def KillEditor():
  status = Kill("editor")
  if os_name == "linux":
    # it is important to kill java after editor on linux
    status += Kill("java")
    status += Kill("eggplant")
  return status

def Main():
  options = GetOptions()
  status = 0
  if (options.kill_dart):
    status += KillDart();
  if (options.kill_vc):
    status += KillVCSystems();
  if (options.kill_browsers):
    status += KillBrowsers()
  if (options.kill_editor):
    status += KillEditor()
  return status

if __name__ == '__main__':
  sys.exit(Main())
