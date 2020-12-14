// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:pub_semver/pub_semver.dart';
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
  static const EdgeOrigin origin = _TestEdgeOrigin();

  LibraryElementImpl _myLibrary;

  ClassElement _myListOfListClass;

  DecoratedType _myListOfListSupertype;

  @override
  final TypeProvider typeProvider;

  @override
  final NullabilityGraphForTesting graph;

  @override
  final decoratedTypeParameterBounds = DecoratedTypeParameterBounds();

  final AssignmentCheckerForTesting checker;

  factory AssignmentCheckerTest() {
    var typeProvider = TestTypeProvider().asLegacy;
    _setCoreLibrariesTypeSystem(typeProvider);

    var graph = NullabilityGraphForTesting();
    var decoratedClassHierarchy = _DecoratedClassHierarchyForTesting();
    var checker = AssignmentCheckerForTesting(
        TypeSystemImpl(
          implicitCasts: true,
          isNonNullableByDefault: false,
          strictInference: false,
          typeProvider: typeProvider,
        ),
        typeProvider,
        graph,
        decoratedClassHierarchy);
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
    _initMyLibrary();
    if (_myListOfListClass == null) {
      var t = typeParameter('T', object());
      _myListOfListSupertype = list(list(typeParameterType(t)));
      _myListOfListClass = ClassElementImpl('MyListOfList', 0)
        ..enclosingElement = _myLibrary.definingCompilationUnit
        ..typeParameters = [t]
        ..supertype = _myListOfListSupertype.type as InterfaceType;
    }
    return DecoratedType(
      InterfaceTypeImpl(
        element: _myListOfListClass,
        typeArguments: [elementType.type],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      newNode(),
      typeArguments: [elementType],
    );
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
    assertEdge(t1.node, bound.node, hard: false);
    // TODO(40622): Should this be a checkable edge?
    assertEdge(t1.typeArguments[0].node, bound.typeArguments[0].node,
        hard: false, checkable: false);
  }

  void test_dynamic_to_dynamic() {
    assign(dynamic_, dynamic_);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_dynamic_to_void() {
    assign(dynamic_, void_);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_function_type_named_parameter() {
    var t1 = function(dynamic_, named: {'x': object()});
    var t2 = function(dynamic_, named: {'x': object()});
    assign(t1, t2, hard: true);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.namedParameters['x'].node, t1.namedParameters['x'].node,
        hard: false, checkable: false);
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
        hard: false, checkable: false);
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
        hard: false, checkable: false);
  }

  void test_function_type_required_parameter() {
    var t1 = function(dynamic_, required: [object()]);
    var t2 = function(dynamic_, required: [object()]);
    assign(t1, t2);
    // Note: t1 and t2 are swapped due to contravariance.
    assertEdge(t2.positionalParameters[0].node, t1.positionalParameters[0].node,
        hard: false, checkable: false);
  }

  void test_function_type_return_type() {
    var t1 = function(object());
    var t2 = function(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.returnType.node, t2.returnType.node,
        hard: false, checkable: false);
  }

  void test_function_void_to_function_object() {
    // This is not an ideal pattern, but void is assignable to Object in certain
    // cases such as those with compound types here. We must support it.
    var t1 = function(void_);
    var t2 = function(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.returnType.node, t2.returnType.node,
        hard: false, checkable: false);
  }

  void test_future_int_to_future_or_int() {
    var t1 = future(int_());
    var t2 = futureOr(int_());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node,
        hard: false, checkable: false);
  }

  void test_future_or_int_to_future_int() {
    var t1 = futureOr(int_());
    var t2 = future(int_());
    assign(t1, t2, hard: true);
    // FutureOr<int>? is nullable, so Future<int>? should be.
    assertEdge(t1.node, t2.node, hard: true);
    // FutureOr<int?> is nullable, so Future<int>? should be.
    assertEdge(t1.typeArguments[0].node, t2.node, hard: true);
    // FutureOr<int?> may hold a Future<int?>, so carry that forward.
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node, hard: false);
    // FutureOr<int>? does not accept a Future<int?>, so don't draw this.
    assertNoEdge(t1.node, t2.typeArguments[0].node);
  }

  void test_future_or_int_to_int() {
    var t1 = futureOr(int_());
    var t2 = int_();
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.node, hard: false);
  }

  void test_future_or_list_object_to_list_int() {
    var t1 = futureOr(list(object()));
    var t2 = list(int_());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.node, hard: false);
    assertEdge(
        t1.typeArguments[0].typeArguments[0].node, t2.typeArguments[0].node,
        hard: false);
  }

  void test_future_or_object_to_future_or_int() {
    var t1 = futureOr(object());
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

  void test_generic_to_dynamic() {
    var t = list(object());
    assign(t, dynamic_);
    assertEdge(t.node, always, hard: false);
    assertNoEdge(t.typeArguments[0].node, anyNode);
  }

  void test_generic_to_generic_downcast() {
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

  void test_generic_to_generic_downcast_of_type_parameter() {
    var t = typeParameterType(typeParameter('T', object()));
    var t1 = iterable(t);
    var t2 = list(t);
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    var a = t1.typeArguments[0].node;
    var b = t2.typeArguments[0].node;
    assertEdge(a, b, hard: false);
  }

  void test_generic_to_generic_downcast_same_element() {
    var t1 = list(object());
    var t2 = list(int_());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node, hard: false);
  }

  void test_generic_to_generic_same_element() {
    var t1 = list(object());
    var t2 = list(object());
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
    assertEdge(t1.typeArguments[0].node, t2.typeArguments[0].node,
        hard: false, checkable: false);
  }

  void test_generic_to_generic_upcast() {
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
    assertEdge(substitutionNode(a, c), b, hard: false, checkable: false);
  }

  void test_generic_to_object() {
    var t1 = list(object());
    var t2 = object();
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
    assertNoEdge(t1.typeArguments[0].node, anyNode);
  }

  void test_generic_to_void() {
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

  void test_iterable_object_to_list_void() {
    assign(iterable(object()), list(void_));
    // Note: no assertions to do; just need to make sure there wasn't a crash.
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

  void test_object_to_void() {
    assign(object(), void_);
    // Note: no assertions to do; just need to make sure there wasn't a crash.
  }

  void test_simple_to_dynamic() {
    var t = object();
    assign(t, dynamic_);
    assertEdge(t.node, always, hard: false);
  }

  void test_simple_to_simple() {
    var t1 = object();
    var t2 = object();
    assign(t1, t2);
    assertEdge(t1.node, t2.node, hard: false);
  }

  void test_simple_to_simple_hard() {
    var t1 = object();
    var t2 = object();
    assign(t1, t2, hard: true);
    assertEdge(t1.node, t2.node, hard: true);
  }

  void test_simple_to_void() {
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
    // TODO(40622): Should this be a checkable edge?
    assertEdge(bound.typeArguments[0].node, t2.typeArguments[0].node,
        hard: false, checkable: false);
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

  void _initMyLibrary() {
    if (_myLibrary != null) {
      return;
    }

    var coreLibrary = typeProvider.boolElement.library as LibraryElementImpl;
    var analysisContext = coreLibrary.context;
    var analysisSession = coreLibrary.session;
    var typeSystem = coreLibrary.typeSystem;

    var uriStr = 'package:test/test.dart';

    _myLibrary = LibraryElementImpl(
      analysisContext,
      analysisSession,
      uriStr,
      -1,
      0,
      FeatureSet.fromEnableFlags2(
        sdkLanguageVersion: Version.parse('2.10.0'),
        flags: [EnableString.non_nullable],
      ),
    );
    _myLibrary.typeSystem = typeSystem;
    _myLibrary.typeProvider = coreLibrary.typeProvider;

    var uri = Uri.parse(uriStr);
    var source = _MockSource(uri);

    var definingUnit = CompilationUnitElementImpl();
    definingUnit.source = source;
    definingUnit.librarySource = source;

    definingUnit.enclosingElement = _myLibrary;
    _myLibrary.definingCompilationUnit = definingUnit;
  }

  static void _setCoreLibrariesTypeSystem(TypeProviderImpl typeProvider) {
    var typeSystem = TypeSystemImpl(
      isNonNullableByDefault: false,
      implicitCasts: true,
      strictInference: false,
      typeProvider: typeProvider,
    );
    _setLibraryTypeSystem(
      typeProvider.objectElement.library,
      typeProvider,
      typeSystem,
    );
    _setLibraryTypeSystem(
      typeProvider.futureElement.library,
      typeProvider,
      typeSystem,
    );
  }

  static void _setLibraryTypeSystem(
    LibraryElement libraryElement,
    TypeProvider typeProvider,
    TypeSystem typeSystem,
  ) {
    var libraryElementImpl = libraryElement as LibraryElementImpl;
    libraryElementImpl.typeProvider = typeProvider as TypeProviderImpl;
    libraryElementImpl.typeSystem = typeSystem as TypeSystemImpl;
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

  void assertLUB(NullabilityNode node, Object left, Object right) {
    var conditionalNode = node as NullabilityNodeForLUB;
    var leftMatcher = NodeMatcher(left);
    var rightMatcher = NodeMatcher(right);
    expect(leftMatcher.matches(conditionalNode.left), true);
    expect(rightMatcher.matches(conditionalNode.right), true);
  }

  /// Checks that there are no nullability nodes upstream from [node] that could
  /// cause it to become nullable.
  void assertNoUpstreamNullability(NullabilityNode node) {
    // Store `neverClosure` in a local variable so that we avoid the
    // computational expense of recomputing it each time through the loop below.
    var neverClosure = this.neverClosure;

    // Any node with a hard edge to never (or never itself) won't become
    // nullable, even if it has nodes upstream from it.
    if (neverClosure.contains(node)) return;

    // Otherwise, make sure that every node directly upstream from this node
    // has a hard edge to never.
    for (var edge in getEdges(anyNode, node)) {
      expect(neverClosure, contains(edge.sourceNode));
    }
  }

  /// Verifies that a null check will occur when the given edge is unsatisfied.
  ///
  /// [expressionChecks] is the object tracking whether or not a null check is
  /// needed.
  void assertNullCheck(
      ExpressionChecksOrigin expressionChecks, NullabilityEdge expectedEdge) {
    expect(expressionChecks.checks.edges.values, contains(expectedEdge));
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

  bool hasNullCheckHint(Expression expression) =>
      variables.getNullCheckHint(testSource, expression) != null;

  Future<void> test_already_migrated_field() async {
    await analyze('''
double f() => double.NAN;
''');
    var nanElement = typeProvider.doubleType.element.getField('NAN');
    assertEdge(variables.decoratedElementType(nanElement).node,
        decoratedTypeAnnotation('double f').node,
        hard: false);
  }

  Future<void> test_ArgumentError_checkNotNull_not_postDominating() async {
    await analyze('''
void f(bool b, int i, int j) {
  ArgumentError.checkNotNull(j);
  if (b) return;
  ArgumentError.checkNotNull(i);
}
''');

    // Asserts after ifs don't demonstrate non-null intent.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
    // But asserts before ifs do
    assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true);
  }

  Future<void> test_ArgumentError_checkNotNull_postDominating() async {
    await analyze('''
void f(int i) {
  ArgumentError.checkNotNull(i);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_ArgumentError_checkNotNull_prefixed() async {
    await analyze('''
import 'dart:core' as core;
void f(core.int i) {
  core.ArgumentError.checkNotNull(i);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_as_dynamic() async {
    await analyze('''
void f(Object o) {
  (o as dynamic).gcd(1);
}
''');
    assertEdge(decoratedTypeAnnotation('Object o').node,
        decoratedTypeAnnotation('dynamic').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('dynamic').node, never, hard: true);
  }

  Future<void> test_as_int() async {
    await analyze('''
void f(Object o) {
  (o as int).gcd(1);
}
''');
    assertEdge(decoratedTypeAnnotation('Object o').node,
        decoratedTypeAnnotation('int').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int').node, never, hard: true);
    expect(
        variables.wasUnnecessaryCast(testSource, findNode.as_('o as')), false);
  }

  Future<void> test_as_int_null_ok() async {
    await analyze('''
void f(Object o) {
  (o as int)?.gcd(1);
}
''');
    assertEdge(decoratedTypeAnnotation('Object o').node,
        decoratedTypeAnnotation('int').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int').node, never);
  }

  Future<void> test_as_int_unnecessary() async {
    verifyNoTestUnitErrors = false;
    await analyze('''
void f(int i) {
  (i as int).gcd(1);
}
''');
    expect(
        testAnalysisResult.errors.single.errorCode, HintCode.UNNECESSARY_CAST);
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int)').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int)').node, never, hard: true);
    expect(
        variables.wasUnnecessaryCast(testSource, findNode.as_('i as')), true);
  }

  Future<void> test_as_side_cast() async {
    await analyze('''
class A {}
class B {}
class C implements A, B {}
B f(A a) {
  // possible via f(C());
  return a as B;
}
''');
    assertEdge(
        decoratedTypeAnnotation('A a').node, decoratedTypeAnnotation('B;').node,
        hard: true);
  }

  Future<void> test_as_side_cast_generics() async {
    await analyze('''
class A<T> {}
class B<T> {}
class C implements A<int>, B<bool> {}
B<bool> f(A<int> a) {
  // possible via f(C());
  return a as B<bool>;
}
''');
    assertEdge(decoratedTypeAnnotation('A<int> a').node,
        decoratedTypeAnnotation('B<bool>;').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('bool>;').node,
        decoratedTypeAnnotation('bool> f').node,
        hard: false, checkable: false);
    assertNoEdge(anyNode, decoratedTypeAnnotation('bool>;').node);
    assertNoEdge(anyNode, decoratedTypeAnnotation('int> a').node);
    // int> a should be connected to the bound of T in A<T>, but nothing else.
    expect(
        decoratedTypeAnnotation('int> a').node.downstreamEdges, hasLength(1));
  }

  Future<void> test_assert_demonstrates_non_null_intent() async {
    await analyze('''
void f(int i) {
  assert(i != null);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_assert_initializer_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  C(int i)
    : assert(i != null);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_assert_is_demonstrates_non_null_intent() async {
    // Note, this could also be handled via improved flow analysis rather than a
    // hard edge.
    await analyze('''
void f(dynamic i) {
  assert(i is int);
}
''');

    assertEdge(decoratedTypeAnnotation('dynamic i').node, never, hard: true);
  }

  Future<void> test_assign_bound_to_type_parameter() async {
    await analyze('''
class C<T extends List<int>> {
  T f(List<int> x) => x;
}
''');
    var boundType = decoratedTypeAnnotation('List<int>>');
    var parameterType = decoratedTypeAnnotation('List<int> x');
    var tType = decoratedTypeAnnotation('T f');
    assertEdge(parameterType.node, tType.node, hard: true);
    assertEdge(parameterType.node, boundType.node, hard: false);
    // TODO(mfairhurst): Confirm we want this edge.
    // TODO(40622): Should this be a checkable edge?
    assertEdge(
        parameterType.typeArguments[0].node, boundType.typeArguments[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_assign_dynamic_to_other_type() async {
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

  Future<void> test_assign_function_type_to_function_interface_type() async {
    await analyze('''
Function f(void Function() x) => x;
''');
    assertEdge(decoratedGenericFunctionTypeAnnotation('void Function()').node,
        decoratedTypeAnnotation('Function f').node,
        hard: true);
  }

  Future<void> test_assign_future_to_futureOr_complex() async {
    await analyze('''
import 'dart:async';
FutureOr<List<int>> f(Future<List<int>> x) => x;
''');
    // If `x` is `Future<List<int?>>`, then the only way to migrate is to make
    // the return type `FutureOr<List<int?>>`.
    assertEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('int>> f').node,
        hard: false, checkable: false);
    assertNoEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('List<int>> f').node);
    assertNoEdge(decoratedTypeAnnotation('int>> x').node,
        decoratedTypeAnnotation('FutureOr<List<int>> f').node);
  }

  Future<void> test_assign_future_to_futureOr_simple() async {
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

    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int> x').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int> f').node,
        hard: false,
        checkable: false);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('FutureOr<int>').node);
  }

  Future<void> test_assign_non_future_to_futureOr_complex() async {
    await analyze('''
import 'dart:async';
FutureOr<List<int>> f(List<int> x) => x;
''');
    // If `x` is `List<int?>`, then the only way to migrate is to make the
    // return type `FutureOr<List<int?>>`.
    assertEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('int>> f').node,
        hard: false, checkable: false);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('List<int>> f').node);
    assertNoEdge(decoratedTypeAnnotation('int> x').node,
        decoratedTypeAnnotation('FutureOr<List<int>> f').node);
  }

  Future<void> test_assign_non_future_to_futureOr_simple() async {
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

  Future<void> test_assign_null_to_generic_type() async {
    await analyze('''
main() {
  List<int> x = null;
}
''');
    // TODO(paulberry): edge should be hard.
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('List').node,
        hard: false);
  }

  Future<void> test_assign_to_bound_as() async {
    // TODO(mfairhurst): support downcast to type params with bounds
    await analyze('''
class C<T> {}
void f(Object o) {
  o as C<int>;
}
''');
    // For now, edge to `anyNode`, because the true bound is inferred.
    assertEdge(decoratedTypeAnnotation('int').node, anyNode, hard: true);
  }

  Future<void> test_assign_to_bound_class_alias() async {
    await analyze('''
class C<T extends Object/*1*/> {}
class D<T extends Object/*2*/> {}
mixin M<T extends Object/*3*/> {}
class F = C<int> with M<String> implements D<num>;
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object/*1*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('num').node,
        decoratedTypeAnnotation('Object/*2*/').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('String').node,
        decoratedTypeAnnotation('Object/*3*/').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_class_extends() async {
    await analyze('''
class A<T extends Object> {}
class C extends A<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_class_implements() async {
    await analyze('''
class A<T extends Object> {}
class C implements A<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_class_with() async {
    await analyze('''
class A<T extends Object> {}
class C extends Object with A<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_extension_extended_type() async {
    await analyze('''
class C<T extends Object> {}
extension E on C<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_field_formal_typed() async {
    await analyze('''
class C<T extends Object> {}
class D {
  dynamic i;
  D(C<int> this.i);
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_field_formal_typed_function() async {
    await analyze('''
class C<T extends Object> {}
class D {
  dynamic i;
  D(this.i(C<int> name));
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_for() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  for (C<int> c = null ;;) {}
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_for_element() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  [for (C<int> c = null ;;) c];
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_for_in() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  for (C<int> c in []) {}
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_for_in_element() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  [for (C<int> c in []) c];
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_function_invocation_type_argument() async {
    await analyze('''
void f<T extends Object>() {}
void main() {
  (f)<int>();
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_in_return_type() async {
    await analyze('''
class C<T extends Object> {}
C<int> f() => null;
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_in_type_argument() async {
    await analyze('''
class C<T extends Object> {}
C<C<int>> f() => null;
''');
    assertEdge(decoratedTypeAnnotation('C<int>').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_instance_creation() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  C<int>();
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_list_literal() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  <C<int>>[];
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_local_variable() async {
    await analyze('''
class C<T extends Object> {}
main() {
  C<int> c = null;
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_map_literal() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  <C<int>, C<String>>{};
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
    assertEdge(decoratedTypeAnnotation('String').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_method_bound() async {
    await analyze('''
class C<T extends Object> {}
class D {
  f<U extends C<int>>() {}
}
''');
  }

  Future<void> test_assign_to_bound_method_call_type_argument() async {
    await analyze('''
void f<T extends Object>() {}
void main() {
  f<int>();
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_mixin_implements() async {
    await analyze('''
class A<T extends Object> {}
mixin C implements A<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_mixin_on() async {
    await analyze('''
class A<T extends Object> {}
mixin C on A<int> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_mixin_type_parameter_bound() async {
    await analyze('''
class C<T extends Object> {}
mixin M<T extends C<int>> {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_redirecting_constructor_argument() async {
    await analyze('''
class A<T extends Object> {}
class C {
  factory C() = D<A<int>>;
}
class D<U> implements C {}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_set_literal() async {
    await analyze('''
class C<T extends Object> {}
void main() {
  <C<int>>{};
}
''');
    assertEdge(decoratedTypeAnnotation('int').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_assign_to_bound_within_bound() async {
    await analyze('''
class A<T extends Object> {}
class B<T extends A<int>> {}
  ''');
    var aBound = decoratedTypeAnnotation('Object').node;
    var aBoundInt = decoratedTypeAnnotation('int').node;
    assertEdge(aBoundInt, aBound, hard: true);
  }

  Future<void> test_assign_to_bound_within_bound_method() async {
    await analyze('''
class C<T extends Object> {}
void f<T extends C<int>>() {}
''');
    var cBound = decoratedTypeAnnotation('Object').node;
    var fcInt = decoratedTypeAnnotation('int').node;
    assertEdge(fcInt, cBound, hard: true);
  }

  Future<void> test_assign_type_parameter_to_bound() async {
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
    // TODO(40622): Should this be a checkable edge?
    assertEdge(
        boundType.typeArguments[0].node, returnType.typeArguments[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_assign_upcast_generic() async {
    await analyze('''
void f(Iterable<int> x) {}
void g(List<int> x) {
  f(x);
}
''');

    var iterableInt = decoratedTypeAnnotation('Iterable<int>');
    var listInt = decoratedTypeAnnotation('List<int>');
    assertEdge(listInt.node, iterableInt.node, hard: true);
    assertEdge(
        substitutionNode(listInt.typeArguments[0].node, inSet(pointsToNever)),
        iterableInt.typeArguments[0].node,
        hard: false,
        checkable: false);
  }

  Future<void> test_assignment_code_reference() async {
    await analyze('''
void f(int i) {
  int j = i;
}
''');
    var edge = assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int j').node,
        hard: true);
    var codeReference = edge.codeReference;
    expect(codeReference, isNotNull);
    expect(codeReference.path, contains('test.dart'));
    expect(codeReference.line, 2);
    expect(codeReference.column, 11);
  }

  Future<void> test_assignmentExpression_compound_dynamic() async {
    await analyze('''
void f(dynamic x, int y) {
  x += y;
}
''');
    // No assertions; just making sure this doesn't crash.
  }

  Future<void> test_assignmentExpression_compound_simple() async {
    var code = '''
abstract class C {
  C operator+(C x);
}
C f(C y, C z) => (y += z);
''';
    await analyze(code);
    var targetEdge = assertEdge(
        decoratedTypeAnnotation('C y').node, inSet(pointsToNever),
        hard: true);
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

  Future<void> test_assignmentExpression_compound_withSubstitution() async {
    // Failing due to a side-cast from incorrectly instantiating the operator.
    var code = '''
abstract class C<T> {
  C<T> operator+(C<T> x);
}
C<int> f(C<int> y, C<int> z) => (y += z);
''';
    await analyze(code);
    var targetEdge = assertEdge(
        decoratedTypeAnnotation('C<int> y').node, inSet(pointsToNever),
        hard: true);
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

  Future<void> test_assignmentExpression_field() async {
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

  Future<void> test_assignmentExpression_field_cascaded() async {
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

  Future<void> test_assignmentExpression_field_target_check() async {
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

  Future<void> test_assignmentExpression_field_target_check_cascaded() async {
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

  Future<void> test_assignmentExpression_indexExpression_index() async {
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

  Future<void> test_assignmentExpression_indexExpression_return_value() async {
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

  Future<void> test_assignmentExpression_indexExpression_target_check() async {
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

  Future<void> test_assignmentExpression_indexExpression_value() async {
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

  Future<void>
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
        hard: false, checkable: false, guards: [xNullable]);
    assertEdge(returnParamNullable, xParamNullable,
        hard: false, checkable: false);
  }

  Future<void> test_assignmentExpression_nullAware_complex_covariant() async {
    await analyze('''
List<int> f(List<int> x, List<int> y) => x ??= y;
''');
    var xNullable = decoratedTypeAnnotation('List<int> x').node;
    var yNullable = decoratedTypeAnnotation('List<int> y').node;
    var xElementNullable = decoratedTypeAnnotation('int> x').node;
    var yElementNullable = decoratedTypeAnnotation('int> y').node;
    var returnElementNullable = decoratedTypeAnnotation('int> f').node;
    assertEdge(yNullable, xNullable, hard: false, guards: [xNullable]);
    assertEdge(yElementNullable, xElementNullable,
        hard: false, checkable: false, guards: [xNullable]);
    assertEdge(xElementNullable, returnElementNullable,
        hard: false, checkable: false);
  }

  Future<void> test_assignmentExpression_nullAware_simple() async {
    await analyze('''
int f(int x, int y) => (x ??= y);
''');
    var yNullable = decoratedTypeAnnotation('int y').node;
    var xNullable = decoratedTypeAnnotation('int x').node;
    var returnNullable = decoratedTypeAnnotation('int f').node;
    var glbNode = decoratedExpressionType('(x ??= y)').node;
    assertEdge(yNullable, xNullable, hard: false, guards: [xNullable]);
    assertEdge(yNullable, glbNode, hard: false, guards: [xNullable]);
    assertEdge(glbNode, xNullable, hard: false);
    assertEdge(glbNode, yNullable, hard: false);
    assertEdge(glbNode, returnNullable, hard: false);
  }

  Future<void> test_assignmentExpression_operands() async {
    await analyze('''
void f(int i, int j) {
  i = j;
}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  Future<void> test_assignmentExpression_return_value() async {
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

  Future<void> test_assignmentExpression_setter() async {
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

  Future<void> test_assignmentExpression_setter_null_aware() async {
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

  Future<void> test_assignmentExpression_setter_target_check() async {
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
  Future<void> test_awaitExpression_future_nonNullable() async {
    await analyze('''
Future<void> f() async {
  int x = await g();
}
Future<int> g() async => 3;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  @failingTest
  Future<void> test_awaitExpression_future_nullable() async {
    await analyze('''
Future<void> f() async {
  int x = await g();
}
Future<int> g() async => null;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void> test_awaitExpression_nonFuture() async {
    await analyze('''
Future<void> f() async {
  int x = await 3;
}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void> test_binaryExpression_ampersand_result_not_null() async {
    await analyze('''
int f(int i, int j) => i & j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_ampersandAmpersand() async {
    await analyze('''
bool f(bool i, bool j) => i && j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool i').node);
  }

  Future<void> test_binaryExpression_bar_result_not_null() async {
    await analyze('''
int f(int i, int j) => i | j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_barBar() async {
    await analyze('''
bool f(bool i, bool j) => i || j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool i').node);
  }

  Future<void> test_binaryExpression_caret_result_not_null() async {
    await analyze('''
int f(int i, int j) => i ^ j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_equal() async {
    await analyze('''
bool f(int i, int j) => i == j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_equal_null() async {
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

  Future<void> test_binaryExpression_equal_null_null() async {
    await analyze('''
void f(int i) {
  if (null == null) {
    g(i);
  }
}
void g(int j) {}
''');
    var iNode = decoratedTypeAnnotation('int i').node;
    var jNode = decoratedTypeAnnotation('int j').node;
    assertEdge(iNode, jNode,
        hard: false,
        guards: TypeMatcher<Iterable<NullabilityNode>>()
            .having((g) => g.single, 'single value', isIn(alwaysPlus)));
  }

  Future<void> test_binaryExpression_equal_null_yoda_condition() async {
    await analyze('''
void f(int i) {
  if (null == i) {
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

  Future<void> test_binaryExpression_gt_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i > j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_gtEq_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i >= j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_gtGt_result_not_null() async {
    await analyze('''
int f(int i, int j) => i >> j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_left_dynamic() async {
    await analyze('''
Object f(dynamic x, int y) => x + g(y);
int g(int z) => z;
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int z').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int g').node, anyNode);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('Object f').node,
        hard: false);
  }

  Future<void> test_binaryExpression_lt_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i < j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_ltEq_result_not_null() async {
    await analyze('''
bool f(int i, int j) => i <= j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_ltLt_result_not_null() async {
    await analyze('''
int f(int i, int j) => i << j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_minus_result_not_null() async {
    await analyze('''
int f(int i, int j) => i - j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_notEqual() async {
    await analyze('''
bool f(int i, int j) => i != j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('bool f').node);
  }

  Future<void> test_binaryExpression_notEqual_null() async {
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

  Future<void> test_binaryExpression_percent_result_not_null() async {
    await analyze('''
int f(int i, int j) => i % j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_plus_left_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true));
  }

  Future<void> test_binaryExpression_plus_left_check_custom() async {
    await analyze('''
class Int {
  Int operator+(Int other) => this;
}
Int f(Int i, Int j) => i + j;
''');

    assertNullCheck(checkExpression('i +'),
        assertEdge(decoratedTypeAnnotation('Int i').node, never, hard: true));
  }

  Future<void> test_binaryExpression_plus_result_custom() async {
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

  Future<void> test_binaryExpression_plus_result_not_null() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_plus_right_check() async {
    await analyze('''
int f(int i, int j) => i + j;
''');

    assertNullCheck(
        checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node, inSet(pointsToNever),
            hard: true));
  }

  Future<void> test_binaryExpression_plus_right_check_custom() async {
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

  Future<void> test_binaryExpression_plus_substituted() async {
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

  Future<void> test_binaryExpression_questionQuestion() async {
    await analyze('''
int f(int i, int j) => i ?? j;
''');

    var left = decoratedTypeAnnotation('int i').node;
    var right = decoratedTypeAnnotation('int j').node;
    var expression = decoratedExpressionType('??').node;
    assertEdge(right, expression, guards: [left], hard: false);
    expect(expression.displayName, '?? operator (test.dart:1:24)');
  }

  Future<void>
      test_binaryExpression_questionQuestion_genericReturnType() async {
    await analyze('''
class C<E> {
  C<E> operator +(C<E> c) => this;
}
C<int> f(C<int> i, C<int> j) => i ?? j;
''');
  }

  Future<void> test_binaryExpression_right_dynamic() async {
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

  Future<void> test_binaryExpression_slash_result_not_null() async {
    await analyze('''
double f(int i, int j) => i / j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('double f').node);
  }

  Future<void> test_binaryExpression_star_result_not_null() async {
    await analyze('''
int f(int i, int j) => i * j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_binaryExpression_tildeSlash_result_not_null() async {
    await analyze('''
int f(int i, int j) => i ~/ j;
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int f').node);
  }

  Future<void> test_boolLiteral() async {
    await analyze('''
bool f() {
  return true;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  Future<void> test_cascadeExpression() async {
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

  Future<void> test_cast_type_used_as_non_nullable() async {
    await analyze('''
void f(int/*!*/ i) {}
void g(num/*?*/ j) {
  f(j as int);
}
''');
    assertEdge(decoratedTypeAnnotation('int)').node,
        decoratedTypeAnnotation('int/*!*/').node,
        hard: true);
  }

  Future<void> test_catch_clause() async {
    await analyze('''
foo() => 1;
main() {
  try { foo(); } on Exception catch (e) { print(e); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void> test_catch_clause_no_type() async {
    await analyze('''
foo() => 1;
main() {
  try { foo(); } catch (e) { print(e); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void>
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
        hard: false, checkable: false);
    assertUnion(constructorParameterType.node,
        decoratedTypeAnnotation('MyList<int>/*1*/').node);
    assertUnion(constructorParameterType.typeArguments[0].node,
        decoratedTypeAnnotation('int>/*1*/').node);
  }

  Future<void>
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

  Future<void>
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

  Future<void>
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

  Future<void>
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

  Future<void> test_class_metadata() async {
    await analyze('''
@deprecated
class C {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_conditionalExpression_condition_check() async {
    await analyze('''
int f(bool b, int i, int j) {
  return (b ? i : j);
}
''');

    var nullable_b = decoratedTypeAnnotation('bool b').node;
    var check_b = checkExpression('b ?');
    assertNullCheck(check_b, assertEdge(nullable_b, never, hard: true));
  }

  Future<void> test_conditionalExpression_false_guard() async {
    await analyze('int f(int x, int y, int z) => x != null ? null : y = z;');
    var guard = decoratedTypeAnnotation('int x').node;
    assertEdge(decoratedTypeAnnotation('int z').node,
        decoratedTypeAnnotation('int y').node,
        hard: false, guards: [guard]);
    var conditionalDiscard =
        variables.conditionalDiscard(findNode.conditionalExpression('!='));
    expect(conditionalDiscard, isNotNull);
    expect(conditionalDiscard.trueGuard, isNull);
    expect(conditionalDiscard.falseGuard, same(guard));
  }

  Future<void> test_conditionalExpression_functionTyped_namedParameter() async {
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

  Future<void>
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

  Future<void>
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

  Future<void>
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

  Future<void> test_conditionalExpression_functionTyped_returnType() async {
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

  Future<void>
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
    expect(resultType.returnType.node.isImmutable, false);
  }

  Future<void> test_conditionalExpression_general() async {
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

  Future<void> test_conditionalExpression_generic() async {
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

  Future<void> test_conditionalExpression_generic_lub() async {
    await analyze('''
class A<T> {}
class B<T> extends A<T/*b*/> {}
class C<T> extends A<T/*c*/> {}
A<num> f(bool b, B<num> x, C<num> y) {
  return (b ? x : y);
}
''');
    var bType = decoratedTypeAnnotation('B<num> x');
    var cType = decoratedTypeAnnotation('C<num> y');
    var bInA = decoratedTypeAnnotation('T/*b*/');
    var cInA = decoratedTypeAnnotation('T/*c*/');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, bType.node, cType.node);
    assertLUB(
        resultType.typeArguments[0].node,
        substitutionNode(bType.typeArguments[0].node, bInA.node),
        substitutionNode(cType.typeArguments[0].node, cInA.node));
  }

  Future<void> test_conditionalExpression_generic_lub_leftSubtype() async {
    await analyze('''
class A<T> {}
class B<T> extends A<T/*b*/> {}
A<num> f(bool b, B<num> x, A<num> y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('A<num> y');
    var bType = decoratedTypeAnnotation('B<num> x');
    var bInA = decoratedTypeAnnotation('T/*b*/');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, bType.node, aType.node);
    assertLUB(
        resultType.typeArguments[0].node,
        substitutionNode(bType.typeArguments[0].node, bInA.node),
        aType.typeArguments[0].node);
  }

  Future<void> test_conditionalExpression_generic_lub_rightSubtype() async {
    await analyze('''
class A<T> {}
class B<T> extends A<T/*b*/> {}
A<num> f(bool b, A<num> x, B<num> y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('A<num> x');
    var bType = decoratedTypeAnnotation('B<num> y');
    var bInA = decoratedTypeAnnotation('T/*b*/');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, aType.node, bType.node);
    assertLUB(resultType.typeArguments[0].node, aType.typeArguments[0].node,
        substitutionNode(bType.typeArguments[0].node, bInA.node));
  }

  Future<void> test_conditionalExpression_generic_typeParameter_bound() async {
    await analyze('''
List<num> f<T extends List<num>>(bool b, List<num> x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('List<num> x');
    var bType = decoratedTypeAnnotation('T y');
    var bBound = decoratedTypeAnnotation('List<num>>');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(
        resultType.node, aType.node, substitutionNode(bBound.node, bType.node));
    assertLUB(resultType.typeArguments[0].node, aType.typeArguments[0].node,
        bBound.typeArguments[0].node);
  }

  Future<void> test_conditionalExpression_left_never() async {
    await analyze('''
List<int> f(bool b, List<int> i) {
  return (b ? (throw i) : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('List<int> i').node;
    var nullable_conditional =
        decoratedExpressionType('(b ?').node as NullabilityNodeForLUB;
    var nullable_throw = nullable_conditional.left;
    assertNoUpstreamNullability(nullable_throw);
    assertLUB(nullable_conditional, nullable_throw, nullable_i);
  }

  Future<void> test_conditionalExpression_left_non_null() async {
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

  Future<void> test_conditionalExpression_left_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? null : i);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, inSet(alwaysPlus), nullable_i);
  }

  Future<void> test_conditionalExpression_left_null_right_function() async {
    await analyze('''
bool Function<T>(int) g(bool b, bool Function<T>(int) f) {
  return (b ? null : f);
}
''');

    var nullable_i =
        decoratedGenericFunctionTypeAnnotation('bool Function<T>(int) f').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, inSet(alwaysPlus), nullable_i);
  }

  Future<void>
      test_conditionalExpression_left_null_right_parameterType() async {
    await analyze('''
T g<T>(bool b, T t) {
  return (b ? null : t);
}
''');

    var nullable_t = decoratedTypeAnnotation('T t').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, inSet(alwaysPlus), nullable_t);
  }

  Future<void> test_conditionalExpression_left_null_right_typeArgs() async {
    await analyze('''
List<int> f(bool b, List<int> l) {
  return (b ? null : l);
}
''');

    var nullable_i = decoratedTypeAnnotation('List<int> l').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, inSet(alwaysPlus), nullable_i);
  }

  Future<void> test_conditionalExpression_nullTyped_nullParameter() async {
    await analyze('''
void f(bool b, void Function(Null p) x, void Function(List<int> p) y) {
  (b ? x : y);
}
''');
    var xType =
        decoratedGenericFunctionTypeAnnotation('void Function(Null p) x');
    var yType =
        decoratedGenericFunctionTypeAnnotation('void Function(List<int> p) y');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, xType.node, yType.node);
    assertGLB(resultType.positionalParameters[0].node,
        xType.positionalParameters[0].node, yType.positionalParameters[0].node);
  }

  Future<void> test_conditionalExpression_parameterType() async {
    await analyze('''
T g<T>(bool b, T x, T y) {
  return (b ? x : y);
}
''');

    var nullable_x = decoratedTypeAnnotation('T x').node;
    var nullable_y = decoratedTypeAnnotation('T y').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_x, nullable_y);
  }

  Future<void> test_conditionalExpression_right_never() async {
    await analyze('''
List<int> f(bool b, List<int> i) {
  return (b ? i : (throw i));
}
''');

    var nullable_i = decoratedTypeAnnotation('List<int> i').node;
    var nullable_conditional =
        decoratedExpressionType('(b ?').node as NullabilityNodeForLUB;
    var nullable_throw = nullable_conditional.right;
    assertNoUpstreamNullability(nullable_throw);
    assertLUB(nullable_conditional, nullable_i, nullable_throw);
  }

  Future<void> test_conditionalExpression_right_non_null() async {
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

  Future<void> test_conditionalExpression_right_null() async {
    await analyze('''
int f(bool b, int i) {
  return (b ? i : null);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_i, inSet(alwaysPlus));
  }

  Future<void> test_conditionalExpression_right_null_left_function() async {
    await analyze('''
bool Function<T>(int) g(bool b, bool Function<T>(int) f) {
  return (b ? f : null);
}
''');

    var nullable_i =
        decoratedGenericFunctionTypeAnnotation('bool Function<T>(int) f').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_i, inSet(alwaysPlus));
  }

  Future<void> test_conditionalExpression_right_null_left_typeArgs() async {
    await analyze('''
List<int> f(bool b, List<int> l) {
  return (b ? l : null);
}
''');

    var nullable_i = decoratedTypeAnnotation('List<int> l').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_i, inSet(alwaysPlus));
  }

  Future<void>
      test_conditionalExpression_right_null_left_typeParameter() async {
    await analyze('''
T f<T>(bool b, T t) {
  return (b ? t : null);
}
''');

    var nullable_t = decoratedTypeAnnotation('T t').node;
    var nullable_conditional = decoratedExpressionType('(b ?').node;
    assertLUB(nullable_conditional, nullable_t, inSet(alwaysPlus));
  }

  Future<void> test_conditionalExpression_true_guard() async {
    await analyze('int f(int x, int y, int z) => x == null ? y = z : null;');
    var guard = decoratedTypeAnnotation('int x').node;
    assertEdge(decoratedTypeAnnotation('int z').node,
        decoratedTypeAnnotation('int y').node,
        hard: false, guards: [guard]);
    var conditionalDiscard =
        variables.conditionalDiscard(findNode.conditionalExpression('=='));
    expect(conditionalDiscard, isNotNull);
    expect(conditionalDiscard.trueGuard, same(guard));
    expect(conditionalDiscard.falseGuard, isNull);
  }

  Future<void> test_conditionalExpression_typeParameter_bound() async {
    await analyze('''
num f<T extends num>(bool b, num x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('num x');
    var bType = decoratedTypeAnnotation('T y');
    var bBound = decoratedTypeAnnotation('num>');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(
        resultType.node, aType.node, substitutionNode(bBound.node, bType.node));
  }

  Future<void> test_conditionalExpression_typeParameter_bound_bound() async {
    await analyze('''
num f<T extends R, R extends num>(bool b, num x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('num x');
    var bType = decoratedTypeAnnotation('T y');
    var bBound = decoratedTypeAnnotation('R,');
    var bBoundBound = decoratedTypeAnnotation('num>');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(
        resultType.node,
        aType.node,
        substitutionNode(
            bBoundBound.node, substitutionNode(bBound.node, bType.node)));
  }

  Future<void> test_conditionalExpression_typeParameter_dynamic() async {
    // "dynamic" can short circuit LUB, incorrectly we may lose nullabilities.
    await analyze('''
dynamic f<T extends num>(bool b, dynamic x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('dynamic x');
    var bType = decoratedTypeAnnotation('T y');
    var bBound = decoratedTypeAnnotation('num>');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(
        resultType.node, aType.node, substitutionNode(bBound.node, bType.node));
  }

  Future<void> test_conditionalExpression_typeParameters_bound() async {
    await analyze('''
num f<T extends num, R extends num>(bool b, R x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('R x');
    var bType = decoratedTypeAnnotation('T y');
    var aBound = decoratedTypeAnnotation('num>');
    var bBound = decoratedTypeAnnotation('num,');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(resultType.node, substitutionNode(aBound.node, aType.node),
        substitutionNode(bBound.node, bType.node));
  }

  Future<void>
      test_conditionalExpression_typeParameters_bound_left_to_right() async {
    await analyze('''
R f<T extends R, R>(bool b, R x, T y) {
  return (b ? x : y);
}
''');
    var aType = decoratedTypeAnnotation('R x');
    var bType = decoratedTypeAnnotation('T y');
    var bBound = decoratedTypeAnnotation('R,');
    var resultType = decoratedExpressionType('(b ?');
    assertLUB(
        resultType.node, aType.node, substitutionNode(bBound.node, bType.node));
  }

  Future<void> test_constructor_default_parameter_value_bool() async {
    await analyze('''
class C {
  C([bool b = true]);
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool b').node);
  }

  Future<void> test_constructor_named() async {
    await analyze('''
class C {
  C.named();
}
''');
    // No assertions; just need to make sure that the test doesn't cause an
    // exception to be thrown.
  }

  Future<void> test_constructor_superInitializer() async {
    await analyze('''
class C {
  C.named(int i);
}
class D extends C {
  D(int j) : super.named(j);
}
''');

    var namedConstructor = findElement.constructor('named', of: 'C');
    var constructorType = variables.decoratedElementType(namedConstructor);
    var constructorParameterType = constructorType.positionalParameters[0];
    assertEdge(
        decoratedTypeAnnotation('int j').node, constructorParameterType.node,
        hard: true);
  }

  Future<void> test_constructor_superInitializer_withTypeArgument() async {
    await analyze('''
class C<T> {
  C.named(T/*1*/ i);
}
class D extends C<int/*2*/> {
  D(int/*3*/ j) : super.named(j);
}
''');

    var nullable_t1 = decoratedTypeAnnotation('T/*1*/').node;
    var nullable_int2 = decoratedTypeAnnotation('int/*2*/').node;
    var nullable_int3 = decoratedTypeAnnotation('int/*3*/').node;
    assertEdge(nullable_int3, substitutionNode(nullable_int2, nullable_t1),
        hard: true);
  }

  Future<void> test_constructor_superInitializer_withTypeVariable() async {
    await analyze('''
class C<T> {
  C.named(T/*1*/ i);
}
class D<U> extends C<U/*2*/> {
  D(U/*3*/ j) : super.named(j);
}
''');

    var nullable_t1 = decoratedTypeAnnotation('T/*1*/').node;
    var nullable_u2 = decoratedTypeAnnotation('U/*2*/').node;
    var nullable_u3 = decoratedTypeAnnotation('U/*3*/').node;
    assertEdge(nullable_u3, substitutionNode(nullable_u2, nullable_t1),
        hard: true);
  }

  Future<void> test_constructorDeclaration_returnType_generic() async {
    await analyze('''
class C<T, U> {
  C();
}
''');
    var constructor = findElement.unnamedConstructor('C');
    var constructorDecoratedType = variables.decoratedElementType(constructor);
    _assertType(constructorDecoratedType.type, 'C<T, U> Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    _assertType(constructorDecoratedType.returnType.type, 'C<T, U>');
    var typeArguments = constructorDecoratedType.returnType.typeArguments;
    expect(typeArguments, hasLength(2));
    _assertType(typeArguments[0].type, 'T');
    expect(typeArguments[0].node, same(never));
    _assertType(typeArguments[1].type, 'U');
    expect(typeArguments[1].node, same(never));
  }

  Future<void> test_constructorDeclaration_returnType_generic_implicit() async {
    await analyze('''
class C<T, U> {}
''');
    var constructor = findElement.unnamedConstructor('C');
    var constructorDecoratedType = variables.decoratedElementType(constructor);
    _assertType(constructorDecoratedType.type, 'C<T, U> Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    _assertType(constructorDecoratedType.returnType.type, 'C<T, U>');
    var typeArguments = constructorDecoratedType.returnType.typeArguments;
    expect(typeArguments, hasLength(2));
    _assertType(typeArguments[0].type, 'T');
    expect(typeArguments[0].node, same(never));
    _assertType(typeArguments[1].type, 'U');
    expect(typeArguments[1].node, same(never));
  }

  Future<void> test_constructorDeclaration_returnType_simple() async {
    await analyze('''
class C {
  C();
}
''');
    var constructorDecoratedType =
        variables.decoratedElementType(findElement.unnamedConstructor('C'));
    _assertType(constructorDecoratedType.type, 'C Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.typeArguments, isEmpty);
  }

  Future<void> test_constructorDeclaration_returnType_simple_implicit() async {
    await analyze('''
class C {}
''');
    var constructorDecoratedType =
        variables.decoratedElementType(findElement.unnamedConstructor('C'));
    _assertType(constructorDecoratedType.type, 'C Function()');
    expect(constructorDecoratedType.node, same(never));
    expect(constructorDecoratedType.typeFormals, isEmpty);
    expect(constructorDecoratedType.returnType.node, same(never));
    expect(constructorDecoratedType.returnType.typeArguments, isEmpty);
  }

  Future<void> test_constructorFieldInitializer_generic() async {
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

  Future<void> test_constructorFieldInitializer_simple() async {
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

  Future<void> test_constructorFieldInitializer_via_this() async {
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

  Future<void> test_do_while_condition() async {
    await analyze('''
void f(bool b) {
  do {} while (b);
}
''');

    assertNullCheck(checkExpression('b);'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
  }

  Future<void> test_doubleLiteral() async {
    await analyze('''
double f() {
  return 1.0;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('double').node);
  }

  Future<void> test_dummyNode_fromEqualityComparison_left() async {
    await analyze('''
f() {
  int i;
  if (i == 7) {}
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertDummyEdge(nullable_i);
  }

  Future<void> test_dummyNode_fromEqualityComparison_right() async {
    await analyze('''
f() {
  int i;
  if (7 == i) {}
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertDummyEdge(nullable_i);
  }

  Future<void> test_dummyNode_fromExpressionStatement() async {
    await analyze('''
f() {
  int i;
  i;
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertDummyEdge(nullable_i);
  }

  Future<void> test_dummyNode_fromForLoopUpdaters() async {
    await analyze('''
f() {
  int i;
  int j;
  for (;; i, j) {}
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_j = decoratedTypeAnnotation('int j').node;
    assertDummyEdge(nullable_i);
    assertDummyEdge(nullable_j);
  }

  Future<void> test_dummyNode_fromForLoopVariables() async {
    await analyze('''
f() {
  int i;
  for (i;;) {}
}
''');
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertDummyEdge(nullable_i);
  }

  Future<void> test_edgeOrigin_call_from_function() async {
    await analyze('''
void f(int i) {}
void g(int j) {
  f(j);
}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true,
        codeReference:
            matchCodeRef(offset: findNode.simple('j);').offset, function: 'g'));
  }

  Future<void> test_edgeOrigin_call_from_method() async {
    await analyze('''
class C {
  void f(int i) {}
  void g(int j) {
    f(j);
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int j').node,
        decoratedTypeAnnotation('int i').node,
        hard: true,
        codeReference: matchCodeRef(
            offset: findNode.simple('j);').offset, function: 'C.g'));
  }

  Future<void> test_export_metadata() async {
    await analyze('''
@deprecated
export 'dart:async';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_extension_metadata() async {
    await analyze('''
@deprecated
extension E on String {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_extension_on_class_with_generic_type_arguments() async {
    await analyze('''
class C<T> {}
void f(C<List> x) {}
extension E on C<List> {
  g() => f(this);
}
''');
    // No assertions yet. This test crashes. When it stops crashing, consider
    // adding assertion(s).
  }

  Future<void> test_extension_on_function_type() async {
    await analyze('''
extension CurryFunction<R, S, T> on R Function(S, T) {
  /// Curry a binary function with its first argument.
  R Function(T) curry(S first) => (T second) => this(first, second);
}
''');
    // No assertions yet. This test crashes. When it stops crashing, consider
    // adding assertion(s).
  }

  Future<void> test_field_final_does_not_override_setter() async {
    await analyze('''
abstract class A {
  void set i(int value);
}
abstract class C implements A {
  final int i;
  C(this.i);
}
''');
    var baseNode = decoratedTypeAnnotation('int value').node;
    var derivedNode = decoratedTypeAnnotation('int i').node;
    assertNoEdge(derivedNode, baseNode);
    assertNoEdge(baseNode, derivedNode);
  }

  Future<void> test_field_initialized_in_constructor() async {
    await analyze('''
class C {
  int i;
  C() : i = 0;
}
''');
    // There is no edge from always to the type of i, because it is initialized
    // in the constructor.
    assertNoEdge(always, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_field_metadata() async {
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

  Future<void> test_field_overrides_field() async {
    await analyze('''
abstract class A {
  int i; // A
}
class C implements A {
  int i; // C
}
''');
    var baseNode = decoratedTypeAnnotation('int i; // A').node;
    var derivedNode = decoratedTypeAnnotation('int i; // C').node;
    assertEdge(baseNode, derivedNode, hard: true);
    assertEdge(derivedNode, baseNode, hard: true);
  }

  Future<void> test_field_overrides_field_final() async {
    await analyze('''
abstract class A {
  final int i; // A
  A(this.i);
}
class C implements A {
  int i; // C
}
''');
    var baseNode = decoratedTypeAnnotation('int i; // A').node;
    var derivedNode = decoratedTypeAnnotation('int i; // C').node;
    assertEdge(derivedNode, baseNode, hard: true);
    assertNoEdge(baseNode, derivedNode);
  }

  Future<void> test_field_overrides_getter() async {
    await analyze('''
abstract class A {
  int get i;
}
class C implements A {
  int i;
}
''');
    var baseNode = decoratedTypeAnnotation('int get i').node;
    var derivedNode = decoratedTypeAnnotation('int i').node;
    assertEdge(derivedNode, baseNode, hard: true);
    assertNoEdge(baseNode, derivedNode);
  }

  Future<void> test_field_overrides_setter() async {
    await analyze('''
abstract class A {
  void set i(int value);
}
class C implements A {
  int i;
}
''');
    var baseNode = decoratedTypeAnnotation('int value').node;
    var derivedNode = decoratedTypeAnnotation('int i').node;
    assertEdge(baseNode, derivedNode, hard: true);
    assertNoEdge(derivedNode, baseNode);
  }

  Future<void> test_field_static_implicitInitializer() async {
    await analyze('''
class C {
  static int i;
}
''');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  Future<void> test_field_type_inferred() async {
    await analyze('''
int f() => 1;
class C {
  var x = f();
}
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertEdge(decoratedTypeAnnotation('int').node, xType.node, hard: false);
  }

  Future<void> test_fieldFormalParameter_function_typed() async {
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
        hard: false, checkable: false);
    assertEdge(fieldType.positionalParameters[0].node,
        ctorParamType.positionalParameters[0].node,
        hard: false, checkable: false);
    assertEdge(fieldType.namedParameters['j'].node,
        ctorParamType.namedParameters['j'].node,
        hard: false, checkable: false);
  }

  Future<void> test_fieldFormalParameter_typed() async {
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

  Future<void> test_fieldFormalParameter_untyped() async {
    await analyze('''
class C {
  int i;
  C.named(this.i);
}
''');
    var decoratedConstructorParamType =
        decoratedConstructorDeclaration('named').positionalParameters[0];
    assertEdge(decoratedConstructorParamType.node,
        decoratedTypeAnnotation('int i').node,
        hard: true);
  }

  Future<void> test_firstWhere_edges() async {
    await analyze('''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''');

    // Normally there would be an edge from the return type of `() => null` to
    // a substitution node that pointed to the type argument to the type of `x`,
    // and another substitution node would point from this to the return type of
    // `firstEven`.  However, since we may replace `firstWhere` with
    // `firstWhereOrNull` in order to avoid having to make `x`'s type argument
    // nullable, we need a synthetic edge to ensure that the return type of
    // `firstEven` is nullable.
    var closureReturnType = decoratedExpressionType('() => null').returnType;
    var firstWhereReturnType = variables
        .decoratedExpressionType(findNode.methodInvocation('firstWhere'));
    assertEdge(closureReturnType.node, firstWhereReturnType.node, hard: false);

    // There should also be an edge from a substitution node to the return type
    // of `firstWhere`, to account for the normal data flow (when the element is
    // found).
    var typeParameterType = decoratedTypeAnnotation('int>');
    var firstWhereType = variables.decoratedElementType(findNode
        .methodInvocation('firstWhere')
        .methodName
        .staticElement
        .declaration);
    assertEdge(
        substitutionNode(
            typeParameterType.node, firstWhereType.returnType.node),
        firstWhereReturnType.node,
        hard: false);
  }

  Future<void> test_for_each_element_with_declaration() async {
    await analyze('''
void f(List<int> l) {
  [for (int i in l) 0];
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  Future<void> test_for_each_element_with_declaration_implicit_type() async {
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
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        iNode,
        hard: false);
  }

  Future<void> test_for_each_element_with_identifier() async {
    await analyze('''
void f(List<int> l) {
  int x;
  [for (x in l) 0];
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  Future<void> test_for_each_on_type_parameter_type() async {
    await analyze('''
void f<T extends List<int>>(T l) {
  for (int i in l) {}
}
''');
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(decoratedTypeAnnotation('T l').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int>').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  Future<void> test_for_each_on_type_parameter_type_bound_bound() async {
    await analyze('''
void f<T extends R, R extends List<int>>(T l) {
  for (int i in l) {}
}
''');
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(decoratedTypeAnnotation('T l').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int>').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  Future<void> test_for_each_with_declaration() async {
    await analyze('''
void f(List<int> l) {
  for (int i in l) {}
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  Future<void> test_for_each_with_declaration_implicit_type() async {
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
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        iNode,
        hard: false);
  }

  Future<void> test_for_each_with_identifier() async {
    await analyze('''
void f(List<int> l) {
  int x;
  for (x in l) {}
}
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(
            decoratedTypeAnnotation('int> l').node, inSet(pointsToNever)),
        decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  Future<void> test_for_element_list() async {
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

  Future<void> test_for_element_map() async {
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

  Future<void> test_for_element_set() async {
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

  Future<void> test_for_with_declaration() async {
    await analyze('''
main() {
  for (int i in <int>[1, 2, 3]) { print(i); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void> test_for_with_var() async {
    await analyze('''
main() {
  for (var i in <int>[1, 2, 3]) { print(i); }
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void> test_forStatement_empty() async {
    await analyze('''

void test() {
  for (; ; ) {
    return;
  }
}
''');
  }

  Future<void> test_function_assignment() async {
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

  Future<void> test_function_metadata() async {
    await analyze('''
@deprecated
void f() {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_functionDeclaration_expression_body() async {
    await analyze('''
int/*1*/ f(int/*2*/ i) => i/*3*/;
''');

    assertNullCheck(
        checkExpression('i/*3*/'),
        assertEdge(decoratedTypeAnnotation('int/*2*/').node,
            decoratedTypeAnnotation('int/*1*/').node,
            hard: true));
  }

  Future<void>
      test_functionDeclaration_parameter_named_default_listConst() async {
    await analyze('''
void f({List<int/*1*/> i = const <int/*2*/>[]}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('List<int/*1*/>').node);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*1*/').node,
        hard: false, checkable: false);
  }

  Future<void>
      test_functionDeclaration_parameter_named_default_notNull() async {
    await analyze('''
void f({int i = 1}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void> test_functionDeclaration_parameter_named_default_null() async {
    await analyze('''
void f({int i = null}) {}
''');

    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
        hard: false);
  }

  Future<void> test_functionDeclaration_parameter_named_no_default() async {
    await analyze('''
void f({int i}) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  Future<void>
      test_functionDeclaration_parameter_named_no_default_required() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
void f({@required int i}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void>
      test_functionDeclaration_parameter_named_no_default_required_hint() async {
    await analyze('''
void f({/*required*/ int i}) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void>
      test_functionDeclaration_parameter_positionalOptional_default_notNull() async {
    await analyze('''
void f([int i = 1]) {}
''');

    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void>
      test_functionDeclaration_parameter_positionalOptional_default_null() async {
    await analyze('''
void f([int i = null]) {}
''');

    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
        hard: false);
  }

  Future<void>
      test_functionDeclaration_parameter_positionalOptional_no_default() async {
    await analyze('''
void f([int i]) {}
''');

    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  Future<void> test_functionExpressionInvocation_bangHint() async {
    await analyze('''
int f1(int Function() g1) => g1();
int f2(int Function() g2) => g2()/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int Function() g1').node,
        decoratedTypeAnnotation('int f1').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int Function() g2').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.functionExpressionInvocation('g2()')),
        isTrue);
  }

  Future<void> test_functionExpressionInvocation_parameterType() async {
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

  Future<void> test_functionExpressionInvocation_returnType() async {
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

  Future<void> test_functionInvocation_parameter_fromLocalParameter() async {
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

  Future<void> test_functionInvocation_parameter_functionTyped() async {
    await analyze('''
void f(void g()) {}
void test() {
  f(null);
}
''');

    var parameter = variables.decoratedElementType(
        findNode.functionTypedFormalParameter('void g()').declaredElement);
    assertNullCheck(checkExpression('null'),
        assertEdge(inSet(alwaysPlus), parameter.node, hard: false));
  }

  Future<void>
      test_functionInvocation_parameter_functionTyped_named_missing() async {
    await analyze('''
void f({void g()}) {}
void h() {
  f();
}
''');
    var parameter = variables.decoratedElementType(
        findNode.functionTypedFormalParameter('void g()').declaredElement);
    expect(getEdges(always, parameter.node), isNotEmpty);
  }

  Future<void> test_functionInvocation_parameter_named() async {
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

  Future<void> test_functionInvocation_parameter_named_missing() async {
    await analyze('''
void f({int i}) {}
void g() {
  f();
}
''');
    var optional_i = decoratedTypeAnnotation('int i').node;
    expect(getEdges(always, optional_i), isNotEmpty);
  }

  Future<void>
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
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertNoUpstreamNullability(nullable_i);
  }

  Future<void>
      test_functionInvocation_parameter_named_missing_required_hint() async {
    verifyNoTestUnitErrors = false;
    await analyze('''
void f({/*required*/ int i}) {}
void g() {
  f();
}
''');
    // The call at `f()` is presumed to be in error; no constraint is recorded.
    var nullable_i = decoratedTypeAnnotation('int i').node;
    assertNoUpstreamNullability(nullable_i);
  }

  Future<void> test_functionInvocation_parameter_null() async {
    await analyze('''
void f(int i) {}
void test() {
  f(null);
}
''');

    assertNullCheck(
        checkExpression('null'),
        assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
            hard: false));
  }

  Future<void> test_functionInvocation_return() async {
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

  Future<void> test_functionInvocation_typeParameter_inferred() async {
    await analyze('''
T h<T>(T t) => t;
T Function<T>(T) get f => h;
void g() {
  int y;
  int x = f(y);
}
''');
    var int_y = decoratedTypeAnnotation('int y').node;
    var int_x = decoratedTypeAnnotation('int x').node;
    var t_ret = decoratedTypeAnnotation('T Function').node;
    var t_param = decoratedTypeAnnotation('T)').node;

    assertEdge(substitutionNode(anyNode, t_ret), int_x, hard: false);
    assertEdge(int_y, substitutionNode(anyNode, t_param), hard: true);
  }

  Future<void> test_functionTypeAlias_inExpression() async {
    await analyze('''
typedef bool _P<T>(T value);
bool f(Object x) => x is _P<Object>;
''');
    // No assertions here; just don't crash. This test can be repurposed for
    // a more specific test with assertions.
  }

  Future<void> test_genericMethodInvocation() async {
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

  Future<void> test_genericMethodInvocation_withBoundSubstitution() async {
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

  Future<void>
      test_genericMethodInvocation_withBoundSubstitution_noFreshParameters() async {
    await analyze('''
class Base<T> {
  U foo<U>(U x) => x;
}
class Derived<V> extends Base {}
int bar(Derived<int> d, int i) => d.foo(i);
''');
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

  Future<void> test_genericMethodInvocation_withSubstitution() async {
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
        hard: false,
        checkable: false);
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

  Future<void> test_genericTypeAlias_inExpression() async {
    await analyze('''
typedef _P<T> = bool Function(T value);
bool f(Object x) => x is _P<Object>;
''');
    // No assertions here; just don't crash. This test can be repurposed for
    // a more specific test with assertions.
  }

  Future<void> test_getter_overrides_implicit_getter() async {
    await analyze('''
class A {
  final String/*1*/ s = "x";
}
class C implements A {
  String/*2*/ get s => false ? "y" : null;
}
''');
    var string1 = decoratedTypeAnnotation('String/*1*/');
    var string2 = decoratedTypeAnnotation('String/*2*/');
    assertEdge(string2.node, string1.node, hard: true);
  }

  Future<void> test_if_condition() async {
    await analyze('''
void f(bool b) {
  if (b) {}
}
''');

    assertNullCheck(checkExpression('b) {}'),
        assertEdge(decoratedTypeAnnotation('bool b').node, never, hard: true));
  }

  Future<void> test_if_conditional_control_flow_after() async {
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

  Future<void>
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

  Future<void> test_if_conditional_control_flow_within() async {
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

  Future<void> test_if_element_guard_equals_null() async {
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
    var discard = elementDiscard('if (i == null)');
    expect(discard.trueGuard, same(nullable_i));
    expect(discard.falseGuard, null);
    expect(discard.pureCondition, true);
  }

  Future<void> test_if_element_list() async {
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

  Future<void> test_if_element_map() async {
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

  Future<void> test_if_element_nested() async {
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

  Future<void> test_if_element_set() async {
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

  Future<void> test_if_guard_equals_null() async {
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

  Future<void> test_if_simple() async {
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

  Future<void> test_if_without_else() async {
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

  Future<void> test_import_metadata() async {
    await analyze('''
@deprecated
import 'dart:async';
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_indexExpression_bangHint() async {
    await analyze('''
abstract class C {
  int operator[](int index);
}
int f1(C c) => c[0];
int f2(C c) => c[0]/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int operator').node,
        decoratedTypeAnnotation('int f1').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int operator').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.index('c[0]/*!*/')), isTrue);
  }

  Future<void> test_indexExpression_dynamic() async {
    await analyze('''
int f(dynamic d, int i) {
  return d[i];
}
''');
    // We assume that the index expression might evaluate to anything, including
    // `null`.
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_indexExpression_index() async {
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

  Future<void> test_indexExpression_index_cascaded() async {
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

  Future<void> test_indexExpression_return_type() async {
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

  Future<void> test_indexExpression_target_check() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[0];
''');
    assertNullCheck(checkExpression('c['),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  Future<void> test_indexExpression_target_check_cascaded() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
C f(C c) => c..[0];
''');
    assertNullCheck(checkExpression('c..['),
        assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true));
  }

  Future<void>
      test_indexExpression_target_demonstrates_non_null_intent() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[0];
''');
    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  Future<void>
      test_indexExpression_target_demonstrates_non_null_intent_cascaded() async {
    await analyze('''
class C {
  int operator[](int i) => 1;
}
C f(C c) => c..[0];
''');
    assertEdge(decoratedTypeAnnotation('C c').node, never, hard: true);
  }

  Future<void> test_instanceCreation_generic() async {
    await analyze('''
class C<T> {}
C<int> f() => C<int>();
''');
    assertEdge(decoratedTypeAnnotation('int>(').node,
        decoratedTypeAnnotation('int> f').node,
        hard: false, checkable: false);
  }

  Future<void> test_instanceCreation_generic_bound() async {
    await analyze('''
class C<T extends Object> {}
C<int> f() => C<int>();
''');
    assertEdge(decoratedTypeAnnotation('int>(').node,
        decoratedTypeAnnotation('int> f').node,
        hard: false, checkable: false);
    assertEdge(decoratedTypeAnnotation('int>(').node,
        decoratedTypeAnnotation('Object').node,
        hard: true);
  }

  Future<void> test_instanceCreation_generic_dynamic() async {
    await analyze('''
class C<T> {}
C<Object> f() => C<dynamic>();
''');
    assertEdge(decoratedTypeAnnotation('dynamic').node,
        decoratedTypeAnnotation('Object').node,
        hard: false, checkable: false);
  }

  Future<void> test_instanceCreation_generic_inferredParameterType() async {
    await analyze('''
class C<T> {
  C(List<T> x);
}
C<int> f(List<int> x) => C(x);
''');
    var edge = assertEdge(anyNode, decoratedTypeAnnotation('int> f').node,
        hard: false, checkable: false);
    var inferredTypeArgument = edge.sourceNode;
    assertEdge(
        decoratedTypeAnnotation('int> x').node,
        substitutionNode(
            inferredTypeArgument, decoratedTypeAnnotation('T> x').node),
        hard: false,
        checkable: false);
  }

  Future<void> test_instanceCreation_generic_parameter() async {
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
    var nullable_c_t_or_nullable_t = check_i.checks.edges[FixReasonTarget.root]
        .destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  Future<void> test_instanceCreation_generic_parameter_named() async {
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
    var nullable_c_t_or_nullable_t = check_i.checks.edges[FixReasonTarget.root]
        .destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  Future<void> test_instanceCreation_implicit_type_params_names() async {
    await analyze('''
class C<T, U> {}
void main() {
  C<Object, Object> x = C();
}
''');
    var edge0 = assertEdge(
        anyNode, decoratedTypeAnnotation('C<Object, Object>').node,
        hard: false);
    expect(edge0.sourceNode.displayName, 'constructed type (test.dart:3:25)');
    var edge1 = assertEdge(anyNode, decoratedTypeAnnotation('Object,').node,
        hard: false, checkable: false);
    expect(edge1.sourceNode.displayName,
        'type argument 0 of constructed type (test.dart:3:25)');
    var edge2 = assertEdge(anyNode, decoratedTypeAnnotation('Object>').node,
        hard: false, checkable: false);
    expect(edge2.sourceNode.displayName,
        'type argument 1 of constructed type (test.dart:3:25)');
  }

  Future<void> test_instanceCreation_parameter_named_optional() async {
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

  Future<void> test_instanceCreation_parameter_positional_optional() async {
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

  Future<void> test_instanceCreation_parameter_positional_required() async {
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

  Future<void> test_integerLiteral() async {
    await analyze('''
int f() {
  return 0;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('int').node);
  }

  Future<void> test_invocation_arguments() async {
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

  Future<void> test_invocation_arguments_parenthesized() async {
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

  Future<void> test_invocation_dynamic() async {
    await analyze('''
int f(dynamic g) => g();
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_invocation_dynamic_parenthesized() async {
    await analyze('''
int f(dynamic g) => (g)();
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_invocation_function() async {
    await analyze('''
int f(Function g) => g();
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
    assertNullCheck(
        checkExpression('g('),
        assertEdge(decoratedTypeAnnotation('Function g').node, never,
            hard: true));
  }

  Future<void> test_invocation_function_parenthesized() async {
    await analyze('''
int f(Function g) => (g)();
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
    assertNullCheck(
        checkExpression('g)('),
        assertEdge(decoratedTypeAnnotation('Function g').node, never,
            hard: true));
  }

  Future<void> test_invocation_type_arguments() async {
    await analyze('''
int f(Function g) => g<C<int>>();
class C<T extends num> {}
''');
    // Make sure the appropriate edge gets created for the instantiation of C.
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('num>').node,
        hard: true);
  }

  Future<void> test_invocation_type_arguments_parenthesized() async {
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
  Future<void> test_isExpression_directlyRelatedTypeParameter() async {
    await analyze('''
bool f(List<num> list) => list is List<int>
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: false);
    assertEdge(decoratedTypeAnnotation('num').node,
        decoratedTypeAnnotation('int').node,
        hard: false);
  }

  Future<void> test_isExpression_genericFunctionType() async {
    await analyze('''
bool f(a) => a is int Function(String);
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
  }

  @failingTest
  Future<void> test_isExpression_indirectlyRelatedTypeParameter() async {
    await analyze('''
bool f(Iterable<num> iter) => iter is List<int>
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List').node, never, hard: false);
    assertEdge(decoratedTypeAnnotation('num').node,
        decoratedTypeAnnotation('int').node,
        hard: false);
  }

  Future<void> test_isExpression_typeName_noTypeArguments() async {
    await analyze('''
bool f(a) => a is String;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('String').node, never, hard: true);
  }

  Future<void> test_isExpression_typeName_typeArguments() async {
    await analyze('''
bool f(a) => a is List<int>;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('bool').node);
    assertEdge(decoratedTypeAnnotation('List').node, never, hard: true);
    assertNoEdge(always, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_library_metadata() async {
    await analyze('''
@deprecated
library foo;
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_libraryDirective() async {
    await analyze('''
library foo;
''');
    // Passes if no exceptions are thrown.
  }

  Future<void> test_list_constructor_length() async {
    await analyze('''
void main() {
  List<int/*1*/> list = List<int/*2*/>(10);
}
''');
    final variableParam = decoratedTypeAnnotation('int/*1*/');
    final filledParam = decoratedTypeAnnotation('int/*2*/');

    assertEdge(filledParam.node, variableParam.node,
        hard: false, checkable: false);
    assertEdge(always, filledParam.node, hard: false);
  }

  Future<void> test_list_constructor_length_implicitParam() async {
    await analyze('''
void main() {
  List<int/*1*/> list = List(10);
}
''');
    final variableParam = decoratedTypeAnnotation('int/*1*/');

    assertEdge(inSet(alwaysPlus), variableParam.node,
        hard: false, checkable: false);
  }

  Future<void> test_listLiteral_noTypeArgument_noNullableElements() async {
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
    expect(listArgType.displayName, 'list element type (test.dart:2:10)');
  }

  Future<void> test_listLiteral_noTypeArgument_nullableElement() async {
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
    assertEdge(inSet(alwaysPlus), listArgType, hard: false);
  }

  Future<void> test_listLiteral_typeArgument_noNullableElements() async {
    await analyze('''
List<String> f() {
  return <String>['a', 'b'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    var typeArgForLiteral = decoratedTypeAnnotation('String>[').node;
    var typeArgForReturnType = decoratedTypeAnnotation('String> ').node;
    assertNoUpstreamNullability(typeArgForLiteral);
    assertEdge(typeArgForLiteral, typeArgForReturnType,
        hard: false, checkable: false);
  }

  Future<void> test_listLiteral_typeArgument_nullableElement() async {
    await analyze('''
List<String> f() {
  return <String>['a', null, 'c'];
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('List').node);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('String>[').node,
        hard: false);
  }

  Future<void> test_localVariable_type_inferred() async {
    await analyze('''
int f() => 1;
main() {
  var x = f();
}
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertEdge(decoratedTypeAnnotation('int').node, xType.node, hard: false);
  }

  Future<void> test_localVariable_unused() async {
    await analyze('''
main() {
  int i;
}
''');
    // There is no edge from always to the type of `i`, because `i` is never
    // used, so it's ok that it's not initialized.
    assertNoEdge(always, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_method_parameterType_inferred() async {
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
    assertEdge(bReturnType.node, cReturnType.node, hard: true);
  }

  Future<void> test_method_parameterType_inferred_named() async {
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
    assertEdge(bReturnType.node, cReturnType.node, hard: true);
  }

  Future<void> test_method_returnType_inferred() async {
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
    assertEdge(cReturnType.node, bReturnType.node, hard: true);
  }

  Future<void>
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

  Future<void>
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

  Future<void> test_methodInvocation_bangHint() async {
    await analyze('''
abstract class C {
  int m1();
  int m2();
}
int f1(C c) => c.m1();
int f2(C c) => c.m2()/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int m1').node,
        decoratedTypeAnnotation('int f1').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int m2').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.methodInvocation('c.m2')), isTrue);
  }

  Future<void> test_methodInvocation_call_functionTyped() async {
    await analyze('''
void f(void Function(int x) callback, int y) => callback.call(y);
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  Future<void> test_methodInvocation_call_interfaceTyped() async {
    // Make sure that we don't try to treat all methods called `call` as though
    // the underlying type is a function type.
    await analyze('''
abstract class C {
  void call(int x);
}
void f(C c, int y) => c.call(y);
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  Future<void> test_methodInvocation_dynamic() async {
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
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_methodInvocation_dynamic_arguments() async {
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

  Future<void> test_methodInvocation_dynamic_type_arguments() async {
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

  Future<void> test_methodInvocation_extension_conflict() async {
    await analyze('''
class C {
  void f(int w) {}
}
extension E on C {
  void f(int x) {}
  void g(int y) {
    this.f(y);
  }
  void h(int z) {
    f(z);
  }
}
''');
    // `this.f(y)` refers to [C.f], not [E.f].
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int w').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node);

    // `f(z)` refers to [E.f], not [C.f].
    assertEdge(decoratedTypeAnnotation('int z').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int z').node,
        decoratedTypeAnnotation('int w').node);
  }

  Future<void> test_methodInvocation_extension_explicitThis() async {
    await analyze('''
class C {
  void f(int x) {}
}
extension E on C {
  void g(int y) {
    this.f(y);
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  Future<void> test_methodInvocation_extension_implicitThis() async {
    await analyze('''
class C {
  void f(int x) {}
}
extension E on C {
  void g(int y) {
    f(y);
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  Future<void> test_methodInvocation_extension_nullTarget() async {
    await analyze('''
class C {}
extension on C /*1*/ {
  void m() {}
}
void f() {
  C c = null;
  c.m();
}
''');
    assertEdge(decoratedTypeAnnotation('C c').node,
        decoratedTypeAnnotation('C /*1*/').node,
        hard: true);
  }

  Future<void> test_methodInvocation_extension_unnamed() async {
    await analyze('''
class C {
  void f(int x) {}
}
extension on C {
  void g(int y) {
    f(y);
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
  }

  Future<void> test_methodInvocation_generic_onResultOfImplicitSuper() async {
    await analyze('''
class Base<T1> {
  Base<T1> noop() => this;
}

class Sub<T2> extends Base<T2> {
  void implicitSuper() => noop().noop();
}
''');
    // Don't bother checking any edges; the assertions in the DecoratedType
    // constructor verify that we've substituted the bound correctly.
  }

  Future<void> test_methodInvocation_implicitSuper_generic() async {
    await analyze('''
class Base<T1> {
  Base<T1> f(T1 x) => this;
}

class Sub<T2> extends Base<T2> {
  void g() => f(null);
}
''');
    assertEdge(
        inSet(alwaysPlus),
        substitutionNode(
          substitutionNode(
            anyNode, // non-null for `this`.
            decoratedTypeAnnotation('T2> {').node,
          ),
          decoratedTypeAnnotation('T1 x').node,
        ),
        hard: false);
  }

  Future<void> test_methodInvocation_implicitSuper_tearOff() async {
    await analyze('''
class Base<T1> {
  Base<T1> f(T1 x) => this;
}

class Sub<T2> extends Base<T2> {
  void g() => (f)(null);
}
''');
    assertEdge(
        inSet(alwaysPlus),
        substitutionNode(
          substitutionNode(
            anyNode, // non-null for `this`.
            decoratedTypeAnnotation('T2> {').node,
          ),
          decoratedTypeAnnotation('T1 x').node,
        ),
        hard: false);
  }

  Future<void> test_methodInvocation_mixin_super() async {
    await analyze('''
class C {
  void f(int x) {}
}
mixin D on C {
  void g(int y) {
    super.f(y);
  }
  @override
  void f(int z) {
  }
}
''');
    assertEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int x').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int y').node,
        decoratedTypeAnnotation('int z').node);
  }

  Future<void> test_methodInvocation_object_method() async {
    await analyze('''
String f(int i) => i.toString();
''');
    // No edge from i to `never` because it is safe to call `toString` on
    // `null`.
    assertNoEdge(decoratedTypeAnnotation('int').node, never);
  }

  Future<void>
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

  Future<void> test_methodInvocation_parameter_contravariant() async {
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
    var nullable_c_t_or_nullable_t = check_i.checks.edges[FixReasonTarget.root]
        .destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_c_t_or_nullable_t.innerNode, same(nullable_c_t));
    expect(nullable_c_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_c_t_or_nullable_t, hard: true));
  }

  Future<void>
      test_methodInvocation_parameter_contravariant_from_migrated_class() async {
    await analyze('''
void f(List<int> x, int i) {
  x.add(i/*check*/);
}
''');

    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_list_t =
        decoratedTypeAnnotation('List<int>').typeArguments[0].node;
    var addMethod = findNode.methodInvocation('x.add').methodName.staticElement;
    var nullable_t = variables
        .decoratedElementType(addMethod.declaration)
        .positionalParameters[0]
        .node;
    assertEdge(nullable_t, never, hard: true, checkable: false);
    var check_i = checkExpression('i/*check*/');
    var nullable_list_t_or_nullable_t = check_i
        .checks
        .edges[FixReasonTarget.root]
        .destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_list_t_or_nullable_t.innerNode, same(nullable_list_t));
    expect(nullable_list_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_list_t_or_nullable_t, hard: true));
  }

  Future<void> test_methodInvocation_parameter_contravariant_function() async {
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
    var nullable_f_t_or_nullable_t = check_i.checks.edges[FixReasonTarget.root]
        .destinationNode as NullabilityNodeForSubstitution;
    expect(nullable_f_t_or_nullable_t.innerNode, same(nullable_f_t));
    expect(nullable_f_t_or_nullable_t.outerNode, same(nullable_t));
    assertNullCheck(check_i,
        assertEdge(nullable_i, nullable_f_t_or_nullable_t, hard: true));
  }

  Future<void> test_methodInvocation_parameter_generic() async {
    await analyze('''
class C<T> {}
void f(C<int/*1*/>/*2*/ c) {}
void g(C<int/*3*/>/*4*/ c) {
  f(c/*check*/);
}
''');

    assertEdge(decoratedTypeAnnotation('int/*3*/').node,
        decoratedTypeAnnotation('int/*1*/').node,
        hard: false, checkable: false);
    assertNullCheck(
        checkExpression('c/*check*/'),
        assertEdge(decoratedTypeAnnotation('C<int/*3*/>/*4*/').node,
            decoratedTypeAnnotation('C<int/*1*/>/*2*/').node,
            hard: true));
  }

  Future<void> test_methodInvocation_parameter_named() async {
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

  Future<void> test_methodInvocation_parameter_named_differentPackage() async {
    addPackageFile('foo', 'c.dart', '''
class C {
  void f({int i}) {}
}
''');
    await analyze('''
import "package:foo/c.dart";
void g(C c, int j) {
  c.f(i: j/*check*/);
}
''');
    var nullable_j = decoratedTypeAnnotation('int j');
    assertNullCheck(checkExpression('j/*check*/'),
        assertEdge(nullable_j.node, inSet(pointsToNever), hard: true));
  }

  Future<void> test_methodInvocation_promoted_in_new_flow_analysis() async {
    await analyze('''
class C<T> {
  void f(T t) {}
}
void g(C<num> c, int i) {
  if (c is! C<int>) {
    return;
  }

  c.f(i/*check*/);
}
''');

    // Mostly here to check DecoratedType's assertions, but here are some edge
    // checks anyways.
    var nullable_i = decoratedTypeAnnotation('int i').node;
    var nullable_t = decoratedTypeAnnotation('T t').node;
    assertEdge(nullable_i, substitutionNode(anyNode, nullable_t), hard: false);
  }

  Future<void> test_methodInvocation_resolves_to_getter() async {
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

  Future<void> test_methodInvocation_return_type() async {
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

  Future<void> test_methodInvocation_return_type_generic_function() async {
    await analyze('''
T f<T extends Object>(T t) => t;
int g() => (f<int>(1));
''');
    var check_i = checkExpression('(f<int>(1))');
    var t_bound = decoratedTypeAnnotation('Object').node;
    var nullable_f_t = decoratedTypeAnnotation('int>').node;
    var nullable_f_t_or_nullable_t = check_i.checks.edges[FixReasonTarget.root]
        .sourceNode as NullabilityNodeForSubstitution;
    var nullable_t = decoratedTypeAnnotation('T f').node;
    expect(nullable_f_t_or_nullable_t.innerNode, same(nullable_f_t));
    expect(nullable_f_t_or_nullable_t.outerNode, same(nullable_t));
    var nullable_return = decoratedTypeAnnotation('int g').node;
    assertNullCheck(check_i,
        assertEdge(nullable_f_t_or_nullable_t, nullable_return, hard: false));
    assertEdge(nullable_f_t, t_bound, hard: true);
  }

  Future<void> test_methodInvocation_return_type_null_aware() async {
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

  Future<void> test_methodInvocation_static_on_generic_class() async {
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

  Future<void> test_methodInvocation_target_check() async {
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

  Future<void> test_methodInvocation_target_check_cascaded() async {
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

  Future<void>
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

  Future<void>
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

  Future<void> test_methodInvocation_target_generic_in_base_class() async {
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

  Future<void> test_methodInvocation_typeParameter_inferred() async {
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
  Future<void>
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
  Future<void>
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

  Future<void> test_methodInvocation_variable_typeParameter_inferred() async {
    await analyze('''
T h<T>(T t) => t;
class C {
  void g() {
    T Function<T>(T) f = h;
    int y;
    int x = f(y);
  }
}
''');
    var int_y = decoratedTypeAnnotation('int y').node;
    var int_x = decoratedTypeAnnotation('int x').node;
    var t_ret = decoratedTypeAnnotation('T Function').node;
    var t_param = decoratedTypeAnnotation('T)').node;

    assertEdge(substitutionNode(anyNode, t_ret), int_x, hard: false);
    assertEdge(int_y, substitutionNode(anyNode, t_param), hard: true);
  }

  Future<void> test_never() async {
    await analyze('');

    expect(never.isNullable, isFalse);
  }

  Future<void> test_non_null_hint_is_not_expression_hint() async {
    await analyze('int/*!*/ x;');
    expect(hasNullCheckHint(findNode.simple('int')), isFalse);
  }

  Future<void> test_override_parameter_function_typed() async {
    await analyze('''
abstract class Base {
  void f(void g(int i)/*1*/);
}
class Derived extends Base {
  void f(void g(int i)/*2*/) {}
}
''');
    var p1 = variables.decoratedElementType(findNode
        .functionTypedFormalParameter('void g(int i)/*1*/')
        .declaredElement);
    var p2 = variables.decoratedElementType(findNode
        .functionTypedFormalParameter('void g(int i)/*2*/')
        .declaredElement);
    assertEdge(p1.node, p2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_named() async {
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
    assertEdge(int1.node, int2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_named_over_none() async {
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

  Future<void> test_override_parameter_type_operator() async {
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
    assertEdge(base1.node, base2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_optional() async {
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
    assertEdge(int1.node, int2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_optional_over_none() async {
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

  Future<void> test_override_parameter_type_optional_over_required() async {
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
    assertEdge(int1.node, int2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_required() async {
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
    assertEdge(int1.node, int2.node, hard: false, checkable: false);
  }

  Future<void> test_override_parameter_type_setter() async {
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
    assertEdge(int1.node, int2.node, hard: false, checkable: false);
  }

  Future<void> test_override_return_type_getter() async {
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

  Future<void> test_override_return_type_method() async {
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

  Future<void> test_override_return_type_operator() async {
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

  Future<void> test_parameter_field_metadata() async {
    await analyze('''
const bar = null;
class C {
  int foo;
  C(@bar this.foo);
}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_named_field_metadata() async {
    await analyze('''
const bar = null;
class C {
  int foo;
  C({@bar this.foo});
}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_named_field_with_default_metadata() async {
    await analyze('''
const bar = null;
class C {
  int foo;
  C({@bar this.foo = 0});
}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_named_metadata() async {
    await analyze('''
void f({@deprecated int foo}) {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_named_with_default_metadata() async {
    await analyze('''
void f({@deprecated int foo = 0}) {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_normal_metadata() async {
    await analyze('''
const foo = null;
void f(@foo int foo) {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_optional_positional_field_metadata() async {
    await analyze('''
const bar = null;
class C {
  int foo;
  C([@bar this.foo]);
}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parameter_optional_positional_metadata() async {
    await analyze('''
const foo = null;
void f([@foo int foo]) {}
''');
    // No assertions needed; the AnnotationTracker mixin verifies that the
    // metadata was visited.
  }

  Future<void> test_parenthesizedExpression() async {
    await analyze('''
int f() {
  return (null);
}
''');

    assertNullCheck(
        checkExpression('(null)'),
        assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
            hard: false));
  }

  Future<void> test_parenthesizedExpression_bangHint() async {
    await analyze('''
int f1(int i1) => (i1);
int f2(int i2) => (i2)/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int i1').node,
        decoratedTypeAnnotation('int f1').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int i2').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.parenthesized('(i2)')), isTrue);
  }

  Future<void> test_part_metadata() async {
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

  Future<void> test_part_of_identifier() async {
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

  Future<void> test_part_of_metadata() async {
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

  Future<void> test_part_of_path() async {
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

  Future<void> test_postDominators_assert() async {
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

  Future<void>
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

  Future<void> test_postDominators_break() async {
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

  Future<void> test_postDominators_continue() async {
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

  Future<void> test_postDominators_doWhileStatement_conditional() async {
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

  Future<void> test_postDominators_doWhileStatement_unconditional() async {
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

  Future<void> test_postDominators_forElement() async {
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

  Future<void> test_postDominators_forInElement() async {
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

  Future<void> test_postDominators_forInStatement_unconditional() async {
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

  Future<void> test_postDominators_forStatement_conditional() async {
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

  Future<void> test_postDominators_forStatement_unconditional() async {
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

  Future<void> test_postDominators_ifElement() async {
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

  Future<void> test_postDominators_ifStatement_conditional() async {
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

  Future<void> test_postDominators_ifStatement_unconditional() async {
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

  Future<void> test_postDominators_inReturn_local() async {
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

  Future<void> test_postDominators_loopReturn() async {
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

  Future<void> test_postDominators_multiDeclaration() async {
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
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int i').node,
        hard: false);
  }

  Future<void> test_postDominators_questionQuestionOperator() async {
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

  Future<void> test_postDominators_reassign() async {
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

  Future<void> test_postDominators_shortCircuitOperators() async {
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

  Future<void> test_postDominators_subFunction() async {
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
  Future<void> test_postDominators_subFunction_ifStatement_conditional() async {
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

  Future<void>
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

  Future<void> test_postDominators_ternaryOperator() async {
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

  Future<void> test_postDominators_tryCatch() async {
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

  Future<void> test_postDominators_whileStatement_unconditional() async {
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

  Future<void> test_postfixExpression_minusMinus() async {
    await analyze('''
int f(int i) {
  return i--;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i--');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(declaration, returnType, hard: false);
  }

  Future<void> test_postfixExpression_plusPlus() async {
    await analyze('''
int f(int i) {
  return i++;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i++');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(declaration, returnType, hard: false);
  }

  Future<void> test_postfixExpression_plusPlus_dynamic() async {
    await analyze('''
Object f(dynamic d) {
  return d++;
}
''');
    assertEdge(decoratedTypeAnnotation('dynamic d').node,
        decoratedTypeAnnotation('Object f').node,
        hard: false);
  }

  Future<void> test_postfixExpression_plusPlus_substituted() async {
    await analyze('''
abstract class C<T> {
  C<T> operator+(int x);
}
C<int> f(C<int> c) {
  return c++;
}
''');

    var cType = decoratedTypeAnnotation('C<int> c');
    var returnType = decoratedTypeAnnotation('C<int> f');
    assertNullCheck(
        checkExpression('c++'), assertEdge(cType.node, never, hard: true));
    assertEdge(cType.node, returnType.node, hard: false);
    assertEdge(cType.typeArguments[0].node, returnType.typeArguments[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_prefixedIdentifier_bangHint() async {
    await analyze('''
import 'dart:math' as m;
double f1() => m.pi;
double f2() => m.pi/*!*/;
''');
    expect(
        assertEdge(anyNode, decoratedTypeAnnotation('double f1').node,
                hard: false)
            .sourceNode,
        isNot(never));
    expect(
        assertEdge(anyNode, decoratedTypeAnnotation('double f2').node,
                hard: false)
            .sourceNode,
        never);
    expect(hasNullCheckHint(findNode.prefixed('m.pi/*!*/')), isTrue);
  }

  Future<void> test_prefixedIdentifier_field_type() async {
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

  Future<void> test_prefixedIdentifier_getter_type() async {
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

  Future<void> test_prefixedIdentifier_getter_type_in_generic() async {
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
        hard: false,
        checkable: false);
  }

  Future<void> test_prefixedIdentifier_target_check() async {
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

  Future<void>
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

  Future<void> test_prefixedIdentifier_tearoff() async {
    await analyze('''
abstract class C {
  int f(int i);
}
int Function(int) g(C c) => c.f;
''');
    var fType = variables.decoratedElementType(findElement.method('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.function('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node,
        hard: false, checkable: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_prefixExpression_bang() async {
    await analyze('''
bool f(bool b) {
  return !b;
}
''');

    var nullable_b = decoratedTypeAnnotation('bool b').node;
    var check_b = checkExpression('b;');
    assertNullCheck(check_b, assertEdge(nullable_b, never, hard: true));

    var return_f = decoratedTypeAnnotation('bool f').node;
    assertEdge(inSet(pointsToNever), return_f, hard: false);
  }

  Future<void> test_prefixExpression_bang_dynamic() async {
    await analyze('''
Object f(dynamic d) {
  return !d;
}
''');
    var return_f = decoratedTypeAnnotation('Object f').node;
    assertEdge(inSet(pointsToNever), return_f, hard: false);
  }

  Future<void> test_prefixExpression_minus() async {
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

  Future<void> test_prefixExpression_minus_dynamic() async {
    await analyze('''
Object test(dynamic d) => -d;
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('Object test').node,
        hard: false);
    assertEdge(decoratedTypeAnnotation('dynamic d').node, never, hard: true);
  }

  Future<void> test_prefixExpression_minus_substituted() async {
    await analyze('''
abstract class C<T> {
  List<T> operator-();
}
List<int> test(C<int> c) => -c/*check*/;
''');
    var operatorReturnType = decoratedTypeAnnotation('List<T> operator');
    var cType = decoratedTypeAnnotation('C<int> c');
    var testReturnType = decoratedTypeAnnotation('List<int> test');
    assertEdge(operatorReturnType.node, testReturnType.node, hard: false);
    assertNullCheck(checkExpression('c/*check*/'),
        assertEdge(cType.node, never, hard: true));
    assertEdge(
        substitutionNode(cType.typeArguments[0].node,
            operatorReturnType.typeArguments[0].node),
        testReturnType.typeArguments[0].node,
        hard: false,
        checkable: false);
  }

  Future<void> test_prefixExpression_minusMinus() async {
    await analyze('''
int f(int i) {
  return --i;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i;');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(inSet(pointsToNever), returnType, hard: false);
  }

  Future<void> test_prefixExpression_plusPlus() async {
    await analyze('''
int f(int i) {
  return ++i;
}
''');

    var declaration = decoratedTypeAnnotation('int i').node;
    var use = checkExpression('i;');
    assertNullCheck(use, assertEdge(declaration, never, hard: true));

    var returnType = decoratedTypeAnnotation('int f').node;
    assertEdge(inSet(pointsToNever), returnType, hard: false);
  }

  Future<void> test_prefixExpression_plusPlus_dynamic() async {
    await analyze('''
Object f(dynamic d) {
  return ++d;
}
''');
    var returnType = decoratedTypeAnnotation('Object f').node;
    assertEdge(inSet(alwaysPlus), returnType, hard: false);
  }

  Future<void> test_prefixExpression_plusPlus_substituted() async {
    await analyze('''
abstract class C<T> {
  C<T> operator+(int i);
}
C<int> f(C<int> x) => ++x;
    ''');
    var xType = decoratedTypeAnnotation('C<int> x');
    var plusReturnType = decoratedTypeAnnotation('C<T> operator');
    var fReturnType = decoratedTypeAnnotation('C<int> f');
    assertEdge(xType.node, never, hard: true);
    assertEdge(plusReturnType.node, fReturnType.node, hard: false);
    assertEdge(
        substitutionNode(
            xType.typeArguments[0].node, plusReturnType.typeArguments[0].node),
        fReturnType.typeArguments[0].node,
        hard: false,
        checkable: false);
  }

  Future<void> test_property_generic_onResultOfImplicitSuper() async {
    await analyze('''
class Base<T1> {
  Base<T1> x;
}

class Sub<T2> extends Base<T2> {
  void implicitSuper() => x.x;
}
''');
    // Don't bother checking any edges; the assertions in the DecoratedType
    // constructor verify that we've substituted the bound correctly.
  }

  Future<void> test_property_implicitSuper_assignment() async {
    await analyze('''
class Base<T1> {
  T1 x;
}

class Sub<T2> extends Base<T2> {
  void g() => x = null;
}
''');
    assertEdge(
        inSet(alwaysPlus),
        substitutionNode(
          substitutionNode(
            anyNode, // non-null for `this`.
            decoratedTypeAnnotation('T2> {').node,
          ),
          decoratedTypeAnnotation('T1 x').node,
        ),
        hard: false);
  }

  Future<void> test_propertyAccess_bangHint() async {
    await analyze('''
abstract class C {
  int get i1;
  int get i2;
}
int f1(C c) => (c).i1;
int f2(C c) => (c).i2/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int get i1').node,
        decoratedTypeAnnotation('int f1').node,
        hard: false);
    assertNoEdge(decoratedTypeAnnotation('int get i2').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.propertyAccess('(c).i2')), isTrue);
  }

  Future<void> test_propertyAccess_call_functionTyped() async {
    await analyze('''
String/*1*/ Function(int/*2*/) f(String/*3*/ Function(int/*4*/) callback)
    => callback.call;
''');
    assertEdge(decoratedTypeAnnotation('String/*3*/').node,
        decoratedTypeAnnotation('String/*1*/').node,
        hard: false, checkable: false);
    assertEdge(decoratedTypeAnnotation('int/*2*/').node,
        decoratedTypeAnnotation('int/*4*/').node,
        hard: false, checkable: false);
    var tearOffNodeMatcher = anyNode;
    assertEdge(
        tearOffNodeMatcher,
        decoratedGenericFunctionTypeAnnotation('String/*1*/ Function(int/*2*/)')
            .node,
        hard: false);
    assertEdge(never, tearOffNodeMatcher.matchingNode,
        hard: true, checkable: false);
  }

  Future<void> test_propertyAccess_call_interfaceTyped() async {
    // Make sure that we don't try to treat all methods called `call` as though
    // the underlying type is a function type.
    await analyze('''
abstract class C {
  String call(int x);
}
String Function(int) f(C c) => c.call;
''');
    assertEdge(decoratedTypeAnnotation('String call').node,
        decoratedTypeAnnotation('String Function').node,
        hard: false, checkable: false);
    assertEdge(decoratedTypeAnnotation('int) f').node,
        decoratedTypeAnnotation('int x').node,
        hard: false, checkable: false);
    assertEdge(never,
        decoratedGenericFunctionTypeAnnotation('String Function(int)').node,
        hard: false);
  }

  Future<void> test_propertyAccess_dynamic() async {
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
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_propertyAccess_object_property() async {
    await analyze('''
int f(int i) => i.hashCode;
''');
    // No edge from i to `never` because it is safe to call `hashCode` on
    // `null`.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
  }

  Future<void> test_propertyAccess_object_property_on_function_type() async {
    await analyze('int f(void Function() g) => g.hashCode;');
    var hashCodeReturnType = variables
        .decoratedElementType(
            typeProvider.objectType.element.getGetter('hashCode'))
        .returnType;
    assertEdge(hashCodeReturnType.node, decoratedTypeAnnotation('int f').node,
        hard: false);
  }

  Future<void> test_propertyAccess_return_type() async {
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

  Future<void> test_propertyAccess_return_type_null_aware() async {
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

  Future<void> test_propertyAccess_static_on_generic_class() async {
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

  Future<void> test_propertyAccess_target_check() async {
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

  Future<void> test_quiver_checkNotNull_not_postDominating() async {
    addQuiverPackage();
    await analyze('''
import 'package:quiver/check.dart';
void f(bool b, int i, int j) {
  checkNotNull(j);
  if (b) return;
  checkNotNull(i);
}
''');

    // Asserts after ifs don't demonstrate non-null intent.
    assertNoEdge(decoratedTypeAnnotation('int i').node, never);
    // But asserts before ifs do
    assertEdge(decoratedTypeAnnotation('int j').node, never, hard: true);
  }

  Future<void> test_quiver_checkNotNull_postDominating() async {
    addQuiverPackage();
    await analyze('''
import 'package:quiver/check.dart';
void f(int i) {
  checkNotNull(i);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_quiver_checkNotNull_prefixed() async {
    addQuiverPackage();
    await analyze('''
import 'package:quiver/check.dart' as quiver;
void f(int i) {
  quiver.checkNotNull(i);
}
''');

    assertEdge(decoratedTypeAnnotation('int i').node, never, hard: true);
  }

  Future<void> test_redirecting_constructor_factory() async {
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

  Future<void>
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

  Future<void> test_redirecting_constructor_factory_to_generic() async {
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

  Future<void> test_redirecting_constructor_ordinary() async {
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

  Future<void> test_redirecting_constructor_ordinary_to_unnamed() async {
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

  Future<void> test_return_from_async_bottom() async {
    await analyze('''
Future<int> f() async => throw '';
''');
    assertNoEdge(always, decoratedTypeAnnotation('Future<int>').node);
    assertNoEdge(always, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_return_from_async_closureBody_future() async {
    await analyze('''
Future<int> f() {
  return () async {
    return g();
  }();
}
int g() => 1;
''');
    assertEdge(
        decoratedTypeAnnotation('int g').node,
        // TODO(40621): This should be a checkable edge.
        assertEdge(anyNode, decoratedTypeAnnotation('int>').node,
                hard: false, checkable: false)
            .sourceNode,
        hard: false,
        // TODO(40621): This should be a checkable edge.
        checkable: false);
  }

  Future<void> test_return_from_async_closureExpression_future() async {
    await analyze('''
Future<int> Function() f() {
  return () async => g();
}
int g() => 1;
''');
    assertEdge(
        decoratedTypeAnnotation('int g').node,
        // TODO(40621): This should be a checkable edge.
        assertEdge(anyNode, decoratedTypeAnnotation('int>').node,
                hard: false, checkable: false)
            .sourceNode,
        hard: false,
        // TODO(40621): This should be a checkable edge.
        checkable: false);
  }

  Future<void> test_return_from_async_expressionBody_future() async {
    await analyze('''
Future<int> f() async => g();
int g() => 1;
''');
    // TODO(40621): This should be a checkable edge.
    assertEdge(decoratedTypeAnnotation('int g').node,
        decoratedTypeAnnotation('int>').node,
        hard: false, checkable: false);
  }

  Future<void> test_return_from_async_future() async {
    await analyze('''
Future<int> f() async {
  return g();
}
int g() => 1;
''');
    // TODO(40621): This should be a checkable edge.
    assertEdge(decoratedTypeAnnotation('int g').node,
        decoratedTypeAnnotation('int>').node,
        hard: false, checkable: false);
  }

  Future<void> test_return_from_async_future_void() async {
    await analyze('''
Future<void> f() async {
  return;
}
int g() => 1;
''');
    assertNoEdge(always, decoratedTypeAnnotation('Future').node);
  }

  Future<void> test_return_from_async_futureOr() async {
    await analyze('''
import 'dart:async';
FutureOr<int> f() async {
  return g();
}
int g() => 1;
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void> test_return_from_async_futureOr_to_future() async {
    await analyze('''
import 'dart:async';
Future<Object> f(FutureOr<int> x) async => x;
''');
    var lubNodeMatcher = anyNode;
    assertEdge(lubNodeMatcher, decoratedTypeAnnotation('Object').node,
        hard: false, checkable: false);
    var lubNode = lubNodeMatcher.matchingNode as NullabilityNodeForLUB;
    expect(lubNode.left, same(decoratedTypeAnnotation('int> x').node));
    expect(lubNode.right, same(decoratedTypeAnnotation('FutureOr<int>').node));
  }

  Future<void> test_return_from_async_list_to_future() async {
    await analyze('''
import 'dart:async';
Future<Object> f(List<int> x) async => x;
''');
    assertEdge(decoratedTypeAnnotation('List<int>').node,
        decoratedTypeAnnotation('Object').node,
        hard: false, checkable: false);
  }

  Future<void> test_return_from_async_null() async {
    await analyze('''
Future<int> f() async {
  return null;
}
''');
    // TODO(40621): This should be a checkable edge.
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int>').node,
        hard: false, checkable: false);
  }

  Future<void> test_return_function_type_simple() async {
    await analyze('''
int/*1*/ Function() f(int/*2*/ Function() x) => x;
''');
    var int1 = decoratedTypeAnnotation('int/*1*/');
    var int2 = decoratedTypeAnnotation('int/*2*/');
    assertEdge(int2.node, int1.node, hard: false, checkable: false);
  }

  Future<void> test_return_implicit_null() async {
    verifyNoTestUnitErrors = false;
    await analyze('''
int f() {
  return;
}
''');

    var edge = assertEdge(
        inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
        hard: false);
    expect(edge.sourceNode.displayName, 'implicit null return (test.dart:2:3)');
  }

  Future<void> test_return_in_asyncStar() async {
    await analyze('''
Stream<int> f() async* {
  yield 1;
  return;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Stream<int>').node);
  }

  Future<void> test_return_in_syncStar() async {
    await analyze('''
Iterable<int> f() sync* {
  yield 1;
  return;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Iterable<int>').node);
  }

  Future<void> test_return_null() async {
    await analyze('''
int f() {
  return null;
}
''');

    var edge = assertEdge(
        inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
        hard: false);
    assertNullCheck(checkExpression('null'), edge);
    expect(edge.sourceNode.displayName, 'null literal (test.dart:2:10)');
  }

  Future<void> test_return_null_generic() async {
    await analyze('''
class C<T> {
  T f() {
    return null;
  }
}
''');
    var tNode = decoratedTypeAnnotation('T f').node;
    assertEdge(inSet(alwaysPlus), tNode, hard: false);
    assertNullCheck(checkExpression('null'),
        assertEdge(inSet(alwaysPlus), tNode, hard: false));
  }

  Future<void>
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
    var keyEdge = assertEdge(anyNode, keyNode, hard: false, checkable: false);
    assertNoUpstreamNullability(keyEdge.sourceNode);
    expect(keyEdge.sourceNode.displayName, 'map key type (test.dart:2:10)');
    var valueEdge =
        assertEdge(anyNode, valueNode, hard: false, checkable: false);
    assertNoUpstreamNullability(valueEdge.sourceNode);
    expect(valueEdge.sourceNode.displayName, 'map value type (test.dart:2:10)');
  }

  Future<void> test_setOrMapLiteral_map_noTypeArgument_nullableKey() async {
    await analyze('''
Map<String, int> f() {
  return {'a' : 1, null : 2, 'c' : 3};
}
''');
    var keyNode = decoratedTypeAnnotation('String').node;
    var valueNode = decoratedTypeAnnotation('int').node;
    var mapNode = decoratedTypeAnnotation('Map').node;

    assertNoUpstreamNullability(mapNode);
    assertEdge(inSet(alwaysPlus),
        assertEdge(anyNode, keyNode, hard: false, checkable: false).sourceNode,
        hard: false);
    assertNoUpstreamNullability(
        assertEdge(anyNode, valueNode, hard: false, checkable: false)
            .sourceNode);
  }

  Future<void>
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
    assertEdge(inSet(alwaysPlus),
        assertEdge(anyNode, keyNode, hard: false, checkable: false).sourceNode,
        hard: false);
    assertEdge(
        inSet(alwaysPlus),
        assertEdge(anyNode, valueNode, hard: false, checkable: false)
            .sourceNode,
        hard: false);
  }

  Future<void> test_setOrMapLiteral_map_noTypeArgument_nullableValue() async {
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
        assertEdge(anyNode, keyNode, hard: false, checkable: false).sourceNode);
    assertEdge(
        inSet(alwaysPlus),
        assertEdge(anyNode, valueNode, hard: false, checkable: false)
            .sourceNode,
        hard: false);
  }

  Future<void>
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
    assertEdge(keyForLiteral, keyForReturnType, hard: false, checkable: false);

    var valueForLiteral = decoratedTypeAnnotation('int>{').node;
    var valueForReturnType = decoratedTypeAnnotation('int> ').node;
    assertNoUpstreamNullability(valueForLiteral);
    assertEdge(valueForLiteral, valueForReturnType,
        hard: false, checkable: false);
  }

  Future<void> test_setOrMapLiteral_map_typeArguments_nullableKey() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, null : 2, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('String, int>{').node,
        hard: false);
    assertNoUpstreamNullability(decoratedTypeAnnotation('int>{').node);
  }

  Future<void>
      test_setOrMapLiteral_map_typeArguments_nullableKeyAndValue() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, null : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('String, int>{').node,
        hard: false);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int>{').node,
        hard: false);
  }

  Future<void> test_setOrMapLiteral_map_typeArguments_nullableValue() async {
    await analyze('''
Map<String, int> f() {
  return <String, int>{'a' : 1, 'b' : null, 'c' : 3};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Map').node);
    assertNoUpstreamNullability(decoratedTypeAnnotation('String, int>{').node);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int>{').node,
        hard: false);
  }

  Future<void>
      test_setOrMapLiteral_set_noTypeArgument_noNullableElements() async {
    await analyze('''
Set<String> f() {
  return {'a', 'b'};
}
''');
    var valueNode = decoratedTypeAnnotation('String').node;
    var setNode = decoratedTypeAnnotation('Set').node;

    assertNoUpstreamNullability(setNode);
    var edge = assertEdge(anyNode, valueNode, hard: false, checkable: false);
    assertNoUpstreamNullability(edge.sourceNode);
    expect(edge.sourceNode.displayName, 'set element type (test.dart:2:10)');
  }

  Future<void> test_setOrMapLiteral_set_noTypeArgument_nullableElement() async {
    await analyze('''
Set<String> f() {
  return {'a', null, 'c'};
}
''');
    var valueNode = decoratedTypeAnnotation('String').node;
    var setNode = decoratedTypeAnnotation('Set').node;

    assertNoUpstreamNullability(setNode);
    assertEdge(
        inSet(alwaysPlus),
        assertEdge(anyNode, valueNode, hard: false, checkable: false)
            .sourceNode,
        hard: false);
  }

  Future<void>
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
    assertEdge(typeArgForLiteral, typeArgForReturnType,
        hard: false, checkable: false);
  }

  Future<void> test_setOrMapLiteral_set_typeArgument_nullableElement() async {
    await analyze('''
Set<String> f() {
  return <String>{'a', null, 'c'};
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Set').node);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('String>{').node,
        hard: false);
  }

  Future<void> test_setter_overrides_implicit_setter() async {
    await analyze('''
class A {
  String/*1*/ s = "x";
}
class C implements A {
  String get s => "x";
  void set s(String/*2*/ value) {}
}
f() => A().s = null;
''');
    var string1 = decoratedTypeAnnotation('String/*1*/');
    var string2 = decoratedTypeAnnotation('String/*2*/');
    assertEdge(string1.node, string2.node, hard: true);
  }

  Future<void> test_setupAssignment_assignment_inDistantSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  int i;
  // There could be tests here in which [i] is not certain to have been
  // assigned.

  group('g2', () {
    setUp(() {
      i = 1;
    });
  });
}
''');

    assertNoEdge(graph.never, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_setupAssignment_assignment_inSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  int i;
    int j = 1;
  setUp(() {
    i = j;
  });
}
''');

    assertNullCheck(
        checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node,
            decoratedTypeAnnotation('int i').node,
            hard: false, isSetupAssignment: true));
  }

  Future<void> test_setupAssignment_assignment_inUnrelatedSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  group('g1', () {
    int/*1*/ i;
  });

  group('g2', () {
    int/*2*/ i;
    int j = 1;
    setUp(() {
      i = j;
    });
  });
}
''');

    assertNoEdge(graph.never, decoratedTypeAnnotation('int/*1*/').node);
    assertNullCheck(
        checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node,
            decoratedTypeAnnotation('int/*2*/').node,
            hard: false, isSetupAssignment: true));
  }

  Future<void> test_setupAssignment_assignment_inWrongSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart' as t;
void main() {
  int i;
  setUp(() {
    i = 1;
  });
}
void setUp(dynamic callback()) {}
''');

    assertNoEdge(graph.never, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_setupAssignment_assignment_outsideSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  int i;
  i = 1;
}
''');

    assertNoEdge(graph.never, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_setupAssignment_assignment_toField() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  setUp(() {
    C c = C();
    c.i = 1;
  });
}
class C {
  int i;
}
''');

    assertNoEdge(graph.never, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_setupAssignment_nullAwareAssignment_inSetUp() async {
    addTestCorePackage();
    await analyze('''
import 'package:test/test.dart';
void main() {
  int i;
    int j = 1;
  setUp(() {
    i ??= j;
  });
}
''');

    var iNullable = decoratedTypeAnnotation('int i').node;
    assertNullCheck(
        checkExpression('j;'),
        assertEdge(decoratedTypeAnnotation('int j').node, iNullable,
            hard: false, guards: [iNullable], isSetupAssignment: true));
  }

  Future<void> test_simpleIdentifier_bangHint() async {
    await analyze('''
int f1(int i1) => i1;
int f2(int i2) => i2/*!*/;
''');
    assertEdge(decoratedTypeAnnotation('int i1').node,
        decoratedTypeAnnotation('int f1').node,
        hard: true);
    assertNoEdge(decoratedTypeAnnotation('int i2').node,
        decoratedTypeAnnotation('int f2').node);
    expect(hasNullCheckHint(findNode.simple('i2/*!*/')), isTrue);
  }

  Future<void> test_simpleIdentifier_function() async {
    await analyze('''
int f() => null;
main() {
  int Function() g = f;
}
''');

    assertEdge(decoratedTypeAnnotation('int f').node,
        decoratedTypeAnnotation('int Function').node,
        hard: false, checkable: false);
  }

  Future<void> test_simpleIdentifier_local() async {
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

  Future<void> test_simpleIdentifier_tearoff_function() async {
    await analyze('''
int f(int i) => 0;
int Function(int) g() => f;
''');
    var fType = variables.decoratedElementType(findElement.function('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.function('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node,
        hard: false, checkable: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_simpleIdentifier_tearoff_method() async {
    await analyze('''
abstract class C {
  int f(int i);
  int Function(int) g() => f;
}
''');
    var fType = variables.decoratedElementType(findElement.method('f'));
    var gReturnType =
        variables.decoratedElementType(findElement.method('g')).returnType;
    assertEdge(fType.returnType.node, gReturnType.returnType.node,
        hard: false, checkable: false);
    assertEdge(gReturnType.positionalParameters[0].node,
        fType.positionalParameters[0].node,
        hard: false, checkable: false);
  }

  Future<void> test_skipDirectives() async {
    await analyze('''
import "dart:core" as one;
main() {}
''');
    // No test expectations.
    // Just verifying that the test passes
  }

  Future<void> test_soft_edge_for_non_variable_reference() async {
    // Edges originating in things other than variable references should be
    // soft.
    await analyze('''
int f() => null;
''');
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int').node,
        hard: false);
  }

  Future<void> test_spread_element_list() async {
    await analyze('''
void f(List<int> ints) {
  <int>[...ints];
}
''');

    assertEdge(decoratedTypeAnnotation('List<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>[').node,
        hard: false,
        checkable: false);
  }

  Future<void> test_spread_element_list_dynamic() async {
    await analyze('''
void f(dynamic ints) {
  <int>[...ints];
}
''');

    // Mostly just check this doesn't crash.
    assertEdge(decoratedTypeAnnotation('dynamic').node, never, hard: true);
  }

  Future<void> test_spread_element_list_nullable() async {
    await analyze('''
void f(List<int> ints) {
  <int>[...?ints];
}
''');

    assertNoEdge(decoratedTypeAnnotation('List<int>').node, never);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>[').node,
        hard: false,
        checkable: false);
  }

  Future<void> test_spread_element_map() async {
    await analyze('''
void f(Map<String, int> map) {
  <String, int>{...map};
}
''');

    assertEdge(decoratedTypeAnnotation('Map<String, int>').node, never,
        hard: true);
    assertEdge(decoratedTypeAnnotation('String, int> map').node,
        decoratedTypeAnnotation('String, int>{').node,
        hard: false, checkable: false);
    assertEdge(decoratedTypeAnnotation('int> map').node,
        decoratedTypeAnnotation('int>{').node,
        hard: false, checkable: false);
  }

  Future<void> test_spread_element_set() async {
    await analyze('''
void f(Set<int> ints) {
  <int>{...ints};
}
''');

    assertEdge(decoratedTypeAnnotation('Set<int>').node, never, hard: true);
    assertEdge(
        substitutionNode(decoratedTypeAnnotation('int> ints').node, anyNode),
        decoratedTypeAnnotation('int>{').node,
        hard: false,
        checkable: false);
  }

  Future<void> test_spread_element_subtype() async {
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
        hard: false,
        checkable: false);
  }

  Future<void> test_static_method_call_prefixed() async {
    await analyze('''
import 'dart:async' as a;
void f(void Function() callback) {
  a.Timer.run(callback);
}
''');
    // No assertions.  Just making sure this doesn't crash.
  }

  Future<void> test_stringLiteral() async {
    // TODO(paulberry): also test string interpolations
    await analyze('''
String f() {
  return 'x';
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('String').node);
  }

  Future<void> test_superExpression() async {
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

  Future<void> test_superExpression_generic() async {
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
            substitutionNode(
                inSet(pointsToNever), decoratedTypeAnnotation('T> {').node),
            decoratedTypeAnnotation('U g').node),
        decoratedTypeAnnotation('T f').node,
        hard: false);
  }

  Future<void> test_symbolLiteral() async {
    await analyze('''
Symbol f() {
  return #symbol;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Symbol').node);
  }

  Future<void> test_this_bangHint() async {
    await analyze('''
extension on int {
  int f1() => this;
  int f2() => this/*!*/;
}
''');
    expect(
        assertEdge(anyNode, decoratedTypeAnnotation('int f1').node, hard: false)
            .sourceNode,
        isNot(never));
    expect(
        assertEdge(anyNode, decoratedTypeAnnotation('int f2').node, hard: false)
            .sourceNode,
        never);
    expect(hasNullCheckHint(findNode.this_('this/*!*/')), isTrue);
  }

  Future<void> test_thisExpression() async {
    await analyze('''
class C {
  C f() => this;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('C f').node);
  }

  Future<void> test_thisExpression_generic() async {
    await analyze('''
class C<T> {
  C<T> f() => this;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('C<T> f').node);
    assertNoUpstreamNullability(decoratedTypeAnnotation('T> f').node);
  }

  Future<void> test_throwExpression() async {
    await analyze('''
int f() {
  return throw null;
}
''');
    var intNode = decoratedTypeAnnotation('int').node;
    assertNoUpstreamNullability(intNode);
    var edge = assertEdge(anyNode, intNode, hard: false);
    expect(edge.sourceNode.displayName, 'throw expression (test.dart:2:10)');
  }

  Future<void> test_top_level_annotation_begins_flow_analysis() async {
    await analyze('''
class C {
  const C(bool x);
}
@C(true)
int x;
''');
  }

  Future<void> test_topLevelSetter() async {
    await analyze('''
void set x(int value) {}
main() { x = 1; }
''');
    var setXType = decoratedTypeAnnotation('int value');
    assertEdge(inSet(pointsToNever), setXType.node, hard: false);
  }

  Future<void> test_topLevelSetter_nullable() async {
    await analyze('''
void set x(int value) {}
main() { x = null; }
''');
    var setXType = decoratedTypeAnnotation('int value');
    assertEdge(inSet(alwaysPlus), setXType.node, hard: false);
  }

  Future<void> test_topLevelVar_implicitInitializer() async {
    await analyze('int i;');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  Future<void> test_topLevelVar_metadata() async {
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

  Future<void> test_topLevelVar_reference() async {
    await analyze('''
double pi = 3.1415;
double get myPi => pi;
''');
    var piType = decoratedTypeAnnotation('double pi');
    var myPiType = decoratedTypeAnnotation('double get');
    assertEdge(piType.node, myPiType.node, hard: false);
  }

  Future<void> test_topLevelVar_reference_differentPackage() async {
    addPackageFile('foo', 'piConst.dart', '''
double pi = 3.1415;
''');
    await analyze('''
import "package:foo/piConst.dart";
double get myPi => pi;
''');
    var myPiType = decoratedTypeAnnotation('double get');
    assertEdge(inSet(pointsToNever), myPiType.node, hard: false);
  }

  Future<void> test_topLevelVariable_type_inferred() async {
    await analyze('''
int f() => 1;
var x = f();
''');
    var xType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    assertEdge(decoratedTypeAnnotation('int').node, xType.node, hard: false);
  }

  Future<void> test_type_argument_explicit_bound() async {
    await analyze('''
class C<T extends Object> {}
void f(C<int> c) {}
''');
    assertEdge(decoratedTypeAnnotation('int>').node,
        decoratedTypeAnnotation('Object>').node,
        hard: true);
  }

  Future<void> test_type_parameter_method_call_bound() async {
    await analyze('''
class Foo {
  void bar(int x) {}
}

void f<T extends Foo>(T t) {
  t.bar(null);
}
''');
    assertEdge(decoratedTypeAnnotation('T t').node, never, hard: true);
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('Foo>').node, never, hard: true);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  Future<void> test_type_parameter_method_call_bound_bound() async {
    await analyze('''
class Foo {
  void bar(int x) {}
}

void f<T extends R, R extends Foo>(T t) {
  t.bar(null);
}
''');
    assertEdge(decoratedTypeAnnotation('T t').node, never, hard: true);
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('Foo>').node, never, hard: true);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  Future<void> test_type_parameter_method_call_bound_generic() async {
    await analyze('''
class Foo<T> {
  void bar(int x) {}
}

void f<T extends Foo<dynamic>>(T t) {
  t.bar(null);
}
''');
    assertEdge(decoratedTypeAnnotation('T t').node, never, hard: true);
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('Foo>').node, never, hard: true);
    assertEdge(inSet(alwaysPlus), decoratedTypeAnnotation('int x').node,
        hard: false);
  }

  Future<void> test_type_parameter_method_call_bound_generic_complex() async {
    await analyze('''
class Foo<T> {
  void bar(T x) {}
}

void f<R extends Object, T extends Foo<R>>(T t) {
  t.bar(null);
}
''');
    assertEdge(decoratedTypeAnnotation('T t').node, never, hard: true);
    // TODO(mfairhurst): fix this: https://github.com/dart-lang/sdk/issues/39852
    //assertEdge(decoratedTypeAnnotation('Foo>').node, never, hard: true);
    assertEdge(
        inSet(alwaysPlus),
        substitutionNode(decoratedTypeAnnotation('R>').node,
            decoratedTypeAnnotation('T x').node),
        hard: false);
  }

  Future<void> test_type_parameterized_migrated_bound_class() async {
    await analyze('''
import 'dart:math';
void f(Point<int> x) {}
''');
    var pointClass =
        findNode.typeName('Point').name.staticElement as ClassElement;
    var pointBound =
        variables.decoratedTypeParameterBound(pointClass.typeParameters[0]);
    _assertType(pointBound.type, 'num');
    assertEdge(decoratedTypeAnnotation('int>').node, pointBound.node,
        hard: true);
  }

  Future<void> test_type_parameterized_migrated_bound_dynamic() async {
    await analyze('''
void f(List<int> x) {}
''');
    var listClass = typeProvider.listElement;
    var listBound =
        variables.decoratedTypeParameterBound(listClass.typeParameters[0]);
    _assertType(listBound.type, 'dynamic');
    assertEdge(decoratedTypeAnnotation('int>').node, listBound.node,
        hard: true);
  }

  Future<void> test_typedef_rhs_not_linked_to_usage() async {
    await analyze('''
typedef F = void Function();
F f;
''');
    var rhs = decoratedGenericFunctionTypeAnnotation('void Function()');
    var usage = decoratedTypeAnnotation('F f');
    assertNoEdge(rhs.node, usage.node);
  }

  Future<void> test_typeName_class() async {
    await analyze('''
class C {}
Type f() => C;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  Future<void> test_typeName_from_sdk() async {
    await analyze('''
Type f() {
  return int;
}
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  Future<void> test_typeName_from_sdk_prefixed() async {
    await analyze('''
import 'dart:async' as a;
Type f() => a.Future;
''');
    assertEdge(inSet(neverClosure), decoratedTypeAnnotation('Type').node,
        hard: false);
  }

  Future<void> test_typeName_functionTypeAlias() async {
    await analyze('''
typedef void F();
Type f() => F;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  Future<void> test_typeName_genericTypeAlias() async {
    await analyze('''
typedef F = void Function();
Type f() => F;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  Future<void> test_typeName_mixin() async {
    await analyze('''
mixin M {}
Type f() => M;
''');
    assertNoUpstreamNullability(decoratedTypeAnnotation('Type').node);
  }

  Future<void> test_typeName_with_bound() async {
    await analyze('''
class C<T extends Object> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var cBound = decoratedTypeAnnotation('Object');
    assertEdge(cType.typeArguments[0].node, cBound.node, hard: true);
  }

  Future<void> test_typeName_with_bound_function_type() async {
    await analyze('''
class C<T extends int Function()> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var cBound = decoratedGenericFunctionTypeAnnotation('int Function()');
    assertEdge(cType.typeArguments[0].node, cBound.node, hard: true);
    assertEdge(cType.typeArguments[0].returnType.node, cBound.returnType.node,
        hard: true);
  }

  Future<void> test_typeName_with_bounds() async {
    await analyze('''
class C<T extends Object, U extends Object> {}
void f(C c) {}
''');
    var cType = decoratedTypeAnnotation('C c');
    var tBound = decoratedTypeAnnotation('Object,');
    var uBound = decoratedTypeAnnotation('Object>');
    assertEdge(cType.typeArguments[0].node, tBound.node, hard: true);
    assertEdge(cType.typeArguments[1].node, uBound.node, hard: true);
  }

  Future<void> test_variableDeclaration() async {
    await analyze('''
void f(int i) {
  int j = i;
}
''');
    assertEdge(decoratedTypeAnnotation('int i').node,
        decoratedTypeAnnotation('int j').node,
        hard: true);
  }

  void _assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
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
    if (class_.name == 'List' && superclass.name == 'Iterable') {
      return DecoratedType(
        superclass.instantiate(
          typeArguments: [type.typeArguments[0].type],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        type.node,
        typeArguments: [type.typeArguments[0]],
      );
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

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestEdgeOrigin implements EdgeOrigin {
  const _TestEdgeOrigin();

  @override
  CodeReference get codeReference => null;

  @override
  String get description => 'Test edge';

  @override
  EdgeOriginKind get kind => null;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
