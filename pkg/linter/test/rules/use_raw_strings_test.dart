// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRawStringsTest);
  });
}

@reflectiveTest
class UseRawStringsTest extends LintRuleTest {
  @override
  String get lintRule => 'use_raw_strings';

  test_escapedBackslash() async {
    await assertDiagnostics(r'''
var f = '\\';
''', [
      lint(8, 4),
    ]);
  }

  test_escapedDollar() async {
    await assertDiagnostics(r'''
var f = '\$';
''', [
      lint(8, 4),
    ]);
  }

  test_escapedMultiple() async {
    await assertDiagnostics(r'''
var f = '\$ and \\';
''', [
      lint(8, 11),
    ]);
  }

  test_escapedMultiple_withInterpolation() async {
    await assertNoDiagnostics(r'''
var x = 1;
var f = '\$ and \\ and $x';
''');
  }

  test_escapedMultiple_withNewline() async {
    await assertNoDiagnostics(r'''
var f = '\$ and \\ and \n';
''');
  }

  test_raw_escapedBackslash() async {
    await assertNoDiagnostics(r'''
var f = r'\\';
''');
  }

  test_raw_escapedDollar() async {
    await assertNoDiagnostics(r'''
var f = r'\$';
''');
  }

  test_raw_escapedMultiple() async {
    await assertNoDiagnostics(r'''
var f = r'\$ and \\';
''');
  }

  test_raw_escapedMultiple_andInterpolation() async {
    await assertNoDiagnostics(r'''
var x = 1;
var f = r'\$ and \\ and $x';
''');
  }

  test_raw_escapedMultiple_andNewline() async {
    await assertNoDiagnostics(r'''
var f = r'\$ and \\ and \n';
''');
  }

  test_triple_escapedBackslash() async {
    await assertDiagnostics(r"""
var f = '''\\''';
""", [
      lint(8, 8),
    ]);
  }

  test_triple_escapedDollar() async {
    await assertDiagnostics(r"""
var f = '''\$''';
""", [
      lint(8, 8),
    ]);
  }

  test_triple_escapedMultiple() async {
    await assertDiagnostics(r"""
var f = '''\$ and \\''';
""", [
      lint(8, 15),
    ]);
  }

  test_triple_escapedMultiple_andInterpolation() async {
    await assertNoDiagnostics(r"""
var x = 1;
var f = '''\$ and \\ and $x''';
""");
  }

  test_triple_escapedMultiple_andNewline() async {
    await assertNoDiagnostics(r"""
var f = '''\$ and \\ and \n''';
""");
  }
}
