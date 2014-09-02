#!/usr/bin/env python
#
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import optparse
import os.path
import re
import subprocess
import sys
import utils

# FIXME: integrate this helper script into the build instead of hardcoding
# these paths.
RESOURCE_AAR_PATTERN = 'content_shell_apk/resource_aar/*.aar'
CONTENT_SHELL_APK_AAR = 'content_shell_apk/content_shell_apk.aar'

SRC_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART_DIR = os.path.join(SRC_PATH, 'dart')
CHROME_VERSION_PATH = os.path.join(SRC_PATH, 'chrome', 'VERSION')

def main():
  parser = optparse.OptionParser()
  parser.add_option('--mode', dest='mode',
                    action='store', type='string',
                    help='Build mode (Debug or Release)')
  parser.add_option('--repo', action='store', type='string',
                    help='Local Maven repository (defaults to ~/.m2)')
  (options, args) = parser.parse_args()
  mode = options.mode
  version = GetVersion()
  if not (mode in ['debug', 'release']):
    raise Exception('Invalid build mode')

  mode = 'Debug' if mode == 'debug' else 'Release'

  build_root = os.path.join('out', mode)

  aars = glob.glob(os.path.join(build_root, RESOURCE_AAR_PATTERN))
  aars.append(os.path.join(build_root, CONTENT_SHELL_APK_AAR))

  flags = [
    '-DgroupId=org.dartlang',
    '-Dversion=%s' % version,
    '-Dpackaging=aar'
  ]
  if options.repo:
    flags.append('-DlocalRepositoryPath=%s' % options.repo)

  for aar_file in aars:
    artifact_id = os.path.splitext(os.path.basename(aar_file))[0]
    cmd = [
      'mvn',
      'install:install-file',
      '-Dfile=%s' % aar_file,
      '-DartifactId=%s' % artifact_id,
    ]
    cmd.extend(flags)
    utils.runCommand(cmd)

def GetVersion():
  version = GetChromeVersion()
  return '%d.%d.%d-%05d-%06d' % (
      version[0],
      version[1],
      version[2],
      version[3],
      GetDartSVNRevision())

def GetChromeVersion():
  version = []
  for line in file(CHROME_VERSION_PATH).readlines():
    version.append(int(line.strip().split('=')[1]))

  return version

def GetDartSVNRevision():
  # When building from tarball use tools/SVN_REVISION
  svn_revision_file = os.path.join(DART_DIR, 'tools', 'SVN_REVISION')
  try:
    with open(svn_revision_file) as fd:
      return int(fd.read())
  except:
    pass

  custom_env = dict(os.environ)
  custom_env['LC_MESSAGES'] = 'en_GB'
  p = subprocess.Popen(['svn', 'info'], stdout = subprocess.PIPE,
                       stderr = subprocess.STDOUT, shell = IsWindows(),
                       env = custom_env,
                       cwd = DART_DIR)
  output, _ = p.communicate()
  revision = ParseSvnInfoOutput(output)
  if revision:
    return int(revision)

  # Check for revision using git (Note: we can't use git-svn because in a
  # pure-git checkout, "git-svn anyCommand" just hangs!). We look an arbitrary
  # number of commits backwards (100) to get past any local commits.
  p = subprocess.Popen(['git', 'log', '-100'], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows(), cwd = DART_DIR)
  output, _ = p.communicate()
  revision = ParseGitInfoOutput(output)
  if revision:
    return int(revision)

  # In the rare off-chance that git log -100 doesn't have a svn repo number,
  # attempt to use "git svn info."
  p = subprocess.Popen(['git', 'svn', 'info'], stdout = subprocess.PIPE,
      stderr = subprocess.STDOUT, shell=IsWindows(), cwd = DART_DIR)
  output, _ = p.communicate()
  revision = ParseSvnInfoOutput(output)
  if revision:
    return int(revision)

  # Only fail on the buildbot in case of a SVN client version mismatch.
  user = GetUserName()
  return '0'

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

def IsWindows():
  return (sys.platform=='win32')

if __name__ == '__main__':
  main()
