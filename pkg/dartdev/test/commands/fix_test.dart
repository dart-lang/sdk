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
    expect(result.stdout, contains('Fixed 1 file.'));
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
    expect(result.stdout, contains('3 proposed fixes in 1 file.'));
    expect(result.stdout, contains('lib${Platform.pathSeparator}main.dart'));
    expect(result.stdout, contains('  annotate_overrides $bullet 1 fix'));
    expect(result.stdout, contains('  prefer_single_quotes $bullet 2 fixes'));
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
    expect(result.stdout, contains('Fixed 1 file.'));
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
}
