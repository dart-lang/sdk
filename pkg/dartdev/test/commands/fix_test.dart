// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/commands/fix.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('fix', defineFix, timeout: longTimeout);
}

/// Enable to run from local source (useful in development).
const runFromSource = false;

void defineFix() {
  TestProject p;

  final bullet = Logger.standard().ansi.bullet;

  setUp(() => p = null);

  tearDown(() => p?.dispose());

  ProcessResult runFix(List<String> args, {String workingDir}) {
    if (runFromSource) {
      var binary = path.join(Directory.current.path, 'bin', 'dartdev.dart');
      return p.runSync([binary, 'fix', ...?args], workingDir: workingDir);
    }
    return p.runSync(['fix', ...args], workingDir: workingDir);
  }

  test('help', () {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = runFix([p.dirPath, '--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(FixCommand.disclaimer));
    expect(
        result.stdout, contains('Apply automated fixes to Dart source code.'));
  });

  test('none', () {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = runFix([p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(FixCommand.disclaimer));
    expect(
        result.stdout, contains('Apply automated fixes to Dart source code.'));
  });

  test('--apply (none)', () {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = runFix(['--apply', p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(FixCommand.disclaimer));
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('--apply (no args)', () {
    p = project(
      mainSrc: '''
var x = "";
''',
      analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
''',
    );

    var result = runFix(['--apply'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        stringContainsInOrder([
          'Applying fixes...',
          'lib${Platform.pathSeparator}main.dart',
          '  prefer_single_quotes $bullet 1 fix',
        ]));
  });

  test('--dry-run', () {
    p = project(
      mainSrc: '''
class A {
  String a() => "";
}

class B extends A {
  String a() => "";
}
''',
      analysisOptions: '''
linter:
  rules:
    - annotate_overrides
    - prefer_single_quotes
''',
    );
    var result = runFix(['--dry-run', '.'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        stringContainsInOrder([
          '3 proposed fixes in 1 file.',
          'lib${Platform.pathSeparator}main.dart',
          '  annotate_overrides $bullet 1 fix',
          '  prefer_single_quotes $bullet 2 fixes',
        ]));
  });

  test('--apply (.)', () {
    p = project(
      mainSrc: '''
var x = "";
''',
      analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
''',
    );
    var result = runFix(['--apply', '.'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        stringContainsInOrder([
          'Applying fixes...',
          'lib${Platform.pathSeparator}main.dart',
          '  prefer_single_quotes $bullet 1 fix',
          '1 fix made in 1 file.',
        ]));
  });

  test('--apply (excludes)', () {
    p = project(
      mainSrc: '''
var x = "";
''',
      analysisOptions: '''
analyzer:
  exclude:
    - lib/**
linter:
  rules:
    - prefer_single_quotes
''',
    );
    var result = runFix(['--apply', '.'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('--apply (ignores)', () {
    p = project(
      mainSrc: '''
// ignore: prefer_single_quotes
var x = "";
''',
      analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
''',
    );
    var result = runFix(['--apply', '.'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  group('compare-to-golden', () {
    test('different', () {
      p = project(
        mainSrc: '''
class A {
  String a() => "";
}

class B extends A {
  String a() => "";
}
''',
        analysisOptions: '''
linter:
  rules:
    - annotate_overrides
    - prefer_single_quotes
''',
      );
      p.file('lib/main.dart.expect', '''
class A {
  String a() => '';
}

class B extends A {
  String a() => '';
}
''');
      var result = runFix(['--compare-to-golden', '.'], workingDir: p.dirPath);
      expect(result.exitCode, 1);
      expect(result.stderr, isEmpty);
    });

    test('same', () {
      p = project(
        mainSrc: '''
class A {
  String a() => "";
}

class B extends A {
  String a() => "";
}
''',
        analysisOptions: '''
linter:
  rules:
    - annotate_overrides
    - prefer_single_quotes
''',
      );
      p.file('lib/main.dart.expect', '''
class A {
  String a() => '';
}

class B extends A {
  @override
  String a() => '';
}
''');
      var result = runFix(['--compare-to-golden', '.'], workingDir: p.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });
  });
}
