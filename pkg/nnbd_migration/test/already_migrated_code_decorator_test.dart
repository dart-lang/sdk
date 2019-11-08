// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/already_migrated_code_decorator.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AlreadyMigratedCodeDecoratorTest);
  });
}

@reflectiveTest
class _AlreadyMigratedCodeDecoratorTest extends Object with EdgeTester {
  final TypeProvider typeProvider;

  final AlreadyMigratedCodeDecorator decorator;

  final NullabilityGraphForTesting graph;

  Element element = _MockElement();

  factory _AlreadyMigratedCodeDecoratorTest() {
    return _AlreadyMigratedCodeDecoratorTest._(
        NullabilityGraphForTesting(), TestTypeProvider());
  }

  _AlreadyMigratedCodeDecoratorTest._(this.graph, this.typeProvider)
      : decorator = AlreadyMigratedCodeDecorator(graph, typeProvider);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  void checkAlwaysNullable(NullabilityNode node) {
    var edge = assertEdge(always, node, hard: false);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alwaysNullableType);
    expect(origin.element, same(element));
  }

  void checkDynamic(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.dynamicType));
    checkAlwaysNullable(decoratedType.node);
  }

  void checkExplicitlyNonNullable(NullabilityNode node) {
    var edge = assertEdge(node, never, hard: true);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
  }

  void checkExplicitlyNullable(NullabilityNode node) {
    var edge = assertEdge(always, node, hard: false);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
  }

  void checkFutureOr(
      DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability,
      void Function(DecoratedType) checkArgument) {
    expect(decoratedType.type.element, typeProvider.futureOrElement);
    checkNullability(decoratedType.node);
    checkArgument(decoratedType.typeArguments[0]);
  }

  void checkInt(DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability) {
    expect(decoratedType.type.element, typeProvider.intType.element);
    checkNullability(decoratedType.node);
  }

  void checkIterable(
      DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability,
      void Function(DecoratedType) checkArgument) {
    expect(
        decoratedType.type.element, typeProvider.iterableDynamicType.element);
    checkNullability(decoratedType.node);
    checkArgument(decoratedType.typeArguments[0]);
  }

  void checkNum(DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability) {
    expect(decoratedType.type.element, typeProvider.numType.element);
    checkNullability(decoratedType.node);
  }

  void checkObject(DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability) {
    expect(decoratedType.type.element, typeProvider.objectType.element);
    checkNullability(decoratedType.node);
  }

  void checkTypeParameter(
      DecoratedType decoratedType,
      void Function(NullabilityNode) checkNullability,
      TypeParameterElement expectedElement) {
    var type = decoratedType.type as TypeParameterTypeImpl;
    expect(type.element, same(expectedElement));
    checkNullability(decoratedType.node);
  }

  void checkVoid(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.voidType));
    checkAlwaysNullable(decoratedType.node);
  }

  DecoratedType decorate(DartType type) {
    var decoratedType = decorator.decorate(type, element);
    expect(decoratedType.type, same(type));
    return decoratedType;
  }

  test_decorate_dynamic() {
    checkDynamic(decorate(typeProvider.dynamicType));
  }

  test_decorate_functionType_generic_bounded() {
    var typeFormal = TypeParameterElementImpl.synthetic('T')
      ..bound = typeProvider.numType;
    var decoratedType = decorate(FunctionTypeImpl.synthetic(
        TypeParameterTypeImpl(typeFormal), [typeFormal], [],
        nullabilitySuffix: NullabilitySuffix.star));
    expect(decoratedType.typeFormalBounds, hasLength(1));
    checkNum(decoratedType.typeFormalBounds[0], checkExplicitlyNonNullable);
    checkTypeParameter(
        decoratedType.returnType, checkExplicitlyNonNullable, typeFormal);
  }

  test_decorate_functionType_generic_no_explicit_bound() {
    var typeFormal = TypeParameterElementImpl.synthetic('T');
    var decoratedType = decorate(FunctionTypeImpl.synthetic(
        TypeParameterTypeImpl(typeFormal), [typeFormal], [],
        nullabilitySuffix: NullabilitySuffix.star));
    expect(decoratedType.typeFormalBounds, hasLength(1));
    checkObject(decoratedType.typeFormalBounds[0], checkExplicitlyNullable);
    checkTypeParameter(
        decoratedType.returnType, checkExplicitlyNonNullable, typeFormal);
  }

  test_decorate_functionType_named_parameter() {
    checkDynamic(decorate(FunctionTypeImpl.synthetic(
            typeProvider.voidType,
            [],
            [
              ParameterElementImpl.synthetic(
                  'x', typeProvider.dynamicType, ParameterKind.NAMED)
            ],
            nullabilitySuffix: NullabilitySuffix.star))
        .namedParameters['x']);
  }

  test_decorate_functionType_ordinary_parameter() {
    checkDynamic(decorate(FunctionTypeImpl.synthetic(
            typeProvider.voidType,
            [],
            [
              ParameterElementImpl.synthetic(
                  'x', typeProvider.dynamicType, ParameterKind.REQUIRED)
            ],
            nullabilitySuffix: NullabilitySuffix.star))
        .positionalParameters[0]);
  }

  test_decorate_functionType_positional_parameter() {
    checkDynamic(decorate(FunctionTypeImpl.synthetic(
            typeProvider.voidType,
            [],
            [
              ParameterElementImpl.synthetic(
                  'x', typeProvider.dynamicType, ParameterKind.POSITIONAL)
            ],
            nullabilitySuffix: NullabilitySuffix.star))
        .positionalParameters[0]);
  }

  test_decorate_functionType_question() {
    checkExplicitlyNullable(decorate(FunctionTypeImpl.synthetic(
            typeProvider.voidType, [], [],
            nullabilitySuffix: NullabilitySuffix.question))
        .node);
  }

  test_decorate_functionType_returnType() {
    checkDynamic(decorate(FunctionTypeImpl.synthetic(
            typeProvider.dynamicType, [], [],
            nullabilitySuffix: NullabilitySuffix.star))
        .returnType);
  }

  test_decorate_functionType_star() {
    checkExplicitlyNonNullable(decorate(FunctionTypeImpl.synthetic(
            typeProvider.voidType, [], [],
            nullabilitySuffix: NullabilitySuffix.star))
        .node);
  }

  test_decorate_interfaceType_simple_question() {
    checkInt(
        decorate(InterfaceTypeImpl(typeProvider.intType.element,
            nullabilitySuffix: NullabilitySuffix.question)),
        checkExplicitlyNullable);
  }

  test_decorate_interfaceType_simple_star() {
    checkInt(
        decorate(InterfaceTypeImpl(typeProvider.intType.element,
            nullabilitySuffix: NullabilitySuffix.star)),
        checkExplicitlyNonNullable);
  }

  test_decorate_iterable_dynamic() {
    var decorated = decorate(typeProvider.iterableDynamicType);
    checkIterable(decorated, checkExplicitlyNonNullable, checkDynamic);
  }

  test_decorate_typeParameterType_question() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(element,
            nullabilitySuffix: NullabilitySuffix.question)),
        checkExplicitlyNullable,
        element);
  }

  test_decorate_typeParameterType_star() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(element,
            nullabilitySuffix: NullabilitySuffix.star)),
        checkExplicitlyNonNullable,
        element);
  }

  test_decorate_void() {
    checkVoid(decorate(typeProvider.voidType));
  }

  test_getImmediateSupertypes_future() {
    var class_ = element = typeProvider.futureElement;
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    var typeParam = class_.typeParameters[0];
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable);
    // Since Future<T> is a subtype of FutureOr<T>, we consider FutureOr<T> to
    // be an immediate supertype, even though the class declaration for Future
    // doesn't mention FutureOr.
    checkFutureOr(decoratedSupertypes[1], checkExplicitlyNonNullable,
        (t) => checkTypeParameter(t, checkExplicitlyNonNullable, typeParam));
  }

  test_getImmediateSupertypes_generic() {
    var t = ElementFactory.typeParameterElement('T');
    var class_ = element = ElementFactory.classElement3(
      name: 'C',
      typeParameters: [t],
      supertype: typeProvider.iterableType2(
        t.instantiate(nullabilitySuffix: NullabilitySuffix.star),
      ),
    );
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkIterable(decoratedSupertypes[0], checkExplicitlyNonNullable,
        (type) => checkTypeParameter(type, checkExplicitlyNonNullable, t));
  }

  test_getImmediateSupertypes_interface() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    class_.interfaces = [typeProvider.numType];
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable);
    checkNum(decoratedSupertypes[1], checkExplicitlyNonNullable);
  }

  test_getImmediateSupertypes_mixin() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    class_.mixins = [typeProvider.numType];
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable);
    checkNum(decoratedSupertypes[1], checkExplicitlyNonNullable);
  }

  test_getImmediateSupertypes_superclassConstraint() {
    var class_ = element = ElementFactory.mixinElement(
        name: 'C', constraints: [typeProvider.numType]);
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkNum(decoratedSupertypes[0], checkExplicitlyNonNullable);
  }

  test_getImmediateSupertypes_supertype() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable);
  }
}

class _MockElement implements Element {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
