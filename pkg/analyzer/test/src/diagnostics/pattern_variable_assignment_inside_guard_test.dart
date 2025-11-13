// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableAssignmentInsideGuardTest);
  });
}

@reflectiveTest
class PatternVariableAssignmentInsideGuardTest
    extends PubPackageResolutionTest {
  test_closure_outer_assignment() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when () {
    if (x case _ when (a = 1) > 0) {}
    return true;
  }()) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.patternVariableAssignmentInsideGuard, 68, 1),
      ],
    );
  }

  test_closure_this_assignment() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when () {
    a = 0;
    return true;
  }()) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.patternVariableAssignmentInsideGuard, 49, 1),
      ],
    );
  }

  test_expression_assignment() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when (a = 1) > 0) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.patternVariableAssignmentInsideGuard, 41, 1),
      ],
    );
  }

  test_expression_assignment_compound() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when (a += 1) > 0) {}
}
''',
      [error(diag.patternVariableAssignmentInsideGuard, 41, 1)],
    );
  }

  test_expression_assignment_logicalOr2() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case int a || int a when (a = 1) > 0) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.deadCode, 35, 8),
        error(diag.unusedLocalVariable, 42, 1),
        error(diag.patternVariableAssignmentInsideGuard, 50, 1),
      ],
    );
  }

  test_expression_postfixIncrement() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when (a++) > 0) {}
}
''',
      [error(diag.patternVariableAssignmentInsideGuard, 41, 1)],
    );
  }

  test_expression_prefixIncrement() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a when (++a) > 0) {}
}
''',
      [error(diag.patternVariableAssignmentInsideGuard, 43, 1)],
    );
  }

  test_ifStatement_caseClause_insideThen() async {
    await assertNoErrorsInCode('''
void f(int x) {
  if (x case var a when a > 0) {
    a = 0;
  }
}
''');
  }

  test_otherVariable_local() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  // ignore:unused_local_variable
  var b = 0;
  if (x case var a when (b = 1) > 0) {}
}
''',
      [error(diag.unusedLocalVariable, 80, 1)],
    );
  }

  test_outerPattern_variablePattern() async {
    await assertNoErrorsInCode('''
void f(int x) {
  if (x case var a when a > 0) {
    if (x case _ when (a = 1) > 0) {}
  }
}
''');
  }
}
