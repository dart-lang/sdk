// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinesLongerThan80CharsTest);
  });
}

@reflectiveTest
class LinesLongerThan80CharsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.lines_longer_than_80_chars;

  test_blockComment_noSpaceAfter80() async {
    await assertNoDiagnostics(
      '/*  5   10   15   20   25   30   35   40   50   55   60 '
      'http://url.com/abcde/abcde/abcde/abcde.dart */',
    );
  }

  test_blockComment_shorterThan80() async {
    await assertNoDiagnostics(
      '/*  5   10   15   20   25   30   35   40   45   50 */',
    );
  }

  test_blockComment_spaceAfter80() async {
    await assertDiagnostics(
      '/*  5   10   15   20   25   30   35   40   50   55   60'
      '   65   70   75   80   85   90   95  100 */',
      [
        lint(80, 18),
      ],
    );
  }

  test_docComment_noSpaceAfter80() async {
    await assertNoDiagnostics(
      '/// 5   10   15   20   25   30   35   40   50   55   60 '
      'http://url.com/abcde/abcde/abcde/abcde.dart',
    );
  }

  test_docComment_shorterThan80() async {
    await assertNoDiagnostics(
      '/// 5   10   15   20   25   30   35   40   45   50',
    );
  }

  test_docComment_spaceAfter80() async {
    await assertDiagnostics(
      '/// 5   10   15   20   25   30   35   40   50   55   60'
      '   65   70   75   80   85   90   95  100',
      [
        lint(80, 15),
      ],
    );
  }

  test_endOfLineComment_noSpaceAfter80() async {
    await assertNoDiagnostics(
      '//  5   10   15   20   25   30   35   40   50   55   60 '
      'http://url.com/abcde/abcde/abcde/abcde.dart',
    );
  }

  test_endOfLineComment_shorterThan80() async {
    await assertNoDiagnostics(
      '//  5   10   15   20   25   30   35   40   45   50',
    );
  }

  test_endOfLineComment_spaceAfter80() async {
    await assertDiagnostics(
      '//  5   10   15   20   25   30   35   40   50   55   60'
      '   65   70   75   80   85   90   95  100',
      [
        lint(80, 15),
      ],
    );
  }

  test_exactly80Characters() async {
    await assertNoDiagnostics(r'''
var p =
    '                                                                         ';
''');
  }

  test_lineEndsWithCrlf() async {
    await assertNoDiagnostics('''
var p =
    '                                                                         ';\r\n
''');
  }

  test_longerThan80Characters() async {
    await assertDiagnostics(r'''
var p =
    '                                                                          ';
''', [
      lint(88, 1),
    ]);
  }

  test_multilineBlockComment_noSpaceAfter80() async {
    await assertNoDiagnostics(
      '/*\n'
      ' *  5   10   15   20   25   30   35   40   50   55   60 '
      'http://url.com/abcde/abcde/abcde/abcde.dart\n'
      ' */',
    );
  }

  test_multilineBlockComment_shorterThan80() async {
    await assertNoDiagnostics(
      '/*\n'
      ' *  5   10   15   20   25   30   35   40   45   50\n'
      ' */',
    );
  }

  test_multilineBlockComment_shorterThan80_withCrlf() async {
    await assertNoDiagnostics(
      '/*\n'
      ' *  5   10   15   20   25   30   35   40   45   50\r\n'
      ' *  5   10   15   20   25   30   35   40   45   50\r\n'
      ' */',
    );
  }

  test_multilineBlockComment_spaceAfter80() async {
    await assertDiagnostics(
      '/*\n'
      ' *  5   10   15   20   25   30   35   40   50   55   60'
      '   65   70   75   80   85   90   95  100\n'
      ' */',
      [
        lint(83, 15),
      ],
    );
  }

  test_multilineString() async {
    await assertNoDiagnostics(r'''
var p = """
This line is a long, very long, very very long, very very very long, very very very very long
""";
''');
  }

  test_shorterThan80Characters() async {
    await assertNoDiagnostics(r'''
var short = 'This is a short line';
''');
  }

  test_stringContainsBackslash() async {
    await assertNoDiagnostics(r'''
var p =
    r'C:\home\dart.dev\guides\language\effective-dart\style\avoid-lines-longer-than-80-characters';
''');
  }

  test_stringContainsForwardSlash() async {
    await assertNoDiagnostics(r'''
var p =
    '/home/dart.dev/guides/language/effective-dart/style#avoid-lines-longer-than-80-characters'; // OK
''');
  }
}
