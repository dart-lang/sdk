// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('fix', defineFix, timeout: longTimeout);
}

/// Enable to run from local source (useful in development).
const runFromSource = false;

void defineFix() {
  TestProject? p;

  late ProcessResult result;

  final bullet = Logger.standard().ansi.bullet;

  setUp(() => p = null);

  tearDown(() async => await p?.dispose());

  void assertResult({int exitCode = 0}) {
    String message;
    if (result.exitCode != exitCode) {
      if (result.stderr.isNotEmpty) {
        message = 'Error code was ${result.exitCode} and stderr was not empty';
      } else {
        message = 'Error code was ${result.exitCode}';
      }
    } else if (result.stderr.isNotEmpty) {
      message = 'stderr was not empty';
    } else {
      return;
    }
    fail('''
$message

stdout:
${result.stdout}

stderr:
${result.stderr}
''');
  }

  Future<ProcessResult> runFix(List<String> args, {String? workingDir}) async {
    if (runFromSource) {
      var binary = path.join(Directory.current.path, 'bin', 'dartdev.dart');
      return await p!.run([binary, 'fix', ...args], workingDir: workingDir);
    }
    return await p!.run(['fix', ...args], workingDir: workingDir);
  }

  test('--help', () async {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = await runFix([p!.dirPath, '--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      contains(
        'Apply automated fixes to Dart source code.',
      ),
    );
    expect(result.stdout, contains('Usage: dart fix [arguments]'));
  });

  test('--help --verbose', () async {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = await runFix([p!.dirPath, '--help', '--verbose']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      contains(
        'Apply automated fixes to Dart source code.',
      ),
    );
    expect(
      result.stdout,
      contains('Usage: dart [vm-options] fix [arguments]'),
    );
  });

  test('none', () async {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = await runFix([p!.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout, contains('Apply automated fixes to Dart source code.'));
  });

  test('--apply (none)', () async {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = await runFix(['--apply', p!.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('--apply (no args)', () async {
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

    var result = await runFix(['--apply'], workingDir: p!.dirPath);
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

  test('--dry-run', () async {
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
    var result = await runFix(['--dry-run', '.'], workingDir: p!.dirPath);
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

  test('--apply (.)', () async {
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
    var result = await runFix(['--apply', '.'], workingDir: p!.dirPath);
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

  test('--apply (contradictory lints do not loop infinitely)', () async {
    p = project(
      mainSrc: '''
var x = "";
''',
      analysisOptions: '''
linter:
  rules:
    - prefer_double_quotes
    - prefer_single_quotes
''',
    );
    var result = await runFix(['--apply', '.'], workingDir: p!.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        stringContainsInOrder([
          'Applying fixes...',
          'lib${Platform.pathSeparator}main.dart',
          '  prefer_double_quotes $bullet 2 fixes',
          '  prefer_single_quotes $bullet 2 fixes',
          '4 fixes made in 1 file.',
        ]));
  });

  test('--apply (excludes)', () async {
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
    var result = await runFix(['--apply', '.'], workingDir: p!.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('--apply (ignores)', () async {
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
    var result = await runFix(['--apply', '.'], workingDir: p!.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Nothing to fix!'));
  });

  test('--apply (unused imports require a second pass)', () async {
    p = project(
      mainSrc: '''
import 'dart:math';

var x = "";
''',
      analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
''',
    );
    var result = await runFix(['--apply', '.'], workingDir: p!.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        stringContainsInOrder([
          'Applying fixes...',
          'lib${Platform.pathSeparator}main.dart',
          '  prefer_single_quotes $bullet 1 fix',
          '  unused_import $bullet 1 fix',
          '2 fixes made in 1 file.',
        ]));
  });

  group('compare-to-golden', () {
    test('applied fixes do not match expected', () async {
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
      p!.file('lib/main.dart.expect', '''
class A {
  String a() => '';
}

class B extends A {
  String a() => '';
}
''');
      result =
          await runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult(exitCode: 1);
    });

    test('applied fixes match expected', () async {
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
      p!.file('lib/main.dart.expect', '''
class A {
  String a() => '';
}

class B extends A {
  @override
  String a() => '';
}
''');
      result =
          await runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult();
    });

    test('missing expect', () async {
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
      result =
          await runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult(exitCode: 1);
    });

    test('missing original', () async {
      p = project(mainSrc: '''
class C {}
''');
      p!.file('lib/main.dart.expect', '''
class C {}
''');
      p!.file('lib/secondary.dart.expect', '''
class A {}
''');
      result =
          await runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult(exitCode: 1);
    });

    test('no fixes to apply does not match expected', () async {
      p = project(
        mainSrc: '''
class A {
  String a() => "";
}
''',
        analysisOptions: '''
linter:
  rules:
    - annotate_overrides
''',
      );
      p!.file('lib/main.dart.expect', '''
class A {
  String a() => '';
}
''');
      result =
          await runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult(exitCode: 1);
    });
  });
}
