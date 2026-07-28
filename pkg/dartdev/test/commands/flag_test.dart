// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:dartdev/src/core.dart';
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
  // For each command and subcommand, assert that the name is in kebab-case,
  // the description is not empty, doesn't have trailing white space, and
  // ends with a period.
  test('description and name formatting', () {
    void validateCommand(String commandKey, Command<int> command) {
      if (command is! DartdevCommand) {
        return;
      }
      expect(commandKey, isNotEmpty);
      if (!command.aliases.contains(commandKey)) {
        expect(
          commandKey,
          matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
          reason: 'Command "$commandKey" name is not kebab-case.',
        );
      }
      expect(
        commandKey,
        contains(RegExp(r'[a-z]')),
        reason: 'Command "$commandKey" name must contain at least one letter.',
      );
      expect(
        command.description,
        isNotEmpty,
        reason: 'Command "$commandKey" description is empty.',
      );
      expect(
        command.description.split('\n').first,
        endsWith('.'),
        reason: 'Command "$commandKey" description must end with a period.',
      );
      expect(
        command.description.trim(),
        equals(command.description),
        reason: 'Command "$commandKey" description must not have leading/trailing whitespace.',
      );

      command.subcommands.forEach(validateCommand);
    }

    DartdevRunner(['--suppress-analytics']).commands.forEach(validateCommand);
  });

  // Assert that all found usageLineLengths are the same and null
  test('argParser usageLineLength', () {
    DartdevRunner(['--suppress-analytics']).commands.forEach((
      String commandKey,
      Command<int> command,
    ) {
      if (command.name != 'help' &&
          command.name != 'format' &&
          command.name != 'pub' &&
          command.name != 'test' &&
          command.name != 'mcp-server') {
        expect(
          command.argParser.usageLineLength,
          stdout.hasTerminal ? stdout.terminalColumns : null,
        );
      } else if (command.name == 'pub') {
        // 'pub' comes from package:pub which defaults usageLineLength to 80
        // when stdout.hasTerminal is false
        //(see https://github.com/dart-lang/pub/issues/2700).
        expect(
          command.argParser.usageLineLength,
          stdout.hasTerminal ? stdout.terminalColumns : 80,
        );
      } else {
        expect(command.argParser.usageLineLength, isNull);
      }
    });
  });
}

void help() {
  late TestProject p;

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
    expect(
      result.stdout,
      contains('The following options are only used for VM development'),
    );
  });

  test('--help -v', () async {
    p = project();
    var result = await p.run(['--help', '-v']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      contains('The following options are only used for VM development'),
    );
  });

  test('print Dart CLI help on usage error', () async {
    p = project();
    var result = await p.run(['---help']);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('Could not find an option named "---help"'));
    expectUsage(result.stderr);
    expect(result.stdout, isEmpty);
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
    expect(
      result.stdout,
      contains('Usage: dart [vm-options] <command|dart-file> [arguments]'),
    );
  });

  test('help -v', () async {
    p = project();
    var result = await p.run(['help', '-v']);

    expect(result.exitCode, 0);
    expect(
      result.stdout,
      contains('Usage: dart [vm-options] <command|dart-file> [arguments]'),
    );
  });
}

void invalidFlags() {
  late TestProject p;

  test('Regress #49437', () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/49437
    p = project();
    final result = await p.run(['-no-load-cse', 'hello.dart']);
    expect(result.exitCode, 64);
    expect(result.stdout, isNot(contains(DartdevRunner.dartdevDescription)));
    expectUsage(result.stderr);
  });
}
