// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDoubleQuotesTest);
  });
}

@reflectiveTest
class PreferDoubleQuotesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_double_quotes';

  test_doubleQuotes() async {
    await assertNoDiagnostics(r'''
var s = "uses double";
''');
  }

  test_doubleQuotes_raw() async {
    await assertNoDiagnostics(r'''
var s = r"uses double";
''');
  }

  test_doubleQuotes_triple_raw() async {
    await assertNoDiagnostics(r'''
var s = r"""uses double""";
''');
  }

  test_doubleQuotes_withInterpolation() async {
    await assertNoDiagnostics(r'''
var x = "x";
var s = "uses double $x";
''');
  }

  test_doubleQuotes_withInterpolationWithSingleQuote() async {
    await assertNoDiagnostics(r'''
var x = "x";
var s = "foo ${x == 'x'} bar";
''');
  }

  test_singleQuote() async {
    await assertDiagnostics(r'''
var s = 'no quote';
''', [
      lint(8, 10),
    ]);
  }

  test_singleQuote_hasDoubleQuote_withInterpolation() async {
    await assertNoDiagnostics(r'''
var x = "x";
var s = 'has double quote " $x';
''');
  }

  test_singleQuote_hasDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var s = 'has double quote "';
''');
  }

  test_singleQuote_raw() async {
    await assertDiagnostics(r'''
var s = r'no double quote';
''', [
      lint(8, 18),
    ]);
  }

  test_singleQuote_raw_hasDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var s = r'has double quote "';
''');
  }

  test_singleQuote_triple_raw() async {
    await assertDiagnostics(r"""
var s = r'''no double quote''';
""", [
      lint(8, 22),
    ]);
  }

  test_singleQuote_triple_raw_hasDouble() async {
    await assertNoDiagnostics(r"""
var s = r'''has double quote "''';
""");
  }

  test_singleQuote_withInterpolation() async {
    await assertDiagnostics(r'''
var x = "x";
var s = 'no double quote $x';
''', [
      lint(21, 20),
    ]);
  }

  test_singleQuote_withInterpolationWithDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = "x";
var s = 'foo ${x == "x"} bar';
''');
  }
}
