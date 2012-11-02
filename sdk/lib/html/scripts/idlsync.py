#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import os
import os.path
import re
import shutil
import subprocess
import sys

SCRIPT_PATH = os.path.abspath(os.path.dirname(__file__))
DART_PATH = os.path.abspath(os.path.join(SCRIPT_PATH, '..', '..', '..'))

# Path to install latest IDL.
IDL_PATH = os.path.join(DART_PATH, 'third_party', 'WebCore')

# Whitelist of files to keep.
WHITELIST = [
    r'LICENSE(\S+)',
    r'(\S+)\.idl']

# README file to generate.
README = os.path.join(IDL_PATH, 'README')

# SVN URL to latest Dartium version of WebKit.
DEPS = 'http://dart.googlecode.com/svn/branches/bleeding_edge/deps/dartium.deps/DEPS'
URL_PATTERN = r'"dartium_webkit_trunk": "(\S+)",'
REV_PATTERN = r'"dartium_webkit_revision": "(\d+)",'
WEBCORE_SUBPATH = 'Source/WebCore'


def RunCommand(cmd):
  """Executes a shell command and return its stdout."""
  print ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = pipe.communicate()
  if pipe.returncode == 0:
    return output[0]
  else:
    print output[1]
    print 'FAILED. RET_CODE=%d' % pipe.returncode
    sys.exit(pipe.returncode)


def GetWebkitSvnRevision():
  """Returns a tuple with the (dartium webkit repo, latest revision)."""
  deps = RunCommand(['svn', 'cat', DEPS])
  url = re.search(URL_PATTERN, deps).group(1)
  revision = re.search(REV_PATTERN, deps).group(1)
  return (url, revision)


def RefreshIDL(url, revision):
  """Refreshes the IDL to specific WebKit url / revision."""
  cwd = os.getcwd()
  try:
    shutil.rmtree(IDL_PATH)
    os.chdir(os.path.dirname(IDL_PATH))
    RunCommand(['svn', 'export', '-r', revision, url + '/' + WEBCORE_SUBPATH])
  finally:
    os.chdir(cwd)


def PruneExtraFiles():
  """Removes all files that do not match the whitelist."""
  pattern = re.compile(reduce(lambda x,y: '%s|%s' % (x,y),
                              map(lambda z: '(%s)' % z, WHITELIST)))
  for (root, dirs, files) in os.walk(IDL_PATH, topdown=False):
    for f in files:
      if not pattern.match(f):
        os.remove(os.path.join(root, f))
    for d in dirs:
      dirpath = os.path.join(root, d)
      if not os.listdir(dirpath):
        shutil.rmtree(dirpath)


def ParseOptions():
  parser = optparse.OptionParser()
  parser.add_option('--revision', '-r', dest='revision',
                    help='Revision to install', default=None)
  args, _ = parser.parse_args()
  return args.revision


def GenerateReadme(url, revision):
  readme = """This directory contains a copy of WebKit/WebCore IDL files.
See the attached LICENSE-* files in this directory.

Please do not modify the files here.  They are periodically copied
using the script: $DART_ROOT/lib/dom/scripts/%(script)s

The current version corresponds to:
URL: %(url)s
Current revision: %(revision)s
""" % {
    'script': os.path.basename(__file__),
    'url': url,
    'revision': revision }
  out = open(README, 'w')
  out.write(readme)
  out.close()


def main():
  revision = ParseOptions()
  url, latest = GetWebkitSvnRevision()
  if not revision:
    revision = latest
  RefreshIDL(url, revision)
  PruneExtraFiles()
  GenerateReadme(url, revision)


if __name__ == '__main__':
  main()
