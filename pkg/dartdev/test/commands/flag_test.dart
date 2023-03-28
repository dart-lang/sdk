// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  initGlobalState();
  group('command', command, timeout: longTimeout);
  group('flag', help, timeout: longTimeout);
  group('invalid flags', invalidFlags, timeout: longTimeout);
}

void expectUsage(String msg) {
  expect(msg, contains('Usage: dart <command|dart-file> [arguments]'));
  expect(msg, contains('Global options:'));
  expect(msg, contains('Available commands:'));
  expect(msg, contains('analyze '));
  expect(msg, contains('create '));
  expect(msg, contains('compile '));
  expect(msg, contains('format '));
}

void command() {
  // For each command description, assert that the values are not empty, don't
  // have trailing white space and end with a period.
  test('description formatting', () {
    DartdevRunner(['--suppress-analytics'])
        .commands
        .forEach((String commandKey, Command command) {
      expect(commandKey, isNotEmpty);
      expect(command.description, isNotEmpty);
      expect(command.description.split('\n').first, endsWith('.'));
      expect(command.description.trim(), equals(command.description));
    });
  });

  // Assert that all found usageLineLengths are the same and null
  test('argParser usageLineLength', () {
    DartdevRunner(['--suppress-analytics'])
        .commands
        .forEach((String commandKey, Command command) {
      if (command.name != 'help' &&
          command.name != 'format' &&
          command.name != 'pub' &&
          command.name != 'test') {
        expect(command.argParser.usageLineLength,
            stdout.hasTerminal ? stdout.terminalColumns : null);
      } else if (command.name == 'pub') {
        // TODO(sigurdm): Avoid special casing here.
        // https://github.com/dart-lang/pub/issues/2700
        expect(command.argParser.usageLineLength,
            stdout.hasTerminal ? stdout.terminalColumns : 80);
      } else {
        expect(command.argParser.usageLineLength, isNull);
      }
    });
  });
}

void help() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('--help', () async {
    p = project();
    var result = await p.run(['--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(DartdevRunner.dartdevDescription));
    expectUsage(result.stdout);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['--help', '--verbose']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout,
        contains('The following options are only used for VM development'));
  });

  test('--help -v', () async {
    p = project();
    var result = await p.run(['--help', '-v']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout,
        contains('The following options are only used for VM development'));
  });

  test('print Dart CLI help on usage error', () async {
    p = project();
    var result = await p.run(['---help']);
    expect(result.exitCode, 255);
    expect(result.stdout, contains(DartdevRunner.dartdevDescription));
    expect(result.stderr, isEmpty);
  });

  test('print VM help on usage error when --disable-dart-dev is provided',
      () async {
    p = project();
    var result = await p.run(['---help', '--disable-dart-dev']);
    expect(result.exitCode, 255);
    expect(result.stdout, isNot(contains(DartdevRunner.dartdevDescription)));
    expect(result.stderr, isEmpty);
  });

  test('help', () async {
    p = project();
    var result = await p.run(['help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(DartdevRunner.dartdevDescription));
    expectUsage(result.stdout);
  });

  test('help --verbose', () async {
    p = project();
    var result = await p.run(['help', '--verbose']);

    expect(result.exitCode, 0);
    expect(result.stdout,
        contains('Usage: dart [vm-options] <command|dart-file> [arguments]'));
  });

  test('help -v', () async {
    p = project();
    var result = await p.run(['help', '-v']);

    expect(result.exitCode, 0);
    expect(result.stdout,
        contains('Usage: dart [vm-options] <command|dart-file> [arguments]'));
  });
}

void invalidFlags() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('Regress #49437', () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/49437
    p = project();
    final result = await p.run(['-no-load-cse', 'hello.dart']);
    expect(result.exitCode, 64);
    expect(result.stdout, isNot(contains(DartdevRunner.dartdevDescription)));
    expectUsage(result.stderr);
  });
}
