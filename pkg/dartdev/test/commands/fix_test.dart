// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('fix', defineFix, timeout: longTimeout);
}

final bullet = '•';
final nonAnsiBullet = '-';

/// Allow for different bullets; depending on how the test harness is run,
/// subprocesses may decide to give us ansi bullets or normal bullets.
/// TODO(jcollins): find a way to detect which one we should be expecting.
Matcher stringContainsInOrderWithVariableBullets(List<String> substrings) {
  var substitutedSubstrings = substrings;
  if (substrings.any((s) => s.contains(bullet))) {
    substitutedSubstrings =
        substrings.map((s) => s.replaceAll(bullet, nonAnsiBullet)).toList();
  }
  return anyOf(stringContainsInOrder(substrings),
      stringContainsInOrder(substitutedSubstrings));
}

void defineFix() {
  TestProject? p;
  late ProcessResult result;

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

  group('usage', () {
    test('--help', () async {
      p = project(mainSrc: 'int get foo => 1;\n');

      var result = await p!.runFix([p!.dirPath, '--help']);

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

      var result = await p!.runFix([p!.dirPath, '--help', '--verbose']);

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

    test('no args', () async {
      p = project(mainSrc: 'int get foo => 1;\n');

      var result = await p!.runFix([p!.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout,
          contains('Apply automated fixes to Dart source code.'));
    });
  });

  group('perform', () {
    test('--apply (nothing to fix)', () async {
      p = project(mainSrc: 'int get foo => 1;\n');

      var result = await p!.runFix(['--apply', p!.dirPath]);

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

      var result = await p!.runFix(['--apply'], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
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
      var result = await p!.runFix(['--dry-run', '.'], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            '3 proposed fixes in 1 file.',
            'lib${Platform.pathSeparator}main.dart',
            '  annotate_overrides $bullet 1 fix',
            '  prefer_single_quotes $bullet 2 fixes',
            'To fix an individual diagnostic, run one of:',
            '  dart fix --apply --code=annotate_overrides .',
            '  dart fix --apply --code=prefer_single_quotes .',
            'To fix all diagnostics, run:',
            '  dart fix --apply .',
          ]));
    });

    test('--dry-run --code=(single)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
    - unnecessary_new
''',
      );
      var result = await p!.runFix(
          ['--dry-run', '--code', 'prefer_single_quotes', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            '1 proposed fix in 1 file.',
            'lib${Platform.pathSeparator}main.dart',
            '  prefer_single_quotes $bullet 1 fix',
          ]));
    });

    test('--dry-run --code=(single: undefined)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - _undefined_
    - unnecessary_new
''',
      );
      var result = await p!.runFix(['--dry-run', '--code', '_undefined_', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            "Unable to compute fixes: The diagnostic '_undefined_' is not defined by the analyzer.",
          ]));
    });

    test('--apply lib/main.dart', () async {
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
      var result = await p!.runFix(['--apply', path.join('lib', 'main.dart')],
          workingDir: p!.dirPath);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            'Applying fixes...',
            'main.dart',
            '  prefer_single_quotes $bullet 1 fix',
            '1 fix made in 1 file.',
          ]));
      expect(result.exitCode, 0);
    });

    test('--apply --code=(single)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
    - unnecessary_new
''',
      );
      var result = await p!.runFix(
          ['--apply', '--code', 'prefer_single_quotes', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            'Applying fixes...',
            'lib${Platform.pathSeparator}main.dart',
            '  prefer_single_quotes $bullet 1 fix',
            '1 fix made in 1 file.',
          ]));
    });

    test('--apply --code=(undefined)', () async {
      p = project(
        mainSrc: '',
      );
      var result = await p!.runFix(['--apply', '--code', '_undefined_', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            "Unable to compute fixes: The diagnostic '_undefined_' is not defined by the analyzer.",
          ]));
    });

    test('--apply --code=(not enabled)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - unnecessary_new
''',
      );
      var result = await p!.runFix(
          ['--apply', '--code', 'prefer_single_quotes', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout,
          stringContainsInOrderWithVariableBullets(['Nothing to fix!']));
    });

    test('--apply --code=(multiple: one undefined)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - _undefined_
    - unnecessary_new
''',
      );
      var result = await p!.runFix([
        '--apply',
        '--code',
        '_undefined_',
        '--code',
        'unnecessary_new',
        '.'
      ], workingDir: p!.dirPath);
      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            "Unable to compute fixes: The diagnostic '_undefined_' is not defined by the analyzer.",
          ]));
    });

    test('--apply --code=(multiple)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
    - unnecessary_new
''',
      );
      var result = await p!.runFix([
        '--apply',
        '--code',
        'prefer_single_quotes',
        '--code',
        'unnecessary_new',
        '.'
      ], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            'Applying fixes...',
            'lib${Platform.pathSeparator}main.dart',
            '  prefer_single_quotes $bullet 1 fix',
            '  unnecessary_new $bullet 1 fix',
            '2 fixes made in 1 file.',
          ]));
    });

    test('--apply --code=(multiple: comma-delimited)', () async {
      p = project(
        mainSrc: '''
var x = "";
class A {
  A a() => new A();
}
''',
        analysisOptions: '''
linter:
  rules:
    - prefer_single_quotes
    - unnecessary_new
''',
      );
      var result = await p!.runFix(
          ['--apply', '--code=prefer_single_quotes,unnecessary_new', '.'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            'Applying fixes...',
            'lib${Platform.pathSeparator}main.dart',
            '  prefer_single_quotes $bullet 1 fix',
            '  unnecessary_new $bullet 1 fix',
            '2 fixes made in 1 file.',
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
      var result = await p!.runFix(['--apply', '.'], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
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
      var result = await p!.runFix(['--apply', '.'], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
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
      var result = await p!.runFix(['--apply', '.'], workingDir: p!.dirPath);
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
      var result = await p!.runFix(['--apply', '.'], workingDir: p!.dirPath);
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
      var result = await p!.runFix(['--apply', '.'], workingDir: p!.dirPath);
      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
          result.stdout,
          stringContainsInOrderWithVariableBullets([
            'Applying fixes...',
            'lib${Platform.pathSeparator}main.dart',
            '  prefer_single_quotes $bullet 1 fix',
            '  unused_import $bullet 1 fix',
            '2 fixes made in 1 file.',
          ]));
    });
  });

  group('compare-to-golden', () {
    test('target is not a directory', () async {
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
      result = await p!.runFix(['--compare-to-golden', 'lib/main.dart.expect'],
          workingDir: p!.dirPath);
      expect(result.exitCode, 64);
      expect(result.stderr,
          startsWith('Golden comparison requires a directory argument.'));
    });

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
          await p!.runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
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
          await p!.runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
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
          await p!.runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
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
          await p!.runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
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
          await p!.runFix(['--compare-to-golden', '.'], workingDir: p!.dirPath);
      assertResult(exitCode: 1);
    });
  });
}
