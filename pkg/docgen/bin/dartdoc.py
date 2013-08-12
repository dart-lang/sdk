#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file. 

""" Run this script to generate documentation for a directory and serve
  the results to localhost for viewing in the browser.
"""

import argparse
import os
from os.path import join, dirname, abspath, exists
import platform
import subprocess
import sys
sys.path.append(abspath(join(dirname(__file__), '../../../tools')))
import utils
from upload_sdk import ExecuteCommand

DIRECTORY = abspath(dirname(__file__))
DART = join(DIRECTORY, '../../../%s/%s/dart-sdk/bin/dart'
    % (utils.BUILD_ROOT[utils.GuessOS()], utils.GetBuildConf('release',
    utils.GuessArchitecture())))
PUB = join(DIRECTORY, '../../../sdk/bin/pub')
DART2JS = join(DIRECTORY, '../../../sdk/bin/dart2js')
PACKAGE_ROOT = join(DART[:-(len('dart'))], '../../packages/')

def SetPackageRoot(path):
  global PACKAGE_ROOT
  if exists(path):
    PACKAGE_ROOT = abspath(path)

def GetOptions():
  parser = argparse.ArgumentParser(description='Runs docgen on the specified '
    'library and displays the resulting documentation in the browser')
  parser.add_argument('--package-root', dest='pkg_root',
    help='The package root for dart (default is in the build directory).',
    action='store', default=PACKAGE_ROOT)
  docgen = [DART, '--checked', '--package-root=' + PACKAGE_ROOT,
    join(DIRECTORY, 'docgen.dart'), '-h']
  process = subprocess.Popen(docgen, stdout=subprocess.PIPE)
  out, error = process.communicate()
  parser.add_argument('--options', help=out)
  parser.add_argument('--gae-sdk',
    help='The path to the Google App Engine SDK.')
  options = parser.parse_args()
  SetPackageRoot(options.pkg_root)
  return options

def main():
  options = GetOptions()
  docgen = [DART, '--checked', '--package-root=' + PACKAGE_ROOT,
    join(DIRECTORY, 'docgen.dart')]
  docgen.extend(options.options.split())
  ExecuteCommand(docgen)
  ExecuteCommand(['git', 'clone', '-b', 'dev',
   'git://github.com/dart-lang/dartdoc-viewer.git'])
  ExecuteCommand(['mv', 'docs', 'dartdoc-viewer/client/local'])
  os.chdir('dartdoc-viewer/client/')
  subprocess.call([PUB, 'install'])
  subprocess.call([DART, 'build.dart'])
  subprocess.call([DART2JS, '-o', 'web/out/index.html_bootstrap.dart.js', 
    './web/out/index.html_bootstrap.dart'])
  server = subprocess.Popen(['python', 
    join(abspath(join(dirname(__file__), options.gae_sdk)), 'dev_appserver.py'),
    '..'])
  print("\nPoint your browser to the address of the 'default' server below.")
  raw_input("Press <RETURN> to terminate the server.\n\n")
  server.terminate()
  os.chdir('../..')
  subprocess.call(['rm', '-rf', 'dartdoc-viewer'])

if __name__ == '__main__':
  main()
