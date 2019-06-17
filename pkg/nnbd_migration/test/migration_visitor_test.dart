// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/graph_builder.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GraphBuilderTest);
    defineReflectiveTests(NodeBuilderTest);
  });
}

@reflectiveTest
class GraphBuilderTest extends MigrationVisitorTestBase {
  /// Analyzes the given source code, producing constraint variables and
  /// constraints for it.
  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    unit.accept(
        GraphBuilder(typeProvider, _variables, graph, testSource, null));
    return unit;
  }

  void assertConditional(
      NullabilityNode node, NullabilityNode left, NullabilityNode right) {
    var conditionalNode = node as NullabilityNodeForLUB;
    expect(conditionalNode.left, same(left));
    expect(conditionalNode.right, same(right));
  }

  /// Checks that there are no nullability nodes upstream from [node] that could
  /// cause it to become nullable.
  void assertNoUpstreamNullability(NullabilityNode node) {
    // never can never become nullable, even if it has nodes
    // upstream from it.
    if (node == never) return;

    for (var edge in graph.getUpstreamEdges(node)) {
      expect(edge.primarySource, never);
    }
  }

  /// Verifies that a null check will occur when the given edge is unsatisfied.
  ///
  /// [expressionChecks] is the object tracking whether or not a null check is
  /// needed.
  void assertNullCheck(
      ExpressionChecks expressionChecks, NullabilityEdge expectedEdge) {
    expect(expressionChecks.edges, contains(expectedEdge));
  }

  /// Gets the [ExpressionChecks] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [ExpressionChecks] associated with it.
  ExpressionChecks checkExpression(String text) {
    return _variables.checkExpression(findNode.expression(text));
  }

  /// Gets the [DecoratedType] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [DecoratedType] associated with it.
  DecoratedType decoratedExpressionType(String text) {
    return _variables.decoratedExpressionType(findNode.expression(text));
  }

  test_assert_demonstrates_non_null_intent() async {
    await analyze('''
void f(int i) {
  assert(i != null);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  test_assignmentExpression_field() async {
    await analyze('''
class C {
  int x = 0;
}
void f(C c, int i) {
  c.x = i;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_assignmentExpression_field_cascaded() async {
    await analyze('''
class C {
  int x = 0;
}
void f(C c, int i) {
  c..x = i;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_assignmentExpression_field_target_check() async {
    await analyze('''
class C {
  int x = 0;
}
void f(C c, int i) {
  c.x = i;
}
''');
    assertNullCheck(checkExpression('c.x'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_assignmentExpression_field_target_check_cascaded() async {
    await analyze('''
class C {
  int x = 0;
}
void f(C c, int i) {
  c..x = i;
}
''');
    assertNullCheck(checkExpression('c..x'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_assignmentExpression_indexExpression_index() async {
    await analyze('''
class C {
  void operator[]=(int a, int b) {}
}
void f(C c, int i, int j) {
  c[i] = j;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int a').node,
        hard: true);
  }

  test_assignmentExpression_indexExpression_return_value() async {
    await analyze('''
class C {
  void operator[]=(int a, int b) {}
}
int f(C c, int i, int j) => c[i] = j;
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  test_assignmentExpression_indexExpression_target_check() async {
    await analyze('''
class C {
  void operator[]=(int a, int b) {}
}
void f(C c, int i, int j) {
  c[i] = j;
}
''');
    assertNullCheck(checkExpression('c['),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_assignmentExpression_indexExpression_value() async {
    await analyze('''
class C {
  void operator[]=(int a, int b) {}
}
void f(C c, int i, int j) {
  c[i] = j;
}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int b').node,
        hard: true);
  }

  test_assignmentExpression_operands() async {
    await analyze('''
void f(int i, int j) {
  i = j;
}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  test_assignmentExpression_return_value() async {
    await analyze('''
void f(int i, int j) {
  g(i = j);
}
void g(int k) {}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int k').node,
        hard: false);
  }

  test_assignmentExpression_setter() async {
    await analyze('''
class C {
  void set s(int value) {}
}
void f(C c, int i) {
  c.s = i;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int value').node,
        hard: true);
  }

  test_assignmentExpression_setter_null_aware() async {
    await analyze('''
class C {
  void set s(int value) {}
}
int f(C c, int i) => (c?.s = i);
''');
    var lubNode =
        decoratedExpressionType('(c?.s = i)').node as NullabilityNodeForLUB;
    expect(lubNode.left, same(decoratedTypeAnnotation('C c').node));
    expect(lubNode.right, same(decoratedTypeAnnotation('int i').node));
    assertEdge(lubNode, decoratedTypeAnnotation('int f').node, hard: false);
  }

  test_assignmentExpression_setter_target_check() async {
    await analyze('''
class C {
  void set s(int value) {}
}
void f(C c, int i) {
  c.s = i;
}
''');
    assertNullCheck(checkExpression('c.s'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  @failingTest
  test_awaitExpression_future_nonNullable() async {
    await analyze('''
Future<void> f() async {
  int x = await g();
}
Future<int> g() async => 3;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  @failingTest
  test_awaitExpression_future_nullable() async {
    await analyze('''
Future<void> f() async {
  int x = await g();
}
Future<int> g() async => null;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_awaitExpression_nonFuture() async {
    await analyze('''
Future<void> f() async {
  int x = await 3;
}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_binaryExpression_add_left_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true));
  }

  test_binaryExpression_add_left_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('Int i').node, never, hard: true));
  }

  test_binaryExpression_add_result_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => (i + j);
''');

    assertNullCheck(
        checkExpression('(i + j)'),
        assertEdge(decoratedTypeAnnotation('Int operator+').node,
            decoratedTypeAnnotation('Int f').node,
            hard: false));
  }

  test_binaryExpression_add_result_not_null() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_add_right_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true));
  }

  test_binaryExpression_add_right_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j/*check*/;
''');

    assertNullCheck(
        checkExpression('j/*check*/'),
        assertEdge(decoratedTypeAnnotation('Int j').node,
            decoratedTypeAnnotation('Int other').node,
            hard: true));
  }

  test_binaryExpression_equal() async {
    await analyze('''
bool f(int i, int j) => i == j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_boolLiteral() async {
    await analyze('''
bool f() {
  return true;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  test_cascadeExpression() async {
    await analyze('''
class C {
  int x = 0;
}
C f(C c, int i) => c..x = i;
''');
    assertEdge(decoratedTypeAnnotation('C c').node,
        decoratedTypeAnnotation('C f').node,
        hard: false);
  }

  test_conditionalExpression_condition_check() async {
    await analyze('''
int f(bool b, int i, int j) {
  return (b ? i : j);
}
''');

    var nullable_b = decoratedTypeAnnotation('bool b').node;
    var check_b = checkExpression('b ?');
    assertNullCheck(check_b, assertEdge(nullable_b, never, hard: true));
  }

  test_conditionalExpression_general() async {
    await analyze('''
int f(bool b, int i, int j) {
  return (b ? i : j);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertConditional(nullable_conditional, nullable_i, nullable_j);
    var nullable_return = decoratedTypeAnnotation('int f').node;
    assertNullCheck(checkExpression('(b ? i : j)'),
        assertEdge(nullable_conditional, nullable_return, hard: false));
  }

  test_conditionalExpression_left_non_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? (throw i) : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional =
        decoratedExpressionType('(b ?').node as NullabilityNodeForLUB;
    var nullable_throw = nullable_conditional.left;
    assertNoUpstreamNullability(nullable_throw);
    assertConditional(nullable_conditional, nullable_throw, nullable_i);
  }

  test_conditionalExpression_left_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? null : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertConditional(nullable_conditional, always, nullable_i);
  }

  test_conditionalExpression_right_non_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : (throw i));
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional =
        decoratedExpressionType('(b ?').node as NullabilityNodeForLUB;
    var nullable_throw = nullable_conditional.right;
    assertNoUpstreamNullability(nullable_throw);
    assertConditional(nullable_conditional, nullable_i, nullable_throw);
  }

  test_conditionalExpression_right_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : null);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertConditional(nullable_conditional, nullable_i, always);
  }

  test_doubleLiteral() async {
    await analyze('''
double f() {
  return 1.0;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('double').node);
  }

  test_functionDeclaration_expression_body() async {
    await analyze('''
int/*1*/ f(int/*2*/ i) => i/*3*/;
''');

    assertNullCheck(
        checkExpression('i/*3*/'),
        assertEdge(decoratedTypeAnnotation('int/*2*/').node,
            decoratedTypeAnnotation('int/*1*/').node,
            hard: true));
  }

  test_functionDeclaration_parameter_named_default_notNull() async {
    await analyze('''
void f({int i = 1}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_functionDeclaration_parameter_named_default_null() async {
    await analyze('''
void f({int i = null}) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_functionDeclaration_parameter_named_no_default() async {
    await analyze('''
void f({int i}) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_functionDeclaration_parameter_named_no_default_required() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
void f({@required int i}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_functionDeclaration_parameter_positionalOptional_default_notNull() async {
    await analyze('''
void f([int i = 1]) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_functionDeclaration_parameter_positionalOptional_default_null() async {
    await analyze('''
void f([int i = null]) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_functionDeclaration_parameter_positionalOptional_no_default() async {
    await analyze('''
void f([int i]) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_functionDeclaration_resets_unconditional_control_flow() async {
    await analyze('''
void f(bool b, int i, int j) {
  assert(i != null);
  if (b) return;
  assert(j != null);
}
void g(int k) {
  assert(k != null);
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
    assertNoEdge(always, decoratedTypeAnnotation('int j').node);
    assertEdge(decoratedTypeAnnotation('int k').node, never, hard: true);
  }

  test_functionInvocation_parameter_fromLocalParameter() async {
    await analyze('''
void f(int/*1*/ i) {}
void test(int/*2*/ i) {
  f(i/*3*/);
}
''');

    var int_1 = decoratedTypeAnnotation('int/*1*/');
    var int_2 = decoratedTypeAnnotation('int/*2*/');
    var i_3 = checkExpression('i/*3*/');
    assertNullCheck(i_3, assertEdge(int_2.node, int_1.node, hard: true));
    assertEdge(int_2.node, int_1.node, hard: true);
  }

  test_functionInvocation_parameter_named() async {
    await analyze('''
void f({int i: 0}) {}
void g(int j) {
  f(i: j/*check*/);
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    assertNullCheck(checkExpression('j/*check*/'),
        assertEdge(nullable_j, nullable_i, hard: true));
  }

  test_functionInvocation_parameter_named_missing() async {
    await analyze('''
void f({int i}) {}
void g() {
  f();
}
''');
    var optional_i = possiblyOptionalParameter('int i');
    expect(getEdges(always, optional_i), isNotEmpty);
  }

  test_functionInvocation_parameter_named_missing_required() async {
    addMetaPackage();
    verifyNoTestUnitErrors = false;
    await analyze('''
import 'package:meta/meta.dart';
void f({@required int i}) {}
void g() {
  f();
}
''');
    // The call at `f()` is presumed to be in error; no constraint is recorded.
    var optional_i = possiblyOptionalParameter('int i');
    expect(optional_i, isNull);
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertNoUpstreamNullability(nullable_i);
  }

  test_functionInvocation_parameter_null() async {
    await analyze('''
void f(int i) {}
void test() {
  f(null);
}
''');

    assertNullCheck(checkExpression('null'),
        assertEdge(always, decoratedTypeAnnotation('int').node, hard: false));
  }

  test_functionInvocation_return() async {
    await analyze('''
int/*1*/ f() => 0;
int/*2*/ g() {
  return (f());
}
''');

    assertNullCheck(
        checkExpression('(f())'),
        assertEdge(decoratedTypeAnnotation('int/*1*/').node,
            decoratedTypeAnnotation('int/*2*/').node,
            hard: false));
  }

  test_if_condition() async {
    await analyze('''
void f(bool b) {
  if (b) {}
}
''');

    assertNullCheck(checkExpression('b) {}'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
  }

  test_if_conditional_control_flow_after() async {
    // Asserts after ifs don't demonstrate non-null intent.
    // TODO(paulberry): if both branches complete normally, they should.
    await analyze('''
void f(bool b, int i) {
  if (b) return;
  assert(i != null);
}
''');

    assertNoEdge(always, decoratedTypeAnnotation('int i').node);
  }

  test_if_conditional_control_flow_within() async {
    // Asserts inside ifs don't demonstrate non-null intent.
    await analyze('''
void f(bool b, int i) {
  if (b) {
    assert(i != null);
  } else {
    assert(i != null);
  }
}
''');

    assertNoEdge(always, decoratedTypeAnnotation('int i').node);
  }

  test_if_guard_equals_null() async {
    await analyze('''
int f(int i, int j, int k) {
  if (i == null) {
    return j/*check*/;
  } else {
    return k/*check*/;
  }
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    var nullable_k = decoratedTypeAnnotation('int k').node;
    var nullable_return = decoratedTypeAnnotation('int f').node;
    assertNullCheck(
        checkExpression('j/*check*/'),
        assertEdge(nullable_j, nullable_return,
            guards: [nullable_i], hard: false));
    assertNullCheck(checkExpression('k/*check*/'),
        assertEdge(nullable_k, nullable_return, hard: false));
    var discard = statementDiscard('if (i == null)');
    expect(discard.trueGuard, same(nullable_i));
    expect(discard.falseGuard, null);
    expect(discard.pureCondition, true);
  }

  test_if_simple() async {
    await analyze('''
int f(bool b, int i, int j) {
  if (b) {
    return i/*check*/;
  } else {
    return j/*check*/;
  }
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    var nullable_return = decoratedTypeAnnotation('int f').node;
    assertNullCheck(checkExpression('i/*check*/'),
        assertEdge(nullable_i, nullable_return, hard: false));
    assertNullCheck(checkExpression('j/*check*/'),
        assertEdge(nullable_j, nullable_return, hard: false));
  }

  test_if_without_else() async {
    await analyze('''
int f(bool b, int i) {
  if (b) {
    return i/*check*/;
  }
  return 0;
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_return = decoratedTypeAnnotation('int f').node;
    assertNullCheck(checkExpression('i/*check*/'),
        assertEdge(nullable_i, nullable_return, hard: false));
  }

  test_indexExpression_index() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c, int j) => c[j];
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  test_indexExpression_index_cascaded() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
C f(C c, int j) => c..[j];
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  test_indexExpression_return_type() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[0];
''');
    assertEdge(decoratedTypeAnnotation('int operator').node,
        decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  test_indexExpression_target_check() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[0];
''');
    assertNullCheck(checkExpression('c['),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_indexExpression_target_check_cascaded() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
C f(C c) => c..[0];
''');
    assertNullCheck(checkExpression('c..['),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_indexExpression_target_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[0];
''');
    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  test_indexExpression_target_demonstrates_non_null_intent_cascaded() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
C f(C c) => c..[0];
''');
    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  test_instanceCreation_parameter_named_optional() async {
    await analyze('''
class C {
  C({int x = 0});
}
void f(int y) {
  C(x: y);
}
''');

    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_instanceCreation_parameter_positional_optional() async {
    await analyze('''
class C {
  C([int x]);
}
void f(int y) {
  C(y);
}
''');

    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_instanceCreation_parameter_positional_required() async {
    await analyze('''
class C {
  C(int x);
}
void f(int y) {
  C(y);
}
''');

    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_integerLiteral() async {
    await analyze('''
int f() {
  return 0;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  @failingTest
  test_isExpression_genericFunctionType() async {
    await analyze('''
bool f(a) => a is int Function(String);
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  test_isExpression_typeName_noTypeArguments() async {
    await analyze('''
bool f(a) => a is String;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  @failingTest
  test_isExpression_typeName_typeArguments() async {
    await analyze('''
bool f(a) => a is List<int>;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  @failingTest
  test_listLiteral_noTypeArgument_noNullableElements() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
List<String> f() {
  return ['a', 'b'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    // TODO(brianwilkerson) Add an assertion that there is an edge from the list
    //  literal's fake type argument to the return type's type argument.
  }

  @failingTest
  test_listLiteral_noTypeArgument_nullableElement() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
List<String> f() {
  return ['a', null, 'c'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    assertEdge(always, decoratedTypeAnnotation('String').node, hard: false);
  }

  test_listLiteral_typeArgument_noNullableElements() async {
    await analyze('''
List<String> f() {
  return <String>['a', 'b'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    var typeArgForLiteral = decoratedTypeAnnotation('String>[').node;
    var typeArgForReturnType = decoratedTypeAnnotation('String> ').node;
    assertNoUpstreamNullability(typeArgForLiteral);
    assertEdge(typeArgForLiteral, typeArgForReturnType, hard: false);
  }

  test_listLiteral_typeArgument_nullableElement() async {
    await analyze('''
List<String> f() {
  return <String>['a', null, 'c'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    assertEdge(always, decoratedTypeAnnotation('String>[').node, hard: false);
  }

  test_methodDeclaration_resets_unconditional_control_flow() async {
    await analyze('''
class C {
  void f(bool b, int i, int j) {
    assert(i != null);
    if (b) return;
    assert(j != null);
  }
  void g(int k) {
    assert(k != null);
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
    assertNoEdge(always, decoratedTypeAnnotation('int j').node);
    assertEdge(decoratedTypeAnnotation('int k').node, never, hard: true);
  }

  test_methodInvocation_parameter_contravariant() async {
    await analyze('''
class C<T> {
  void f(T t) {}
}
void g(C<int> c, int i) {
  c.f(i/*check*/);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_c_t = decoratedTypeAnnotation('C<int>').typeArguments[0].node;
    var nullable_t = decoratedTypeAnnotation('T t').node;
    var check_i = checkExpression('i/*check*/');
    var nullable_c_t_or_nullable_t =
        check_i.edges.single.destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  test_methodInvocation_parameter_generic() async {
    await analyze('''
class C<T> {}
void f(C<int/*1*/>/*2*/ c) {}
void g(C<int/*3*/>/*4*/ c) {
  f(c/*check*/);
}
''');

    assertEdge(decoratedTypeAnnotation('int/*3*/').node,
        decoratedTypeAnnotation('int/*1*/').node,
        hard: false);
    assertNullCheck(
        checkExpression('c/*check*/'),
        assertEdge(decoratedTypeAnnotation('C<int/*3*/>/*4*/').node,
            decoratedTypeAnnotation('C<int/*1*/>/*2*/').node,
            hard: true));
  }

  test_methodInvocation_parameter_named() async {
    await analyze('''
class C {
  void f({int i: 0}) {}
}
void g(C c, int j) {
  c.f(i: j/*check*/);
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    assertNullCheck(checkExpression('j/*check*/'),
        assertEdge(nullable_j, nullable_i, hard: true));
  }

  test_methodInvocation_return_type() async {
    await analyze('''
class C {
  bool m() => true;
}
bool f(C c) => c.m();
''');
    assertEdge(decoratedTypeAnnotation('bool m').node,
        decoratedTypeAnnotation('bool f').node,
        hard: false);
  }

  test_methodInvocation_return_type_null_aware() async {
    await analyze('''
class C {
  bool m() => true;
}
bool f(C c) => (c?.m());
''');
    var lubNode =
        decoratedExpressionType('(c?.m())').node as NullabilityNodeForLUB;
    expect(lubNode.left, same(decoratedTypeAnnotation('C c').node));
    expect(lubNode.right, same(decoratedTypeAnnotation('bool m').node));
    assertEdge(lubNode, decoratedTypeAnnotation('bool f').node, hard: false);
  }

  test_methodInvocation_target_check() async {
    await analyze('''
class C {
  void m() {}
}
void test(C c) {
  c.m();
}
''');

    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_methodInvocation_target_check_cascaded() async {
    await analyze('''
class C {
  void m() {}
}
void test(C c) {
  c..m();
}
''');

    assertNullCheck(checkExpression('c..m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_methodInvocation_target_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  void m() {}
}
void test(C c) {
  c.m();
}
''');

    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  test_methodInvocation_target_demonstrates_non_null_intent_cascaded() async {
    await analyze('''
class C {
  void m() {}
}
void test(C c) {
  c..m();
}
''');

    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  test_never() async {
    await analyze('');

    expect(never.isNullable, isFalse);
  }

  test_parenthesizedExpression() async {
    await analyze('''
int f() {
  return (null);
}
''');

    assertNullCheck(checkExpression('(null)'),
        assertEdge(always, decoratedTypeAnnotation('int').node, hard: false));
  }

  test_prefixedIdentifier_field_type() async {
    await analyze('''
class C {
  bool b = true;
}
bool f(C c) => c.b;
''');
    assertEdge(decoratedTypeAnnotation('bool b').node,
        decoratedTypeAnnotation('bool f').node,
        hard: false);
  }

  test_prefixedIdentifier_getter_type() async {
    await analyze('''
class C {
  bool get b => true;
}
bool f(C c) => c.b;
''');
    assertEdge(decoratedTypeAnnotation('bool get').node,
        decoratedTypeAnnotation('bool f').node,
        hard: false);
  }

  test_prefixedIdentifier_target_check() async {
    await analyze('''
class C {
  int get x => 1;
}
void test(C c) {
  c.x;
}
''');

    assertNullCheck(checkExpression('c.x'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_prefixedIdentifier_target_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  int get x => 1;
}
void test(C c) {
  c.x;
}
''');

    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  test_prefixExpression_bang2() async {
    await analyze('''
bool f(bool b) {
  return !b;
}
''');

    var nullable_b = decoratedTypeAnnotation('bool b').node;
    var check_b = checkExpression('b;');
    assertNullCheck(check_b, assertEdge(nullable_b, never, hard: true));

    var return_f = decoratedTypeAnnotation('bool f').node;
    assertEdge(never, return_f, hard: false);
  }

  test_propertyAccess_return_type() async {
    await analyze('''
class C {
  bool get b => true;
}
bool f(C c) => (c).b;
''');
    assertEdge(decoratedTypeAnnotation('bool get').node,
        decoratedTypeAnnotation('bool f').node,
        hard: false);
  }

  test_propertyAccess_return_type_null_aware() async {
    await analyze('''
class C {
  bool get b => true;
}
bool f(C c) => (c?.b);
''');
    var lubNode =
        decoratedExpressionType('(c?.b)').node as NullabilityNodeForLUB;
    expect(lubNode.left, same(decoratedTypeAnnotation('C c').node));
    expect(lubNode.right, same(decoratedTypeAnnotation('bool get b').node));
    assertEdge(lubNode, decoratedTypeAnnotation('bool f').node, hard: false);
  }

  test_propertyAccess_target_check() async {
    await analyze('''
class C {
  int get x => 1;
}
void test(C c) {
  (c).x;
}
''');

    // TODO(paulberry): this is wrong.  It should be a hard edge.
    assertNullCheck(checkExpression('c).x'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: false));
  }

  test_return_implicit_null() async {
    verifyNoTestUnitErrors = false;
    await analyze('''
int f() {
  return;
}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_return_null() async {
    await analyze('''
int f() {
  return null;
}
''');

    assertNullCheck(checkExpression('null'),
        assertEdge(always, decoratedTypeAnnotation('int').node, hard: false));
  }

  test_return_null_generic() async {
    await analyze('''
class C<T> {
  T f() {
    return null;
  }
}
''');
    var tNode = decoratedTypeAnnotation('T f').node;
    assertEdge(always, tNode, hard: false);
    assertNullCheck(
        checkExpression('null'), assertEdge(always, tNode, hard: false));
  }

  @failingTest
  test_setOrMapLiteral_map_noTypeArgument_noNullableKeysAndValues() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, 'b' : 2};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    // TODO(brianwilkerson) Add an assertion that there is an edge from the set
    //  literal's fake type argument to the return type's type argument.
  }

  @failingTest
  test_setOrMapLiteral_map_noTypeArgument_nullableKey() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, null : 2, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(always, decoratedTypeAnnotation('String').node, hard: false);
    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  @failingTest
  test_setOrMapLiteral_map_noTypeArgument_nullableKeyAndValue() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, null : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(always, decoratedTypeAnnotation('String').node, hard: false);
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  @failingTest
  test_setOrMapLiteral_map_noTypeArgument_nullableValue() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, 'b' : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertNoUpstreamNullability(decoratedTypeAnnotation('String').node);
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_setOrMapLiteral_map_typeArguments_noNullableKeysAndValues() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, 'b' : 2};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);

    var keyForLiteral = decoratedTypeAnnotation('String, int>{').node;
    var keyForReturnType = decoratedTypeAnnotation('String, int> ').node;
    assertNoUpstreamNullability(keyForLiteral);
    assertEdge(keyForLiteral, keyForReturnType, hard: false);

    var valueForLiteral = decoratedTypeAnnotation('int>{').node;
    var valueForReturnType = decoratedTypeAnnotation('int> ').node;
    assertNoUpstreamNullability(valueForLiteral);
    assertEdge(valueForLiteral, valueForReturnType, hard: false);
  }

  test_setOrMapLiteral_map_typeArguments_nullableKey() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, null : 2, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(always, decoratedTypeAnnotation('String, int>{').node,
        hard: false);
    assertNoUpstreamNullability(decoratedTypeAnnotation('int>{').node);
  }

  test_setOrMapLiteral_map_typeArguments_nullableKeyAndValue() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, null : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(always, decoratedTypeAnnotation('String, int>{').node,
        hard: false);
    assertEdge(always, decoratedTypeAnnotation('int>{').node, hard: false);
  }

  test_setOrMapLiteral_map_typeArguments_nullableValue() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, 'b' : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertNoUpstreamNullability(decoratedTypeAnnotation('String, int>{').node);
    assertEdge(always, decoratedTypeAnnotation('int>{').node, hard: false);
  }

  @failingTest
  test_setOrMapLiteral_set_noTypeArgument_noNullableElements() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Set<String> f() {
  return {'a', 'b'};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Set').node);
    // TODO(brianwilkerson) Add an assertion that there is an edge from the set
    //  literal's fake type argument to the return type's type argument.
  }

  @failingTest
  test_setOrMapLiteral_set_noTypeArgument_nullableElement() async {
    // Failing because we're not yet handling collection literals without a
    // type argument.
    await analyze('''
Set<String> f() {
  return {'a', null, 'c'};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Set').node);
    assertEdge(always, decoratedTypeAnnotation('String').node, hard: false);
  }

  test_setOrMapLiteral_set_typeArgument_noNullableElements() async {
    await analyze('''
Set<String> f() {
  return <String>{'a', 'b'};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Set').node);
    var typeArgForLiteral = decoratedTypeAnnotation('String>{').node;
    var typeArgForReturnType = decoratedTypeAnnotation('String> ').node;
    assertNoUpstreamNullability(typeArgForLiteral);
    assertEdge(typeArgForLiteral, typeArgForReturnType, hard: false);
  }

  test_setOrMapLiteral_set_typeArgument_nullableElement() async {
    await analyze('''
Set<String> f() {
  return <String>{'a', null, 'c'};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Set').node);
    assertEdge(always, decoratedTypeAnnotation('String>{').node, hard: false);
  }

  test_simpleIdentifier_local() async {
    await analyze('''
main() {
  int i = 0;
  int j = i;
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int j').node,
        hard: true);
  }

  test_soft_edge_for_non_variable_reference() async {
    // Edges originating in things other than variable references should be
    // soft.
    await analyze('''
int f() => null;
''');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_stringLiteral() async {
    // TODO(paulberry): also test string interpolations
    await analyze('''
String f() {
  return 'x';
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('String').node);
  }

  test_superExpression() async {
    await analyze('''
class C {
  C f() => super;
}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('C f').node);
  }

  test_symbolLiteral() async {
    await analyze('''
Symbol f() {
  return #symbol;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Symbol').node);
  }

  test_thisExpression() async {
    await analyze('''
class C {
  C f() => this;
}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('C f').node);
  }

  test_throwExpression() async {
    await analyze('''
int f() {
  return throw null;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_type_argument_explicit_bound() async {
    await analyze('''
class C<T extends Object> {}
void f(C<int> c) {}
''');
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  test_typeName() async {
    await analyze('''
Type f() {
  return int;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  test_typeName_union_with_bound() async {
    await analyze('''
class C<T extends Object> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var cBound = decoratedTypeAnnotation('Object');
    assertUnion(cType.typeArguments[0].node, cBound.node);
  }

  test_typeName_union_with_bounds() async {
    await analyze('''
class C<T extends Object, U extends Object> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var tBound = decoratedTypeAnnotation('Object,');
    var uBound = decoratedTypeAnnotation('Object>');
    assertUnion(cType.typeArguments[0].node, tBound.node);
    assertUnion(cType.typeArguments[1].node, uBound.node);
  }

  test_variableDeclaration() async {
    await analyze('''
void f(int i) {
  int j = i;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int j').node,
        hard: true);
  }
}

class MigrationVisitorTestBase extends AbstractSingleUnitTest {
  final _Variables _variables;

  final NullabilityGraphForTesting graph;

  MigrationVisitorTestBase() : this._(NullabilityGraphForTesting());

  MigrationVisitorTestBase._(this.graph) : _variables = _Variables(graph);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  Future<CompilationUnit> analyze(String code) async {
    await resolveTestUnit(code);
    testUnit
        .accept(NodeBuilder(_variables, testSource, null, graph, typeProvider));
    return testUnit;
  }

  NullabilityEdge assertEdge(
      NullabilityNode source, NullabilityNode destination,
      {@required bool hard, List<NullabilityNode> guards = const []}) {
    var edges = getEdges(source, destination);
    if (edges.length == 0) {
      fail('Expected edge $source -> $destination, found none');
    } else if (edges.length != 1) {
      fail('Found multiple edges $source -> $destination');
    } else {
      var edge = edges[0];
      expect(edge.hard, hard);
      expect(edge.guards, unorderedEquals(guards));
      return edge;
    }
  }

  void assertNoEdge(NullabilityNode source, NullabilityNode destination) {
    var edges = getEdges(source, destination);
    if (edges.isNotEmpty) {
      fail('Expected no edge $source -> $destination, found ${edges.length}');
    }
  }

  void assertUnion(NullabilityNode x, NullabilityNode y) {
    var edges = getEdges(x, y);
    for (var edge in edges) {
      if (edge.isUnion) {
        expect(edge.sources, hasLength(1));
        return;
      }
    }
    fail('Expected union between $x and $y, not found');
  }

  /// Gets the [DecoratedType] associated with the generic function type
  /// annotation whose text is [text].
  DecoratedType decoratedGenericFunctionTypeAnnotation(String text) {
    return _variables.decoratedTypeAnnotation(
        testSource, findNode.genericFunctionType(text));
  }

  /// Gets the [DecoratedType] associated with the type annotation whose text
  /// is [text].
  DecoratedType decoratedTypeAnnotation(String text) {
    return _variables.decoratedTypeAnnotation(
        testSource, findNode.typeAnnotation(text));
  }

  List<NullabilityEdge> getEdges(
          NullabilityNode source, NullabilityNode destination) =>
      graph
          .getUpstreamEdges(destination)
          .where((e) => e.primarySource == source)
          .toList();

  NullabilityNode possiblyOptionalParameter(String text) {
    return _variables
        .possiblyOptionalParameter(findNode.defaultParameter(text));
  }

  /// Gets the [ConditionalDiscard] information associated with the statement
  /// whose text is [text].
  ConditionalDiscard statementDiscard(String text) {
    return _variables.conditionalDiscard(findNode.statement(text));
  }
}

@reflectiveTest
class NodeBuilderTest extends MigrationVisitorTestBase {
  /// Gets the [DecoratedType] associated with the constructor declaration whose
  /// name matches [search].
  DecoratedType decoratedConstructorDeclaration(String search) => _variables
      .decoratedElementType(findNode.constructor(search).declaredElement);

  /// Gets the [DecoratedType] associated with the function declaration whose
  /// name matches [search].
  DecoratedType decoratedFunctionType(String search) =>
      _variables.decoratedElementType(
          findNode.functionDeclaration(search).declaredElement);

  DecoratedType decoratedTypeParameterBound(String search) => _variables
      .decoratedElementType(findNode.typeParameter(search).declaredElement);

  test_constructor_returnType_implicit_dynamic() async {
    await analyze('''
class C {
  C();
}
''');
    var decoratedType = decoratedConstructorDeclaration('C(').returnType;
    expect(decoratedType.node, same(never));
  }

  test_dynamic_type() async {
    await analyze('''
dynamic f() {}
''');
    var decoratedType = decoratedTypeAnnotation('dynamic');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertEdge(always, decoratedType.node, hard: false);
  }

  test_field_type_simple() async {
    await analyze('''
class C {
  int f = 0;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(
        _variables.decoratedElementType(
            findNode.fieldDeclaration('f').fields.variables[0].declaredElement),
        same(decoratedType));
  }

  test_genericFunctionType_namedParameterType() async {
    await analyze('''
void f(void Function({int y}) x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('void Function({int y})');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.namedParameters['y'], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  test_genericFunctionType_returnType() async {
    await analyze('''
void f(int Function() x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('int Function()');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.returnType, same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  test_genericFunctionType_unnamedParameterType() async {
    await analyze('''
void f(void Function(int) x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('void Function(int)');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.positionalParameters[0], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  test_interfaceType_generic_instantiate_to_dynamic() async {
    await analyze('''
void f(List x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, isNotNull);
    expect(decoratedListType.node, isNot(never));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node, same(always));
  }

  test_interfaceType_generic_instantiate_to_generic_type() async {
    await analyze('''
class C<T> {}
class D<T extends C<int>> {}
void f(D x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('D x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedListType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, hasLength(1));
    var decoratedArgArgType = decoratedArgType.typeArguments[0];
    expect(decoratedArgArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgArgType.typeArguments, isEmpty);
  }

  test_interfaceType_generic_instantiate_to_generic_type_2() async {
    await analyze('''
class C<T, U> {}
class D<T extends C<int, String>, U extends C<num, double>> {}
void f(D x) {}
''');
    var decoratedDType = decoratedTypeAnnotation('D x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedDType));
    expect(decoratedDType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedDType.typeArguments, hasLength(2));
    var decoratedArg0Type = decoratedDType.typeArguments[0];
    expect(decoratedArg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Type.typeArguments, hasLength(2));
    var decoratedArg0Arg0Type = decoratedArg0Type.typeArguments[0];
    expect(decoratedArg0Arg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Arg0Type.typeArguments, isEmpty);
    var decoratedArg0Arg1Type = decoratedArg0Type.typeArguments[1];
    expect(decoratedArg0Arg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Arg1Type.typeArguments, isEmpty);
    var decoratedArg1Type = decoratedDType.typeArguments[1];
    expect(decoratedArg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Type.typeArguments, hasLength(2));
    var decoratedArg1Arg0Type = decoratedArg1Type.typeArguments[0];
    expect(decoratedArg1Arg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Arg0Type.typeArguments, isEmpty);
    var decoratedArg1Arg1Type = decoratedArg1Type.typeArguments[1];
    expect(decoratedArg1Arg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Arg1Type.typeArguments, isEmpty);
  }

  test_interfaceType_generic_instantiate_to_object() async {
    await analyze('''
class C<T extends Object> {}
void f(C x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('C x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedListType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, isEmpty);
  }

  test_interfaceType_typeParameter() async {
    await analyze('''
void f(List<int> x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List<int>');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, isNotNull);
    expect(decoratedListType.node, isNot(never));
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedListType.typeArguments[0], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  test_topLevelFunction_parameterType_implicit_dynamic() async {
    await analyze('''
void f(x) {}
''');
    var decoratedType =
        _variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.type.isDynamic, isTrue);
    assertUnion(always, decoratedType.node);
  }

  test_topLevelFunction_parameterType_named_no_default() async {
    await analyze('''
void f({String s}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(decoratedType.node, isNot(always));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, true);
  }

  test_topLevelFunction_parameterType_named_no_default_required() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
void f({@required String s}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(decoratedType.node, isNot(always));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, false);
  }

  test_topLevelFunction_parameterType_named_with_default() async {
    await analyze('''
void f({String s: 'x'}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, false);
  }

  test_topLevelFunction_parameterType_positionalOptional() async {
    await analyze('''
void f([int i]) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_topLevelFunction_parameterType_simple() async {
    await analyze('''
void f(int i) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_topLevelFunction_returnType_implicit_dynamic() async {
    await analyze('''
f() {}
''');
    var decoratedType = decoratedFunctionType('f').returnType;
    expect(decoratedType.type.isDynamic, isTrue);
    assertUnion(always, decoratedType.node);
  }

  test_topLevelFunction_returnType_simple() async {
    await analyze('''
int f() => 0;
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_type_comment_bang() async {
    await analyze('''
void f(int/*!*/ i) {}
''');
    assertEdge(decoratedTypeAnnotation('int').node, never, hard: true);
  }

  test_type_comment_question() async {
    await analyze('''
void f(int/*?*/ i) {}
''');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_type_parameter_explicit_bound() async {
    await analyze('''
class C<T extends Object> {}
''');
    var bound = decoratedTypeParameterBound('T');
    expect(decoratedTypeAnnotation('Object'), same(bound));
    expect(bound.node, isNot(always));
    expect(bound.type, typeProvider.objectType);
  }

  test_type_parameter_implicit_bound() async {
    // The implicit bound of `T` is automatically `Object?`.  TODO(paulberry):
    // consider making it possible for type inference to infer an explicit bound
    // of `Object`.
    await analyze('''
class C<T> {}
''');
    var bound = decoratedTypeParameterBound('T');
    assertUnion(always, bound.node);
    expect(bound.type, same(typeProvider.objectType));
  }

  test_variableDeclaration_type_simple() async {
    await analyze('''
main() {
  int i;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_void_type() async {
    await analyze('''
void f() {}
''');
    var decoratedType = decoratedTypeAnnotation('void');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertEdge(always, decoratedType.node, hard: false);
  }
}

/// Mock representation of constraint variables.
class _Variables extends Variables {
  final _conditionalDiscard = <AstNode, ConditionalDiscard>{};

  final _decoratedExpressionTypes = <Expression, DecoratedType>{};

  final _expressionChecks = <Expression, ExpressionChecks>{};

  final _possiblyOptional = <DefaultFormalParameter, NullabilityNode>{};

  _Variables(NullabilityGraph graph) : super(graph);

  /// Gets the [ExpressionChecks] associated with the given [expression].
  ExpressionChecks checkExpression(Expression expression) =>
      _expressionChecks[_normalizeExpression(expression)];

  /// Gets the [conditionalDiscard] associated with the given [expression].
  ConditionalDiscard conditionalDiscard(AstNode node) =>
      _conditionalDiscard[node];

  /// Gets the [DecoratedType] associated with the given [expression].
  DecoratedType decoratedExpressionType(Expression expression) =>
      _decoratedExpressionTypes[_normalizeExpression(expression)];

  /// Gets the [NullabilityNode] associated with the possibility that
  /// [parameter] may be optional.
  NullabilityNode possiblyOptionalParameter(DefaultFormalParameter parameter) =>
      _possiblyOptional[parameter];

  @override
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard) {
    _conditionalDiscard[node] = conditionalDiscard;
    super.recordConditionalDiscard(source, node, conditionalDiscard);
  }

  void recordDecoratedExpressionType(Expression node, DecoratedType type) {
    super.recordDecoratedExpressionType(node, type);
    _decoratedExpressionTypes[_normalizeExpression(node)] = type;
  }

  @override
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecks checks) {
    super.recordExpressionChecks(source, expression, checks);
    _expressionChecks[_normalizeExpression(expression)] = checks;
  }

  @override
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node) {
    _possiblyOptional[parameter] = node;
    super.recordPossiblyOptional(source, parameter, node);
  }

  /// Unwraps any parentheses surrounding [expression].
  Expression _normalizeExpression(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    return expression;
  }
}
