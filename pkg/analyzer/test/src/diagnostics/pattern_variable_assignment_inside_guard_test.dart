// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableAssignmentInsideGuardTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternVariableAssignmentInsideGuardTest
    extends PubPackageResolutionTest {
  test_closure_outer_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when () {
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    if (x case _ when (a = 1) > 0) {}
//                     ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
    return true;
  }()) {}
}
''');
  }

  test_closure_this_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when () {
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    a = 0;
//  ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
    return true;
  }()) {}
}
''');
  }

  test_expression_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when (a = 1) > 0) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                       ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
}
''');
  }

  test_expression_assignment_compound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when (a += 1) > 0) {}
//                       ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
}
''');
  }

  test_expression_assignment_logicalOr2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case int a || int a when (a = 1) > 0) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                 ^^^^^^^^
// [diag.deadCode] Dead code.
//                        ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                                ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
}
''');
  }

  test_expression_postfixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when (a++) > 0) {}
//                       ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
}
''');
  }

  test_expression_prefixIncrement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when (++a) > 0) {}
//                         ^
// [diag.patternVariableAssignmentInsideGuard] Pattern variables can't be assigned inside the guard of the enclosing guarded pattern.
}
''');
  }

  test_ifStatement_caseClause_insideThen() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when a > 0) {
    a = 0;
  }
}
''');
  }

  test_otherVariable_local() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  // ignore:unused_local_variable
  var b = 0;
  if (x case var a when (b = 1) > 0) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_outerPattern_variablePattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var a when a > 0) {
    if (x case _ when (a = 1) > 0) {}
  }
}
''');
  }
}
