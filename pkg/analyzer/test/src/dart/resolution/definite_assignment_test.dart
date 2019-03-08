// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/definite_assignment.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefiniteAssignmentTrackerTest);
  });
}

@reflectiveTest
class DefiniteAssignmentTrackerTest extends DriverResolutionTest
    with PackageMixin {
  DefiniteAssignmentTracker tracker;

  /// Assert that only local variables with the given names are marked as read
  /// before being written.  All the other local variables are implicitly
  /// considered definitely assigned.
  void assertReadBeforeWritten(
      [String name1, String name2, String name3, String name4]) {
    var expected = [name1, name2, name3, name4]
        .where((i) => i != null)
        .map((name) => findElement.localVar(name))
        .toList();
    expect(tracker.readBeforeWritten, unorderedEquals(expected));
  }

  test_assert() async {
    await trackCode(r'''
main() {
  int v;
  assert((v = 0) >= 0, v);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftExpression() async {
    await trackCode(r'''
main() {
  List<int> v;
  v[0] = (v = [1, 2])[1];
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_compound() async {
    await trackCode(r'''
main() {
  int v;
  v += 1;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_compound_assignInRight() async {
    await trackCode(r'''
main() {
  int v;
  v += (v = v);
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_eq() async {
    await trackCode(r'''
main() {
  int v;
  v = 0;
}
''');
    assertReadBeforeWritten();
  }

  test_assignment_leftLocal_pure_eq_self() async {
    await trackCode(r'''
main() {
  int v;
  v = v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_questionEq() async {
    await trackCode(r'''
main() {
  int v;
  v ??= 0;
}
''');
    assertReadBeforeWritten('v');
  }

  test_assignment_leftLocal_pure_questionEq_self() async {
    await trackCode(r'''
main() {
  int v;
  v ??= v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_binaryExpression_ifNull_left() async {
    await trackCode(r'''
main() {
  int v;
  (v = 0) ?? 0;
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_binaryExpression_ifNull_right() async {
    await trackCode(r'''
main(int a) {
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

  test_conditionalExpression_both() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c ? (v = 0) : (v = 0);
  v;
}
''');
    assertReadBeforeWritten();
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

  test_conditionalExpression_else() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c ? (v = 0) : 2;
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_conditionalExpression_then() async {
    await trackCode(r'''
main(bool c) {
  int v;
  c ? (v = 0) : 2;
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_break_afterAssignment() async {
    await trackCode(r'''
main(bool c) {
  int v;
  do {
    v = 0;
    v;
    if (c) break;
  } while (c);
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_doWhile_break_beforeAssignment() async {
    await trackCode(r'''
main(bool c) {
  int v;
  do {
    if (c) break;
    v = 0;
  } while (c);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_breakOuterFromInner() async {
    await trackCode(r'''
main(bool c) {
  int v1, v2, v3;
  L1: do {
    do {
      v1 = 0;
      if (c) break L1;
      v2 = 0;
      v3 = 0;
    } while (c);
    v2;
  } while (c);
  v1;
  v3;
}
''');
    assertReadBeforeWritten('v3');
  }

  test_doWhile_condition() async {
    await trackCode(r'''
main() {
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
main(bool c) {
  int v;
  do {
    if (c) break;
  } while ((v = 0) >= 0);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_doWhile_condition_break_continue() async {
    await trackCode(r'''
main(bool c1, bool c2) {
  int v1, v2, v3, v4, v5, v6;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (c1) break;
    v2 = 0; // not visible outside, visible to the condition
    v3 = 0; // not visible outside, visible to the condition
    if (c2) continue;
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
main(bool c) {
  int v1, v2, v3, v4;
  do {
    v1 = 0; // visible outside, visible to the condition
    if (c) continue;
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
main(bool c) {
  int v;
  do {
    if (c) continue;
    v = 0;
  } while (c);
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_for_body() async {
    await trackCode(r'''
main(bool c) {
  int v;
  for (; c;) {
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten('v');
  }

  test_for_break() async {
    await trackCode(r'''
main(bool c) {
  int v1, v2;
  for (; c;) {
    v1 = 0;
    if (c) break;
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
main(bool c) {
  int v1, v2;
  for (; c; v1 + v2) {
    v1 = 0;
    if (c) break;
    v2 = 0;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_for_condition() async {
    await trackCode(r'''
main() {
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
main(bool c) {
  int v1, v2;
  for (; c;) {
    v1 = 0;
    if (c) continue;
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
main(bool c) {
  int v1, v2;
  for (; c; v1 + v2) {
    v1 = 0;
    if (c) continue;
    v2 = 0;
  }
}
''');
    assertReadBeforeWritten('v2');
  }

  test_for_initializer_expression() async {
    await trackCode(r'''
main() {
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
main() {
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
main(bool c) {
  int v1, v2, v3, v4;
  for (; c; v1 = 0, v2 = 0, v3 = 0, v4) {
    v1;
  }
  v2;
}
''');
    assertReadBeforeWritten('v1', 'v2', 'v4');
  }

  test_for_updaters_afterBody() async {
    await trackCode(r'''
main(bool c) {
  int v;
  for (; c; v) {
    v = 0;
  }
}
''');
    assertReadBeforeWritten();
  }

  test_forEach() async {
    await trackCode(r'''
main() {
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
main(bool c) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) break;
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
main(bool c) {
  int v1, v2;
  for (var _ in [0, 1, 2]) {
    v1 = 0;
    if (c) continue;
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
main() {
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
main() {
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
main() {
  int v;

  v = 0;

  void f() {
    int v; // 1
    v;
  }
}
''');
    var localV = findNode.simple('v; // 1').staticElement;
    expect(tracker.readBeforeWritten, unorderedEquals([localV]));
  }

  test_functionExpression_localFunction_local2() async {
    await trackCode(r'''
main() {
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
main() {
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
main() {
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

  test_if_thenElse_then_exit_alwaysThrows() async {
    addMetaPackage();
    await trackCode(r'''
import 'package:meta/meta.dart';

main(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    foo();
  }
  v;
}

@alwaysThrows
void foo() {}
''');
    assertReadBeforeWritten();
  }

  test_if_thenElse_then_exit_return() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    return;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_if_thenElse_then_exit_throw() async {
    await trackCode(r'''
main(bool c) {
  int v;
  if (c) {
    v = 0;
  } else {
    throw 42;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_switch_case1_default() async {
    await trackCode(r'''
main(int e) {
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
main(int e) {
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
main(int e, bool c) {
  int v1, v2;
  switch (e) {
    case 1:
      v1 = 0;
      if (c) break;
      v2 = 0;
      break;
    default:
      v1 = 0;
      if (c) break;
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
main(int e) {
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
    // We don't analyze to which `case` we go from `continue L`,
    // but we don't have to. If all cases assign, then the variable is
    // not in the `breakSet`. And if there is a case when it is not assigned,
    // we the variable will be left in the `breakSet`.
    assertReadBeforeWritten();
  }

  test_switch_case_noDefault() async {
    await trackCode(r'''
main(int e) {
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

  test_switch_condition() async {
    await trackCode(r'''
main() {
  int v;
  switch (v = 0) {}
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_tryCatch_all() async {
    await trackCode(r'''
main() {
  int v;
  try {
    f();
    v = 0;
  } catch (_) {
    v = 0;
  }
  v;
}

void f() {}
''');
    assertReadBeforeWritten();
  }

  test_tryCatch_catch() async {
    await trackCode(r'''
main() {
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

  test_tryCatch_try() async {
    await trackCode(r'''
main() {
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

  test_tryCatchFinally_catch() async {
    await trackCode(r'''
main() {
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
main() {
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

  test_tryCatchFinally_try() async {
    await trackCode(r'''
main() {
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

  test_tryFinally_finally() async {
    await trackCode(r'''
main() {
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

  test_tryFinally_try() async {
    await trackCode(r'''
main() {
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

  test_while_condition() async {
    await trackCode(r'''
main() {
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
main(bool c) {
  int v1, v2;
  while (c) {
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
main(bool c) {
  int v1, v2;
  while (true) {
    v1 = 0;
    v1;
    if (c) break;
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
main(bool c) {
  int v1, v2;
  while (true) {
    if (c) break;
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
main(bool c) {
  int v;
  while (true) {
    if (c) {
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
main(bool c) {
  var v;
  while (true) {
    if (c) {
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
main(bool c) {
  int v1, v2;
  while (true) {
    if (c) {
      v1 = 0;
      v2 = 0;
      if (c) break;
    } else {
      if (c) break;
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
main(bool c) {
  int v1, v2, v3;
  L1: while (true) {
    L2: while (true) {
      v1 = 0;
      if (c) break L1;
      v2 = 0;
      v3 = 0;
      if (c) break L2;
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
main(bool c) {
  int v;
  while (true) {
    if (c) continue;
    v = 0;
  }
  v;
}
''');
    assertReadBeforeWritten();
  }

  test_while_true_noBreak() async {
    await trackCode(r'''
main(bool c) {
  int v;
  while (true) {
    // No assignment, but not break.
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

    tracker = DefiniteAssignmentTracker();

    var visitor = _AstVisitor(tracker);
    result.unit.accept(visitor);
  }
}

/// [AstVisitor] that drives the [tracker] in the way we expect the resolver
/// will do in production.
class _AstVisitor extends RecursiveAstVisitor<void> {
  final DefiniteAssignmentTracker tracker;

  _AstVisitor(this.tracker);

  @override
  void visitAssertStatement(AssertStatement node) {
    tracker.beginAssertStatement();
    super.visitAssertStatement(node);
    tracker.endAssertStatement();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    LocalVariableElement localElement;
    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is LocalVariableElement) {
        localElement = element;
      }
    }

    if (localElement != null) {
      var isPure = node.operator.type == TokenType.EQ;
      if (!isPure) {
        tracker.read(localElement);
      }
      right.accept(this);
      tracker.write(localElement);
    } else {
      left.accept(this);
      right.accept(this);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var left = node.leftOperand;
    var right = node.rightOperand;

    var operator = node.operator.type;
    var isLogical = operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.QUESTION_QUESTION;

    left.accept(this);

    if (isLogical) {
      tracker.beginBinaryExpressionLogicalRight();
    }

    right.accept(this);

    if (isLogical) {
      tracker.endBinaryExpressionLogicalRight();
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    tracker.handleBreak(target);
    super.visitBreakStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var condition = node.condition;
    var thenExpression = node.thenExpression;
    var elseExpression = node.elseExpression;

    condition.accept(this);

    tracker.beginConditionalExpressionThen();
    thenExpression.accept(this);

    tracker.beginConditionalExpressionElse();
    elseExpression.accept(this);

    tracker.endConditionalExpression();
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    tracker.handleContinue(target);
    super.visitContinueStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    var body = node.body;
    var condition = node.condition;

    tracker.beginDoWhileStatement(node);
    body.accept(this);

    tracker.beginDoWhileStatementCondition();
    condition.accept(this);

    tracker.endDoWhileStatement();
  }

  @override
  void visitForStatement2(ForStatement2 node) {
    var parts = node.forLoopParts;

    tracker.beginForStatement2(node);

    if (parts is ForParts) {
      if (parts is ForPartsWithDeclarations) {
        parts.variables?.accept(this);
      } else if (parts is ForPartsWithExpression) {
        parts.initialization?.accept(this);
      } else {
        throw new StateError('Unrecognized for loop parts');
      }
      parts.condition?.accept(this);
    } else if (parts is ForEachParts) {
      parts.iterable.accept(this);
    } else {
      throw new StateError('Unrecognized for loop parts');
    }

    tracker.beginForStatement2Body();
    node.body?.accept(this);

    if (parts is ForParts) {
      tracker.beginForStatementUpdaters();
      parts.updaters?.accept(this);
    }

    tracker.endForStatement2();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    super.visitFunctionDeclaration(node);
    if (node.parent is CompilationUnit) {
      expect(tracker.isRootBranch, isTrue);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    tracker.beginFunctionExpression();
    super.visitFunctionExpression(node);
    tracker.endFunctionExpression();
  }

  @override
  void visitIfStatement(IfStatement node) {
    var condition = node.condition;
    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;

    condition.accept(this);

    tracker.beginIfStatementThen();
    thenStatement.accept(this);

    if (elseStatement != null) {
      tracker.beginIfStatementElse();
      elseStatement.accept(this);
    }

    tracker.endIfStatement(elseStatement != null);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    var element = node.methodName.staticElement;
    if (element != null && element.hasAlwaysThrows) {
      tracker.handleExit();
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    super.visitReturnStatement(node);
    tracker.handleExit();
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is LocalVariableElement) {
      if (node.inGetterContext()) {
        tracker.read(element);
      }
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    tracker.beginSwitchStatement(node);

    node.expression.accept(this);
    tracker.endSwitchStatementExpression();

    var members = node.members;
    var membersLength = members.length;
    var hasDefault = false;
    for (var i = 0; i < membersLength; i++) {
      var member = members[i];
      tracker.beginSwitchStatementMember();
      member.accept(this);
      // Implicit `break` at the end of `default`.
      if (member is SwitchDefault) {
        hasDefault = true;
        tracker.handleBreak(node);
      }
    }

    tracker.endSwitchStatement(hasDefault);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    tracker.handleExit();
  }

  @override
  void visitTryStatement(TryStatement node) {
    var body = node.body;
    var catchClauses = node.catchClauses;

    tracker.beginTryStatement();

    body.accept(this);
    tracker.endTryStatementBody();

    var catchLength = catchClauses.length;
    for (var i = 0; i < catchLength; ++i) {
      var catchClause = catchClauses[i];
      tracker.beginTryStatementCatchClause();
      catchClause.accept(this);
      tracker.endTryStatementCatchClause();
    }

    tracker.endTryStatementCatchClauses();

    node.finallyBlock?.accept(this);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var variables = node.variables.variables;
    for (var i = 0; i < variables.length; ++i) {
      var variable = variables[i];
      tracker.add(variable.declaredElement,
          assigned: variable.initializer != null);
    }

    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    var condition = node.condition;
    var body = node.body;

    tracker.beginWhileStatement(node);
    condition.accept(this);

    var conditionIsLiteralTrue = condition is BooleanLiteral && condition.value;
    tracker.beginWhileStatementBody(conditionIsLiteralTrue);
    body.accept(this);

    tracker.endWhileStatement();
  }

  /// This code has OK performance for tests, but think if there is something
  /// better when using in production.
  AstNode _getLabelTarget(AstNode node, LabelElement element) {
    for (; node != null; node = node.parent) {
      if (node is DoStatement ||
          node is ForStatement2 ||
          node is SwitchStatement ||
          node is WhileStatement) {
        if (element == null) {
          return node;
        }
        var parent = node.parent;
        if (parent is LabeledStatement) {
          for (var nodeLabel in parent.labels) {
            if (identical(nodeLabel.label.staticElement, element)) {
              return node;
            }
          }
        }
      }
      if (element != null && node is SwitchStatement) {
        for (var member in node.members) {
          for (var nodeLabel in member.labels) {
            if (identical(nodeLabel.label.staticElement, element)) {
              return node;
            }
          }
        }
      }
    }
    return null;
  }
}
