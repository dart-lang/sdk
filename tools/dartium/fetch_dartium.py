#!/usr/bin/python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A script to fetch and build dartium branches into an empty directory.
#
# Main dev directories - src, src/third_party/WebKit, src/dart - are checked out
# via git.  A custom_deps entry is added to the .gclient file.
#
# Note: this checkout is not suitable for git merges across branches
# (e.g., upstream merges).  It's a shallow checkout without history.
#
# Usage:
# .../fetch_dartium.py --branch=[trunk|bleeding_edge|dartium_integration|1.4|...]
#    --path=path [--build]
#
# Default branch is bleeding_edge.  The path must be created by this script.

import optparse
import os
import os.path
import re
import shutil
import subprocess
import sys

def Run(cmd, path = '.', isPiped = False):
  print 'Running in ' + path + ': ' + ' '.join(cmd)
  cwd = os.getcwd()
  os.chdir(path)
  if isPiped:
    p = subprocess.Popen(cmd, stdout = subprocess.PIPE)
  else:
    p = subprocess.Popen(cmd)
  os.chdir(cwd)
  return p

def RunSync(cmd):
  print "\n[%s]\n$ %s" % (os.getcwd(), " ".join(cmd))
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = pipe.communicate()
  if pipe.returncode == 0:
    return output[0]
  else:
    print output[1]
    print "FAILED. RET_CODE=%d" % pipe.returncode
    sys.exit(pipe.returncode)


def main():
  option_parser = optparse.OptionParser()
  option_parser.add_option('', '--branch', help="Checkout a branch of Dartium, e.g., [bleeding_edge|dartium_integration|trunk|1.4]",
                           action="store", dest="branch", default="bleeding_edge")
  option_parser.add_option('', '--build', help="Compile",
                           action="store_true", dest="build")
  option_parser.add_option('', '--path', help="Path to checkout to",
                           action="store", dest="path", default=None)
  options, args = option_parser.parse_args()

  path = options.path
  if not path:
    print 'Please set a path'
    exit(1)
  path = os.path.expanduser(path)
  if os.path.isfile(path) or os.path.isdir(path):
    print 'Path %s already exists' % path
  os.mkdir(path)
  os.chdir(path)

  if options.branch != 'trunk':
    branch = 'branches/' + options.branch
  else:
    branch = 'trunk'
  deps_path = 'https://dart.googlecode.com/svn/%s/deps/dartium.deps' % branch

  Run(['gclient', 'config', deps_path]).wait()

  # Mark chrome, blink, and dart as custom. We'll check them out separately
  # via git.
  f = open('.gclient', 'r')
  lines = f.readlines()
  f.close()
  f = open('.gclient', 'w')
  for line in lines:
    f.write(line)
    if 'custom_deps' in line:
      f.write(
        '      "src": None,\n'
        '      "src/third_party/WebKit": None,\n'
        '      "src/dart": None,\n'
        )
  f.close()

  # Find branches from the DEPS file.
  DEPS = RunSync(['svn', 'cat', deps_path + '/DEPS'])
  chrome_base = 'svn://svn.chromium.org/'
  chrome_branch = re.search('dartium_chromium_branch":\s*"(.+)"', DEPS).group(1)
  blink_branch = re.search('dartium_webkit_branch":\s*"(.+)"', DEPS).group(1)
  dart_base = 'https://dart.googlecode.com/svn/'
  dart_branch = re.search('dart_branch":\s*"(.+)"', DEPS).group(1)

  chrome_url = chrome_base + chrome_branch
  blink_url = chrome_base + blink_branch
  dart_url =  dart_base + dart_branch + '/dart'

  # Fetch dart, chrome, and blink via git-svn and everything else via
  # gclient sync.
  blink_fetch = Run(['git', 'svn', 'clone', '-rHEAD', blink_url, 'blink'])
  dart_fetch = Run(['git', 'svn', 'clone', '-rHEAD', dart_url, 'dart'])
  Run(['git', 'svn', 'clone', '-rHEAD', chrome_url, 'src']).wait()
  sync = Run(['gclient', 'sync', '--nohooks'])
  ps = [blink_fetch, dart_fetch, sync]

  # Spin until everything is done.
  while True:
    ps_status = [p.poll() for p in ps]
    if all([x is not None for x in ps_status]):
      break

  # Move blink and dart to the right locations.
  webkit_relative_path = os.path.join('src', 'third_party', 'WebKit')
  if os.path.isdir(webkit_relative_path):
    shutil.rmtree(webkit_relative_path)
  Run(['mv', 'blink', webkit_relative_path]).wait()
  dart_relative_path = os.path.join('src', 'dart')
  if os.path.isdir(dart_relative_path):
    shutil.rmtree(dart_relative_path)
  Run(['mv', 'dart', dart_relative_path]).wait()
  os.chdir('src')

  # Sync again and runhooks.
  Run(['gclient', 'sync']).wait()
  Run(['gclient', 'runhooks']).wait()

  # Build if requested.
  if options.build:
    Run([os.path.join('.', 'dart', 'tools', 'dartium', 'build.py'), '--mode=Release'])

if '__main__' == __name__:
  main()
