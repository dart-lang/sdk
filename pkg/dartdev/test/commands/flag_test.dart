// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('command', command, timeout: longTimeout);
  group('flag', help, timeout: longTimeout);
}

void command() {
  // For each command description, assert that the values are not empty, don't
  // have trailing white space and end with a period.
  test('description formatting', () {
    DartdevRunner(['--disable-dartdev-analytics'])
        .commands
        .forEach((String commandKey, Command command) {
      expect(commandKey, isNotEmpty);
      expect(command.description, isNotEmpty);
      expect(command.description.split('\n').first, endsWith('.'));
      expect(command.description.trim(), equals(command.description));
    });
  });

  // Assert that all found usageLineLengths are the same and null
  test('argParser usageLineLength isNull', () {
    DartdevRunner(['--disable-dartdev-analytics'])
        .commands
        .forEach((String commandKey, Command command) {
      if (command.argParser != null) {
        expect(command.argParser.usageLineLength, isNull);
      }
    });
  });

  test('enable experiments flag is supported', () {
    final args = [
      '--disable-dartdev-analytics',
      '--enable-experiment=non-nullable'
    ];
    final runner = DartdevRunner(args);
    ArgResults results = runner.parse(args);
    expect(results['enable-experiment'], isNotEmpty);
    expect(results['enable-experiment'].first, 'non-nullable');
  });
}

void help() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('--help', []);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(DartdevRunner.dartdevDescription));
    expect(result.stdout,
        contains('Usage: dart [<vm-flags>] <command|dart-file> [<arguments>]'));
    expect(result.stdout, contains('Global options:'));
    expect(result.stdout, contains('Available commands:'));
    expect(result.stdout, contains('analyze '));
    expect(result.stdout, contains('create '));
    expect(result.stdout, contains('compile '));
    expect(result.stdout, contains('format '));
    expect(result.stdout, contains('migrate '));
  });

  test('--help --verbose', () {
    p = project();
    var result = p.runSync('--help', ['--verbose']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('migrate '));
  });

  test('--help -v', () {
    p = project();
    var result = p.runSync('--help', ['-v']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('migrate '));
  });
}
