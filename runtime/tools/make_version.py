# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a version string in a C++ file.

import os
import sys
import subprocess
import platform
import getpass
from os.path import join
import time
from optparse import OptionParser

def debugLog(message):
  print >> sys.stderr, message
  sys.stderr.flush()


def getVersionPart(version_file, part):
  command = ['awk', '$1 == "%s" {print $2}' % (part), version_file]
  debugLog("Getting version part: %s Running command %s" % (part, command))
  proc = subprocess.Popen(command,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT)
  result = proc.communicate()[0].split('\n')[0]
  debugLog("Got result: %s" % result)
  return result

def getRevision():
  debugLog("Getting revision")
  is_svn = True
  if os.path.exists('.svn'):
    debugLog("Using svn to get revision")
    cmd = ['svn', 'info']
  else:
    git_proc = subprocess.Popen(
        ['git', 'branch', '-r'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if 'git-svn' in git_proc.communicate()[0]:
      debugLog("Using git svn to get revision")
      cmd = ['git', 'svn', 'info']
    else:
      # Cannot get revision because we are not in svn or
      # git svn checkout.
      debugLog("Could not get revision: not an svn or git-svn checkout?")
      return ''
  debugLog("Running command to get revision: %s" % cmd)
  proc = subprocess.Popen(cmd,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  revision = proc.communicate()[0].split('\n')[4].split(' ')[1]
  debugLog("Got revision: %s" % revision)
  return revision

def makeVersionString(version_file):
  id = platform.system()
  if id == 'Windows' or id == 'Microsoft':
    return '0.0.0.0'
  major = getVersionPart(version_file, 'MAJOR')
  minor = getVersionPart(version_file, 'MINOR')
  build = getVersionPart(version_file, 'BUILD')
  patch = getVersionPart(version_file, 'PATCH')
  revision = getRevision()
  user = getpass.getuser()
  version_string = '%s.%s.%s.%s_%s_%s' % (major,
                                          minor,
                                          build,
                                          patch,
                                          revision,
                                          user)
  debugLog("Returning version string: %s " % version_string)
  return version_string

def makeFile(output_file, input_file, version_file):
  debugLog("Making version file")
  version_cc_text = open(input_file).read()
  version_string = makeVersionString(version_file)
  debugLog("Writing version to version_cc file: %s" % version_string)
  version_cc_text = version_cc_text.replace("{{VERSION_STR}}",
                                            version_string)
  version_time = time.ctime(time.time())
  debugLog("Writing time to version_cc file: %s" % version_time)
  version_cc_text = version_cc_text.replace("{{BUILD_TIME}}",
                                            version_time)
  open(output_file, 'w').write(version_cc_text)
  return True


def main(args):
  try:
    # Parse input.
    parser = OptionParser()
    parser.add_option("--output",
                      action="store", type="string",
                      help="output file name")
    parser.add_option("--input",
                      action="store", type="string",
                      help="input template file")
    parser.add_option("--version",
                      action="store", type="string",
                      help="version file")

    (options, args) = parser.parse_args()
    if not options.output:
      sys.stderr.write('--output not specified\n')
      return -1
    if not len(options.input):
      sys.stderr.write('--input not specified\n')
      return -1

    files = [ ]
    for arg in args:
      files.append(arg)

    if not makeFile(options.output,
                    options.input,
                    options.version):
      return -1

    return 0
  except Exception, inst:
    sys.stderr.write('make_version.py exception\n')
    sys.stderr.write(str(inst))
    sys.stderr.write('\n')
    return -1

if __name__ == '__main__':
  debugLog('starting make_version.py')
  exit_code = main(sys.argv)
  debugLog('exiting make_version.py (exit code: %s)' % exit_code)
  sys.exit(exit_code)
