// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferSingleQuotesTest);
  });
}

@reflectiveTest
class PreferSingleQuotesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_single_quotes';

  test_doubleQuotes() async {
    await assertDiagnostics(r'''
var x = "no quote";
''', [
      lint(8, 10),
    ]);
  }

  test_doubleQuotes_import() async {
    await assertDiagnostics(r'''
import "dart:core";
''', [
      lint(7, 11),
    ]);
  }

  test_doubleQuotes_innerSingleQuote() async {
    await assertNoDiagnostics(r'''
var x = "has quote '";
''');
  }

  test_doubleQuotes_innerSingleQuote_interpolation() async {
    await assertNoDiagnostics(r'''
void f(String p) {
  "has quote ' $p";
}
''');
  }

  test_doubleQuotes_interpolation() async {
    await assertDiagnostics(r'''
void f(String p) {
  "no quote $p";
}
''', [
      lint(21, 13),
    ]);
  }

  test_doubleQuotes_interpolationWithSingleQuote() async {
    await assertNoDiagnostics(r'''
var x = "foo ${1 == 'x'} bar";
''');
  }

  test_doubleQuotes_raw() async {
    await assertDiagnostics(r'''
var x = r"no quote";
''', [
      lint(8, 11),
    ]);
  }

  test_doubleQuotes_raw_innerSingleQuote() async {
    await assertNoDiagnostics(r'''
var x = r"has quote '";
''');
  }

  test_doubleQuotes_triple() async {
    await assertDiagnostics(r'''
var x = r"""no quote""";
''', [
      lint(8, 15),
    ]);
  }

  test_doubleQuotes_triple_innerSingleQuote() async {
    await assertNoDiagnostics(r'''
var x = r"""has quote '""";
''');
  }

  test_singleQuote() async {
    await assertNoDiagnostics(r'''
var x = 'uses single';
''');
  }

  test_singleQuote_import() async {
    await assertNoDiagnostics(r'''
import 'dart:core';
''');
  }

  test_singleQuote_interpolation() async {
    await assertNoDiagnostics(r'''
void f(String p) {
  'uses single $p';
}
''');
  }

  test_singleQuote_interpolationWithDoubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = 'foo ${1 == "x"} bar';
''');
  }

  test_singleQuote_raw() async {
    await assertNoDiagnostics(r'''
var x = r'uses single';
''');
  }

  test_singleQuote_triple() async {
    await assertNoDiagnostics(r"""
var x = r'''uses single''';
""");
  }
}
