// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      NotInitializedPotentiallyNonNullableLocalVariableTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotInitializedPotentiallyNonNullableLocalVariableTest
    extends PubPackageResolutionTest {
  test_assignment_leftExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<int> v;
  v[0] = (v = [1, 2])[1];
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
  v;
}
''');
  }

  test_assignment_leftLocal_compound() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v += 1;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
  v;
}
''');
  }

  test_assignment_leftLocal_compound_assignInRight() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v += (v = v);
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//          ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_assignment_leftLocal_pure_eq() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v = 0;
  v;
}
''');
  }

  test_assignment_leftLocal_pure_eq_self() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v = v;
//    ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_assignment_leftLocal_pure_questionEq() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v ??= 0;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//      ^^
// [diag.deadCode] Dead code.
//      ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
  }

  test_assignment_leftLocal_pure_questionEq_self() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v ??= v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//      ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//      ^^
// [diag.deadCode] Dead code.
//      ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
  }

  test_basic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  v = 0;
  v;
}
''');
  }

  test_binaryExpression_ifNull_left() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  (v = 0) ?? 0;
//        ^^^^
// [diag.deadCode] Dead code.
//           ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  v;
}
''');
  }

  test_binaryExpression_ifNull_right() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  int v;
  a ?? (v = 0);
//  ^^^^^^^^^^
// [diag.deadCode] Dead code.
//     ^^^^^^^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_binaryExpression_logicalAnd_left() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  ((v = 0) >= 0) && c;
  v;
}
''');
  }

  test_binaryExpression_logicalAnd_right() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  c && ((v = 0) >= 0);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_binaryExpression_logicalOr_left() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  ((v = 0) >= 0) || c;
  v;
}
''');
  }

  test_binaryExpression_logicalOr_right() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  c || ((v = 0) >= 0);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_binaryExpression_plus_left() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  int v;
  (v = 0) + 1;
  v;
}
''');
  }

  test_binaryExpression_plus_right() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  int v;
  1 + (v = 0);
  v;
}
''');
  }

  test_conditional_both() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool b) {
  int v;
  b ? (v = 1) : (v = 2);
  v;
}
''');
  }

  test_conditional_else() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool b) {
  int v;
  b ? 1 : (v = 2);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_conditional_then() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool b) {
  int v;
  b ? (v = 1) : 2;
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_conditionalExpression_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  int v;
  (v = 0) >= 0 ? 1 : 2;
  v;
}
''');
  }

  test_doWhile_break_afterAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  do {
    v = 0;
    v;
    if (b) break;
  } while (b);
  v;
}
''');
  }

  test_doWhile_break_beforeAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
    v = 0;
  } while (b);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_doWhile_breakOuterFromInner() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2, v3;
  L1: do {
    do {
      v1 = 0;
      if (b) break L1;
      v2 = 0;
      v3 = 0;
    } while (b);
    v2;
  } while (b);
  v1;
  v3;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v3' must be assigned before it can be used.
}
''');
  }

  test_doWhile_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v1, v2;
  do {
    v1; // assigned in the condition, but not yet
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  } while ((v1 = 0) + (v2 = 0) >= 0);
  v2;
}
''');
  }

  test_doWhile_condition_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
  } while ((v = 0) >= 0);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_doWhile_condition_break_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b1, b2) {
  int v1, v2, v3, v4, v5, v6;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (b1) break;
    v2 = 0; // not visible outside, visible to the condition
    v3 = 0; // not visible outside, visible to the condition
    if (b2) continue;
    v4 = 0; // not visible
    v5 = 0; // not visible
  } while ((v6 = v1 + v2 + v4) == 0); // has break => v6 is not visible outside
//                         ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v4' must be assigned before it can be used.
  v1;
  v3;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v3' must be assigned before it can be used.
  v5;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v5' must be assigned before it can be used.
  v6;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v6' must be assigned before it can be used.
}
''');
  }

  test_doWhile_condition_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2, v3, v4;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (b) continue;
    v2 = 0; // not visible
    v3 = 0; // not visible
  } while ((v4 = v1 + v2) == 0); // no break => v4 visible outside
//                    ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
  v1;
  v3;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v3' must be assigned before it can be used.
  v4;
}
''');
  }

  test_doWhile_continue_beforeAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  do {
    if (b) continue;
    v = 0;
  } while (b);
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_doWhile_true_assignInBreak() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  do {
    if (b) {
      v = 0;
      break;
    }
  } while (true);
  v;
}
''');
  }

  test_extensionType_hasImplements() async {
    // Extension types are always potentially non-nullable.
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) implements int {}

void f() {
  E v;
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_extensionType_noImplements() async {
    // Extension types are always potentially non-nullable.
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {}

void f() {
  E v;
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_for_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  for (; b;) {
    v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_for_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_for_break_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
}
''');
  }

  test_for_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  for (; (v = 0) >= 0;) {
    v;
  }
  v;
}
''');
  }

  test_for_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_for_continue_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
//               ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
}
''');
  }

  test_for_initializer_expression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  for (v = 0;;) {
    v;
  }
  v;
//^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_for_initializer_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  for (var t = (v = 0);;) {
//         ^
// [diag.unusedLocalVariable] The value of the local variable 't' isn't used.
    v;
  }
  v;
//^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_for_updaters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2, v3, v4;
//            ^^
// [diag.unusedLocalVariable] The value of the local variable 'v3' isn't used.
  for (; b; v1 = 0, v2 = 0, v3 = 0, v4) {
//                                  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v4' must be assigned before it can be used.
    v1;
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  }
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_for_updaters_afterBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  for (; b; v) {
    v = 0;
  }
}
''');
  }

  test_forEach() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  List<int> v1;
  int v2;
  for (var _ in (v1 = [0, 1, 2])) {
    v2 = 0;
  }
  v1;
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_forEach_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_forEach_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v1' must be assigned before it can be used.
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_functionExpression_closure_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v1, v2;

  v1 = 0;

  [0, 1, 2].forEach((t) {
    v1;
    v2;
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
  });
}
''');
  }

  test_functionExpression_closure_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;

  [0, 1, 2].forEach((t) {
    v = t;
  });

  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_functionExpression_localFunction_local() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.

  v = 0;

  void f() {
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
    int v; // 1
    v;
//  ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
  }
}
''');
  }

  test_functionExpression_localFunction_local2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v1;

  v1 = 0;

  void f() {
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
    int v2, v3;
    v2 = 0;
    v1;
    v2;
    v3;
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v3' must be assigned before it can be used.
  }
}
''');
  }

  test_functionExpression_localFunction_read() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v1, v2;

  v1 = 0;

  void f() {
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
    v1;
    v2;
//  ^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
  }

  v2 = 0;
}
''');
  }

  test_functionExpression_localFunction_write() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;

  void f() {
//     ^
// [diag.unusedElement] The declaration 'f' isn't referenced.
    v = 0;
  }

  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_futureOr_questionArgument_none() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

f() {
  FutureOr<int?> v;
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int v = 0;
  v;
}
''');
  }

  test_if_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  int v;
  if ((v = 0) >= 0) {
    v;
  } else {
    v;
  }
  v;
}
''');
  }

  test_if_condition_false() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  if (false) {
// [diag.deadCode][column 14][length 25] Dead code.
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
  }

  test_if_condition_logicalAnd() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
    v;
  } else {
    v;
//  ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_if_condition_logicalOr() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
    v;
//  ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
  } else {
    v;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_if_condition_notFalse() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  if (!false) {
    v = 0;
  }
  v;
}
''');
  }

  test_if_condition_notTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  if (!true) {
// [diag.deadCode][column 14][length 25] Dead code.
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
  }

  test_if_condition_true() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  if (true) {
    v = 0;
  }
  v;
}
''');
  }

  test_if_then() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_if_thenElse_all() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
    v;
  } else {
    v = 0;
    v;
  }
  v;
}
''');
  }

  test_if_thenElse_else() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  if (c) {
    // not assigned
  } else {
    v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_if_thenElse_then() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    // not assigned
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_late() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  late int v;

  void g() {
    v = 0;
  }

  g();
  v;
}
''');
  }

  test_noInitializer() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int v;
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_noInitializer_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
f<T>() {
  T v;
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_notUsed() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  int v;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int? v;
  v;
}
''');
  }

  test_switch_case1_default() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
    case 2:
      // not assigned
      break;
    default:
      v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_switch_case1_default_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
    case 2:
      // not assigned
      break;
    default:
      v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_switch_case2_default() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      v2 = 0;
      v1;
      break;
    default:
      v1 = 0;
      v1;
  }
  v1;
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_switch_case2_default_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      v2 = 0;
      v1;
      break;
    default:
      v1 = 0;
      v1;
  }
  v1;
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_switch_case_default_break() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b, int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      if (b) break;
      v2 = 0;
      break;
    default:
      v1 = 0;
      if (b) break;
      v2 = 0;
  }
  v1;
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_switch_case_default_break_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(bool b, int e) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      if (b) break;
      v2 = 0;
      break;
    default:
      v1 = 0;
      if (b) break;
      v2 = 0;
  }
  v1;
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_switch_case_default_continue() async {
    // We don't analyze to which `case` we go from `continue L`,
    // but we don't have to. If all cases assign, then the variable is
    // removed from the unassigned set in the `breakState`. And if there is a
    // case when it is not assigned, then the variable will be left unassigned
    // in the `breakState`.
    await resolveTestCodeWithDiagnostics(r'''
void f(int e) {
  int v;
  switch (e) {
    L: case 1:
      v = 0;
      break;
    case 2:
      continue L;
    default:
      v = 0;
  }
  v;
}
''');
  }

  test_switch_case_default_continue_language219() async {
    // We don't analyze to which `case` we go from `continue L`,
    // but we don't have to. If all cases assign, then the variable is
    // removed from the unassigned set in the `breakState`. And if there is a
    // case when it is not assigned, then the variable will be left unassigned
    // in the `breakState`.
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int e) {
  int v;
  switch (e) {
    L: case 1:
      v = 0;
      break;
    case 2:
      continue L;
    default:
      v = 0;
  }
  v;
}
''');
  }

  test_switch_case_noDefault() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_switch_case_noDefault_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_switch_expression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  switch (v = 0) {}
  v;
}
''');
  }

  test_switch_expression_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f() {
  int v;
  switch (v = 0) {}
  v;
}
''');
  }

  test_syntheticPatternVariable_orPattern_inIfCase() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case <int>[var a || var a] when a > 0) {
//                       ^^^^^^^^
// [diag.deadCode] Dead code.
    a;
  }
}
''');
  }

  test_syntheticPatternVariable_orPattern_inSwitchExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  (switch (x) {
    <int>[var a || var a] when a > 0 => a,
//              ^^^^^^^^
// [diag.deadCode] Dead code.
    _ => 0,
  });
}
''');
  }

  test_syntheticPatternVariable_orPattern_inSwitchStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case <int>[var a || var a] when a > 0:
//                   ^^^^^^^^
// [diag.deadCode] Dead code.
      a;
  }
}
''');
  }

  test_syntheticPatternVariable_switchCasesSharingABody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case <int>[var a] when a > 0:
    case <int>[var a, 0] when a > 0:
      a;
  }
}
''');
  }

  test_tryCatch_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_tryCatch_body_catch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    g();
    v = 0;
  } catch (_) {
    v = 0;
  }
  v;
}

void g() {}
''');
  }

  test_tryCatch_body_catchRethrow() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    rethrow;
  }
  v;
}
''');
  }

  test_tryCatch_catch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_tryCatchFinally_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  } finally {
    // not assigned
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_tryCatchFinally_catch() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  } finally {
    // not assigned
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_tryCatchFinally_finally() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    // not assigned
  } finally {
    v = 0;
  }
  v;
}
''');
  }

  test_tryCatchFinally_useInFinally() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int x;
  try {
    g(); // may throw an exception
    x = 1;
  } catch (_) {
    x = 1;
  } finally {
    x; // BAD
//  ^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'x' must be assigned before it can be used.
  }
}

void g() {}
''');
  }

  test_tryFinally_body() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    v = 0;
  } finally {
    // not assigned
  }
  v;
}
''');
  }

  test_tryFinally_finally() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  try {
    // not assigned
  } finally {
    v = 0;
  }
  v;
}
''');
  }

  test_type_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  dynamic v;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_type_dynamicImplicit() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  var v;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_type_void() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  void v;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
  }

  test_while_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  while ((v = 0) >= 0) {
    v;
  }
  v;
}
''');
  }

  test_while_condition_notTrue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  while (b) {
    v = 0;
    v;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_while_true_break_afterAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    v1 = 0;
    v1;
    if (b) break;
    v2 = 0;
    v1;
    v2;
  }
  v1;
}
''');
  }

  test_while_true_break_beforeAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) break;
    v = 0;
    v;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
}
''');
  }

  test_while_true_break_if() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) {
      v = 0;
      break;
    } else {
      v = 0;
      break;
    }
    v;
//  ^^
// [diag.deadCode] Dead code.
  }
  v;
}
''');
  }

  test_while_true_break_if2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  var v;
  while (true) {
    if (b) {
      break;
    } else {
      v = 0;
    }
    v;
  }
}
''');
  }

  test_while_true_break_if3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    if (b) {
      v1 = 0;
      v2 = 0;
      if (b) break;
    } else {
      if (b) break;
      v1 = 0;
      v2 = 0;
    }
    v1;
  }
  v2;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v2' must be assigned before it can be used.
}
''');
  }

  test_while_true_breakOuterFromInner() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v1, v2, v3;
  L1: while (true) {
    L2: while (true) {
      v1 = 0;
      if (b) break L1;
      v2 = 0;
      v3 = 0;
      if (b) break L2;
    }
    v2;
  }
  v1;
  v3;
//^^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v3' must be assigned before it can be used.
}
''');
  }

  test_while_true_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) continue;
    v = 0;
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_while_true_noBreak() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int v;
  while (true) {
    // No assignment, but no break.
    // So, we don't exit the loop.
  }
  v;
//^
// [diag.notAssignedPotentiallyNonNullableLocalVariable] The non-nullable local variable 'v' must be assigned before it can be used.
//^^
// [diag.deadCode] Dead code.
}
''');
  }
}
