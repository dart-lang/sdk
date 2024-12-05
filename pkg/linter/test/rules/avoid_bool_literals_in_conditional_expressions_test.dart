// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBoolLiteralsInConditionalExpressionsTest);
  });
}

@reflectiveTest
class AvoidBoolLiteralsInConditionalExpressionsTest extends LintRuleTest {
  @override
  String get lintRule =>
      LintNames.avoid_bool_literals_in_conditional_expressions;

  test_elseFalse() async {
    await assertDiagnostics(r'''
var a = true;
var b = a ? a : false;
''', [
      lint(22, 13),
    ]);
  }

  test_elseTrue() async {
    await assertDiagnostics(r'''
var a = true;
var b = a ? a : true;
''', [
      lint(22, 12),
    ]);
  }

  test_noLiterals() async {
    await assertNoDiagnostics(r'''
var a = true;
var b = a ? a : a;
''');
  }

  test_thenFalse() async {
    await assertDiagnostics(r'''
var a = true;
var b = a ? false : a;
''', [
      lint(22, 13),
    ]);
  }

  test_thenTrue() async {
    await assertDiagnostics(r'''
var a = true;
var b = a ? true : a;
''', [
      lint(22, 12),
    ]);
  }

  test_thenTrue_parenthesized() async {
    await assertDiagnostics(r'''
var a = true;
var b = a ? (true) : a;
''', [
      lint(22, 14),
    ]);
  }
}
