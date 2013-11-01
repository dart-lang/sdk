#!/usr/bin/env python
#
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run this script to generate documentation for a directory and serve
# the results to localhost for viewing in the browser.

import optparse
import os
from os.path import join, dirname, abspath, exists
import platform
import subprocess
import sys
sys.path.append(abspath(join(dirname(__file__), '../../../tools')))
import utils
from upload_sdk import ExecuteCommand

DIRECTORY = abspath(dirname(__file__))
DART_DIR = dirname(dirname(dirname(DIRECTORY)))
DART_EXECUTABLE = join(DART_DIR,
    '%s/%s/dart-sdk/bin/dart' % (utils.BUILD_ROOT[utils.GuessOS()],
    utils.GetBuildConf('release', utils.GuessArchitecture())))
PUB = join(DART_DIR, 'sdk/bin/pub')
DART2JS = join(DART_DIR, 'sdk/bin/dart2js')
PACKAGE_ROOT = join(dirname(dirname(dirname(DART_EXECUTABLE[:-(len('dart'))]))),
    'packages/')
EXCLUDED_PACKAGES = ['browser', 'html_import', 'mutation_observer',
    'pkg.xcodeproj', 'shadow_dom']


def SetPackageRoot(path):
  global PACKAGE_ROOT
  if exists(path):
    PACKAGE_ROOT = abspath(path)


def ParseArgs():
  parser = optparse.OptionParser(description='Generate documentation and '
    'display the resulting documentation in the browser.')
  parser.add_option('--full-docs-only', '-d', dest='just_docs',
      action='store_true', default=False,
      help='Only generate documentation, no html output. (If no other '
      'options are specified, will document the SDK and all packages in the '
      'repository.)')
  parser.add_option('--package-root', '-p', dest='pkg_root',
      help='The package root for dart (default is in the build directory).',
      action='store', default=PACKAGE_ROOT)
  parser.add_option('--docgen-options', '-o',
      dest='docgen_options', help='Options to pass to docgen. If no file to '
      'document is specified, by default we generate all documenation for the '
      'SDK and all packages in the dart repository in JSON.',
      default='--json')
  parser.add_option('--gae-sdk',
      help='The path to the Google App Engine SDK. Defaults to the top level '
      'dart directory.', default=PACKAGE_ROOT)
  options, _ = parser.parse_args()
  SetPackageRoot(options.pkg_root)
  return options


def AddUserDocgenOptions(sdk_cmd, docgen_options, all_docs=False):
  '''Expand the command with user specified docgen options.'''
  specified_pkg = False
  remove_append = False
  append = '--append'
  for option in docgen_options:
    if '--package-root' in option:
      specified_pkg = True
    if option == append and all_docs:
      remove_append = True
  if remove_append:
    docgen_options.remove(append)
  if not specified_pkg:
    sdk_cmd.extend(['--package-root=%s' % PACKAGE_ROOT])
  sdk_cmd.extend(docgen_options)
  return sdk_cmd


def GenerateAllDocs(docgen_options):
  '''Generate all documentation for the SDK and all packages in the repository.
  We first attempt to run the quickest path to generate all docs, but if that
  fails, we fall back on a slower option.'''
  sdk_cmd = [DART_EXECUTABLE, 'docgen.dart', '--parse-sdk']
  ExecuteCommand(AddUserDocgenOptions(sdk_cmd, docgen_options))

  doc_dir = join(DART_DIR, 'pkg')
  cmd_lst = [DART_EXECUTABLE, '--old_gen_heap_size=1024',
      '--package-root=%s' % PACKAGE_ROOT, 'docgen.dart', '--append']
  cmd_str = ' '.join(AddUserDocgenOptions(cmd_lst, docgen_options, True))
  # Try to run all pkg docs together at once as it's fastest.
  (return_code, _) = ExecuteCommandString('%s %s' % (cmd_str, doc_dir))
  if return_code != 0:
    # We failed to run all the pkg docs, so try to generate docs for each pkg
    # individually.
    failed_pkgs = []
    for directory in os.listdir(join(DART_DIR, 'pkg')):
      doc_dir = join(DART_DIR, 'pkg', directory)
      if (directory not in EXCLUDED_PACKAGES and
          os.path.isdir(doc_dir)):
        (return_code, output) = ExecuteCommandString('%s %s' % (cmd_str,
            doc_dir))
        if return_code != 0:
          failed_pkgs += [directory]
    print ('Generated documentation, but failed to generate documentation for '
        'the following packages, please investigate: %r' % failed_pkgs)


def ExecuteCommandString(cmd):
  '''A variant of the ExecuteCommand function that specifically executes a
  particular command string in the shell context. When you execute a string, you
  must execute in the shell.'''
  print 'Executing: %s ' % cmd
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
      shell=True)
  output = pipe.communicate()
  return (pipe.returncode, output)


def main():
  options = ParseArgs()
  generate_all_docs = True
  docgen_options = []
  if options.docgen_options:
    # If the user specified particular files to generate docs for, then don't
    # generate docs for everything.
    docgen_options = options.docgen_options.split()
    last_option = docgen_options[-1]
    if '=' not in last_option and exists(last_option):
      generate_all_docs = False
      docgen = [DART_EXECUTABLE, '--checked',
          '--package-root=' + PACKAGE_ROOT, join(DIRECTORY, 'docgen.dart')]
      docgen.extend(options.options.split())
      ExecuteCommand(docgen)
  if generate_all_docs:
    GenerateAllDocs(docgen_options)
  if not options.just_docs:
    cwd = os.getcwd()
    try:
      ExecuteCommand(['git', 'clone', '-b', 'master',
       'git://github.com/dart-lang/dartdoc-viewer.git'])
      ExecuteCommand(['mv', 'docs', 'dartdoc-viewer/client/local'])
      os.chdir('dartdoc-viewer/client/')
      subprocess.call([PUB, 'install'])
      subprocess.call([DART_EXECUTABLE, 'deploy.dart'])
      server = subprocess.Popen(['python',
        join(abspath(join(dirname(__file__), options.gae_sdk)),
        'dev_appserver.py'), '..'])
      print (
        "\nPoint your browser to the address of the 'default' server below.")
      raw_input("Press <RETURN> to terminate the server.\n\n")
      server.terminate()
    finally:
      os.chdir(cwd)
      subprocess.call(['rm', '-rf', 'dartdoc-viewer'])

if __name__ == '__main__':
  main()
