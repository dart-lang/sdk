// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryStringEscapesTest);
  });
}

@reflectiveTest
class UnnecessaryStringEscapesTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_string_escapes';

  test_escapedBackslash() async {
    await assertNoDiagnostics(r'''
var x = '\\';
''');
  }

  test_escapedColon() async {
    await assertDiagnostics(r'''
var x = '\:';
''', [
      lint(9, 1),
    ]);
  }

  test_escapedDoubleQuotes_inDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = "\"";
''');
  }

  test_escapedDoubleQuotes_inSingleQuotes() async {
    await assertDiagnostics(r'''
var x = '\"';
''', [
      lint(9, 1),
    ]);
  }

  test_escapedDoubleQuotes_inSingleQuotes_raw() async {
    await assertNoDiagnostics(r'''
var x = r'\"';
''');
  }

  test_escapedDoubleQuotes_inThree_inThreeDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = """text"\""text""";
''');
  }

  test_escapedDoubleQuotes_inThreeDoubleQuotes() async {
    await assertDiagnostics(r'''
var x = """\"text""";
''', [
      lint(11, 1),
    ]);
  }

  test_escapedDoubleQuotes_inThreeDoubleQuotes_atEnd() async {
    await assertNoDiagnostics(r'''
var x = """text\"""";
''');
  }

  test_escapedDoubleQuotes_inThreeSingleQuotes() async {
    await assertDiagnostics(r"""
var x = '''\"''';
""", [
      lint(11, 1),
    ]);
  }

  test_escapedLowerA() async {
    await assertDiagnostics(r'''
var x = '\a';
''', [
      lint(9, 1),
    ]);
  }

  test_escapedLowerDollar() async {
    await assertNoDiagnostics(r'''
var x = '\$';
''');
  }

  test_escapedLowerN() async {
    await assertNoDiagnostics(r'''
var x = '\n';
''');
  }

  test_escapedLowerR() async {
    await assertNoDiagnostics(r'''
var x = '\r';
''');
  }

  test_escapedLowerT() async {
    await assertNoDiagnostics(r'''
var x = '\t';
''');
  }

  test_escapedSingleQuote_inDoubleQuotes() async {
    await assertDiagnostics(r'''
var x = "\'";
''', [
      lint(9, 1),
    ]);
  }

  test_escapedSingleQuote_inDoubleQuotes_raw() async {
    await assertNoDiagnostics(r'''
var x = r"\'";
''');
  }

  test_escapedSingleQuote_inSingleQuotes() async {
    await assertNoDiagnostics(r'''
var x = '\'';
''');
  }

  test_escapedSingleQuote_inThree_inThreeSingleQuotes() async {
    await assertNoDiagnostics(r"""
var x = '''text'\''text''';
""");
  }

  test_escapedSingleQuote_inThreeDoubleQuotes() async {
    await assertDiagnostics(r'''
var x = """\'""";
''', [
      lint(11, 1),
    ]);
  }

  test_escapedSingleQuote_inThreeSingleQuotes() async {
    await assertDiagnostics(r"""
var x = '''\'text''';
""", [
      lint(11, 1),
    ]);
  }

  test_escapedSingleQuote_inThreeSingleQuotes_atEnd() async {
    await assertNoDiagnostics(r"""
var x = '''text\'''';
""");
  }

  test_escapedUtfHex() async {
    await assertNoDiagnostics(r'''
var x = '\uFFFF';
''');
  }

  test_escapedXHex() async {
    await assertNoDiagnostics(r'''
var x = '\x00';
''');
  }

  test_moreThanThreeEscapedDoubleQuotes_inThreeDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = """text\"\"\"\"\"\"text""";
''');
  }

  test_moreThanThreeEscapedSingleQuote_inThreeSingleQuotes() async {
    await assertNoDiagnostics(r"""
var x = '''text\'\'\'\'\'\'text''';
""");
  }

  test_threeEscapedDoubleQuote_inThreeDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = """text\"\"\"text""";
''');
  }

  test_threeEscapedSingleQuote_inThreeSingleQuotes() async {
    await assertNoDiagnostics(r"""
var x = '''text\'\'\'text''';
""");
  }

  test_unterminatedStringLiteral() async {
    // Note that putting `''` on the new line is important to get a token
    // with `'\` with no closing quote.
    await assertDiagnostics(r'''
String unclosedQuote() => '\
'';
''', [
      // Ensure linter does not crash.
      error(ParserErrorCode.INVALID_UNICODE_ESCAPE_STARTED, 27, 1),
      error(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 27, 1),
    ]);
  }
}
