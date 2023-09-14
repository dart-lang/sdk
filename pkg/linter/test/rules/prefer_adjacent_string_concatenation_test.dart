// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAdjacentStringConcatenationTest);
  });
}

@reflectiveTest
class PreferAdjacentStringConcatenationTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_adjacent_string_concatenation';

  test_concatenation() async {
    await assertNoDiagnostics(r'''
var s = 'hello' ' world';
''');
  }

  test_plusOperator() async {
    await assertDiagnostics(r'''
var s = 'hello' + ' world';
''', [
      lint(16, 1),
    ]);
  }

  test_plusOperator_inListLiteral() async {
    await assertDiagnostics(r'''
var list = ['this is' + ' not allowed'];
''', [
      lint(22, 1),
    ]);
  }

  test_plusOperator_nonStringLiteralLeft() async {
    await assertNoDiagnostics(r'''
var p = '';
var s = p + 'hello';
''');
  }

  test_plusOperator_nonStringLiteralRight() async {
    await assertNoDiagnostics(r'''
var p = '';
var s = 'hello' + p;
''');
  }
}
