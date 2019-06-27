// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefiniteAssignmentFlowTest);
    defineReflectiveTests(NullableFlowTest);
    defineReflectiveTests(ReachableFlowTest);
    defineReflectiveTests(TypePromotionFlowTest);
  });
}

@reflectiveTest
class DefiniteAssignmentFlowTest extends DriverResolutionTest {
  FlowAnalysisResult flowResult;

  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  /// Assert that only local variables with the given names are marked as read
  /// before being written.  All the other local variables are implicitly
  /// considered definitely assigned.
  void assertReadBeforeWritten(
      [String name1, String name2, String name3, String name4]) {
    var expected = [name1, name2, name3, name4]
        .where((i) => i != null)
        .map((name) => findElement.localVar(name))
        .toList();
    expect(flowResult.readBeforeWritten, unorderedEquals(expected));
  }

  test_assignment_leftExpression() async {
    await trackCode(r'''
void f() {
  List<int> v;
  v[0] = (v = [1, 2])[1];
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_compound() async {
    await trackCode(r'''
void f() {
  int v;
  v += 1;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_compound_assignInRight() async {
    await trackCode(r'''
void f() {
  int v;
  v += (v = v);
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_eq() async {
    await trackCode(r'''
void f() {
  int v;
  v = 0;
}
''');
    assertReadBeforeWritten();
  }

  test_assignment_leftLocal_pure_eq_self() async {
    await trackCode(r'''
void f() {
  int v;
  v = v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_questionEq() async {
    await trackCode(r'''
void f() {
  int v;
  v ??= 0;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_questionEq_self() async {
    await trackCode(r'''
void f() {
  int v;
  v ??= v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_ifNull_left() async {
    await trackCode(r'''
void f() {
  int v;
  (v = 0) ?? 0;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_ifNull_right() async {
    await trackCode(r'''
void f(int a) {
  int v;
  a ?? (v = 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_logicalAnd_left() async {
    await trackCode(r'''
main(bool c) {
  int v;
  ((v = 0) >= 0) && c;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_logicalAnd_right() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c && ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_logicalOr_left() async {
    await trackCode(r'''
main(bool c) {
  int v;
  ((v = 0) >= 0) || c;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_logicalOr_right() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c || ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_plus_left() async {
    await trackCode(r'''
main() {
  int v;
  (v = 0) + 1;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_plus_right() async {
    await trackCode(r'''
main() {
  int v;
  1 + (v = 0);
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_conditional_both() async {
    await trackCode(r'''
f(bool v) {
  int v;
  b ? (v = 1) : (v = 2);
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_conditional_else() async {
    await trackCode(r'''
f(bool v) {
  int v;
  b ? 1 : (v = 2);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_conditional_then() async {
    await trackCode(r'''
f(bool v) {
  int v;
  b ? (v = 1) : 2;
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_conditionalExpression_condition() async {
    await trackCode(r'''
main() {
  int v;
  (v = 0) >= 0 ? 1 : 2;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_doWhile_break_afterAssignment() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_doWhile_break_beforeAssignment() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
    v = 0;
  } while (b);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_breakOuterFromInner() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v3');
  }

  test_doWhile_condition() async {
    await trackCode(r'''
void f() {
  int v1, v2;
  do {
    v1; // assigned in the condition, but not yet
  } while ((v1 = 0) + (v2 = 0) >= 0);
  v2;
}
''');
    assertReadBeforeWritten('v1');
  }

  test_doWhile_condition_break() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) break;
  } while ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_condition_break_continue() async {
    await trackCode(r'''
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
  v1;
  v3;
  v5;
  v6;
}
''');
    assertReadBeforeWritten('v3', 'v4', 'v5', 'v6');
  }

  test_doWhile_condition_continue() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2, v3, v4;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (b) continue;
    v2 = 0; // not visible
    v3 = 0; // not visible
  } while ((v4 = v1 + v2) == 0); // no break => v4 visible outside
  v1;
  v3;
  v4;
}
''');
    assertReadBeforeWritten('v2', 'v3');
  }

  test_doWhile_continue_beforeAssignment() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  do {
    if (b) continue;
    v = 0;
  } while (b);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_true_assignInBreak() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_for_body() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  for (; b;) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_for_break() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2');
  }

  test_for_break_updaters() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_for_condition() async {
    await trackCode(r'''
void f() {
  int v;
  for (; (v = 0) >= 0;) {
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_for_continue() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b;) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2');
  }

  test_for_continue_updaters() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (; b; v1 + v2) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
}
''');
    assertReadBeforeWritten('v2');
  }

  test_for_initializer_expression() async {
    await trackCode(r'''
void f() {
  int v;
  for (v = 0;;) {
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_for_initializer_variable() async {
    await trackCode(r'''
void f() {
  int v;
  for (var t = (v = 0);;) {
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_for_updaters() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2, v3, v4;
  for (; b; v1 = 0, v2 = 0, v3 = 0, v4) {
    v1;
  }
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2', 'v4');
  }

  test_for_updaters_afterBody() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  for (; b; v) {
    v = 0;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_forEach() async {
    await trackCode(r'''
void f() {
  int v1, v2;
  for (var _ in (v1 = [0, 1, 2])) {
    v2 = 0;
  }
  v1;
  v2;
}
''');
    assertReadBeforeWritten('v2');
  }

  test_forEach_break() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) break;
    v2 = 0;
  }
  v1;
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2');
  }

  test_forEach_continue() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (b) continue;
    v2 = 0;
  }
  v1;
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2');
  }

  test_functionExpression_closure_read() async {
    await trackCode(r'''
void f() {
  int v1, v2;
  
  v1 = 0;
  
  [0, 1, 2].forEach((t) {
    v1;
    v2;
  });
}
''');
    assertReadBeforeWritten('v2');
  }

  test_functionExpression_closure_write() async {
    await trackCode(r'''
void f() {
  int v;
  
  [0, 1, 2].forEach((t) {
    v = t;
  });

  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_functionExpression_localFunction_local() async {
    await trackCode(r'''
void f() {
  int v;

  v = 0;

  void f() {
    int v; // 1
    v;
  }
}
''');
    var localV = findNode.simple('v; // 1').staticElement;
    expect(flowResult.readBeforeWritten, unorderedEquals([localV]));
  }

  test_functionExpression_localFunction_local2() async {
    await trackCode(r'''
void f() {
  int v1;

  v1 = 0;

  void f() {
    int v2, v3;
    v2 = 0;
    v1;
    v2;
    v3;
  }
}
''');
    assertReadBeforeWritten('v3');
  }

  test_functionExpression_localFunction_read() async {
    await trackCode(r'''
void f() {
  int v1, v2, v3;

  v1 = 0;

  void f() {
    v1;
    v2;
  }

  v2 = 0;
}
''');
    assertReadBeforeWritten('v2');
  }

  test_functionExpression_localFunction_write() async {
    await trackCode(r'''
void f() {
  int v;

  void f() {
    v = 0;
  }

  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_condition() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_if_condition_false() async {
    await trackCode(r'''
void f() {
  int v;
  if (false) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalAnd_else() async {
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
  } else {
    v;
  }
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_condition_logicalAnd_then() async {
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b && (v = i) > 0) {
    v;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalOr_else() async {
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
  } else {
    v;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_logicalOr_then() async {
    await trackCode(r'''
void f(bool b, int i) {
  int v;
  if (b || (v = i) > 0) {
    v;
  } else {
  }
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_condition_notFalse() async {
    await trackCode(r'''
void f() {
  int v;
  if (!false) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_notTrue() async {
    await trackCode(r'''
void f() {
  int v;
  if (!true) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_condition_true() async {
    await trackCode(r'''
void f() {
  int v;
  if (true) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_then() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_thenElse_all() async {
    await trackCode(r'''
main(bool c) {
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
    assertReadBeforeWritten();
  }

  test_if_thenElse_else() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    // not assigned
  } else {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_if_thenElse_then() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    // not assigned
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_switch_case1_default() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v');
  }

  test_switch_case2_default() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v2');
  }

  test_switch_case_default_break() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v2');
  }

  test_switch_case_default_continue() async {
    await trackCode(r'''
void f(int e) {
  int v;
  switch (e) {
    L: case 1:
      v = 0;
      break;
    case 2:
      continue L;
      break;
    default:
      v = 0;
  }
  v;
}
''');
    // We don't analyze to which `case` we go from `continue L`,
    // but we don't have to. If all cases assign, then the variable is
    // removed from the unassigned set in the `breakState`. And if there is a
    // case when it is not assigned, then the variable will be left unassigned
    // in the `breakState`.
    assertReadBeforeWritten();
  }

  test_switch_case_noDefault() async {
    await trackCode(r'''
void f(int e) {
  int v;
  switch (e) {
    case 1:
      v = 0;
      break;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_switch_expression() async {
    await trackCode(r'''
void f() {
  int v;
  switch (v = 0) {}
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_tryCatch_body() async {
    await trackCode(r'''
void f() {
  int v;
  try {
    v = 0;
  } catch (_) {
    // not assigned
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_tryCatch_body_catch() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_tryCatch_body_catchRethrow() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_tryCatch_catch() async {
    await trackCode(r'''
void f() {
  int v;
  try {
    // not assigned
  } catch (_) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_tryCatchFinally_body() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v');
  }

  test_tryCatchFinally_catch() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v');
  }

  test_tryCatchFinally_finally() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_tryCatchFinally_useInFinally() async {
    await trackCode(r'''
f() {
  int x;
  try {
    g(); // may throw an exception
    x = 1;
  } catch (_) {
    x = 1;
  } finally {
    x; // BAD
  }
}

void g() {}
''');
    assertReadBeforeWritten('x');
  }

  test_tryFinally_body() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_tryFinally_finally() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_while_condition() async {
    await trackCode(r'''
void f() {
  int v;
  while ((v = 0) >= 0) {
    v;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_while_condition_notTrue() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  while (b) {
    v1 = 0;
    v2 = 0;
    v1;
  }
  v2;
}
''');
    assertReadBeforeWritten('v2');
  }

  test_while_true_break_afterAssignment() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    v1 = 0;
    v1;
    if (b) break;
    v1;
    v2 = 0;
    v2;
  }
  v1;
}
''');
    assertReadBeforeWritten();
  }

  test_while_true_break_beforeAssignment() async {
    await trackCode(r'''
void f(bool b) {
  int v1, v2;
  while (true) {
    if (b) break;
    v1 = 0;
    v2 = 0;
    v2;
  }
  v1;
}
''');
    assertReadBeforeWritten('v1');
  }

  test_while_true_break_if() async {
    await trackCode(r'''
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
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_while_true_break_if2() async {
    await trackCode(r'''
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
    assertReadBeforeWritten();
  }

  test_while_true_break_if3() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v2');
  }

  test_while_true_breakOuterFromInner() async {
    await trackCode(r'''
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
}
''');
    assertReadBeforeWritten('v3');
  }

  test_while_true_continue() async {
    await trackCode(r'''
void f(bool b) {
  int v;
  while (true) {
    if (b) continue;
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_while_true_noBreak() async {
    await trackCode(r'''
void f() {
  int v;
  while (true) {
    // No assignment, but no break.
    // So, we don't exit the loop.
    // So, all variables are assigned.
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  /// Resolve the given [code] and track assignments in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var unit = result.unit;
    flowResult = FlowAnalysisResult.getFromNode(unit);
  }
}

@reflectiveTest
class NullableFlowTest extends DriverResolutionTest {
  FlowAnalysisResult flowResult;

  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  void assertNonNullable([
    String search1,
    String search2,
    String search3,
    String search4,
    String search5,
  ]) {
    var expected = [search1, search2, search3, search4, search5]
        .where((i) => i != null)
        .map((search) => findNode.simple(search))
        .toList();
    expect(flowResult.nonNullableNodes, unorderedEquals(expected));
  }

  void assertNullable([
    String search1,
    String search2,
    String search3,
    String search4,
    String search5,
  ]) {
    var expected = [search1, search2, search3, search4, search5]
        .where((i) => i != null)
        .map((search) => findNode.simple(search))
        .toList();
    expect(flowResult.nullableNodes, unorderedEquals(expected));
  }

  test_assign_toNonNull() async {
    await trackCode(r'''
void f(int x) {
  if (x != null) return;
  x; // 1
  x = 0;
  x; // 2
}
''');
    assertNullable('x; // 1');
    assertNonNullable('x; // 2');
  }

  test_assign_toNull() async {
    await trackCode(r'''
void f(int x) {
  if (x == null) return;
  x; // 1
  x = null;
  x; // 2
}
''');
    assertNullable('x; // 2');
    assertNonNullable('x; // 1');
  }

  test_assign_toUnknown_fromNotNull() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a == null) return;
  a; // 1
  a = b;
  a; // 2
}
''');
    assertNullable();
    assertNonNullable('a; // 1');
  }

  test_assign_toUnknown_fromNull() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a != null) return;
  a; // 1
  a = b;
  a; // 2
}
''');
    assertNullable('a; // 1');
    assertNonNullable();
  }

  test_binaryExpression_logicalAnd() async {
    await trackCode(r'''
void f(int x) {
  x == null && x.isEven;
}
''');
    assertNullable('x.isEven');
    assertNonNullable();
  }

  test_binaryExpression_logicalOr() async {
    await trackCode(r'''
void f(int x) {
  x == null || x.isEven;
}
''');
    assertNullable();
    assertNonNullable('x.isEven');
  }

  test_constructor_if_then_else() async {
    await trackCode(r'''
class C {
  C(int x) {
    if (x == null) {
      x; // 1
    } else {
      x; // 2
    }
  }
}
''');
    assertNullable('x; // 1');
    assertNonNullable('x; // 2');
  }

  test_if_joinThenElse_ifNull() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a == null) {
    a; // 1
    if (b == null) return;
    b; // 2
  } else {
    a; // 3
    if (b == null) return;
    b; // 4
  }
  a; // 5
  b; // 6
}
''');
    assertNullable('a; // 1');
    assertNonNullable('b; // 2', 'a; // 3', 'b; // 4', 'b; // 6');
  }

  test_if_notNull_thenExit_left() async {
    await trackCode(r'''
void f(int x) {
  if (null != x) return;
  x; // 1
}
''');
    assertNullable('x; // 1');
    assertNonNullable();
  }

  test_if_notNull_thenExit_right() async {
    await trackCode(r'''
void f(int x) {
  if (x != null) return;
  x; // 1
}
''');
    assertNullable('x; // 1');
    assertNonNullable();
  }

  test_if_null_thenExit_left() async {
    await trackCode(r'''
void f(int x) {
  if (null == x) return;
  x; // 1
}
''');
    assertNullable();
    assertNonNullable('x; // 1');
  }

  test_if_null_thenExit_right() async {
    await trackCode(r'''
void f(int x) {
  if (x == null) return;
  x; // 1
}
''');
    assertNullable();
    assertNonNullable('x; // 1');
  }

  test_if_then_else() async {
    await trackCode(r'''
void f(int x) {
  if (x == null) {
    x; // 1
  } else {
    x; // 2
  }
}
''');
    assertNullable('x; // 1');
    assertNonNullable('x; // 2');
  }

  test_method_if_then_else() async {
    await trackCode(r'''
class C {
  void f(int x) {
    if (x == null) {
      x; // 1
    } else {
      x; // 2
    }
  }
}
''');
    assertNullable('x; // 1');
    assertNonNullable('x; // 2');
  }

  test_potentiallyMutatedInClosure() async {
    await trackCode(r'''
f(int a, int b) {
  localFunction() {
    a = b;
  }

  if (a == null) {
    a; // 1
    localFunction();
    a; // 2
  }
}
''');
    assertNullable();
    assertNonNullable();
  }

  test_tryFinally_eqNullExit_body() async {
    await trackCode(r'''
void f(int x) {
  try {
    if (x == null) return;
    x; // 1
  } finally {
    x; // 2
  }
  x; // 3
}
''');
    assertNullable();
    assertNonNullable('x; // 1', 'x; // 3');
  }

  test_tryFinally_eqNullExit_finally() async {
    await trackCode(r'''
void f(int x) {
  try {
    x; // 1
  } finally {
    if (x == null) return;
    x; // 2
  }
  x; // 3
}
''');
    assertNullable();
    assertNonNullable('x; // 2', 'x; // 3');
  }

  test_tryFinally_outerEqNotNullExit_assignUnknown_body() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a != null) return;
  try {
    a; // 1
    a = b;
    a; // 2
  } finally {
    a; // 3
  }
  a; // 4
}
''');
    assertNullable('a; // 1');
    assertNonNullable();
  }

  test_tryFinally_outerEqNullExit_assignUnknown_body() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a == null) return;
  try {
    a; // 1
    a = b;
    a; // 2
  } finally {
    a; // 3
  }
  a; // 4
}
''');
    assertNullable();
    assertNonNullable('a; // 1');
  }

  test_tryFinally_outerEqNullExit_assignUnknown_finally() async {
    await trackCode(r'''
void f(int a, int b) {
  if (a == null) return;
  try {
    a; // 1
  } finally {
    a; // 2
    a = b;
    a; // 3
  }
  a; // 4
}
''');
    assertNullable();
    assertNonNullable('a; // 1', 'a; // 2');
  }

  test_while_eqNull() async {
    await trackCode(r'''
void f(int x) {
  while (x == null) {
    x; // 1
  }
  x; // 2
}
''');
    assertNullable('x; // 1');
    assertNonNullable('x; // 2');
  }

  test_while_notEqNull() async {
    await trackCode(r'''
void f(int x) {
  while (x != null) {
    x; // 1
  }
  x; // 2
}
''');
    assertNullable('x; // 2');
    assertNonNullable('x; // 1');
  }

  /// Resolve the given [code] and track nullability in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var unit = result.unit;
    flowResult = FlowAnalysisResult.getFromNode(unit);
  }
}

@reflectiveTest
class ReachableFlowTest extends DriverResolutionTest {
  FlowAnalysisResult flowResult;

  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_conditional_false() async {
    await trackCode(r'''
void f() {
  false ? 1 : 2;
}
''');
    verify(unreachableExpressions: ['1']);
  }

  test_conditional_true() async {
    await trackCode(r'''
void f() {
  true ? 1 : 2;
}
''');
    verify(unreachableExpressions: ['2']);
  }

  test_do_false() async {
    await trackCode(r'''
void f() {
  do {
    1;
  } while (false);
  2;
}
''');
    verify();
  }

  test_do_true() async {
    await trackCode(r'''
void f() { // f
  do {
    1;
  } while (true);
  2;
}
''');
    verify(
      unreachableStatements: ['2;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_exit_beforeSplitStatement() async {
    await trackCode(r'''
void f(bool b, int i) { // f
  return;
  do {} while (b);
  for (;;) {}
  for (_ in []) {}
  if (b) {}
  switch (i) {}
  try {} finally {}
  while (b) {}
}
''');
    verify(
      unreachableStatements: [
        'do {}',
        'for (;;',
        'for (_',
        'if (b)',
        'try {',
        'switch (i)',
        'while (b) {}'
      ],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_for_condition_true() async {
    await trackCode(r'''
void f() { // f
  for (; true;) {
    1;
  }
  2;
}
''');
    verify(
      unreachableStatements: ['2;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_for_condition_true_implicit() async {
    await trackCode(r'''
void f() { // f
  for (;;) {
    1;
  }
  2;
}
''');
    verify(
      unreachableStatements: ['2;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_forEach() async {
    await trackCode(r'''
void f() {
  for (_ in [0, 1, 2]) {
    1;
    return;
  }
  2;
}
''');
    verify();
  }

  test_functionBody_hasReturn() async {
    await trackCode(r'''
int f() { // f
  return 42;
}
''');
    verify(functionBodiesThatDontComplete: ['{ // f']);
  }

  test_functionBody_noReturn() async {
    await trackCode(r'''
void f() {
  1;
}
''');
    verify();
  }

  test_if_condition() async {
    await trackCode(r'''
void f(bool b) {
  if (b) {
    1;
  } else {
    2;
  }
  3;
}
''');
    verify();
  }

  test_if_false_then_else() async {
    await trackCode(r'''
void f() {
  if (false) { // 1
    1;
  } else { // 2
  }
  3;
}
''');
    verify(unreachableStatements: ['{ // 1']);
  }

  test_if_true_return() async {
    await trackCode(r'''
void f() { // f
  1;
  if (true) {
    return;
  }
  2;
}
''');
    verify(
      unreachableStatements: ['2;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_if_true_then_else() async {
    await trackCode(r'''
void f() {
  if (true) { // 1
  } else { // 2
    2;
  }
  3;
}
''');
    verify(unreachableStatements: ['{ // 2']);
  }

  test_logicalAnd_leftFalse() async {
    await trackCode(r'''
void f(int x) {
  false && (x == 1);
}
''');
    verify(unreachableExpressions: ['(x == 1)']);
  }

  test_logicalOr_leftTrue() async {
    await trackCode(r'''
void f(int x) {
  true || (x == 1);
}
''');
    verify(unreachableExpressions: ['(x == 1)']);
  }

  test_switch_case_neverCompletes() async {
    await trackCode(r'''
void f(bool b, int i) {
  switch (i) {
    case 1:
      1;
      if (b) {
        return;
      } else {
        return;
      }
      2;
  }
  3;
}
''');
    verify(unreachableStatements: ['2;']);
  }

  test_tryCatch() async {
    await trackCode(r'''
void f() {
  try {
    1;
  } catch (_) {
    2;
  }
  3;
}
''');
    verify();
  }

  test_tryCatch_return_body() async {
    await trackCode(r'''
void f() {
  try {
    1;
    return;
    2;
  } catch (_) {
    3;
  }
  4;
}
''');
    verify(unreachableStatements: ['2;']);
  }

  test_tryCatch_return_catch() async {
    await trackCode(r'''
void f() {
  try {
    1;
  } catch (_) {
    2;
    return;
    3;
  }
  4;
}
''');
    verify(unreachableStatements: ['3;']);
  }

  test_tryCatchFinally_return_body() async {
    await trackCode(r'''
void f() {
  try {
    1;
    return;
  } catch (_) {
    2;
  } finally {
    3;
  }
  4;
}
''');
    verify();
  }

  test_tryCatchFinally_return_bodyCatch() async {
    await trackCode(r'''
void f() { // f
  try {
    1;
    return;
  } catch (_) {
    2;
    return;
  } finally {
    3;
  }
  4;
}
''');
    verify(
      unreachableStatements: ['4;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_tryCatchFinally_return_catch() async {
    await trackCode(r'''
void f() {
  try {
    1;
  } catch (_) {
    2;
    return;
  } finally {
    3;
  }
  4;
}
''');
    verify();
  }

  test_tryFinally_return_body() async {
    await trackCode(r'''
void f() { // f
  try {
    1;
    return;
  } finally {
    2;
  }
  3;
}
''');
    verify(
      unreachableStatements: ['3;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_while_false() async {
    await trackCode(r'''
void f() {
  while (false) { // 1
    1;
  }
  2;
}
''');
    verify(unreachableStatements: ['{ // 1']);
  }

  test_while_true() async {
    await trackCode(r'''
void f() { // f
  while (true) {
    1;
  }
  2;
  3;
}
''');
    verify(
      unreachableStatements: ['2;', '3;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  test_while_true_break() async {
    await trackCode(r'''
void f() {
  while (true) {
    1;
    break;
    2;
  }
  3;
}
''');
    verify(unreachableStatements: ['2;']);
  }

  test_while_true_breakIf() async {
    await trackCode(r'''
void f(bool b) {
  while (true) {
    1;
    if (b) break;
    2;
  }
  3;
}
''');
    verify();
  }

  test_while_true_continue() async {
    await trackCode(r'''
void f() { // f
  while (true) {
    1;
    continue;
    2;
  }
  3;
}
''');
    verify(
      unreachableStatements: ['2;', '3;'],
      functionBodiesThatDontComplete: ['{ // f'],
    );
  }

  /// Resolve the given [code] and track unreachable nodes in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var unit = result.unit;
    flowResult = FlowAnalysisResult.getFromNode(unit);
  }

  void verify({
    List<String> unreachableExpressions = const [],
    List<String> unreachableStatements = const [],
    List<String> functionBodiesThatDontComplete = const [],
  }) {
    var expectedUnreachableNodes = <AstNode>[];
    expectedUnreachableNodes.addAll(
      unreachableStatements.map((search) => findNode.statement(search)),
    );
    expectedUnreachableNodes.addAll(
      unreachableExpressions.map((search) => findNode.expression(search)),
    );

    expect(
      flowResult.unreachableNodes,
      unorderedEquals(expectedUnreachableNodes),
    );
    expect(
      flowResult.functionBodiesThatDontComplete,
      unorderedEquals(
        functionBodiesThatDontComplete
            .map((search) => findNode.functionBody(search))
            .toList(),
      ),
    );
  }
}

@reflectiveTest
class TypePromotionFlowTest extends DriverResolutionTest {
  FlowAnalysisResult flowResult;

  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  void assertNotPromoted(String search) {
    var node = findNode.simple(search);
    var actualType = flowResult.promotedTypes[node];
    expect(actualType, isNull, reason: search);
  }

  void assertPromoted(String search, String expectedType) {
    var node = findNode.simple(search);
    var actualType = flowResult.promotedTypes[node];
    if (actualType == null) {
      fail('$expectedType expected, but actually not promoted\n$search');
    }
    assertElementTypeString(actualType, expectedType);
  }

  test_assignment() async {
    await trackCode(r'''
f(Object x) {
  if (x is String) {
    x = 42;
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_binaryExpression_ifNull() async {
    await trackCode(r'''
void f(Object x) {
  ((x is num) || (throw 1)) ?? ((x is int) || (throw 2));
  x; // 1
}
''');
    assertPromoted('x; // 1', 'num');
  }

  test_binaryExpression_ifNull_rightUnPromote() async {
    await trackCode(r'''
void f(Object x, Object y, Object z) {
  if (x is int) {
    x; // 1
    y ?? (x = z);
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'int');
    assertNotPromoted('x; // 2');
  }

  test_conditional_both() async {
    await trackCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : ((x is int) || (throw 2));
  x; // 1
}
''');
    assertPromoted('x; // 1', 'num');
  }

  test_conditional_else() async {
    await trackCode(r'''
void f(bool b, Object x) {
  b ? 0 : ((x is int) || (throw 2));
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_conditional_then() async {
    await trackCode(r'''
void f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : 0;
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_do_condition_isNotType() async {
    await trackCode(r'''
void f(Object x) {
  do {
    x; // 1
    x = '';
  } while (x is! String)
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
  }

  test_do_condition_isType() async {
    await trackCode(r'''
void f(Object x) {
  do {
    x; // 1
  } while (x is String)
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
    } while (b);
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_do_outerIsType_loopAssigned_body() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
      x = x.length;
    } while (b);
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType_loopAssigned_condition() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
      x = x.length;
    } while (x != 0);
    x; // 2
  }
}
''');
    assertNotPromoted('x != 0');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_do_outerIsType_loopAssigned_condition2() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    do {
      x; // 1
    } while ((x = 1) != 0);
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_for_outerIsType_loopAssigned_body() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b;) {
      x; // 1
      x = 42;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType_loopAssigned_condition() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    for (; (x = 42) > 0;) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_for_outerIsType_loopAssigned_updaters() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    for (; b; x = 42) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_forEach_outerIsType_loopAssigned() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    for (var _ in (v1 = [0, 1, 2])) {
      x; // 1
      x = 42;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_functionExpression_isType() async {
    await trackCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      x; // 1
    }
    x = 42;
  }
}
''');
    assertPromoted('x; // 1', 'String');
  }

  test_functionExpression_isType_mutatedInClosure2() async {
    await trackCode(r'''
void f() {
  void g(Object x) {
    if (x is String) {
      x; // 1
    }
    
    void h() {
      x = 42;
    }
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_functionExpression_outerIsType_assignedOutside() async {
    await trackCode(r'''
void f(Object x) {
  void Function() g;
  
  if (x is String) {
    x; // 1

    g = () {
      x; // 2
    }
  }

  x = 42;
  x; // 3
  g();
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
  }

  test_if_combine_empty() async {
    await trackCode(r'''
main(bool b, Object v) {
  if (b) {
    v is int || (throw 1);
  } else {
    v is String || (throw 2);
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 3');
  }

  test_if_conditional_isNotType() async {
    await trackCode(r'''
f(bool b, Object v) {
  if (b ? (v is! int) : (v is! num)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'num');
    assertNotPromoted('v; // 3');
  }

  test_if_conditional_isType() async {
    await trackCode(r'''
f(bool b, Object v) {
  if (b ? (v is int) : (v is num)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertPromoted('v; // 1', 'num');
    assertNotPromoted('v; // 2');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType() async {
    await trackCode(r'''
main(v) {
  if (v is! String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_if_isNotType_return() async {
    await trackCode(r'''
main(v) {
  if (v is! String) return;
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_if_isNotType_throw() async {
    await trackCode(r'''
main(v) {
  if (v is! String) throw 42;
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_if_isType() async {
    await trackCode(r'''
main(v) {
  if (v is String) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertPromoted('v; // 1', 'String');
    assertNotPromoted('v; // 2');
    assertNotPromoted('v; // 3');
  }

  test_if_isType_thenNonBoolean() async {
    await trackCode(r'''
f(Object x) {
  if ((x is String) != 3) {
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_if_logicalNot_isType() async {
    await trackCode(r'''
main(v) {
  if (!(v is String)) {
    v; // 1
  } else {
    v; // 2
  }
  v; // 3
}
''');
    assertNotPromoted('v; // 1');
    assertPromoted('v; // 2', 'String');
    assertNotPromoted('v; // 3');
  }

  test_if_then_isNotType_return() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (b) {
    if (x is! String) return;
  }
  x; // 1
}
''');
    assertNotPromoted('x; // 1');
  }

  test_logicalOr_throw() async {
    await trackCode(r'''
main(v) {
  v is String || (throw 42);
  v; // ref
}
''');
    assertPromoted('v; // ref', 'String');
  }

  test_potentiallyMutatedInClosure() async {
    await trackCode(r'''
f(Object x) {
  localFunction() {
    x = 42;
  }

  if (x is String) {
    localFunction();
    x; // 1
  }
}
''');
    assertNotPromoted('x; // 1');
  }

  test_potentiallyMutatedInScope() async {
    await trackCode(r'''
f(Object x) {
  if (x is String) {
    x; // 1
  }

  x = 42;
}
''');
    assertPromoted('x; // 1', 'String');
  }

  test_switch_outerIsType_assignedInCase() async {
    await trackCode(r'''
void f(int e, Object x) {
  if (x is String) {
    switch (e) {
      L: case 1:
        x; // 1
        break;
      case 2: // no label
        x; // 2
        break;
      case 3:
        x = 42;
        continue L;
    }
    x; // 3
  }
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_tryCatch_assigned_body() async {
    await trackCode(r'''
void f(Object x) {
  if (x is! String) return;
  x; // 1
  try {
    x = 42;
    g(); // might throw
    if (x is! String) return;
    x; // 2
  } catch (_) {}
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_tryCatch_isNotType_exit_body() async {
    await trackCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {}
  x; // 2
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_tryCatch_isNotType_exit_body_catch() async {
    await trackCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {
    if (x is! String) return;
    x; // 2
  }
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertPromoted('x; // 3', 'String');
  }

  test_tryCatch_isNotType_exit_body_catchRethrow() async {
    await trackCode(r'''
void f(Object x) {
  try {
    if (x is! String) return;
    x; // 1
  } catch (_) {
    x; // 2
    rethrow;
  }
  x; // 3
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertPromoted('x; // 3', 'String');
  }

  test_tryCatch_isNotType_exit_catch() async {
    await trackCode(r'''
void f(Object x) {
  try {
  } catch (_) {
    if (x is! String) return;
    x; // 1
  }
  x; // 2
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_tryCatchFinally_outerIsType() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } catch (_) {
      x; // 2
    } finally {
      x; // 3
    }
    x; // 4
  }
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertPromoted('x; // 3', 'String');
    assertPromoted('x; // 4', 'String');
  }

  test_tryCatchFinally_outerIsType_assigned_body() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
      x = 42;
      g();
    } catch (_) {
      x; // 2
    } finally {
      x; // 3
    }
    x; // 4
  }
}

void g() {}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
    assertNotPromoted('x; // 4');
  }

  test_tryCatchFinally_outerIsType_assigned_catch() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } catch (_) {
      x; // 2
      x = 42;
    } finally {
      x; // 3
    }
    x; // 4
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
    assertNotPromoted('x; // 4');
  }

  test_tryFinally_outerIsType_assigned_body() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
      x = 42;
    } finally {
      x; // 2
    }
    x; // 3
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
    assertNotPromoted('x; // 3');
  }

  test_tryFinally_outerIsType_assigned_finally() async {
    await trackCode(r'''
void f(Object x) {
  if (x is String) {
    try {
      x; // 1
    } finally {
      x; // 2
      x = 42;
    }
    x; // 3
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
    assertNotPromoted('x; // 3');
  }

  test_while_condition_false() async {
    await trackCode(r'''
void f(Object x) {
  while (x is! String) {
    x; // 1
  }
  x; // 2
}
''');
    assertNotPromoted('x; // 1');
    assertPromoted('x; // 2', 'String');
  }

  test_while_condition_true() async {
    await trackCode(r'''
void f(Object x) {
  while (x is String) {
    x; // 1
  }
  x; // 2
}
''');
    assertPromoted('x; // 1', 'String');
    assertNotPromoted('x; // 2');
  }

  test_while_outerIsType() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      x; // 1
    }
    x; // 2
  }
}
''');
    assertPromoted('x; // 1', 'String');
    assertPromoted('x; // 2', 'String');
  }

  test_while_outerIsType_loopAssigned_body() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (b) {
      x; // 1
      x = x.length;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  test_while_outerIsType_loopAssigned_condition() async {
    await trackCode(r'''
void f(bool b, Object x) {
  if (x is String) {
    while (x != 0) {
      x; // 1
      x = x.length;
    }
    x; // 2
  }
}
''');
    assertNotPromoted('x != 0');
    assertNotPromoted('x; // 1');
    assertNotPromoted('x; // 2');
  }

  /// Resolve the given [code] and track assignments in the unit.
  Future<void> trackCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    var unit = result.unit;
    flowResult = FlowAnalysisResult.getFromNode(unit);
  }
}
