// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/dartdev.dart';
import 'package:dartdev/src/events.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParserUtils', _argParserUtils);
  group('event constant', _constants);
}

void _argParserUtils() {
  test('getCommandStr help', () {
    expect(ArgParserUtils.getCommandStr(['help']), 'help');
    expect(ArgParserUtils.getCommandStr(['analyze', 'help']), 'help');
    expect(ArgParserUtils.getCommandStr(['help', 'analyze']), 'help');
    expect(ArgParserUtils.getCommandStr(['analyze', '-h']), 'help');
    expect(ArgParserUtils.getCommandStr(['analyze', '--help']), 'help');
  });

  test('getCommandStr command', () {
    expect(ArgParserUtils.getCommandStr(['analyze']), 'analyze');
    expect(ArgParserUtils.getCommandStr(['analyze', 'foo']), 'analyze');
    expect(ArgParserUtils.getCommandStr(['foo', 'bar']), '<unknown>');
    expect(ArgParserUtils.getCommandStr([]), '<unknown>');
    expect(ArgParserUtils.getCommandStr(['']), '<unknown>');
  });

  test('isHelp false', () {
    expect(ArgParserUtils.isHelp(null), isFalse);
    expect(ArgParserUtils.isHelp(''), isFalse);
    expect(ArgParserUtils.isHelp(' '), isFalse);
    expect(ArgParserUtils.isHelp('-help'), isFalse);
    expect(ArgParserUtils.isHelp('--HELP'), isFalse);
    expect(ArgParserUtils.isHelp('--Help'), isFalse);
    expect(ArgParserUtils.isHelp('Help'), isFalse);
    expect(ArgParserUtils.isHelp('HELP'), isFalse);
    expect(ArgParserUtils.isHelp('foo'), isFalse);
  });

  test('isHelp true', () {
    expect(ArgParserUtils.isHelp('help'), isTrue);
    expect(ArgParserUtils.isHelp('--help'), isTrue);
    expect(ArgParserUtils.isHelp('-h'), isTrue);
  });

  test('isFlag false', () {
    expect(ArgParserUtils.isFlag(null), isFalse);
    expect(ArgParserUtils.isFlag(''), isFalse);
    expect(ArgParserUtils.isFlag(' '), isFalse);
    expect(ArgParserUtils.isFlag('help'), isFalse);
    expect(ArgParserUtils.isFlag('_flag'), isFalse);
  });

  test('isFlag true', () {
    expect(ArgParserUtils.isFlag('-'), isTrue);
    expect(ArgParserUtils.isFlag('--'), isTrue);
    expect(ArgParserUtils.isFlag('--flag'), isTrue);
    expect(ArgParserUtils.isFlag('--help'), isTrue);
    expect(ArgParserUtils.isFlag('-h'), isTrue);
  });

  test('parseCommandFlags analyze', () {
    expect(
        ArgParserUtils.parseCommandFlags('analyze', [
          '-g',
          'analyze',
        ]),
        <String>[]);
    expect(
        ArgParserUtils.parseCommandFlags('analyze', [
          '-g',
          'analyze',
          '--one',
          '--two',
          '--three=bar',
          '-f',
          '--fatal-infos',
          '-h',
          'five'
        ]),
        <String>['--one', '--two', '--three', '-f', '--fatal-infos']);
  });

  test('parseCommandFlags trivial', () {
    expect(ArgParserUtils.parseCommandFlags('foo', []), <String>[]);
    expect(ArgParserUtils.parseCommandFlags('foo', ['']), <String>[]);
    expect(
        ArgParserUtils.parseCommandFlags('foo', ['bar', '-flag']), <String>[]);
    expect(
        ArgParserUtils.parseCommandFlags('foo', ['--global', 'bar', '-flag']),
        <String>[]);
    expect(ArgParserUtils.parseCommandFlags('foo', ['--global', 'fo', '-flag']),
        <String>[]);
    expect(
        ArgParserUtils.parseCommandFlags('foo', ['--global', 'FOO', '-flag']),
        <String>[]);
  });

  test('parseCommandFlags exclude help', () {
    expect(
        ArgParserUtils.parseCommandFlags(
            'analyze', ['-g', 'analyze', '--flag', '--help']),
        <String>['--flag']);
    expect(
        ArgParserUtils.parseCommandFlags(
            'analyze', ['-g', 'analyze', '--flag', '-h']),
        <String>['--flag']);
    expect(
        ArgParserUtils.parseCommandFlags(
            'analyze', ['-g', 'analyze', '--flag', 'help']),
        <String>['--flag']);
  });

  test('sanitizeFlag', () {
    expect(ArgParserUtils.sanitizeFlag(null), '');
    expect(ArgParserUtils.sanitizeFlag(''), '');
    expect(ArgParserUtils.sanitizeFlag('foo'), '');
    expect(ArgParserUtils.sanitizeFlag('--foo'), '--foo');
    expect(ArgParserUtils.sanitizeFlag('--foo=bar'), '--foo');
  });
}

void _constants() {
  test('allCommands', () {
    expect(allCommands, DartdevRunner([]).commands.keys.toList());
  });
}
