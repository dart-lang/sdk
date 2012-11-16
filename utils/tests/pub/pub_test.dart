// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';

final USAGE_STRING = """
    Pub is a package manager for Dart.

    Usage: pub command [arguments]

    Global options:
    -h, --help          Prints this usage information
        --version       Prints the version of Pub
        --[no-]trace    Prints a stack trace when an error occurs

    Available commands:
      help      display help information for Pub
      install   install the current package's dependencies
      update    update the current package's dependencies to the latest versions
      version   print Pub version

    Use "pub help [command]" for more information about a command.
    """;

final VERSION_STRING = '''
    Pub 0.0.0
    ''';

main() {
  test('running pub with no command displays usage', () =>
      runPub(args: [], output: USAGE_STRING));

  test('running pub with just --help displays usage', () =>
      runPub(args: ['--help'], output: USAGE_STRING));

  test('running pub with just -h displays usage', () =>
      runPub(args: ['-h'], output: USAGE_STRING));

  test('running pub with just --version displays version', () =>
      runPub(args: ['--version'], output: VERSION_STRING));

  test('an unknown command displays an error message', () {
    runPub(args: ['quylthulg'],
        error: '''
        Could not find a command named "quylthulg".
        Run "pub help" to see available commands.
        ''',
        exitCode: 64);
  });

  test('an unknown option displays an error message', () {
    runPub(args: ['--blorf'],
        error: '''
        Could not find an option named "blorf".
        Run "pub help" to see available options.
        ''',
        exitCode: 64);
  });

  test('an unknown command option displays an error message', () {
    // TODO(rnystrom): When pub has command-specific options, a more precise
    // error message would be good here.
    runPub(args: ['version', '--blorf'],
        error: '''
        Could not find an option named "blorf".
        Use "pub help" for more information.
        ''',
        exitCode: 64);
  });

  test('an unknown help command displays an error message', () {
    runPub(args: ['help', 'quylthulg'],
        error: '''
        Could not find a command named "quylthulg".
        Run "pub help" to see available commands.
        ''',
        exitCode: 64);
  });

  test('displays the current version', () =>
    runPub(args: ['version'], output: VERSION_STRING));
}
