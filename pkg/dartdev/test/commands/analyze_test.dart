// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('analyze', defineAnalyze, timeout: defaultTimeout);
}

const String _analyzeDescriptionText = "Analyze the project's Dart code.";

const String _analyzeUsageText =
    'Usage: dart analyze [arguments] [<directory>]';

const String _warningDartCodeSnippet = '''
  enum E { e1, e2 }
  void f(E e) {
    switch (e) {
    case E.e1:
      break;
    }
  }
  ''';

void defineAnalyze() {
  TestProject p;

  setUp(() => p = null);

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('analyze', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(_analyzeDescriptionText));
    expect(result.stdout, contains(_analyzeUsageText));
  });

  test('multiple directories', () {
    p = project();
    var result = p.runSync('analyze', ['/no/such/dir1/', '/no/such/dir2/']);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Only one directory is expected.'));
    expect(result.stderr, contains(_analyzeUsageText));
  });

  test('no such directory', () {
    p = project();
    var result = p.runSync('analyze', ['/no/such/dir1/']);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains("Directory doesn't exist: /no/such/dir1/"));
    expect(result.stderr, contains(_analyzeUsageText));
  });

  test('current working directory', () {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = p.runSync('analyze', [], workingDir: p.dirPath);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No issues found!'));
  });

  test('no errors', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('analyze', [p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No issues found!'));
  });

  test('one error', () {
    p = project(mainSrc: "int get foo => 'str';\n");
    var result = p.runSync('analyze', [p.dirPath]);

    expect(result.exitCode, 3);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('A value of type '));
    expect(result.stdout, contains('lib/main.dart:1:16 '));
    expect(result.stdout, contains('return_of_invalid_type'));
    expect(result.stdout, contains('1 issue found.'));
  });

  test('two errors', () {
    p = project(mainSrc: "int get foo => 'str';\nint get bar => 'str';\n");
    var result = p.runSync('analyze', [p.dirPath]);

    expect(result.exitCode, 3);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('2 issues found.'));
  });

  test('warning --fatal-warnings', () {
    p = project(mainSrc: _warningDartCodeSnippet);
    var result = p.runSync('analyze', ['--fatal-warnings', p.dirPath]);

    //TODO(jwren) Once http://dartbug.com/40768 is resolved, this assertion
    //  should be exitCode == 2, not greater than 0:
    expect(result.exitCode, greaterThan(0));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('warning implicit --fatal-warnings', () {
    p = project(mainSrc: _warningDartCodeSnippet);
    var result = p.runSync('analyze', [p.dirPath]);

    //TODO(jwren) Once http://dartbug.com/40768 is resolved, this assertion
    //  should be exitCode == 2, not greater than 0:
    expect(result.exitCode, greaterThan(0));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('warning --no-fatal-warnings', () {
    p = project(mainSrc: _warningDartCodeSnippet);
    var result = p.runSync('analyze', ['--no-fatal-warnings', p.dirPath]);

    //TODO(jwren) Once http://dartbug.com/40768 is resolved, this assertion
    //  should be exitCode == 0:
    // expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('info implicit no --fatal-infos', () {
    p = project(mainSrc: 'String foo() {}');
    var result = p.runSync('analyze', [p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('info --fatal-infos', () {
    p = project(mainSrc: 'String foo() {}');
    var result = p.runSync('analyze', ['--fatal-infos', p.dirPath]);

    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });
}
