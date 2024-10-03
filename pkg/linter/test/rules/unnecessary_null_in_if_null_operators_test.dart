// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsTest);
  });
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_null_in_if_null_operators;

  test_localVariableDeclaration_noNull() async {
    await assertDiagnostics(r'''
void f() {
  var x = 1 ?? 1;
}
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 26, 1),
    ]);
  }

  test_localVariableDeclaration_nullOnLeft() async {
    await assertDiagnostics(r'''
void f() {
  var x = null ?? 1;
}
''', [
      lint(21, 4),
    ]);
  }

  test_localVariableDeclaration_nullOnRight() async {
    await assertDiagnostics(r'''
void f() {
  var x = 1 ?? null;
}
''', [
      lint(26, 4),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 26, 4),
    ]);
  }

  test_methodBody() async {
    await assertDiagnostics(r'''
class C {
  m() {
    var x = 1 ?? null;
    var y = null ?? 1;
  }
}
''', [
      lint(35, 4),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 35, 4),
      lint(53, 4),
    ]);
  }

  test_methodBody_noNull() async {
    await assertDiagnostics(r'''
class C {
  m() {
    var x = 1 ?? 1;
  }
}
''', [
      // No lint.
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 35, 1),
    ]);
  }

  test_topLevel() async {
    await assertDiagnostics(r'''
var x = 1 ?? null;
var y = null ?? 1;
''', [
      lint(13, 4),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 13, 4),
      lint(27, 4),
    ]);
  }

  test_topLevel_noNull() async {
    await assertDiagnostics(r'''
var x = 1 ?? 1;
''', [
      // No lint.
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 13, 1),
    ]);
  }

  test_topLevelVariableDeclaration_noNull() async {
    await assertDiagnostics(r'''
var x = 1 ?? 1;
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 13, 1),
    ]);
  }

  test_topLevelVariableDeclaration_nullOnLeft() async {
    await assertDiagnostics(r'''
var x = null ?? 1;
''', [
      lint(8, 4),
    ]);
  }

  test_topLevelVariableDeclaration_nullOnRight() async {
    await assertDiagnostics(r'''
var x = 1 ?? null;
''', [
      lint(13, 4),
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 13, 4),
    ]);
  }
}
