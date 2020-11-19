// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('fix', defineFix, timeout: longTimeout);
}

void defineFix() {
  TestProject p;

  final bullet = Logger.standard().ansi.bullet;

  setUp(() => p = null);

  tearDown(() => p?.dispose());

  test('none', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('fix', [p.dirPath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('no args', () {
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
    var result = p.runSync('fix', [], workingDir: p.dirPath);
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

  test('dry-run', () {
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
    var result = p.runSync('fix', ['--dry-run', '.'], workingDir: p.dirPath);
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

  test('.', () {
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
    var result = p.runSync('fix', ['.'], workingDir: p.dirPath);
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

  test('excludes', () {
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
    var result = p.runSync('fix', ['.'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('ignores', () {
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
    var result = p.runSync('fix', ['.'], workingDir: p.dirPath);
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
      var result =
          p.runSync('fix', ['--compare-to-golden', '.'], workingDir: p.dirPath);
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
      var result =
          p.runSync('fix', ['--compare-to-golden', '.'], workingDir: p.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });
  });
}
