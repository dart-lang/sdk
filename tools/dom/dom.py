#!/usr/bin/python

# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A script which makes it easy to execute common DOM-related tasks

import os
import subprocess
import sys
from sys import argv

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
import utils

dart_out_dir = utils.GetBuildRoot(utils.GuessOS(), 'release', 'ia32')
if utils.IsWindows():
    dart_bin = os.path.join(dart_out_dir, 'dart.exe')
else:
    dart_bin = os.path.join(dart_out_dir, 'dart')

dart_dir = os.path.abspath(
    os.path.join(
        os.path.dirname(os.path.realpath(__file__)), os.path.pardir,
        os.path.pardir))


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
        os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dartanalyzer'),
        os.path.join('tests', 'html', 'element_test.dart'),
        '--dart-sdk=sdk',
        '--show-package-warnings',
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


def docs():
    return call([
        os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dart'),
        '--package-root=%s' % os.path.join(dart_out_dir, 'packages/'),
        os.path.join('tools', 'dom', 'docs', 'bin', 'docs.dart'),
    ])


def test_docs():
    return call([
        os.path.join('tools', 'test.py'), '--mode=release', '--checked', 'docs'
    ])


def compile_dart2js(dart_file, checked):
    out_file = dart_file + '.js'
    dart2js_path = os.path.join(dart_out_dir, 'dart-sdk', 'bin', 'dart2js')
    args = [dart2js_path, dart_file, '--library-root=sdk/', '-o%s' % out_file]
    if checked:
        args.append('--checked')

    call(args)
    return out_file


def gen():
    os.chdir(os.path.join('tools', 'dom', 'scripts'))
    result = call([
        os.path.join(os.getcwd(), 'dartdomgenerator.py'), '--rebuild',
        '--parallel', '--systems=htmldart2js,htmldartium'
    ])
    os.chdir(os.path.join('..', '..', '..'))
    return result


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
        '-c',
        'dart2js',
        '-r',
        browser,
        '--mode=release',
        '--checked',
        '--arch=ia32',
        '-v',
    ]
    if argv:
        cmd.append(argv.pop(0))
    else:
        print(
            'Test commands should be followed by tests to run. Defaulting to html'
        )
        cmd.append('html')
    return call(cmd)


def test_server():
    start_test_server(5400, os.path.join('out', 'ReleaseX64'))


def test_server_dartium():
    start_test_server(5500, os.path.join('..', 'out', 'Release'))


def start_test_server(port, build_directory):
    print(
        'Browse tests at '
        '\033[94mhttp://localhost:%d/root_build/generated_tests/\033[0m' % port)
    return call([
        utils.CheckedInSdkExecutable(),
        os.path.join('tools', 'testing', 'dart', 'http_server.dart'),
        '--port=%d' % port,
        '--crossOriginPort=%d' % (port + 1), '--network=0.0.0.0',
        '--build-directory=%s' % build_directory
    ])


def call(args):
    print ' '.join(args)
    pipe = subprocess.Popen(
        args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = pipe.communicate()
    if output:
        print output
    if error:
        print error
    return pipe.returncode


commands = {
    'analyze': [analyze, 'Run the dart analyzer'],
    'build': [build, 'Build dart in release mode'],
    'dart2js': [dart2js, 'Run dart2js on the .dart file specified'],
    'docs': [docs, 'Generates docs.json'],
    'gen': [gen, 'Re-generate DOM generated files (run go.sh)'],
    'size_check': [size_check, 'Check the size of dart2js compiled Swarm'],
    'test_docs': [test_docs, 'Tests docs.dart'],
    'test_chrome': [
        test_chrome, 'Run tests in checked mode in Chrome.\n'
        '\t\tOptionally provide name of test to run.'
    ],
    # TODO(antonm): fix option name.
    'test_drt': [
        test_drt, 'Run tests in checked mode in content shell.\n'
        '\t\tOptionally provide name of test to run.'
    ],
    'test_ff': [
        test_ff, 'Run tests in checked mode in Firefox.\n'
        '\t\tOptionally provide name of test to run.'
    ],
    'test_server': [
        test_server, 'Starts the testing server for manually '
        'running browser tests.'
    ],
    'test_server_dartium': [
        test_server_dartium, 'Starts the testing server for '
        'manually running browser tests from a dartium enlistment.'
    ],
}


def main():
    success = True
    argv.pop(0)

    if not argv:
        help()
        success = False

    while (argv):
        # Make sure that we're always rooted in the dart root folder.
        os.chdir(dart_dir)
        command = argv.pop(0)

        if not command in commands:
            help()
            success = False
            break
        returncode = commands[command][0]()
        success = success and not bool(returncode)

    sys.exit(not success)


if __name__ == '__main__':
    main()
