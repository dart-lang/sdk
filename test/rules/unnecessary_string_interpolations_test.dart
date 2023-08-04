// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryStringInterpolationsTest);
  });
}

@reflectiveTest
class UnnecessaryStringInterpolationsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_string_interpolations';

  test_necessaryInterpolation_adjacentStrings() async {
    await assertNoDiagnostics(r'''
var a = '';
var b = 'x' '$a';
''');
  }

  test_necessaryInterpolation_nullableString() async {
    await assertNoDiagnostics(r'''
class Node {
  String? x = '';
  String f() => '$x';
}
''');
  }

  test_necessaryInterpolation_property() async {
    await assertNoDiagnostics(r'''
var a = '';
var b = '${a.length}';
''');
  }

  test_necessaryInterpolation_single() async {
    await assertNoDiagnostics(r'''
var a = '';
var b = 'x$a';
''');
  }

  test_necessaryInterpolation_triple() async {
    await assertNoDiagnostics(r"""
var a = '';
var b = '''x$a''';
""");
  }

  test_unnecessaryInterpolation_single() async {
    await assertDiagnostics(r'''
var a = '';
var b = '$a';
''', [
      lint(20, 4),
    ]);
  }

  test_unnecessaryInterpolation_substring() async {
    await assertDiagnostics(r'''
var a = '';
var b = '${a.substring(1)}';
''', [
      lint(20, 19),
    ]);
  }

  test_unnecessaryInterpolation_triple() async {
    await assertDiagnostics(r"""
var a = '';
var b = '''$a''';
""", [
      lint(20, 8),
    ]);
  }

  test_unnecessaryInterpolation_withBraces() async {
    await assertDiagnostics(r'''
var a = '';
var b = '${a}';
''', [
      lint(20, 6),
    ]);
  }
}
