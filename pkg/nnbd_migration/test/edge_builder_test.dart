// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentCheckerTest);
    defineReflectiveTests(EdgeBuilderTest);
  });
}

@reflectiveTest
class AssignmentCheckerTest extends Object
    with EdgeTester, DecoratedTypeTester {
  static const EdgeOrigin origin = const _TestEdgeOrigin();

  ClassElement _myListOfListClass;

  DecoratedType _myListOfListSupertype;

  @override
  final TypeProvider typeProvider;

  @override
  final NullabilityGraphForTesting graph;

  final AssignmentCheckerForTesting checker;

  factory AssignmentCheckerTest() {
    var typeProvider = TestTypeProvider();
    var graph = NullabilityGraphForTesting();
    var decoratedClassHierarchy = _DecoratedClassHierarchyForTesting();
    var checker = AssignmentCheckerForTesting(Dart2TypeSystem(typeProvider),
        typeProvider, graph, decoratedClassHierarchy);
    var assignmentCheckerTest =
        AssignmentCheckerTest._(typeProvider, graph, checker);
    decoratedClassHierarchy.assignmentCheckerTest = assignmentCheckerTest;
    return assignmentCheckerTest;
  }

  AssignmentCheckerTest._(this.typeProvider, this.graph, this.checker);

  void assign(DecoratedType source, DecoratedType destination,
      {bool hard = false}) {
    checker.checkAssignment(origin,
        source: source, destination: destination, hard: hard);
  }

  DecoratedType myListOfList(DecoratedType elementType) {
    if (_myListOfListClass == null) {
      var t = typeParameter('T', object());
      _myListOfListSupertype = list(list(typeParameterType(t)));
      _myListOfListClass = ClassElementImpl('MyListOfList', 0)
        ..typeParameters = [t]
        ..supertype = _myListOfListSupertype.type as InterfaceType;
    }
    return DecoratedType(
        InterfaceTypeImpl(_myListOfListClass)
          ..typeArguments = [elementType.type],
        newNode(),
        typeArguments: [elementType]);
  }

  void test_bottom_to_generic() {
    var t = list(object());
    assign(bottom, t);
    assertEdge(never, t.node, hard: false);
    assertNoEdge(anyNode, t.typeArguments[0].node);
  }

  void test_bottom_to_simple() {
    var t = object();
    assign(bottom, t);
    assertEdge(never, t.node, hard: false);
  }

  void test_complex_to_typeParam() {
    var bound = list(object());
    var t1 = list(object());
    var t2 = typeParameterType(typeParameter('T', bound));
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertNoEdge(t1.node, bound.node);
    assertEdge(t1.typeArguments[0].node, bound.typeArguments[0].node,
        hard: false);
  }

  void test_dynamic_to_dynamic() {
    assign(dynamic_, dynamic_);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_function_type_named_parameter() {
    var t1 = function(dynamic_, named: {'x': object()});
    var t2 = function(dynamic_, named: {'x': object()});
    assign(t1, t2, hard: true);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.namedParameters['x'].node, t1.namedParameters['x'].node,
        hard: false);
  }

  void test_function_type_named_to_no_parameter() {
    var t1 = function(dynamic_, named: {'x': object()});
    var t2 = function(dynamic_);
    assign(t1, t2);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_function_type_positional_parameter() {
    var t1 = function(dynamic_, positional: [object()]);
    var t2 = function(dynamic_, positional: [object()]);
    assign(t1, t2, hard: true);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.positionalParameters[0].node, t1.positionalParameters[0].node,
        hard: false);
  }

  void test_function_type_positional_to_no_parameter() {
    var t1 = function(dynamic_, positional: [object()]);
    var t2 = function(dynamic_);
    assign(t1, t2);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_function_type_positional_to_required_parameter() {
    var t1 = function(dynamic_, positional: [object()]);
    var t2 = function(dynamic_, required: [object()]);
    assign(t1, t2, hard: true);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.positionalParameters[0].node, t1.positionalParameters[0].node,
        hard: false);
  }

  void test_function_type_required_parameter() {
    var t1 = function(dynamic_, required: [object()]);
    var t2 = function(dynamic_, required: [object()]);
    assign(t1, t2);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.positionalParameters[0].node, t1.positionalParameters[0].node,
        hard: false);
  }

  void test_function_type_return_type() {
    var t1 = function(object());
    var t2 = function(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.returnType.node, t2.returnType.node, hard: false);
  }

  void test_future_int_to_future_or_int() {
    var t1 = future(int_());
    var t2 = futureOr(int_());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node, hard: false);
  }

  void test_future_or_to_future_or() {
    var t1 = futureOr(int_());
    var t2 = futureOr(int_());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node, hard: false);
  }

  test_generic_to_dynamic() {
    var t = list(object());
    assign(t, dynamic_);
    assertEdge(t.node, always, hard: false);
    assertNoEdge(t.typeArguments[0].node, anyNode);
  }

  test_generic_to_generic_downcast() {
    var t1 = list(list(object()));
    var t2 = myListOfList(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    // Let A, B, and C be nullability nodes such that:
    // - t2 is MyListOfList<Object?A>
    var a = t2.typeArguments[0].node;
    // - t1 is List<List<Object?B>>
    var b = t1.typeArguments[0].typeArguments[0].node;
    // - the supertype of MyListOfList<T> is List<List<T?C>>
    var c = _myListOfListSupertype.typeArguments[0].typeArguments[0].node;
    // Then there should be an edge from b to substitute(a, c)
    assertEdge(b, substitutionNode(a, c), hard: false);
  }

  test_generic_to_generic_same_element() {
    var t1 = list(object());
    var t2 = list(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node, hard: false);
  }

  test_generic_to_generic_upcast() {
    var t1 = myListOfList(object());
    var t2 = list(list(object()));
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
    // Let A, B, and C be nullability nodes such that:
    // - t1 is MyListOfList<Object?A>
    var a = t1.typeArguments[0].node;
    // - t2 is List<List<Object?B>>
    var b = t2.typeArguments[0].typeArguments[0].node;
    // - the supertype of MyListOfList<T> is List<List<T?C>>
    var c = _myListOfListSupertype.typeArguments[0].typeArguments[0].node;
    // Then there should be an edge from substitute(a, c) to b.
    assertEdge(substitutionNode(a, c), b, hard: false);
  }

  test_generic_to_object() {
    var t1 = list(object());
    var t2 = object();
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
    assertNoEdge(t1.typeArguments[0].node, anyNode);
  }

  test_generic_to_void() {
    var t = list(object());
    assign(t, void_);
    assertEdge(t.node, always, hard: false);
    assertNoEdge(t.typeArguments[0].node, anyNode);
  }

  void test_int_to_future_or_int() {
    var t1 = int_();
    var t2 = futureOr(int_());
    assign(t1, t2, hard: true);
    // Note: given code like:
    //   int x = null;
    //   FutureOr<int> y = x;
    // There are two possible migrations for `FutureOr<int>`: we could change it
    // to either `FutureOr<int?>` or `FutureOr<int>?`.  We choose to do
    // `FutureOr<int>?` because it is a narrower type, so it is less likely to
    // cause a proliferation of nullable types in the user's program.
    assertEdge(t1.node, t2.node, hard: true);
    assertNoEdge(t1.node, t2.typeArguments[0].node);
  }

  void test_null_to_generic() {
    var t = list(object());
    assign(null_, t);
    assertEdge(always, t.node, hard: false);
    assertNoEdge(anyNode, t.typeArguments[0].node);
  }

  void test_null_to_simple() {
    var t = object();
    assign(null_, t);
    assertEdge(always, t.node, hard: false);
  }

  test_simple_to_dynamic() {
    var t = object();
    assign(t, dynamic_);
    assertEdge(t.node, always, hard: false);
  }

  test_simple_to_simple() {
    var t1 = object();
    var t2 = object();
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
  }

  test_simple_to_simple_hard() {
    var t1 = object();
    var t2 = object();
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
  }

  test_simple_to_void() {
    var t = object();
    assign(t, void_);
    assertEdge(t.node, always, hard: false);
  }

  void test_typeParam_to_complex() {
    var bound = list(object());
    var t1 = typeParameterType(typeParameter('T', bound));
    var t2 = list(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(bound.node, t2.node, hard: false);
    assertEdge(bound.typeArguments[0].node, t2.typeArguments[0].node,
        hard: false);
  }

  void test_typeParam_to_object() {
    var t1 = typeParameterType(typeParameter('T', object()));
    var t2 = object();
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
  }

  void test_typeParam_to_typeParam() {
    var t = typeParameter('T', object());
    var t1 = typeParameterType(t);
    var t2 = typeParameterType(t);
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
  }

  @override
  TypeParameterElement typeParameter(String name, DecoratedType bound) {
    var t = super.typeParameter(name, bound);
    checker.bounds[t] = bound;
    return t;
  }
}

@reflectiveTest
class EdgeBuilderTest extends EdgeBuilderTestBase {
  void assertGLB(
      NullabilityNode node, NullabilityNode left, NullabilityNode right) {
    expect(node, isNot(TypeMatcher<NullabilityNodeForLUB>()));
    assertEdge(left, node, hard: false, guards: [right]);
    assertEdge(node, left, hard: false);
    assertEdge(node, right, hard: false);
  }

  void assertLUB(
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

    for (var edge in getEdges(anyNode, node)) {
      expect(edge.sourceNode, never);
    }
  }

  /// Verifies that a null check will occur when the given edge is unsatisfied.
  ///
  /// [expressionChecks] is the object tracking whether or not a null check is
  /// needed.
  void assertNullCheck(
      ExpressionChecksOrigin expressionChecks, NullabilityEdge expectedEdge) {
    expect(expressionChecks.checks.edges, contains(expectedEdge));
  }

  /// Gets the [ExpressionChecks] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [ExpressionChecks] associated with it.
  ExpressionChecksOrigin checkExpression(String text) {
    return variables.checkExpression(findNode.expression(text));
  }

  /// Gets the [DecoratedType] associated with the expression whose text
  /// representation is [text], or `null` if the expression has no
  /// [DecoratedType] associated with it.
  DecoratedType decoratedExpressionType(String text) {
    return variables.decoratedExpressionType(findNode.expression(text));
  }

  test_already_migrated_field() async {
    await analyze('''
double f() => double.NAN;
''');
    var nanElement = typeProvider.doubleType.element.getField('NAN');
    assertEdge(variables.decoratedElementType(nanElement).node,
        decoratedTypeAnnotation('double f').node,
        hard: false);
  }

  test_as_dynamic() async {
    await analyze('''
void f(Object o) {
  (o as dynamic).gcd(1);
}
''');
    assertEdge(decoratedTypeAnnotation('Object o').node,
        decoratedTypeAnnotation('dynamic').node,
        hard: true);
    // TODO(mfairhurst): these should probably be hard edges.
    assertEdge(decoratedTypeAnnotation('dynamic').node, never, hard: false);
  }

  test_as_int() async {
    await analyze('''
void f(Object o) {
  (o as int).gcd(1);
}
''');
    assertEdge(decoratedTypeAnnotation('Object o').node,
        decoratedTypeAnnotation('int').node,
        hard: true);
    // TODO(mfairhurst): these should probably be hard edges.
    assertEdge(decoratedTypeAnnotation('int').node, never, hard: false);
  }

  test_assert_demonstrates_non_null_intent() async {
    await analyze('''
void f(int i) {
  assert(i != null);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  test_assert_initializer_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  C(int i)
    : assert(i != null);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  test_assign_bound_to_type_parameter() async {
    await analyze('''
class C<T extends List<int>> {
  T f(List<int> x) => x;
}
''');
    var boundType = decoratedTypeAnnotation('List<int>>');
    var parameterType = decoratedTypeAnnotation('List<int> x');
    var tType = decoratedTypeAnnotation('T f');
    assertEdge(parameterType.node, tType.node, hard: true);
    assertNoEdge(parameterType.node, boundType.node);
    assertEdge(
        parameterType.typeArguments[0].node, boundType.typeArguments[0].node,
        hard: false);
  }

  test_assign_dynamic_to_other_type() async {
    await analyze('''
int f(dynamic d) => d;
''');
    // There is no explicit null check necessary, since `dynamic` is
    // downcastable to any type, nullable or not.
    expect(checkExpression('d;'), isNull);
    // But we still create an edge, to make sure that the possibility of `null`
    // propagates to callees.
    assertEdge(decoratedTypeAnnotation('dynamic').node,
        decoratedTypeAnnotation('int').node,
        hard: true);
  }

  test_assign_function_type_to_function_interface_type() async {
    await analyze('''
Function f(void Function() x) => x;
''');
    assertEdge(decoratedGenericFunctionTypeAnnotation('void Function()').node,
        decoratedTypeAnnotation('Function f').node,
        hard: true);
  }

  test_assign_future_to_futureOr_complex() async {
    await analyze('''
import 'dart:async';
FutureOr<List<int>> f(Future<List<int>> x) => x;
''');
    // If `x` is `Future<List<int?>>`, then the only way to migrate is to make
    // the return type `FutureOr<List<int?>>`.
    assertEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('int>> f').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('List<int>> f').node);
    assertNoEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('FutureOr<List<int>> f').node);
  }

  test_assign_future_to_futureOr_simple() async {
    await analyze('''
import 'dart:async';
FutureOr<int> f(Future<int> x) => x;
''');
    // If `x` is nullable, then there are two migrations possible: we could make
    // the return type `FutureOr<int?>` or we could make it `FutureOr<int>?`.
    // We choose `FutureOr<int>?` because it's strictly more conservative (it's
    // a subtype of `FutureOr<int?>`).
    assertEdge(decoratedTypeAnnotation('Future<int> x').node,
        decoratedTypeAnnotation('FutureOr<int>').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('Future<int> x').node,
        decoratedTypeAnnotation('int> f').node);
    // If `x` is `Future<int?>`, then the only way to migrate is to make the
    // return type `FutureOr<int?>`.
    assertEdge(substitutionNode(decoratedTypeAnnotation('int> x').node, never),
        decoratedTypeAnnotation('int> f').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('FutureOr<int>').node);
  }

  test_assign_non_future_to_futureOr_complex() async {
    await analyze('''
import 'dart:async';
FutureOr<List<int>> f(List<int> x) => x;
''');
    // If `x` is `List<int?>`, then the only way to migrate is to make the
    // return type `FutureOr<List<int?>>`.
    assertEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('int>> f').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('List<int>> f').node);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('FutureOr<List<int>> f').node);
  }

  test_assign_non_future_to_futureOr_simple() async {
    await analyze('''
import 'dart:async';
FutureOr<int> f(int x) => x;
''');
    // If `x` is nullable, then there are two migrations possible: we could make
    // the return type `FutureOr<int?>` or we could make it `FutureOr<int>?`.
    // We choose `FutureOr<int>?` because it's strictly more conservative (it's
    // a subtype of `FutureOr<int?>`).
    assertEdge(decoratedTypeAnnotation('int x').node,
        decoratedTypeAnnotation('FutureOr<int>').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int x').node,
        decoratedTypeAnnotation('int>').node);
  }

  test_assign_null_to_generic_type() async {
    await analyze('''
main() {
  List<int> x = null;
}
''');
    // TODO(paulberry): edge should be hard.
    assertEdge(always, decoratedTypeAnnotation('List').node, hard: false);
  }

  test_assign_type_parameter_to_bound() async {
    await analyze('''
class C<T extends List<int>> {
  List<int> f(T x) => x;
}
''');
    var boundType = decoratedTypeAnnotation('List<int>>');
    var returnType = decoratedTypeAnnotation('List<int> f');
    var tType = decoratedTypeAnnotation('T x');
    assertEdge(tType.node, returnType.node, hard: true);
    assertEdge(boundType.node, returnType.node, hard: false);
    assertEdge(
        boundType.typeArguments[0].node, returnType.typeArguments[0].node,
        hard: false);
  }

  test_assign_upcast_generic() async {
    await analyze('''
void f(Iterable<int> x) {}
void g(List<int> x) {
  f(x);
}
''');

    var iterableInt = decoratedTypeAnnotation('Iterable<int>');
    var listInt = decoratedTypeAnnotation('List<int>');
    assertEdge(listInt.node, iterableInt.node, hard: true);
    assertEdge(substitutionNode(listInt.typeArguments[0].node, never),
        iterableInt.typeArguments[0].node,
        hard: false);
  }

  test_assignmentExpression_compound_dynamic() async {
    await analyze('''
void f(dynamic x, int y) {
  x += y;
}
''');
    // No assertions; just making sure this doesn't crash.
  }

  test_assignmentExpression_compound_simple() async {
    var code = '''
abstract class C {
  C operator+(C x);
}
C f(C y, C z) => (y += z);
''';
    await analyze(code);
    var targetEdge =
        assertEdge(decoratedTypeAnnotation('C y').node, never, hard: true);
    expect(
        (graph.getEdgeOrigin(targetEdge) as CompoundAssignmentOrigin)
            .node
            .operator
            .offset,
        code.indexOf('+='));
    assertNullCheck(
        checkExpression('z);'),
        assertEdge(decoratedTypeAnnotation('C z').node,
            decoratedTypeAnnotation('C x').node,
            hard: true));
    var operatorReturnEdge = assertEdge(
        decoratedTypeAnnotation('C operator').node,
        decoratedTypeAnnotation('C y').node,
        hard: false);
    expect(
        (graph.getEdgeOrigin(operatorReturnEdge) as CompoundAssignmentOrigin)
            .node
            .operator
            .offset,
        code.indexOf('+='));
    var fReturnEdge = assertEdge(decoratedTypeAnnotation('C operator').node,
        decoratedTypeAnnotation('C f').node,
        hard: false);
    assertNullCheck(checkExpression('(y += z)'), fReturnEdge);
  }

  test_assignmentExpression_compound_withSubstitution() async {
    var code = '''
abstract class C<T> {
  C<T> operator+(C<T> x);
}
C<int> f(C<int> y, C<int> z) => (y += z);
''';
    await analyze(code);
    var targetEdge =
        assertEdge(decoratedTypeAnnotation('C<int> y').node, never, hard: true);
    expect(
        (graph.getEdgeOrigin(targetEdge) as CompoundAssignmentOrigin)
            .node
            .operator
            .offset,
        code.indexOf('+='));
    assertNullCheck(
        checkExpression('z);'),
        assertEdge(decoratedTypeAnnotation('C<int> z').node,
            decoratedTypeAnnotation('C<T> x').node,
            hard: true));
    var operatorReturnEdge = assertEdge(
        decoratedTypeAnnotation('C<T> operator').node,
        decoratedTypeAnnotation('C<int> y').node,
        hard: false);
    expect(
        (graph.getEdgeOrigin(operatorReturnEdge) as CompoundAssignmentOrigin)
            .node
            .operator
            .offset,
        code.indexOf('+='));
    var fReturnEdge = assertEdge(decoratedTypeAnnotation('C<T> operator').node,
        decoratedTypeAnnotation('C<int> f').node,
        hard: false);
    assertNullCheck(checkExpression('(y += z)'), fReturnEdge);
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

  test_assignmentExpression_nullAware_complex_contravariant() async {
    await analyze('''
void Function(int) f(void Function(int) x, void Function(int) y) => x ??= y;
''');
    var xNullable =
        decoratedGenericFunctionTypeAnnotation('void Function(int) x').node;
    var xParamNullable = decoratedTypeAnnotation('int) x').node;
    var yParamNullable = decoratedTypeAnnotation('int) y').node;
    var returnParamNullable = decoratedTypeAnnotation('int) f').node;
    assertEdge(xParamNullable, yParamNullable,
        hard: false, guards: [xNullable]);
    assertEdge(returnParamNullable, xParamNullable, hard: false);
  }

  test_assignmentExpression_nullAware_complex_covariant() async {
    await analyze('''
List<int> f(List<int> x, List<int> y) => x ??= y;
''');
    var xNullable = decoratedTypeAnnotation('List<int> x').node;
    var xElementNullable = decoratedTypeAnnotation('int> x').node;
    var yElementNullable = decoratedTypeAnnotation('int> y').node;
    var returnElementNullable = decoratedTypeAnnotation('int> f').node;
    assertEdge(yElementNullable, xElementNullable,
        hard: false, guards: [xNullable]);
    assertEdge(xElementNullable, returnElementNullable, hard: false);
  }

  test_assignmentExpression_nullAware_simple() async {
    await analyze('''
int f(int x, int y) => (x ??= y);
''');
    var yNullable = decoratedTypeAnnotation('int y').node;
    var xNullable = decoratedTypeAnnotation('int x').node;
    var returnNullable = decoratedTypeAnnotation('int f').node;
    var glbNode = decoratedExpressionType('(x ??= y)').node;
    assertEdge(yNullable, xNullable, hard: true, guards: [xNullable]);
    assertEdge(yNullable, glbNode, hard: false, guards: [xNullable]);
    assertEdge(glbNode, xNullable, hard: false);
    assertEdge(glbNode, yNullable, hard: false);
    assertEdge(glbNode, returnNullable, hard: false);
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

  test_binaryExpression_ampersand_result_not_null() async {
    await analyze('''
int f(int i, int j) => i & j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_ampersandAmpersand() async {
    await analyze('''
bool f(bool i, bool j) => i && j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool i').node);
  }

  test_binaryExpression_bar_result_not_null() async {
    await analyze('''
int f(int i, int j) => i | j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_barBar() async {
    await analyze('''
bool f(bool i, bool j) => i || j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool i').node);
  }

  test_binaryExpression_caret_result_not_null() async {
    await analyze('''
int f(int i, int j) => i ^ j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_equal() async {
    await analyze('''
bool f(int i, int j) => i == j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_equal_null() async {
    await analyze('''
void f(int i) {
  if (i == null) {
    g(i);
  } else {
    h(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j
    assertEdge(iNode, jNode, hard: false, guards: [iNode]);
  }

  test_binaryExpression_gt_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i > j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_gtEq_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i >= j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_gtGt_result_not_null() async {
    await analyze('''
int f(int i, int j) => i >> j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_left_dynamic() async {
    await analyze('''
Object f(dynamic x, int y) => x + g(y);
int g(int z) => z;
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int z').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int g').node, anyNode);
    assertEdge(always, decoratedTypeAnnotation('Object f').node, hard: false);
  }

  test_binaryExpression_lt_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i < j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_ltEq_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i <= j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_ltLt_result_not_null() async {
    await analyze('''
int f(int i, int j) => i << j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_minus_result_not_null() async {
    await analyze('''
int f(int i, int j) => i - j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_notEqual() async {
    await analyze('''
bool f(int i, int j) => i != j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  test_binaryExpression_notEqual_null() async {
    await analyze('''
void f(int i) {
  if (i != null) {
    h(i);
  } else {
    g(i);
  }
}
void g(int j) {}
void h(int k) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    var kNode = decoratedTypeAnnotation('int k').node;
    // No edge from i to k because i is known to be non-nullable at the site of
    // the call to h()
    assertNoEdge(iNode, kNode);
    // But there is an edge from i to j
    assertEdge(iNode, jNode, hard: false, guards: [iNode]);
  }

  test_binaryExpression_percent_result_not_null() async {
    await analyze('''
int f(int i, int j) => i % j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_plus_left_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true));
  }

  test_binaryExpression_plus_left_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('Int i').node, never, hard: true));
  }

  test_binaryExpression_plus_result_custom() async {
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

  test_binaryExpression_plus_result_not_null() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_plus_right_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true));
  }

  test_binaryExpression_plus_right_check_custom() async {
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

  test_binaryExpression_plus_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
Object _f(_C<int, String> c, String s) => c + s;
''');
    assertEdge(
        decoratedTypeAnnotation('String s').node,
        substitutionNode(decoratedTypeAnnotation('String>').node,
            decoratedTypeAnnotation('U u').node),
        hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int,').node,
            decoratedTypeAnnotation('T operator').node),
        decoratedTypeAnnotation('Object _f').node,
        hard: false);
  }

  test_binaryExpression_questionQuestion() async {
    await analyze('''
int f(int i, int j) => i ?? j;
''');

    var left = decoratedTypeAnnotation('int i').node;
    var right = decoratedTypeAnnotation('int j').node;
    var expression = decoratedExpressionType('??').node;
    assertEdge(right, expression, guards: [left], hard: false);
  }

  test_binaryExpression_right_dynamic() async {
    await analyze('''
class C {
  C operator+(C other) => other;
}
C f(C x, dynamic y) => x + y;
''');
    assertNullCheck(checkExpression('x +'),
        assertEdge(decoratedTypeAnnotation('C x').node, never, hard: true));
    assertEdge(decoratedTypeAnnotation('C operator').node,
        decoratedTypeAnnotation('C f').node,
        hard: false);
  }

  test_binaryExpression_slash_result_not_null() async {
    await analyze('''
double f(int i, int j) => i / j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('double f').node);
  }

  test_binaryExpression_star_result_not_null() async {
    await analyze('''
int f(int i, int j) => i * j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  test_binaryExpression_tildeSlash_result_not_null() async {
    await analyze('''
int f(int i, int j) => i ~/ j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
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

  test_catch_clause() async {
    await analyze('''
foo() => 1;
main() {
  try { foo(); } on Exception catch (e) { print(e); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_catch_clause_no_type() async {
    await analyze('''
foo() => 1;
main() {
  try { foo(); } catch (e) { print(e); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_class_alias_synthetic_constructor_with_parameters_complex() async {
    await analyze('''
class MyList<T> {}
class C {
  C(MyList<int>/*1*/ x);
}
mixin M {}
class D = C with M;
D f(MyList<int>/*2*/ x) => D(x);
''');
    var syntheticConstructor = findElement.unnamedConstructor('D');
    var constructorType = variables.decoratedElementType(syntheticConstructor);
    var constructorParameterType = constructorType.positionalParameters[0];
    assertEdge(decoratedTypeAnnotation('MyList<int>/*2*/').node,
        constructorParameterType.node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int>/*2*/').node,
        constructorParameterType.typeArguments[0].node,
        hard: false);
    assertUnion(constructorParameterType.node,
        decoratedTypeAnnotation('MyList<int>/*1*/').node);
    assertUnion(constructorParameterType.typeArguments[0].node,
        decoratedTypeAnnotation('int>/*1*/').node);
  }

  test_class_alias_synthetic_constructor_with_parameters_generic() async {
    await analyze('''
class C<T> {
  C(T t);
}
mixin M {}
class D<U> = C<U> with M;
''');
    var syntheticConstructor = findElement.unnamedConstructor('D');
    var constructorType = variables.decoratedElementType(syntheticConstructor);
    var constructorParameterType = constructorType.positionalParameters[0];
    assertUnion(
        constructorParameterType.node, decoratedTypeAnnotation('T t').node);
  }

  test_class_alias_synthetic_constructor_with_parameters_named() async {
    await analyze('''
class C {
  C({int/*1*/ i});
}
mixin M {}
class D = C with M;
D f(int/*2*/ i) => D(i: i);
''');
    var syntheticConstructor = findElement.unnamedConstructor('D');
    var constructorType = variables.decoratedElementType(syntheticConstructor);
    var constructorParameterType = constructorType.namedParameters['i'];
    assertEdge(
        decoratedTypeAnnotation('int/*2*/').node, constructorParameterType.node,
        hard: true);
    assertUnion(constructorParameterType.node,
        decoratedTypeAnnotation('int/*1*/').node);
  }

  test_class_alias_synthetic_constructor_with_parameters_optional() async {
    await analyze('''
class C {
  C([int/*1*/ i]);
}
mixin M {}
class D = C with M;
D f(int/*2*/ i) => D(i);
''');
    var syntheticConstructor = findElement.unnamedConstructor('D');
    var constructorType = variables.decoratedElementType(syntheticConstructor);
    var constructorParameterType = constructorType.positionalParameters[0];
    assertEdge(
        decoratedTypeAnnotation('int/*2*/').node, constructorParameterType.node,
        hard: true);
    assertUnion(constructorParameterType.node,
        decoratedTypeAnnotation('int/*1*/').node);
  }

  test_class_alias_synthetic_constructor_with_parameters_required() async {
    await analyze('''
class C {
  C(int/*1*/ i);
}
mixin M {}
class D = C with M;
D f(int/*2*/ i) => D(i);
''');
    var syntheticConstructor = findElement.unnamedConstructor('D');
    var constructorType = variables.decoratedElementType(syntheticConstructor);
    var constructorParameterType = constructorType.positionalParameters[0];
    assertEdge(
        decoratedTypeAnnotation('int/*2*/').node, constructorParameterType.node,
        hard: true);
    assertUnion(constructorParameterType.node,
        decoratedTypeAnnotation('int/*1*/').node);
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

  test_conditionalExpression_functionTyped_namedParameter() async {
    await analyze('''
void f(bool b, void Function({int p}) x, void Function({int p}) y) {
  (b ? x : y);
}
''');
    var xType =
        decoratedGenericFunctionTypeAnnotation('void Function({int p}) x');
    var yType =
        decoratedGenericFunctionTypeAnnotation('void Function({int p}) y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertGLB(resultType.namedParameters['p'].node,
        xType.namedParameters['p'].node, yType.namedParameters['p'].node);
  }

  test_conditionalExpression_functionTyped_normalParameter() async {
    await analyze('''
void f(bool b, void Function(int) x, void Function(int) y) {
  (b ? x : y);
}
''');
    var xType = decoratedGenericFunctionTypeAnnotation('void Function(int) x');
    var yType = decoratedGenericFunctionTypeAnnotation('void Function(int) y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertGLB(resultType.positionalParameters[0].node,
        xType.positionalParameters[0].node, yType.positionalParameters[0].node);
  }

  test_conditionalExpression_functionTyped_normalParameters() async {
    await analyze('''
void f(bool b, void Function(int, int) x, void Function(int, int) y) {
  (b ? x : y);
}
''');
    var xType =
        decoratedGenericFunctionTypeAnnotation('void Function(int, int) x');
    var yType =
        decoratedGenericFunctionTypeAnnotation('void Function(int, int) y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertGLB(resultType.positionalParameters[0].node,
        xType.positionalParameters[0].node, yType.positionalParameters[0].node);
    assertGLB(resultType.positionalParameters[1].node,
        xType.positionalParameters[1].node, yType.positionalParameters[1].node);
  }

  test_conditionalExpression_functionTyped_optionalParameter() async {
    await analyze('''
void f(bool b, void Function([int]) x, void Function([int]) y) {
  (b ? x : y);
}
''');
    var xType =
        decoratedGenericFunctionTypeAnnotation('void Function([int]) x');
    var yType =
        decoratedGenericFunctionTypeAnnotation('void Function([int]) y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertGLB(resultType.positionalParameters[0].node,
        xType.positionalParameters[0].node, yType.positionalParameters[0].node);
  }

  test_conditionalExpression_functionTyped_returnType() async {
    await analyze('''
void f(bool b, int Function() x, int Function() y) {
  (b ? x : y);
}
''');
    var xType = decoratedGenericFunctionTypeAnnotation('int Function() x');
    var yType = decoratedGenericFunctionTypeAnnotation('int Function() y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertLUB(resultType.returnType.node, xType.returnType.node,
        yType.returnType.node);
  }

  test_conditionalExpression_functionTyped_returnType_void() async {
    await analyze('''
void f(bool b, void Function() x, void Function() y) {
  (b ? x : y);
}
''');
    var xType = decoratedGenericFunctionTypeAnnotation('void Function() x');
    var yType = decoratedGenericFunctionTypeAnnotation('void Function() y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    expect(resultType.returnType.node, same(always));
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
    assertLUB(nullable_conditional, nullable_i, nullable_j);
    var nullable_return = decoratedTypeAnnotation('int f').node;
    assertNullCheck(checkExpression('(b ? i : j)'),
        assertEdge(nullable_conditional, nullable_return, hard: false));
  }

  test_conditionalExpression_generic() async {
    await analyze('''
void f(bool b, Map<int, String> x, Map<int, String> y) {
  (b ? x : y);
}
''');
    var xType = decoratedTypeAnnotation('Map<int, String> x');
    var yType = decoratedTypeAnnotation('Map<int, String> y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertLUB(resultType.typeArguments[0].node, xType.typeArguments[0].node,
        yType.typeArguments[0].node);
    assertLUB(resultType.typeArguments[1].node, xType.typeArguments[1].node,
        yType.typeArguments[1].node);
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
    assertLUB(nullable_conditional, nullable_throw, nullable_i);
  }

  test_conditionalExpression_left_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? null : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, always, nullable_i);
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
    assertLUB(nullable_conditional, nullable_i, nullable_throw);
  }

  test_conditionalExpression_right_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : null);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_i, always);
  }

  test_constructor_default_parameter_value_bool() async {
    await analyze('''
class C {
  C([bool b = true]);
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool b').node);
  }

  test_constructor_named() async {
    await analyze('''
class C {
  C.named();
}
''');
    // No assertions; just need to make sure that the test doesn't cause an
    // exception to be thrown.
  }

  test_constructorDeclaration_returnType_generic() async {
    await analyze('''
class C<T, U> {
  C();
}
''');
    var constructor = findElement.unnamedConstructor('C');
    var constructorDecoratedType = variables.decoratedElementType(constructor);
    expect(constructorDecoratedType.type.toString(), 'C<T, U> Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.type.toString(), 'C<T, U>');
    var typeArguments = constructorDecoratedType.returnType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0].type.toString(), 'T');
    expect(typeArguments[0].node, same(never));
    expect(typeArguments[1].type.toString(), 'U');
    expect(typeArguments[1].node, same(never));
  }

  test_constructorDeclaration_returnType_generic_implicit() async {
    await analyze('''
class C<T, U> {}
''');
    var constructor = findElement.unnamedConstructor('C');
    var constructorDecoratedType = variables.decoratedElementType(constructor);
    expect(constructorDecoratedType.type.toString(), 'C<T, U> Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.type.toString(), 'C<T, U>');
    var typeArguments = constructorDecoratedType.returnType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0].type.toString(), 'T');
    expect(typeArguments[0].node, same(never));
    expect(typeArguments[1].type.toString(), 'U');
    expect(typeArguments[1].node, same(never));
  }

  test_constructorDeclaration_returnType_simple() async {
    await analyze('''
class C {
  C();
}
''');
    var constructorDecoratedType =
        variables.decoratedElementType(findElement.unnamedConstructor('C'));
    expect(constructorDecoratedType.type.toString(), 'C Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.typeArguments, isEmpty);
  }

  test_constructorDeclaration_returnType_simple_implicit() async {
    await analyze('''
class C {}
''');
    var constructorDecoratedType =
        variables.decoratedElementType(findElement.unnamedConstructor('C'));
    expect(constructorDecoratedType.type.toString(), 'C Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.typeArguments, isEmpty);
  }

  test_constructorFieldInitializer_generic() async {
    await analyze('''
class C<T> {
  C(T/*1*/ x) : f = x;
  T/*2*/ f;
}
''');
    assertEdge(decoratedTypeAnnotation('T/*1*/').node,
        decoratedTypeAnnotation('T/*2*/').node,
        hard: true);
  }

  test_constructorFieldInitializer_simple() async {
    await analyze('''
class C {
  C(int/*1*/ i) : f = i;
  int/*2*/ f;
}
''');
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*2*/').node,
        hard: true);
  }

  test_constructorFieldInitializer_via_this() async {
    await analyze('''
class C {
  C(int/*1*/ i) : this.f = i;
  int/*2*/ f;
}
''');
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*2*/').node,
        hard: true);
  }

  test_do_while_condition() async {
    await analyze('''
void f(bool b) {
  do {} while (b);
}
''');

    assertNullCheck(checkExpression('b);'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
  }

  test_doubleLiteral() async {
    await analyze('''
double f() {
  return 1.0;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('double').node);
  }

  test_export_metadata() async {
    await analyze('''
@deprecated
export 'dart:async';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_field_metadata() async {
    await analyze('''
class A {
  const A();
}
class C {
  @A()
  int f;
}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_field_type_inferred() async {
    await analyze('''
int f() => 1;
class C {
  var x = f();
}
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertUnion(xType.node, decoratedTypeAnnotation('int').node);
  }

  test_fieldFormalParameter_function_typed() async {
    await analyze('''
class C {
  int Function(int, {int j}) f;
  C(int this.f(int i, {int j}));
}
''');
    var ctorParamType = variables
        .decoratedElementType(findElement.unnamedConstructor('C'))
        .positionalParameters[0];
    var fieldType = variables.decoratedElementType(findElement.field('f'));
    assertEdge(ctorParamType.node, fieldType.node, hard: true);
    assertEdge(ctorParamType.returnType.node, fieldType.returnType.node,
        hard: false);
    assertEdge(fieldType.positionalParameters[0].node,
        ctorParamType.positionalParameters[0].node,
        hard: false);
    assertEdge(fieldType.namedParameters['j'].node,
        ctorParamType.namedParameters['j'].node,
        hard: false);
  }

  test_fieldFormalParameter_typed() async {
    await analyze('''
class C {
  int i;
  C(int this.i);
}
''');
    assertEdge(decoratedTypeAnnotation('int this').node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  test_fieldFormalParameter_untyped() async {
    await analyze('''
class C {
  int i;
  C.named(this.i);
}
''');
    var decoratedConstructorParamType =
        decoratedConstructorDeclaration('named').positionalParameters[0];
    assertUnion(decoratedConstructorParamType.node,
        decoratedTypeAnnotation('int i').node);
  }

  test_for_each_element_with_declaration() async {
    await analyze('''
void f(List<int> l) {
  [for (int i in l) 0];
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(substitutionNode(decoratedTypeAnnotation('int> l').node, never),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  test_for_each_element_with_declaration_implicit_type() async {
    await analyze('''
void f(List<int> l) {
  [for (var i in l) g(i)];
}
int g(int j) => 0;
''');
    var jNode = decoratedTypeAnnotation('int j').node;
    var iMatcher = anyNode;
    assertEdge(iMatcher, jNode, hard: false);
    var iNode = iMatcher.matchingNode;
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> l').node, never), iNode,
        hard: false);
  }

  test_for_each_element_with_identifier() async {
    await analyze('''
void f(List<int> l) {
  int x;
  [for (x in l) 0];
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(substitutionNode(decoratedTypeAnnotation('int> l').node, never),
        decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  test_for_each_with_declaration() async {
    await analyze('''
void f(List<int> l) {
  for (int i in l) {}
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(substitutionNode(decoratedTypeAnnotation('int> l').node, never),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  test_for_each_with_declaration_implicit_type() async {
    await analyze('''
void f(List<int> l) {
  for (var i in l) {
    g(i);
  }
}
void g(int j) {}
''');
    var jNode = decoratedTypeAnnotation('int j').node;
    var iMatcher = anyNode;
    assertEdge(iMatcher, jNode, hard: false);
    var iNode = iMatcher.matchingNode;
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> l').node, never), iNode,
        hard: false);
  }

  test_for_each_with_identifier() async {
    await analyze('''
void f(List<int> l) {
  int x;
  for (x in l) {}
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(substitutionNode(decoratedTypeAnnotation('int> l').node, never),
        decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  test_for_element_list() async {
    await analyze('''
void f(List<int> ints) {
  <int>[for(int i in ints) i];
}
''');

    assertNullCheck(
        checkExpression('ints) i'),
        assertEdge(decoratedTypeAnnotation('List<int> ints').node, never,
            hard: true));
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_for_element_map() async {
    await analyze('''
void f(List<String> strs, List<int> ints) {
  <String, int>{
    for (String s in strs)
      for (int i in ints)
        s: i,
  };
}
''');

    assertNullCheck(
        checkExpression('strs)\n'),
        assertEdge(decoratedTypeAnnotation('List<String> strs').node, never,
            hard: true));
    assertNullCheck(
        checkExpression('ints)\n'),
        assertEdge(decoratedTypeAnnotation('List<int> ints').node, never,
            hard: false));

    var keyTypeNode = decoratedTypeAnnotation('String, int>{').node;
    var valueTypeNode = decoratedTypeAnnotation('int>{').node;
    assertEdge(decoratedTypeAnnotation('String s').node, keyTypeNode,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i').node, valueTypeNode,
        hard: false);
  }

  test_for_element_set() async {
    await analyze('''
void f(List<int> ints) {
  <int>{for(int i in ints) i};
}
''');

    assertNullCheck(
        checkExpression('ints) i'),
        assertEdge(decoratedTypeAnnotation('List<int> ints').node, never,
            hard: true));
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int>{').node,
        hard: false);
  }

  test_for_with_declaration() async {
    await analyze('''
main() {
  for (int i in <int>[1, 2, 3]) { print(i); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_for_with_var() async {
    await analyze('''
main() {
  for (var i in <int>[1, 2, 3]) { print(i); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_forStatement_empty() async {
    await analyze('''

void test() {
  for (; ; ) {
    return;
  }
}
''');
  }

  test_function_assignment() async {
    await analyze('''
class C {
  void f1(String message) {}
  void f2(String message) {}
}
foo(C c, bool flag) {
  Function(String message) out = flag ? c.f1 : c.f2;
  out('hello');
}
bar() {
  foo(C(), true);
  foo(C(), false);
}
''');
    var type = decoratedTypeAnnotation('Function(String message)');
    expect(type.returnType, isNotNull);
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

  test_functionDeclaration_parameter_named_default_listConst() async {
    await analyze('''
void f({List<int/*1*/> i = const <int/*2*/>[]}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('List<int/*1*/>').node);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*1*/').node,
        hard: false);
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

  test_functionExpressionInvocation_parameterType() async {
    await analyze('''
abstract class C {
  void Function(int) f();
}
void g(C c, int i) {
  c.f()(i);
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int)').node,
        hard: true);
  }

  test_functionExpressionInvocation_returnType() async {
    await analyze('''
abstract class C {
  int Function() f();
}
int g(C c) => c.f()();
''');
    assertEdge(decoratedTypeAnnotation('int Function').node,
        decoratedTypeAnnotation('int g').node,
        hard: false);
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

  test_genericMethodInvocation() async {
    await analyze('''
class Base {
  T foo<T>(T x) => x;
}
class Derived extends Base {}
int bar(Derived d, int i) => d.foo(i);
''');
    var implicitTypeArgumentMatcher = anyNode;
    assertEdge(
        decoratedTypeAnnotation('int i').node,
        substitutionNode(
            implicitTypeArgumentMatcher, decoratedTypeAnnotation('T x').node),
        hard: true);
    var implicitTypeArgumentNullability =
        implicitTypeArgumentMatcher.matchingNode;
    assertEdge(
        substitutionNode(implicitTypeArgumentNullability,
            decoratedTypeAnnotation('T foo').node),
        decoratedTypeAnnotation('int bar').node,
        hard: false);
  }

  test_genericMethodInvocation_withBoundSubstitution() async {
    await analyze('''
class Base<T> {
  U foo<U extends T>(U x) => x;
}
class Derived<V> extends Base<Iterable<V>> {}
bar(Derived<int> d, List<int> x) => d.foo(x);
''');
    // Don't bother checking any edges; the assertions in the DecoratedType
    // constructor verify that we've substituted the bound correctly.
  }

  test_genericMethodInvocation_withSubstitution() async {
    await analyze('''
class Base<T> {
  U foo<U>(U x, T y) => x;
}
class Derived<V> extends Base<List<V>> {}
int bar(Derived<String> d, int i, List<String> j) => d.foo(i, j);
''');
    assertEdge(
        decoratedTypeAnnotation('String> j').node,
        substitutionNode(decoratedTypeAnnotation('String> d').node,
            decoratedTypeAnnotation('V>>').node),
        hard: false);
    assertEdge(
        decoratedTypeAnnotation('List<String> j').node,
        substitutionNode(decoratedTypeAnnotation('List<V>>').node,
            decoratedTypeAnnotation('T y').node),
        hard: true);
    var implicitTypeArgumentMatcher = anyNode;
    assertEdge(
        decoratedTypeAnnotation('int i').node,
        substitutionNode(
            implicitTypeArgumentMatcher, decoratedTypeAnnotation('U x').node),
        hard: true);
    var implicitTypeArgumentNullability =
        implicitTypeArgumentMatcher.matchingNode;
    assertEdge(
        substitutionNode(implicitTypeArgumentNullability,
            decoratedTypeAnnotation('U foo').node),
        decoratedTypeAnnotation('int bar').node,
        hard: false);
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
    await analyze('''
void f(bool b, int i, int j) {
  assert(j != null);
  if (b) return;
  assert(i != null);
}
''');

    // Asserts after ifs don't demonstrate non-null intent.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
    // But asserts before ifs do
    assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true);
  }

  test_if_conditional_control_flow_after_normal_completion() async {
    await analyze('''
void f(bool b1, bool b2, int i, int j) {
  if (b1) {}
  assert(j != null);
  if (b2) return;
  assert(i != null);
}
''');

    // Asserts after `if (...) return` s don't demonstrate non-null intent.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
    // But asserts after `if (...) {}` do, since both branches of the `if`
    // complete normally, so the assertion is unconditionally reachable.
    assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true);
  }

  test_if_conditional_control_flow_within() async {
    await analyze('''
void f(bool b, int i, int j) {
  assert(j != null);
  if (b) {
    assert(i != null);
  } else {
    assert(i != null);
  }
}
''');

    // Asserts inside ifs don't demonstrate non-null intent.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
    // But asserts outside ifs do.
    assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true);
  }

  @failingTest
  test_if_element_guard_equals_null() async {
    // failing because of an unimplemented exception in conditional modification
    await analyze('''
dynamic f(int i, int j, int k) {
  <int>[if (i == null) j/*check*/ else k/*check*/];
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    var nullable_k = decoratedTypeAnnotation('int k').node;
    var nullable_itemType = decoratedTypeAnnotation('int>[').node;
    assertNullCheck(
        checkExpression('j/*check*/'),
        assertEdge(nullable_j, nullable_itemType,
            guards: [nullable_i], hard: false));
    assertNullCheck(checkExpression('k/*check*/'),
        assertEdge(nullable_k, nullable_itemType, hard: false));
    var discard = statementDiscard('if (i == null)');
    expect(discard.trueGuard, same(nullable_i));
    expect(discard.falseGuard, null);
    expect(discard.pureCondition, true);
  }

  test_if_element_list() async {
    await analyze('''
void f(bool b) {
  int i1 = null;
  int i2 = null;
  <int>[if (b) i1 else i2];
}
''');

    assertNullCheck(checkExpression('b) i1'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertEdge(decoratedTypeAnnotation('int i1').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i2').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_if_element_map() async {
    await analyze('''
void f(bool b) {
  int i1 = null;
  int i2 = null;
  String s1 = null;
  String s2 = null;
  <String, int>{if (b) s1: i1 else s2: i2};
}
''');

    assertNullCheck(checkExpression('b) s1'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));

    var keyTypeNode = decoratedTypeAnnotation('String, int>{').node;
    var valueTypeNode = decoratedTypeAnnotation('int>{').node;
    assertEdge(decoratedTypeAnnotation('String s1').node, keyTypeNode,
        hard: false);
    assertEdge(decoratedTypeAnnotation('String s2').node, keyTypeNode,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i1').node, valueTypeNode,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i2').node, valueTypeNode,
        hard: false);
  }

  test_if_element_nested() async {
    await analyze('''
void f(bool b1, bool b2) {
  int i1 = null;
  int i2 = null;
  int i3 = null;
  <int>[if (b1) if (b2) i1 else i2 else i3];
}
''');

    assertNullCheck(checkExpression('b1)'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(
        checkExpression('b2) i1'),
        assertEdge(decoratedTypeAnnotation('bool b2').node, never,
            hard: false));
    assertEdge(decoratedTypeAnnotation('int i1').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i2').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i3').node,
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_if_element_set() async {
    await analyze('''
void f(bool b) {
  int i1 = null;
  int i2 = null;
  <int>{if (b) i1 else i2};
}
''');

    assertNullCheck(checkExpression('b) i1'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertEdge(decoratedTypeAnnotation('int i1').node,
        decoratedTypeAnnotation('int>{').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int i2').node,
        decoratedTypeAnnotation('int>{').node,
        hard: false);
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

  test_import_metadata() async {
    await analyze('''
@deprecated
import 'dart:async';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_indexExpression_dynamic() async {
    await analyze('''
int f(dynamic d, int i) {
  return d[i];
}
''');
    // We assume that the index expression might evaluate to anything, including
    // `null`.
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
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

  test_instanceCreation_generic() async {
    await analyze('''
class C<T> {}
C<int> f() => C<int>();
''');
    assertEdge(decoratedTypeAnnotation('int>(').node,
        decoratedTypeAnnotation('int> f').node,
        hard: false);
  }

  test_instanceCreation_generic_dynamic() async {
    await analyze('''
class C<T> {}
C<Object> f() => C<dynamic>();
''');
    assertEdge(decoratedTypeAnnotation('dynamic').node,
        decoratedTypeAnnotation('Object').node,
        hard: false);
  }

  test_instanceCreation_generic_inferredParameterType() async {
    await analyze('''
class C<T> {
  C(List<T> x);
}
C<int> f(List<int> x) => C(x);
''');
    var edge = assertEdge(anyNode, decoratedTypeAnnotation('int> f').node,
        hard: false);
    var inferredTypeArgument = edge.sourceNode;
    assertEdge(
        decoratedTypeAnnotation('int> x').node,
        substitutionNode(
            inferredTypeArgument, decoratedTypeAnnotation('T> x').node),
        hard: false);
  }

  test_instanceCreation_generic_parameter() async {
    await analyze('''
class C<T> {
  C(T t);
}
f(int i) => C<int>(i/*check*/);
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_c_t = decoratedTypeAnnotation('C<int>').typeArguments[0].node;
    var nullable_t = decoratedTypeAnnotation('T t').node;
    var check_i = checkExpression('i/*check*/');
    var nullable_c_t_or_nullable_t = check_i.checks.edges.single.destinationNode
        as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  test_instanceCreation_generic_parameter_named() async {
    await analyze('''
class C<T> {
  C({T t});
}
f(int i) => C<int>(t: i/*check*/);
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_c_t = decoratedTypeAnnotation('C<int>').typeArguments[0].node;
    var nullable_t = decoratedTypeAnnotation('T t').node;
    var check_i = checkExpression('i/*check*/');
    var nullable_c_t_or_nullable_t = check_i.checks.edges.single.destinationNode
        as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
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

  test_invocation_arguments() async {
    await analyze('''
int f(Function g, int i, int j) => g(h(i), named: h(j));
int h(int x) => 0;
''');
    // Make sure the appropriate edges get created for the calls to h().
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_invocation_arguments_parenthesized() async {
    await analyze('''
int f(Function g, int i, int j) => (g)(h(i), named: h(j));
int h(int x) => 0;
''');
    // Make sure the appropriate edges get created for the calls to h().
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_invocation_dynamic() async {
    await analyze('''
int f(dynamic g) => g();
''');
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
  }

  test_invocation_dynamic_parenthesized() async {
    await analyze('''
int f(dynamic g) => (g)();
''');
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
  }

  test_invocation_function() async {
    await analyze('''
int f(Function g) => g();
''');
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
    assertNullCheck(
        checkExpression('g('),
        assertEdge(decoratedTypeAnnotation('Function g').node, never,
            hard: true));
  }

  test_invocation_function_parenthesized() async {
    await analyze('''
int f(Function g) => (g)();
''');
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
    assertNullCheck(
        checkExpression('g)('),
        assertEdge(decoratedTypeAnnotation('Function g').node, never,
            hard: true));
  }

  test_invocation_type_arguments() async {
    await analyze('''
int f(Function g) => g<C<int>>();
class C<T extends num> {}
''');
    // Make sure the appropriate edge gets created for the instantiation of C.
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('num>').node,
        hard: true);
  }

  test_invocation_type_arguments_parenthesized() async {
    await analyze('''
int f(Function g) => (g)<C<int>>();
class C<T extends num> {}
''');
    // Make sure the appropriate edge gets created for the instantiation of C.
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('num>').node,
        hard: true);
  }

  @failingTest
  test_isExpression_directlyRelatedTypeParameter() async {
    await analyze('''
bool f(List<num> list) => list is List<int>
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: false);
    assertEdge(decoratedTypeAnnotation('num').node,
        decoratedTypeAnnotation('int').node,
        hard: false);
  }

  @failingTest
  test_isExpression_genericFunctionType() async {
    await analyze('''
bool f(a) => a is int Function(String);
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  @failingTest
  test_isExpression_indirectlyRelatedTypeParameter() async {
    await analyze('''
bool f(Iterable<num> iter) => iter is List<int>
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List').node, never, hard: false);
    assertEdge(decoratedTypeAnnotation('num').node,
        decoratedTypeAnnotation('int').node,
        hard: false);
  }

  test_isExpression_typeName_noTypeArguments() async {
    await analyze('''
bool f(a) => a is String;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('String').node, never, hard: false);
  }

  test_isExpression_typeName_typeArguments() async {
    await analyze('''
bool f(a) => a is List<int>;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List').node, never, hard: false);
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_library_metadata() async {
    await analyze('''
@deprecated
library foo;
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_libraryDirective() async {
    await analyze('''
library foo;
''');
    // Passes if no exceptions are thrown.
  }

  test_listLiteral_noTypeArgument_noNullableElements() async {
    await analyze('''
List<String> f() {
  return ['a', 'b'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    final returnTypeNode = decoratedTypeAnnotation('String').node;
    final returnTypeEdges = getEdges(anyNode, returnTypeNode);

    expect(returnTypeEdges.length, 1);
    final returnTypeEdge = returnTypeEdges.single;

    final listArgType = returnTypeEdge.sourceNode;
    assertNoUpstreamNullability(listArgType);
  }

  test_listLiteral_noTypeArgument_nullableElement() async {
    await analyze('''
List<String> f() {
  return ['a', null, 'c'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    final returnTypeNode = decoratedTypeAnnotation('String').node;
    final returnTypeEdges = getEdges(anyNode, returnTypeNode);

    expect(returnTypeEdges.length, 1);
    final returnTypeEdge = returnTypeEdges.single;

    final listArgType = returnTypeEdge.sourceNode;
    assertEdge(always, listArgType, hard: false);
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

  test_localVariable_type_inferred() async {
    await analyze('''
int f() => 1;
main() {
  var x = f();
}
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertUnion(xType.node, decoratedTypeAnnotation('int').node);
  }

  test_method_parameterType_inferred() async {
    await analyze('''
class B {
  void f/*B*/(int x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var bReturnType = decoratedMethodType('f/*B*/').positionalParameters[0];
    var cReturnType = decoratedMethodType('f/*C*/').positionalParameters[0];
    assertUnion(bReturnType.node, cReturnType.node);
  }

  test_method_parameterType_inferred_named() async {
    await analyze('''
class B {
  void f/*B*/({int x = 0}) {}
}
class C extends B {
  void f/*C*/({x = 0}) {}
}
''');
    var bReturnType = decoratedMethodType('f/*B*/').namedParameters['x'];
    var cReturnType = decoratedMethodType('f/*C*/').namedParameters['x'];
    assertUnion(bReturnType.node, cReturnType.node);
  }

  test_method_returnType_inferred() async {
    await analyze('''
class B {
  int f/*B*/() => 1;
}
class C extends B {
  f/*C*/() => 1;
}
''');
    var bReturnType = decoratedMethodType('f/*B*/').returnType;
    var cReturnType = decoratedMethodType('f/*C*/').returnType;
    assertUnion(bReturnType.node, cReturnType.node);
  }

  test_methodDeclaration_doesntAffect_unconditional_control_flow() async {
    await analyze('''
class C {
  void f(bool b, int i, int j) {
    assert(i != null);
    if (b) {}
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

  test_methodInvocation_dynamic() async {
    await analyze('''
class C {
  int g(int i) => i;
}
int f(dynamic d, int j) {
  return d.g(j);
}
''');
    // The call `d.g(j)` is dynamic, so we can't tell what method it resolves
    // to.  There's no reason to assume it resolves to `C.g`.
    assertNoEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node);
    assertNoEdge(decoratedTypeAnnotation('int g').node,
        decoratedTypeAnnotation('int f').node);
    // We do, however, assume that it might return anything, including `null`.
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
  }

  test_methodInvocation_dynamic_arguments() async {
    await analyze('''
int f(dynamic d, int i, int j) {
  return d.g(h(i), named: h(j));
}
int h(int x) => 0;
''');
    // Make sure the appropriate edges get created for the calls to h().
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  test_methodInvocation_dynamic_type_arguments() async {
    await analyze('''
int f(dynamic d, int i, int j) {
  return d.g<C<int>>();
}
class C<T extends num> {}
''');
    // Make sure the appropriate edge gets created for the instantiation of C.
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('num>').node,
        hard: true);
  }

  test_methodInvocation_object_method() async {
    await analyze('''
String f(int i) => i.toString();
''');
    // No edge from i to `never` because it is safe to call `toString` on
    // `null`.
    assertNoEdge(decoratedTypeAnnotation('int').node, never);
  }

  test_methodInvocation_object_method_on_non_interface_type() async {
    await analyze('''
String f(void Function() g) => g.toString();
''');
    var toStringReturnType = variables
        .decoratedElementType(
            typeProvider.objectType.element.getMethod('toString'))
        .returnType;
    assertEdge(
        toStringReturnType.node, decoratedTypeAnnotation('String f').node,
        hard: false);
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
    var nullable_c_t_or_nullable_t = check_i.checks.edges.single.destinationNode
        as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  test_methodInvocation_parameter_contravariant_from_migrated_class() async {
    await analyze('''
void f(List<int> x, int i) {
  x.add(i/*check*/);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_list_t =
        decoratedTypeAnnotation('List<int>').typeArguments[0].node;
    var addMethod = findNode.methodInvocation('x.add').methodName.staticElement
        as MethodMember;
    var nullable_t = variables
        .decoratedElementType(addMethod.baseElement)
        .positionalParameters[0]
        .node;
    expect(nullable_t, same(never));
    var check_i = checkExpression('i/*check*/');
    var nullable_list_t_or_nullable_t = check_i
        .checks.edges.single.destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_list_t_or_nullable_t.innerNode, same(nullable_list_t));
    expect(nullable_list_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_list_t_or_nullable_t, hard: true));
  }

  test_methodInvocation_parameter_contravariant_function() async {
    await analyze('''
void f<T>(T t) {}
void g(int i) {
  f<int>(i/*check*/);
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_f_t = decoratedTypeAnnotation('int>').node;
    var nullable_t = decoratedTypeAnnotation('T t').node;
    var check_i = checkExpression('i/*check*/');
    var nullable_f_t_or_nullable_t = check_i.checks.edges.single.destinationNode
        as NullabilityNodeForSubstitution;
    expect(nullable_f_t_or_nullable_t.innerNode, same(nullable_f_t));
    expect(nullable_f_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_f_t_or_nullable_t, hard: true));
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

  test_methodInvocation_parameter_named_differentPackage() async {
    addPackageFile('pkgC', 'c.dart', '''
class C {
  void f({int i}) {}
}
''');
    await analyze('''
import "package:pkgC/c.dart";
void g(C c, int j) {
  c.f(i: j/*check*/);
}
''');
    var nullable_j = decoratedTypeAnnotation('int j');
    assertNullCheck(checkExpression('j/*check*/'),
        assertEdge(nullable_j.node, never, hard: true));
  }

  test_methodInvocation_resolves_to_getter() async {
    await analyze('''
abstract class C {
  int/*1*/ Function(int/*2*/ i) get f;
}
int/*3*/ g(C c, int/*4*/ i) => c.f(i);
''');
    assertEdge(decoratedTypeAnnotation('int/*4*/').node,
        decoratedTypeAnnotation('int/*2*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*3*/').node,
        hard: false);
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

  test_methodInvocation_return_type_generic_function() async {
    await analyze('''
T f<T>(T t) => t;
int g() => (f<int>(1));
''');
    var check_i = checkExpression('(f<int>(1))');
    var nullable_f_t = decoratedTypeAnnotation('int>').node;
    var nullable_f_t_or_nullable_t = check_i.checks.edges.single.sourceNode
        as NullabilityNodeForSubstitution;
    var nullable_t = decoratedTypeAnnotation('T f').node;
    expect(nullable_f_t_or_nullable_t.innerNode, same(nullable_f_t));
    expect(nullable_f_t_or_nullable_t.outerNode, same(nullable_t));
    var nullable_return = decoratedTypeAnnotation('int g').node;
    assertNullCheck(check_i,
        assertEdge(nullable_f_t_or_nullable_t, nullable_return, hard: false));
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

  test_methodInvocation_static_on_generic_class() async {
    await analyze('''
class C<T> {
  static int f(int x) => 0;
}
int g(int y) => C.f(y);
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int f').node,
        decoratedTypeAnnotation('int g').node,
        hard: false);
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

  test_methodInvocation_target_generic_in_base_class() async {
    await analyze('''
abstract class B<T> {
  void m(T/*1*/ t);
}
abstract class C extends B<int/*2*/> {}
void f(C c, int/*3*/ i) {
  c.m(i);
}
''');
    // nullable(3) -> substitute(nullable(2), nullable(1))
    var nullable1 = decoratedTypeAnnotation('T/*1*/').node;
    var nullable2 = decoratedTypeAnnotation('int/*2*/').node;
    var nullable3 = decoratedTypeAnnotation('int/*3*/').node;
    assertEdge(nullable3, substitutionNode(nullable2, nullable1), hard: true);
  }

  test_methodInvocation_typeParameter_inferred() async {
    await analyze('''
T f<T>(T t) => t;
void g() {
  int y;
  int x = f(y);
}
''');
    var int_y = decoratedTypeAnnotation('int y').node;
    var int_x = decoratedTypeAnnotation('int x').node;
    var t_ret = decoratedTypeAnnotation('T f').node;
    var t_param = decoratedTypeAnnotation('T t').node;

    assertEdge(substitutionNode(anyNode, t_ret), int_x, hard: false);
    assertEdge(int_y, substitutionNode(anyNode, t_param), hard: true);
    assertEdge(t_param, t_ret, hard: true);
  }

  @failingTest
  test_methodInvocation_typeParameter_inferred_inGenericClass() async {
    // this creates an edge case because the typeArguments are not equal in
    // length the the typeFormals of the calleeType, due to the enclosing
    // generic class.
    await analyze('''
class C<T> {
 void g() {
   // use a local fn because generic methods aren't implemented.
   T f<T>(T t) => t;
   int y;
   int x = f(y);
 }
}
''');
    var int_y = decoratedTypeAnnotation('int y').node;
    var int_x = decoratedTypeAnnotation('int x').node;
    var t_ret = decoratedTypeAnnotation('T f').node;
    var t_param = decoratedTypeAnnotation('T t').node;

    assertEdge(int_y, t_param, hard: true);
    assertEdge(t_param, t_ret, hard: true);
    assertEdge(t_ret, int_x, hard: false);
  }

  @failingTest
  test_methodInvocation_typeParameter_inferred_inGenericExtreme() async {
    // this creates an edge case because the typeArguments are not equal in
    // length the the typeFormals of the calleeType, due to the enclosing
    // generic class/functions.
    await analyze('''
class C<T> {
 void g() {
   // use local fns because generic methods aren't implemented.
   void f2<R1>() {
     void f3<R2>() {
       T f<T>(T t) => t;
       int y;
       int x = f(y);
     }
   }
 }
}
''');
    var int_y = decoratedTypeAnnotation('int y').node;
    var int_x = decoratedTypeAnnotation('int x').node;
    var t_ret = decoratedTypeAnnotation('T f').node;
    var t_param = decoratedTypeAnnotation('T t').node;

    assertEdge(int_y, t_param, hard: true);
    assertEdge(t_param, t_ret, hard: true);
    assertEdge(t_ret, int_x, hard: false);
  }

  test_never() async {
    await analyze('');

    expect(never.isNullable, isFalse);
  }

  test_override_parameter_type_named() async {
    await analyze('''
abstract class Base {
  void f({int/*1*/ i});
}
class Derived extends Base {
  void f({int/*2*/ i}) {}
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int1.node, int2.node, hard: true);
  }

  test_override_parameter_type_named_over_none() async {
    await analyze('''
abstract class Base {
  void f();
}
class Derived extends Base {
  void f({int i}) {}
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_override_parameter_type_operator() async {
    await analyze('''
abstract class Base {
  Base operator+(Base/*1*/ b);
}
class Derived extends Base {
  Base operator+(Base/*2*/ b) => this;
}
''');
    var base1 = decoratedTypeAnnotation('Base/*1*/');
    var base2 = decoratedTypeAnnotation('Base/*2*/');
    assertEdge(base1.node, base2.node, hard: true);
  }

  test_override_parameter_type_optional() async {
    await analyze('''
abstract class Base {
  void f([int/*1*/ i]);
}
class Derived extends Base {
  void f([int/*2*/ i]) {}
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int1.node, int2.node, hard: true);
  }

  test_override_parameter_type_optional_over_none() async {
    await analyze('''
abstract class Base {
  void f();
}
class Derived extends Base {
  void f([int i]) {}
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_override_parameter_type_optional_over_required() async {
    await analyze('''
abstract class Base {
  void f(int/*1*/ i);
}
class Derived extends Base {
  void f([int/*2*/ i]) {}
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int1.node, int2.node, hard: true);
  }

  test_override_parameter_type_required() async {
    await analyze('''
abstract class Base {
  void f(int/*1*/ i);
}
class Derived extends Base {
  void f(int/*2*/ i) {}
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int1.node, int2.node, hard: true);
  }

  test_override_parameter_type_setter() async {
    await analyze('''
abstract class Base {
  void set x(int/*1*/ value);
}
class Derived extends Base {
  void set x(int/*2*/ value) {}
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int1.node, int2.node, hard: true);
  }

  test_override_return_type_getter() async {
    await analyze('''
abstract class Base {
  int/*1*/ get x;
}
class Derived extends Base {
  int/*2*/ get x => null;
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int2.node, int1.node, hard: true);
  }

  test_override_return_type_method() async {
    await analyze('''
abstract class Base {
  int/*1*/ f();
}
class Derived extends Base {
  int/*2*/ f() => null;
}
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int2.node, int1.node, hard: true);
  }

  test_override_return_type_operator() async {
    await analyze('''
abstract class Base {
  Base/*1*/ operator-();
}
class Derived extends Base {
  Derived/*2*/ operator-() => null;
}
''');
    var base1 = decoratedTypeAnnotation('Base/*1*/');
    var derived2 = decoratedTypeAnnotation('Derived/*2*/');
    assertEdge(derived2.node, base1.node, hard: true);
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

  test_part_metadata() async {
    var pathContext = resourceProvider.pathContext;
    addSource(pathContext.join(pathContext.dirname(testFile), 'part.dart'), '''
part of test;
''');
    await analyze('''
library test;
@deprecated
part 'part.dart';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_part_of_identifier() async {
    var pathContext = resourceProvider.pathContext;
    var testFileName = pathContext.basename(testFile);
    addSource(pathContext.join(pathContext.dirname(testFile), 'lib.dart'), '''
library test;
part '$testFileName';
''');
    await analyze('''
part of test;
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_part_of_metadata() async {
    var pathContext = resourceProvider.pathContext;
    var testFileName = pathContext.basename(testFile);
    addSource(pathContext.join(pathContext.dirname(testFile), 'lib.dart'), '''
library test;
part '$testFileName';
''');
    await analyze('''
@deprecated
part of test;
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_part_of_path() async {
    var pathContext = resourceProvider.pathContext;
    var testFileName = pathContext.basename(testFile);
    addSource(pathContext.join(pathContext.dirname(testFile), 'lib.dart'), '''
part '$testFileName';
''');
    await analyze('''
part of 'lib.dart';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_postDominators_assert() async {
    await analyze('''
void test(bool b1, bool b2, bool b3, bool _b) {
  assert(b1 != null);
  if (_b) {
    assert(b2 != null);
  }
  assert(b3 != null);
}
''');

    assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true);
    assertNoEdge(decoratedTypeAnnotation('bool b2').node, never);
    assertEdge(decoratedTypeAnnotation('bool b3').node, never, hard: true);
  }

  test_postDominators_assignment_with_same_var_on_lhs_and_in_rhs() async {
    await analyze('''
void f(int i) {
  i = g(i);
}
int g(int j) => 0;
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int j').node,
        hard: true);
  }

  test_postDominators_break() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b1, C _c) {
  while (b1/*check*/) {
    bool b2 = b1;
    C c = _c;
    if (b2/*check*/) {
      break;
    }
    c.m();
  }
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(checkExpression('b2/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b2').node, never, hard: true));
    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: false));
  }

  test_postDominators_continue() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b1, C _c) {
  while (b1/*check*/) {
    bool b2 = b1;
    C c = _c;
    if (b2/*check*/) {
      continue;
    }
    c.m();
  }
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(checkExpression('b2/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b2').node, never, hard: true));
    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: false));
  }

  test_postDominators_doWhileStatement_conditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b, C c) {
  do {
    return;
  } while(b/*check*/);

  c.m();
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: false));
    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: false));
  }

  test_postDominators_doWhileStatement_unconditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b, C c1, C c2) {
  do {
    C c3 = C();
    c1.m();
    c3.m();
  } while(b/*check*/);

  c2.m();
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: true));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: true));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));
  }

  test_postDominators_forElement() async {
    await analyze('''
class C {
  int m() => 0;
}

void test(bool _b, C c1, C c2) {
  <int>[for (bool b1 = _b; b1/*check*/; c2.m()) c1.m()];
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
  }

  test_postDominators_forInElement() async {
    await analyze('''
class C {
  int m() => 0;
}
void test(List<C> l, C c1) {
  <int>[for (C _c in l/*check*/) c1.m()];
  <int>[for (C c2 in <C>[]) c2.m()];
}
''');

    assertNullCheck(
        checkExpression('l/*check*/'),
        assertEdge(decoratedTypeAnnotation('List<C> l').node, never,
            hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
  }

  test_postDominators_forInStatement_unconditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(List<C> l, C c1, C c2) {
  for (C c3 in l/*check*/) {
    c1.m();
    c3.m();
  }

  c2.m();
}
''');

    assertNullCheck(
        checkExpression('l/*check*/'),
        assertEdge(decoratedTypeAnnotation('List<C> l').node, never,
            hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: true));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: false));
  }

  test_postDominators_forStatement_conditional() async {
    await analyze('''

class C {
  void m() {}
}
void test(bool b1, C c1, C c2, C c3) {
  for (; b1/*check*/; c2.m()) {
    C c4 = c1;
    c4.m();
    return;
  }

  c3.m();
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(checkExpression('c4.m'),
        assertEdge(decoratedTypeAnnotation('C c4').node, never, hard: true));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: false));
  }

  test_postDominators_forStatement_unconditional() async {
    await analyze('''

class C {
  void m() {}
}
void test(bool b1, C c1, C c2, C c3) {
  for (bool b2 = b1, b3 = b1; b1/*check*/ & b2/*check*/; c3.m()) {
    c1.m();
    assert(b3 != null);
  }

  c2.m();
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    //TODO(mfairhurst): enable this check
    //assertNullCheck(checkExpression('b2/*check*/'),
    //    assertEdge(decoratedTypeAnnotation('bool b2').node, never, hard: true));
    //assertEdge(decoratedTypeAnnotation('b3 =').node, never, hard: false);
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: true));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: false));
  }

  test_postDominators_ifElement() async {
    await analyze('''
class C {
  int m() => 0;
}
void test(bool b, C c1, C c2, C c3) {
  <int>[if (b) c1.m() else c2.m()];
  c3.m();
}
''');

    assertNullCheck(checkExpression('b)'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));
  }

  test_postDominators_ifStatement_conditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b, C c1, C c2) {
  if (b/*check*/) {
    C c3 = C();
    C c4 = C();
    c1.m();
    c3.m();

    // Divergence breaks post-dominance.
    return;
    c4.m();

  }
  c2.m();
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));
    assertNullCheck(checkExpression('c4.m'),
        assertEdge(decoratedTypeAnnotation('C c4').node, never, hard: false));
  }

  test_postDominators_ifStatement_unconditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b, C c1, C c2) {
  if (b/*check*/) {
    C c3 = C();
    C c4 = C();
    c1.m();
    c3.m();

    // We ignore exceptions for post-dominance.
    throw '';
    c4.m();

  }
  c2.m();
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: true));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));
    assertNullCheck(checkExpression('c4.m'),
        assertEdge(decoratedTypeAnnotation('C c4').node, never, hard: true));
  }

  test_postDominators_inReturn_local() async {
    await analyze('''
class C {
  int m() => 0;
}
int test(C c) {
  return c.m();
}
''');

    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_postDominators_loopReturn() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b1, C _c) {
  C c1 = _c;
  while (b1/*check*/) {
    bool b2 = b1;
    C c2 = _c;
    if (b2/*check*/) {
      return;
    }
    c2.m();
  }
  c1.m();
}
''');

    assertNullCheck(checkExpression('b1/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b1').node, never, hard: true));
    assertNullCheck(checkExpression('b2/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b2').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));
  }

  test_postDominators_multiDeclaration() async {
    // Multi declarations cannot use hard edges as shown below.
    await analyze('''
void test() {
  int i1 = 0, i2 = null;
  i1.toDouble();
}
''');

    // i1.toDouble() cannot be a hard edge or i2 will fail assignment
    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: false);
    // i2 gets a soft edge to always due to null assignment
    assertEdge(always, decoratedTypeAnnotation('int i').node, hard: false);
  }

  test_postDominators_questionQuestionOperator() async {
    await analyze('''
class C {
  Object m() => null;
}
Object test(C x, C y) => x.m() ?? y.m();
''');
    // There is a hard edge from x to `never` because `x.m()` is unconditionally
    // reachable from the top of `test`.
    assertEdge(decoratedTypeAnnotation('C x').node, never, hard: true);
    // However, the edge from y to `never` is soft because `y.m()` is only
    // executed if `x.m()` returned `null`.
    assertEdge(decoratedTypeAnnotation('C y').node, never,
        hard: false, guards: [decoratedTypeAnnotation('Object m').node]);
  }

  test_postDominators_reassign() async {
    await analyze('''
void test(bool b, int i1, int i2) {
  i1 = null;
  i1.toDouble();
  if (b) {
    i2 = null;
  }
  i2.toDouble();
}
''');

    assertNullCheck(checkExpression('i1.toDouble'),
        assertEdge(decoratedTypeAnnotation('int i1').node, never, hard: false));

    assertNullCheck(checkExpression('i2.toDouble'),
        assertEdge(decoratedTypeAnnotation('int i2').node, never, hard: false));
  }

  test_postDominators_shortCircuitOperators() async {
    await analyze('''
class C {
  bool m() => true;
}
void test(C c1, C c2, C c3, C c4) {
  c1.m() && c2.m();
  c3.m() || c4.m();
}
''');

    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: true));

    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));

    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));

    assertNullCheck(checkExpression('c4.m'),
        assertEdge(decoratedTypeAnnotation('C c4').node, never, hard: false));
  }

  test_postDominators_subFunction() async {
    await analyze('''
class C {
  void m() {}
}
void test() {
  (C c) {
    c.m();
  };
}
''');

    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  @failingTest
  test_postDominators_subFunction_ifStatement_conditional() async {
    // Failing because function expressions aren't implemented
    await analyze('''
class C {
  void m() {}
}
void test() {
  (bool b, C c) {
    if (b/*check*/) {
      return;
    }
    c.m();
  };
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: false));
    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: false));
  }

  test_postDominators_subFunction_ifStatement_unconditional() async {
    await analyze('''
class C {
  void m() {}
}
void test() {
  (bool b, C c) {
    if (b/*check*/) {
    }
    c.m();
  };
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c.m'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_postDominators_ternaryOperator() async {
    await analyze('''
class C {
  bool m() => true;
}
void test(C c1, C c2, C c3, C c4) {
  c1.m() ? c2.m() : c3.m();

  c4.m();
}
''');

    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: true));

    assertNullCheck(checkExpression('c4.m'),
        assertEdge(decoratedTypeAnnotation('C c4').node, never, hard: true));

    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: false));

    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: false));
  }

  test_postDominators_tryCatch() async {
    await analyze('''
void test(int i) {
  try {} catch (_) {
    i.isEven;
  }
}
''');
    // Edge should not be hard because the call to `i.isEven` does not
    // post-dominate the declaration of `i`.
    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: false);
  }

  test_postDominators_whileStatement_unconditional() async {
    await analyze('''
class C {
  void m() {}
}
void test(bool b, C c1, C c2) {
  while (b/*check*/) {
    C c3 = C();
    c1.m();
    c3.m();
  }

  c2.m();
}
''');

    assertNullCheck(checkExpression('b/*check*/'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
    assertNullCheck(checkExpression('c1.m'),
        assertEdge(decoratedTypeAnnotation('C c1').node, never, hard: false));
    assertNullCheck(checkExpression('c2.m'),
        assertEdge(decoratedTypeAnnotation('C c2').node, never, hard: true));
    assertNullCheck(checkExpression('c3.m'),
        assertEdge(decoratedTypeAnnotation('C c3').node, never, hard: true));
  }

  test_postfixExpression_minusMinus() async {
    await analyze('''
int f(int i) {
  return i--;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i--');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(never, returnType, hard: false);
  }

  test_postfixExpression_plusPlus() async {
    await analyze('''
int f(int i) {
  return i++;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i++');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(never, returnType, hard: false);
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

  test_prefixedIdentifier_getter_type_in_generic() async {
    await analyze('''
class C<T> {
  List<T> _x;
  List<T> get x => _x;
}
List<int> f(C<int> c) => c.x;
''');
    assertEdge(decoratedTypeAnnotation('List<T> get').node,
        decoratedTypeAnnotation('List<int> f').node,
        hard: false);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> c').node,
            decoratedTypeAnnotation('T> get').node),
        decoratedTypeAnnotation('int> f').node,
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

  test_prefixedIdentifier_tearoff() async {
    await analyze('''
abstract class C {
  int f(int i);
}
int Function(int) g(C c) => c.f;
''');
    var fType = variables.decoratedElementType(findElement.method('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.function('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node, hard: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false);
  }

  test_prefixExpression_bang() async {
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

  test_prefixExpression_minus() async {
    await analyze('''
abstract class C {
  C operator-();
}
C test(C c) => -c/*check*/;
''');
    assertEdge(decoratedTypeAnnotation('C operator').node,
        decoratedTypeAnnotation('C test').node,
        hard: false);
    assertNullCheck(checkExpression('c/*check*/'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_prefixExpression_minusMinus() async {
    await analyze('''
int f(int i) {
  return --i;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i;');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(never, returnType, hard: false);
  }

  test_prefixExpression_plusPlus() async {
    await analyze('''
int f(int i) {
  return ++i;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i;');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(never, returnType, hard: false);
  }

  test_propertyAccess_dynamic() async {
    await analyze('''
class C {
  int get g => 0;
}
int f(dynamic d) {
  return d.g;
}
''');
    // The call `d.g` is dynamic, so we can't tell what method it resolves
    // to.  There's no reason to assume it resolves to `C.g`.
    assertNoEdge(decoratedTypeAnnotation('int get g').node,
        decoratedTypeAnnotation('int f').node);
    // We do, however, assume that it might return anything, including `null`.
    assertEdge(always, decoratedTypeAnnotation('int f').node, hard: false);
  }

  test_propertyAccess_object_property() async {
    await analyze('''
int f(int i) => i.hashCode;
''');
    // No edge from i to `never` because it is safe to call `hashCode` on
    // `null`.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
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

  test_propertyAccess_static_on_generic_class() async {
    await analyze('''
class C<T> {
  static int x = 1;
}
int f() => C.x;
''');
    assertEdge(decoratedTypeAnnotation('int x').node,
        decoratedTypeAnnotation('int f').node,
        hard: false);
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

    assertNullCheck(checkExpression('c).x'),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  test_redirecting_constructor_factory() async {
    await analyze('''
class C {
  factory C(int/*1*/ i, {int/*2*/ j}) = D;
}
class D implements C {
  D(int/*3*/ i, {int/*4*/ j});
}
''');
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*3*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*4*/').node,
        hard: true);
  }

  test_redirecting_constructor_factory_from_generic_to_generic() async {
    await analyze('''
class C<T> {
  factory C(T/*1*/ t) = D<T/*2*/>;
}
class D<U> implements C<U> {
  D(U/*3*/ u);
}
''');
    var nullable_t1 = decoratedTypeAnnotation('T/*1*/').node;
    var nullable_t2 = decoratedTypeAnnotation('T/*2*/').node;
    var nullable_u3 = decoratedTypeAnnotation('U/*3*/').node;
    assertEdge(nullable_t1, substitutionNode(nullable_t2, nullable_u3),
        hard: true);
  }

  test_redirecting_constructor_factory_to_generic() async {
    await analyze('''
class C {
  factory C(int/*1*/ i) = D<int/*2*/>;
}
class D<T> implements C {
  D(T/*3*/ i);
}
''');
    var nullable_i1 = decoratedTypeAnnotation('int/*1*/').node;
    var nullable_i2 = decoratedTypeAnnotation('int/*2*/').node;
    var nullable_t3 = decoratedTypeAnnotation('T/*3*/').node;
    assertEdge(nullable_i1, substitutionNode(nullable_i2, nullable_t3),
        hard: true);
  }

  test_redirecting_constructor_ordinary() async {
    await analyze('''
class C {
  C(int/*1*/ i, int/*2*/ j) : this.named(j, i);
  C.named(int/*3*/ j, int/*4*/ i);
}
''');
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*4*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*3*/').node,
        hard: true);
  }

  test_redirecting_constructor_ordinary_to_unnamed() async {
    await analyze('''
class C {
  C.named(int/*1*/ i, int/*2*/ j) : this(j, i);
  C(int/*3*/ j, int/*4*/ i);
}
''');
    assertEdge(decoratedTypeAnnotation('int/*1*/').node,
        decoratedTypeAnnotation('int/*4*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*3*/').node,
        hard: true);
  }

  test_return_from_async_future() async {
    await analyze('''
Future<int> f() async {
  return g();
}
int g() => 1;
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_return_from_async_futureOr() async {
    await analyze('''
import 'dart:async';
FutureOr<int> f() async {
  return g();
}
int g() => 1;
''');
    // No assertions; just checking that it doesn't crash.
  }

  test_return_function_type_simple() async {
    await analyze('''
int/*1*/ Function() f(int/*2*/ Function() x) => x;
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int2.node, int1.node, hard: false);
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

  test_setOrMapLiteral_map_noTypeArgument_noNullableKeysAndValues() async {
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, 'b' : 2};
}
''');
    var keyNode = decoratedTypeAnnotation('String').node;
    var valueNode = decoratedTypeAnnotation('int').node;
    var mapNode = decoratedTypeAnnotation('Map').node;

    assertNoUpstreamNullability(mapNode);
    assertNoUpstreamNullability(
        assertEdge(anyNode, keyNode, hard: false).sourceNode);
    assertNoUpstreamNullability(
        assertEdge(anyNode, valueNode, hard: false).sourceNode);
  }

  test_setOrMapLiteral_map_noTypeArgument_nullableKey() async {
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, null : 2, 'c' : 3};
}
''');
    var keyNode = decoratedTypeAnnotation('String').node;
    var valueNode = decoratedTypeAnnotation('int').node;
    var mapNode = decoratedTypeAnnotation('Map').node;

    assertNoUpstreamNullability(mapNode);
    assertEdge(always, assertEdge(anyNode, keyNode, hard: false).sourceNode,
        hard: false);
    assertNoUpstreamNullability(
        assertEdge(anyNode, valueNode, hard: false).sourceNode);
  }

  test_setOrMapLiteral_map_noTypeArgument_nullableKeyAndValue() async {
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, null : null, 'c' : 3};
}
''');
    var keyNode = decoratedTypeAnnotation('String').node;
    var valueNode = decoratedTypeAnnotation('int').node;
    var mapNode = decoratedTypeAnnotation('Map').node;

    assertNoUpstreamNullability(mapNode);
    assertEdge(always, assertEdge(anyNode, keyNode, hard: false).sourceNode,
        hard: false);
    assertEdge(always, assertEdge(anyNode, valueNode, hard: false).sourceNode,
        hard: false);
  }

  test_setOrMapLiteral_map_noTypeArgument_nullableValue() async {
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, 'b' : null, 'c' : 3};
}
''');
    var keyNode = decoratedTypeAnnotation('String').node;
    var valueNode = decoratedTypeAnnotation('int').node;
    var mapNode = decoratedTypeAnnotation('Map').node;

    assertNoUpstreamNullability(mapNode);
    assertNoUpstreamNullability(
        assertEdge(anyNode, keyNode, hard: false).sourceNode);
    assertEdge(always, assertEdge(anyNode, valueNode, hard: false).sourceNode,
        hard: false);
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

  test_setOrMapLiteral_set_noTypeArgument_noNullableElements() async {
    await analyze('''
Set<String> f() {
  return {'a', 'b'};
}
''');
    var valueNode = decoratedTypeAnnotation('String').node;
    var setNode = decoratedTypeAnnotation('Set').node;

    assertNoUpstreamNullability(setNode);
    assertNoUpstreamNullability(
        assertEdge(anyNode, valueNode, hard: false).sourceNode);
  }

  test_setOrMapLiteral_set_noTypeArgument_nullableElement() async {
    await analyze('''
Set<String> f() {
  return {'a', null, 'c'};
}
''');
    var valueNode = decoratedTypeAnnotation('String').node;
    var setNode = decoratedTypeAnnotation('Set').node;

    assertNoUpstreamNullability(setNode);
    assertEdge(always, assertEdge(anyNode, valueNode, hard: false).sourceNode,
        hard: false);
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

  test_simpleIdentifier_function() async {
    await analyze('''
int f() => null;
main() {
  int Function() g = f;
}
''');

    assertEdge(decoratedTypeAnnotation('int f').node,
        decoratedTypeAnnotation('int Function').node,
        hard: false);
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

  test_simpleIdentifier_tearoff_function() async {
    await analyze('''
int f(int i) => 0;
int Function(int) g() => f;
''');
    var fType = variables.decoratedElementType(findElement.function('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.function('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node, hard: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false);
  }

  test_simpleIdentifier_tearoff_method() async {
    await analyze('''
abstract class C {
  int f(int i);
  int Function(int) g() => f;
}
''');
    var fType = variables.decoratedElementType(findElement.method('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.method('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node, hard: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false);
  }

  test_skipDirectives() async {
    await analyze('''
import "dart:core" as one;
main() {}
''');
    // No test expectations.
    // Just verifying that the test passes
  }

  test_soft_edge_for_non_variable_reference() async {
    // Edges originating in things other than variable references should be
    // soft.
    await analyze('''
int f() => null;
''');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_spread_element_list() async {
    await analyze('''
void f(List<int> ints) {
  <int>[...ints];
}
''');

    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_spread_element_list_dynamic() async {
    await analyze('''
void f(dynamic ints) {
  <int>[...ints];
}
''');

    // Mostly just check this doesn't crash.
    assertEdge(decoratedTypeAnnotation('dynamic').node, never, hard: true);
  }

  test_spread_element_list_nullable() async {
    await analyze('''
void f(List<int> ints) {
  <int>[...?ints];
}
''');

    assertNoEdge(decoratedTypeAnnotation('List<int>').node, never);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_spread_element_map() async {
    await analyze('''
void f(Map<String, int> map) {
  <String, int>{...map};
}
''');

    assertEdge(decoratedTypeAnnotation('Map<String, int>').node, never,
        hard: true);
    assertEdge(decoratedTypeAnnotation('String, int> map').node,
        decoratedTypeAnnotation('String, int>{').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('int> map').node,
        decoratedTypeAnnotation('int>{').node,
        hard: false);
  }

  test_spread_element_set() async {
    await analyze('''
void f(Set<int> ints) {
  <int>{...ints};
}
''');

    assertEdge(decoratedTypeAnnotation('Set<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>{').node,
        hard: false);
  }

  test_spread_element_subtype() async {
    await analyze('''
abstract class C<T, R> implements Iterable<R> {}
void f(C<dynamic, int> ints) {
  <int>[...ints];
}
''');

    assertEdge(decoratedTypeAnnotation('C<dynamic, int>').node, never,
        hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node,
            decoratedTypeAnnotation('R> {}').node),
        decoratedTypeAnnotation('int>[').node,
        hard: false);
  }

  test_static_method_call_prefixed() async {
    await analyze('''
import 'dart:async' as a;
void f(void Function() callback) {
  a.Timer.run(callback);
}
''');
    // No assertions.  Just making sure this doesn't crash.
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
class B {
  void f(int/*1*/ i, int/*2*/ j) {}
}
class C extends B {
  void f(int/*3*/ i, int/*4*/ j) => super.f(j, i);
}
''');
    assertEdge(decoratedTypeAnnotation('int/*3*/').node,
        decoratedTypeAnnotation('int/*2*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int/*4*/').node,
        decoratedTypeAnnotation('int/*1*/').node,
        hard: true);
  }

  test_superExpression_generic() async {
    await analyze('''
class B<U> {
  U g() => null;
}
class C<T> extends B<T> {
  T f() => super.g();
}
''');
    assertEdge(
        substitutionNode(
            substitutionNode(never, decoratedTypeAnnotation('T> {').node),
            decoratedTypeAnnotation('U g').node),
        decoratedTypeAnnotation('T f').node,
        hard: false);
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

  test_thisExpression_generic() async {
    await analyze('''
class C<T> {
  C<T> f() => this;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('C<T> f').node);
    assertNoUpstreamNullability(decoratedTypeAnnotation('T> f').node);
  }

  test_throwExpression() async {
    await analyze('''
int f() {
  return throw null;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  test_topLevelSetter() async {
    await analyze('''
void set x(int value) {}
main() { x = 1; }
''');
    var setXType = decoratedTypeAnnotation('int value');
    assertEdge(never, setXType.node, hard: false);
  }

  test_topLevelSetter_nullable() async {
    await analyze('''
void set x(int value) {}
main() { x = null; }
''');
    var setXType = decoratedTypeAnnotation('int value');
    assertEdge(always, setXType.node, hard: false);
  }

  test_topLevelVar_metadata() async {
    await analyze('''
class A {
  const A();
}
@A()
int v;
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  test_topLevelVar_reference() async {
    await analyze('''
double pi = 3.1415;
double get myPi => pi;
''');
    var piType = decoratedTypeAnnotation('double pi');
    var myPiType = decoratedTypeAnnotation('double get');
    assertEdge(piType.node, myPiType.node, hard: false);
  }

  test_topLevelVar_reference_differentPackage() async {
    addPackageFile('pkgPi', 'piConst.dart', '''
double pi = 3.1415;
''');
    await analyze('''
import "package:pkgPi/piConst.dart";
double get myPi => pi;
''');
    var myPiType = decoratedTypeAnnotation('double get');
    assertEdge(never, myPiType.node, hard: false);
  }

  test_topLevelVariable_type_inferred() async {
    await analyze('''
int f() => 1;
var x = f();
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertUnion(xType.node, decoratedTypeAnnotation('int').node);
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

  test_type_parameterized_migrated_bound_class() async {
    await analyze('''
import 'dart:math';
void f(Point<int> x) {}
''');
    var pointClass =
        findNode.typeName('Point').name.staticElement as ClassElement;
    var pointBound =
        variables.decoratedTypeParameterBound(pointClass.typeParameters[0]);
    expect(pointBound.type.toString(), 'num');
    assertEdge(decoratedTypeAnnotation('int>').node, pointBound.node,
        hard: true);
  }

  test_type_parameterized_migrated_bound_dynamic() async {
    await analyze('''
void f(List<int> x) {}
''');
    var listClass = typeProvider.listElement;
    var listBound =
        variables.decoratedTypeParameterBound(listClass.typeParameters[0]);
    expect(listBound.type.toString(), 'dynamic');
    assertEdge(decoratedTypeAnnotation('int>').node, listBound.node,
        hard: true);
  }

  test_typeName_class() async {
    await analyze('''
class C {}
Type f() => C;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  test_typeName_from_sdk() async {
    await analyze('''
Type f() {
  return int;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  test_typeName_from_sdk_prefixed() async {
    await analyze('''
import 'dart:async' as a;
Type f() => a.Future;
''');
    assertEdge(never, decoratedTypeAnnotation('Type').node, hard: false);
  }

  test_typeName_functionTypeAlias() async {
    await analyze('''
typedef void F();
Type f() => F;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  test_typeName_genericTypeAlias() async {
    await analyze('''
typedef F = void Function();
Type f() => F;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  test_typeName_mixin() async {
    await analyze('''
mixin M {}
Type f() => M;
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

  test_typeName_union_with_bound_function_type() async {
    await analyze('''
class C<T extends int Function()> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var cBound = decoratedGenericFunctionTypeAnnotation('int Function()');
    assertUnion(cType.typeArguments[0].node, cBound.node);
    assertUnion(cType.typeArguments[0].returnType.node, cBound.returnType.node);
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

class _DecoratedClassHierarchyForTesting implements DecoratedClassHierarchy {
  AssignmentCheckerTest assignmentCheckerTest;

  @override
  DecoratedType asInstanceOf(DecoratedType type, ClassElement superclass) {
    var class_ = (type.type as InterfaceType).element;
    if (class_ == superclass) return type;
    if (superclass.name == 'Object') {
      return DecoratedType(
        superclass.instantiate(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        type.node,
      );
    }
    if (class_.name == 'MyListOfList' && superclass.name == 'List') {
      return assignmentCheckerTest._myListOfListSupertype
          .substitute({class_.typeParameters[0]: type.typeArguments[0]});
    }
    if (class_.name == 'Future' && superclass.name == 'FutureOr') {
      return DecoratedType(
        superclass.instantiate(
          typeArguments: [type.typeArguments[0].type],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        type.node,
        typeArguments: [type.typeArguments[0]],
      );
    }
    throw UnimplementedError(
        'TODO(paulberry): asInstanceOf($type, $superclass)');
  }

  @override
  DecoratedType getDecoratedSupertype(
      ClassElement class_, ClassElement superclass) {
    throw UnimplementedError('TODO(paulberry)');
  }
}

class _TestEdgeOrigin implements EdgeOrigin {
  const _TestEdgeOrigin();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
