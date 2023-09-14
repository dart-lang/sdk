// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryRawStringsTest);
  });
}

@reflectiveTest
class UnnecessaryRawStringsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_raw_strings';

  test_doubleQuotes_raw() async {
    await assertDiagnostics(r'''
var s = r"a b c d";
''', [
      lint(8, 10),
    ]);
  }

  test_doubleQuotes_raw_containsBackslash() async {
    await assertNoDiagnostics(r'''
var s = r"a b c\d";
''');
  }

  test_doubleQuotes_raw_containsDollar() async {
    await assertNoDiagnostics(r'''
var s = r"a b c$d";
''');
  }

  test_singleQuote() async {
    await assertNoDiagnostics(r'''
var s = 'a b c d';
''');
  }

  test_singleQuote_raw() async {
    await assertDiagnostics(r'''
var s = r'a b c d';
''', [
      lint(8, 10),
    ]);
  }

  test_singleQuote_raw_containsBackslash() async {
    await assertNoDiagnostics(r'''
var s = r'a b c\d';
''');
  }

  test_singleQuote_raw_containsDollar() async {
    await assertNoDiagnostics(r'''
var s = r'a b c$d';
''');
  }

  test_tripleDoubleQuotes_raw() async {
    await assertDiagnostics(r'''
var s = r"""a b c d""";
''', [
      lint(8, 14),
    ]);
  }

  test_tripleDoubleQuotes_raw_containsBackslash() async {
    await assertNoDiagnostics(r'''
var s = r"""a b c\d""";
''');
  }

  test_tripleDoubleQuotes_raw_containsDollar() async {
    await assertNoDiagnostics(r'''
var s = r"""a b c$d""";
''');
  }

  test_tripleSingleQuote_raw() async {
    await assertDiagnostics(r"""
var s = r'''a b c d''';
""", [
      lint(8, 14),
    ]);
  }

  test_tripleSingleQuote_raw_containsBackslash() async {
    await assertNoDiagnostics(r"""
var s = r'''a b c\d''';
""");
  }

  test_tripleSingleQuote_raw_containsDollar() async {
    await assertNoDiagnostics(r"""
var s = r'''a b c$d''';
""");
  }
}
