# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This python script creates a version string in a C++ file.

import os
import pwd
import sys
import subprocess
from os.path import join
import time
from optparse import OptionParser

def getVersionPart(version_file, part):
  proc = subprocess.Popen(['awk',
                           '$1 == "%s" {print $2}' % (part),
                           version_file],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT)
  return proc.communicate()[0].split('\n')[0]

def getRevision():
  is_svn = True
  if os.path.exists('.svn'):
    cmd = ['svn', 'info']
  else:
    cmd = ['git', 'svn', 'info']
  proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
  return proc.communicate()[0].split('\n')[4].split(' ')[1]
  
def makeVersionString(version_file):
  major = getVersionPart(version_file, 'MAJOR')
  minor = getVersionPart(version_file, 'MINOR')
  build = getVersionPart(version_file, 'BUILD')
  patch = getVersionPart(version_file, 'PATCH')
  revision = getRevision()
  user = pwd.getpwuid(os.getuid())[0]
  return '%s.%s.%s.%s_%s_%s' % (major, minor, build, patch, revision, user)

def makeFile(output_file, input_file, version_file):
  version_cc_text = open(input_file).read()
  version_cc_text = version_cc_text.replace("{{VERSION_STR}}",
                                            makeVersionString(version_file))
  version_cc_text = version_cc_text.replace("{{BUILD_TIME}}",
                                            time.ctime(time.time()))
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
  sys.exit(main(sys.argv))
