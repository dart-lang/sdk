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
    defineReflectiveTests(NullableFlowTest);
    defineReflectiveTests(ReachableFlowTest);
  });
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
  Object _;
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
        'Object _',
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
  Object _;
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
