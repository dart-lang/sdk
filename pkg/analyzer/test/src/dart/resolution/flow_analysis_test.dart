// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefiniteAssignmentFlowTest);
    defineReflectiveTests(TypePromotionFlowTest);
  });
}

@reflectiveTest
class DefiniteAssignmentFlowTest extends DriverResolutionTest {
  final List<LocalVariableElement> readBeforeWritten = [];

  /// Assert that only local variables with the given names are marked as read
  /// before being written.  All the other local variables are implicitly
  /// considered definitely assigned.
  void assertReadBeforeWritten(
      [String name1, String name2, String name3, String name4]) {
    var expected = [name1, name2, name3, name4]
        .where((i) => i != null)
        .map((name) => findElement.localVar(name))
        .toList();
    expect(readBeforeWritten, unorderedEquals(expected));
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
    expect(readBeforeWritten, unorderedEquals([localV]));
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

    var loopAssignedVariables = LoopAssignedVariables();
    unit.accept(_LoopAssignedVariablesVisitor(loopAssignedVariables));

    var typeSystem = unit.declaredElement.context.typeSystem;
    unit.accept(_AstVisitor(
      typeSystem,
      loopAssignedVariables,
      {},
      readBeforeWritten,
    ));
  }
}

@reflectiveTest
class TypePromotionFlowTest extends DriverResolutionTest {
  final Map<AstNode, DartType> promotedTypes = {};

  void assertNotPromoted(String search) {
    var node = findNode.simple(search);
    var actualType = promotedTypes[node];
    expect(actualType, isNull, reason: search);
  }

  void assertPromoted(String search, String expectedType) {
    var node = findNode.simple(search);
    var actualType = promotedTypes[node];
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

  test_conditional() async {
    await trackCode(r'''
f(bool b, Object x) {
  b ? ((x is num) || (throw 1)) : ((x is int) || (throw 2));
  x; // 1
}
''');
    assertPromoted('x; // 1', 'num');
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

  test_try_assigned_body() async {
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

  test_try_isNotType_exit_body() async {
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

  test_try_isNotType_exit_body_catch() async {
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

  test_try_isNotType_exit_catch() async {
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

  test_try_outerIsType() async {
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

  test_try_outerIsType_assigned_body() async {
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

  test_try_outerIsType_assigned_catch() async {
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

  test_try_outerIsType_assigned_finally() async {
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

    var loopAssignedVariables = LoopAssignedVariables();
    unit.accept(_LoopAssignedVariablesVisitor(loopAssignedVariables));

    var typeSystem = unit.declaredElement.context.typeSystem;
    unit.accept(_AstVisitor(
      typeSystem,
      loopAssignedVariables,
      promotedTypes,
      [],
    ));
  }
}

/// [AstVisitor] that drives the [flow] in the way we expect the resolver
/// will do in production.
class _AstVisitor extends RecursiveAstVisitor<void> {
  static final trueLiteral = astFactory.booleanLiteral(null, true);

  final TypeSystem typeSystem;
  final LoopAssignedVariables loopAssignedVariables;
  final Map<AstNode, DartType> promotedTypes;
  final List<LocalVariableElement> readBeforeWritten;

  FlowAnalysis flow;

  _AstVisitor(this.typeSystem, this.loopAssignedVariables, this.promotedTypes,
      this.readBeforeWritten);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    VariableElement localElement;
    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        localElement = element;
      }
    }

    if (localElement != null) {
      var isPure = node.operator.type == TokenType.EQ;
      if (!isPure) {
        flow.read(localElement);
      }
      right.accept(this);
      flow.write(localElement);
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

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      left.accept(this);

      flow.logicalAnd_rightBegin(node);
      right.accept(this);

      flow.logicalAnd_end(node);
    } else if (operator == TokenType.BAR_BAR) {
      left.accept(this);

      flow.logicalOr_rightBegin(node);
      right.accept(this);

      flow.logicalOr_end(node);
    } else {
      left.accept(this);
      right.accept(this);
    }

//    var isLogical = operator == TokenType.AMPERSAND_AMPERSAND ||
//        operator == TokenType.BAR_BAR ||
//        operator == TokenType.QUESTION_QUESTION;
//
//    left.accept(this);
//
//    if (isLogical) {
//      tracker.beginBinaryExpressionLogicalRight();
//    }
//
//    right.accept(this);
//
//    if (isLogical) {
//      tracker.endBinaryExpressionLogicalRight();
//    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    var isFlowOwner = flow == null;
    flow ??= FlowAnalysis(typeSystem, node);

    super.visitBlockFunctionBody(node);

    if (isFlowOwner) {
      readBeforeWritten.addAll(flow.readBeforeWritten);
      flow.verifyStackEmpty();
      flow = null;
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    super.visitBooleanLiteral(node);
    if (_isFalseLiteral(node)) {
      flow.falseLiteral(node);
    }
    if (_isTrueLiteral(node)) {
      flow.trueLiteral(node);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleBreak(target);
    super.visitBreakStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    var condition = node.condition;
    var thenExpression = node.thenExpression;
    var elseExpression = node.elseExpression;

    condition.accept(this);

    flow.conditional_thenBegin(node);
    thenExpression.accept(this);
    var isBool = thenExpression.staticType.isDartCoreBool;

    flow.conditional_elseBegin(node, isBool);
    elseExpression.accept(this);

    flow.conditional_end(node, isBool);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleContinue(target);
    super.visitContinueStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    var body = node.body;
    var condition = node.condition;

    flow.doStatement_bodyBegin(node, loopAssignedVariables[node]);
    body.accept(this);

    flow.doStatement_conditionBegin();
    condition.accept(this);

    flow.doStatement_end(node);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    var iterable = node.iterable;
    var body = node.body;

    iterable.accept(this);
    flow.forEachStatement_bodyBegin(loopAssignedVariables[node]);

    body.accept(this);

    flow.forEachStatement_end();
  }

  @override
  void visitForStatement(ForStatement node) {
    var condition = node.condition;

    node.initialization?.accept(this);
    node.variables?.accept(this);

    flow.forStatement_conditionBegin(loopAssignedVariables[node]);
    if (condition != null) {
      condition.accept(this);
    } else {
      flow.trueLiteral(trueLiteral);
    }

    flow.forStatement_bodyBegin(node, condition ?? trueLiteral);
    node.body.accept(this);

    flow.forStatement_updaterBegin();
    node.updaters?.accept(this);

    flow.forStatement_end();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    flow?.functionExpression_begin();
    super.visitFunctionExpression(node);
    flow?.functionExpression_end();
  }

  @override
  void visitIfStatement(IfStatement node) {
    var condition = node.condition;
    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;

    condition.accept(this);

    flow.ifStatement_thenBegin(node);
    thenStatement.accept(this);

    if (elseStatement != null) {
      flow.ifStatement_elseBegin();
      elseStatement.accept(this);
    }

    flow.ifStatement_end(elseStatement != null);
  }

  @override
  void visitIsExpression(IsExpression node) {
    super.visitIsExpression(node);
    var expression = node.expression;
    var typeAnnotation = node.type;

    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is VariableElement) {
        flow.isExpression_end(node, element, typeAnnotation.type);
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand;

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      operand.accept(this);
      flow.logicalNot_end(node);
    } else {
      operand.accept(this);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    super.visitReturnStatement(node);
    flow.handleExit();
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    var isLocalVariable = element is LocalVariableElement;
    if (isLocalVariable || element is ParameterElement) {
      if (node.inGetterContext()) {
        if (isLocalVariable) {
          flow.read(element);
        }

        var promotedType = flow?.promotedType(element);
        if (promotedType != null) {
          promotedTypes[node] = promotedType;
        }
      }
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    flow.switchStatement_expressionEnd(node);

    var assignedInCases = loopAssignedVariables[node];

    var members = node.members;
    var membersLength = members.length;
    var hasDefault = false;
    for (var i = 0; i < membersLength; i++) {
      var member = members[i];

      flow.switchStatement_beginCase(
        member.labels.isNotEmpty
            ? assignedInCases
            : LoopAssignedVariables.emptySet,
      );
      member.accept(this);

      // Implicit `break` at the end of `default`.
      if (member is SwitchDefault) {
        hasDefault = true;
        flow.handleBreak(node);
      }
    }

    flow.switchStatement_end(node, hasDefault);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    super.visitThrowExpression(node);
    flow.handleExit();
  }

  @override
  void visitTryStatement(TryStatement node) {
    var body = node.body;
    var catchClauses = node.catchClauses;

    flow.tryStatement_bodyBegin();
    body.accept(this);
    flow.tryStatement_bodyEnd(loopAssignedVariables[node.body]);

    var catchLength = catchClauses.length;
    for (var i = 0; i < catchLength; ++i) {
      var catchClause = catchClauses[i];
      flow.tryStatement_catchBegin();
      catchClause.accept(this);
      flow.tryStatement_catchEnd();
    }

    flow.tryStatement_finallyBegin();
    node.finallyBlock?.accept(this);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var variables = node.variables.variables;
    for (var i = 0; i < variables.length; ++i) {
      var variable = variables[i];
      flow.add(variable.declaredElement,
          assigned: variable.initializer != null);
    }

    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    var condition = node.condition;
    var body = node.body;

    flow.whileStatement_conditionBegin(loopAssignedVariables[node]);
    condition.accept(this);

    flow.whileStatement_bodyBegin(node);
    body.accept(this);

    flow.whileStatement_end();
  }

  /// This code has OK performance for tests, but think if there is something
  /// better when using in production.
  AstNode _getLabelTarget(AstNode node, LabelElement element) {
    for (; node != null; node = node.parent) {
      if (node is DoStatement ||
          node is ForEachStatement ||
          node is ForStatement ||
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

  static bool _isFalseLiteral(AstNode node) {
    return node is BooleanLiteral && !node.value;
  }

  static bool _isTrueLiteral(AstNode node) {
    return node is BooleanLiteral && node.value;
  }
}

class _LoopAssignedVariablesVisitor extends RecursiveAstVisitor<void> {
  final LoopAssignedVariables loopAssignedVariables;

  _LoopAssignedVariablesVisitor(this.loopAssignedVariables);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;

    super.visitAssignmentExpression(node);

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        loopAssignedVariables.write(element);
      }
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    loopAssignedVariables.beginLoop();
    super.visitDoStatement(node);
    loopAssignedVariables.endLoop(node);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    var iterable = node.iterable;
    var body = node.body;

    iterable.accept(this);

    loopAssignedVariables.beginLoop();
    body.accept(this);
    loopAssignedVariables.endLoop(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    node.initialization?.accept(this);
    node.variables?.accept(this);

    loopAssignedVariables.beginLoop();
    node.condition?.accept(this);
    node.body.accept(this);
    node.updaters?.accept(this);
    loopAssignedVariables.endLoop(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var expression = node.expression;
    var members = node.members;

    expression.accept(this);

    loopAssignedVariables.beginLoop();
    members.accept(this);
    loopAssignedVariables.endLoop(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    loopAssignedVariables.beginLoop();
    node.body.accept(this);
    loopAssignedVariables.endLoop(node.body);

    node.catchClauses.accept(this);
    node.finallyBlock?.accept(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    loopAssignedVariables.beginLoop();
    super.visitWhileStatement(node);
    loopAssignedVariables.endLoop(node);
  }
}
