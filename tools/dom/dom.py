#!/usr/bin/python

# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A script which makes it easy to execute common DOM-related tasks

import os
import subprocess
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
import utils

dart_out_dir = utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')
if utils.IsWindows():
  dart_bin = os.path.join(dart_out_dir, 'dart.exe')
else:
  dart_bin = os.path.join(dart_out_dir, 'dart')

def help():
  print('Helper script to make it easy to perform common tasks encountered '
     'during the life of a Dart DOM developer.\n'
     '\n'
     'For example, to re-generate DOM classes then run a specific test:\n'
     '  dom.py gen test_drt html/element_test\n'
     '\n'
     'Or re-generate DOM classes and run the Dart analyzer:\n'
     '  dom.py gen analyze\n')
  print('Commands: ')
  for cmd in sorted(commands.keys()):
    print('\t%s - %s' % (cmd, commands[cmd][1]))

def analyze():
  ''' Runs the dart analyzer. '''
  return call([
    os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dart_analyzer'),
    os.path.join('tests', 'html', 'element_test.dart'),
    '--dart-sdk', 'sdk',
    '--show-sdk-warnings',
  ])

def build():
  ''' Builds the Dart binary '''
  return call([
    os.path.join('tools', 'build.py'),
    '--mode=release',
    '--arch=ia32',
    'runtime',
  ])

def dart2js():
  compile_dart2js(argv.pop(0), True)

def dartc():
  return call([
    os.path.join('tools', 'test.py'),
    '-m',
    'release',
    '-c',
    'dartc',
    '-r',
    'none'
  ])

def docs():
  return call([
    os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dart'),
    '--package-root=%s' % os.path.join(dart_out_dir, 'packages/'),
    os.path.join('tools', 'dom', 'docs', 'bin', 'docs.dart'),
  ])

def test_docs():
  return call([
    os.path.join('tools', 'test.py'),
    '--mode=release',
    '--checked',
    'docs'
  ])

def compile_dart2js(dart_file, checked):
  out_file = dart_file + '.js'
  dart2js_path = os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dart2js')
  args = [
    dart2js_path,
    dart_file,
    '--library-root=sdk/',
    '--disallow-unsafe-eval',
    '-o%s' % out_file
  ]
  if checked:
    args.append('--checked')

  call(args)
  return out_file

def gen():
  os.chdir(os.path.join('tools', 'dom', 'scripts'))
  return call(os.path.join(os.getcwd(), 'go.sh'))

def http_server():
  print('Browse tests at '
      '\033[94mhttp://localhost:5400/root_build/generated_tests/\033[0m')
  return call([
    utils.DartBinary(),
    os.path.join('tools', 'testing', 'dart', 'http_server.dart'),
    '--port=5400',
    '--crossOriginPort=5401',
    '--network=0.0.0.0',
    '--build-directory=%s' % os.path.join('out', 'ReleaseIA32')
  ])

def size_check():
  ''' Displays the dart2js size of swarm. '''
  dart_file = os.path.join('samples', 'swarm', 'swarm.dart')
  out_file = compile_dart2js(dart_file, False)

  return call([
    'du',
    '-kh',
    '--apparent-size',
    out_file,
  ])

  os.remove(out_file)
  os.remove(out_file + '.deps')
  os.remove(out_file + '.map')

def test_ff():
  test_dart2js('ff', argv)

def test_drt():
  test_dart2js('drt', argv)

def test_chrome():
  test_dart2js('chrome', argv)

def test_dart2js(browser, argv):
  cmd = [
    os.path.join('tools', 'test.py'),
    '-c', 'dart2js',
    '-r', browser,
    '--mode=release',
    '--checked',
    '--arch=ia32',
    '-v',
  ]
  if argv:
    cmd.append(argv.pop(0))
  else:
    print(
        'Test commands should be followed by tests to run. Defaulting to html')
    cmd.append('html')
  return call(cmd)

def call(args):
  print ' '.join(args)
  pipe = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output, error = pipe.communicate()
  if output:
    print output
  if error:
    print error
  return pipe.returncode

def init_dir():
  ''' Makes sure that we're always rooted in the dart root folder.'''
  dart_dir = os.path.abspath(os.path.join(
      os.path.dirname(os.path.realpath(__file__)),
      os.path.pardir, os.path.pardir))
  os.chdir(dart_dir)

commands = {
  'analyze': [analyze, 'Run the dart analyzer'],
  'build': [build, 'Build dart in release mode'],
  'dart2js': [dart2js, 'Run dart2js on the .dart file specified'],
  'dartc': [dartc, 'Runs dartc in release mode'],
  'docs': [docs, 'Generates docs.json'],
  'gen': [gen, 'Re-generate DOM generated files (run go.sh)'],
  'size_check': [size_check, 'Check the size of dart2js compiled Swarm'],
  'test_docs': [test_docs, 'Tests docs.dart'],
  'test_chrome': [test_chrome, 'Run tests in checked mode in Chrome.\n'
      '\t\tOptionally provide name of test to run.'],
  'test_drt': [test_drt, 'Run tests in checked mode in DumpRenderTree.\n'
      '\t\tOptionally provide name of test to run.'],
  'test_ff': [test_ff, 'Run tests in checked mode in Firefox.\n'
      '\t\tOptionally provide name of test to run.'],
  'http_server': [http_server, 'Starts the testing server for manually '
      'running browser tests.'],
}

def main(argv):
  success = True
  argv.pop(0)

  if not argv:
    help()
    success = False

  while (argv):
    init_dir()
    command = argv.pop(0)

    if not command in commands:
      help();
      success = False
      break
    returncode = commands[command][0]()
    success = success and not bool(returncode)

  sys.exit(not success)

if __name__ == '__main__':
  main(sys.argv)
