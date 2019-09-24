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
import 'package:nnbd_migration/src/already_migrated_code_decorator.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AlreadyMigratedCodeDecoratorTest);
  });
}

@reflectiveTest
class _AlreadyMigratedCodeDecoratorTest {
  final TypeProvider typeProvider;

  final AlreadyMigratedCodeDecorator decorator;

  final NullabilityGraphForTesting graph;

  factory _AlreadyMigratedCodeDecoratorTest() {
    return _AlreadyMigratedCodeDecoratorTest._(
        NullabilityGraphForTesting(), TestTypeProvider());
  }

  _AlreadyMigratedCodeDecoratorTest._(this.graph, this.typeProvider)
      : decorator = AlreadyMigratedCodeDecorator(graph, typeProvider);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  void checkDynamic(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.dynamicType));
    expect(decoratedType.node, same(always));
  }

  void checkFutureOr(
      DecoratedType decoratedType,
      NullabilityNode expectedNullability,
      void Function(DecoratedType) checkArgument) {
    expect(decoratedType.type.element, typeProvider.futureOrElement);
    expect(decoratedType.node, expectedNullability);
    checkArgument(decoratedType.typeArguments[0]);
  }

  void checkInt(
      DecoratedType decoratedType, NullabilityNode expectedNullability) {
    expect(decoratedType.type.element, typeProvider.intType.element);
    expect(decoratedType.node, expectedNullability);
  }

  void checkIterable(
      DecoratedType decoratedType,
      NullabilityNode expectedNullability,
      void Function(DecoratedType) checkArgument) {
    expect(
        decoratedType.type.element, typeProvider.iterableDynamicType.element);
    expect(decoratedType.node, expectedNullability);
    checkArgument(decoratedType.typeArguments[0]);
  }

  void checkNum(
      DecoratedType decoratedType, NullabilityNode expectedNullability) {
    expect(decoratedType.type.element, typeProvider.numType.element);
    expect(decoratedType.node, expectedNullability);
  }

  void checkObject(
      DecoratedType decoratedType, NullabilityNode expectedNullability) {
    expect(decoratedType.type.element, typeProvider.objectType.element);
    expect(decoratedType.node, expectedNullability);
  }

  void checkTypeParameter(
      DecoratedType decoratedType,
      NullabilityNode expectedNullability,
      TypeParameterElement expectedElement) {
    var type = decoratedType.type as TypeParameterTypeImpl;
    expect(type.element, same(expectedElement));
    expect(decoratedType.node, expectedNullability);
  }

  void checkVoid(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.voidType));
    expect(decoratedType.node, same(always));
  }

  DecoratedType decorate(DartType type) {
    var decoratedType = decorator.decorate(type);
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
        TypeParameterTypeImpl(typeFormal), [typeFormal], []));
    expect(decoratedType.typeFormalBounds, hasLength(1));
    checkNum(decoratedType.typeFormalBounds[0], never);
    checkTypeParameter(decoratedType.returnType, never, typeFormal);
  }

  test_decorate_functionType_generic_no_explicit_bound() {
    var typeFormal = TypeParameterElementImpl.synthetic('T');
    var decoratedType = decorate(FunctionTypeImpl.synthetic(
        TypeParameterTypeImpl(typeFormal), [typeFormal], []));
    expect(decoratedType.typeFormalBounds, hasLength(1));
    checkObject(decoratedType.typeFormalBounds[0], always);
    checkTypeParameter(decoratedType.returnType, never, typeFormal);
  }

  test_decorate_functionType_named_parameter() {
    checkDynamic(
        decorate(FunctionTypeImpl.synthetic(typeProvider.voidType, [], [
      ParameterElementImpl.synthetic(
          'x', typeProvider.dynamicType, ParameterKind.NAMED)
    ])).namedParameters['x']);
  }

  test_decorate_functionType_ordinary_parameter() {
    checkDynamic(
        decorate(FunctionTypeImpl.synthetic(typeProvider.voidType, [], [
      ParameterElementImpl.synthetic(
          'x', typeProvider.dynamicType, ParameterKind.REQUIRED)
    ])).positionalParameters[0]);
  }

  test_decorate_functionType_positional_parameter() {
    checkDynamic(
        decorate(FunctionTypeImpl.synthetic(typeProvider.voidType, [], [
      ParameterElementImpl.synthetic(
          'x', typeProvider.dynamicType, ParameterKind.POSITIONAL)
    ])).positionalParameters[0]);
  }

  test_decorate_functionType_question() {
    expect(
        decorate(FunctionTypeImpl.synthetic(typeProvider.voidType, [], [],
                nullabilitySuffix: NullabilitySuffix.question))
            .node,
        same(always));
  }

  test_decorate_functionType_returnType() {
    checkDynamic(
        decorate(FunctionTypeImpl.synthetic(typeProvider.dynamicType, [], []))
            .returnType);
  }

  test_decorate_functionType_star() {
    expect(
        decorate(FunctionTypeImpl.synthetic(typeProvider.voidType, [], [],
                nullabilitySuffix: NullabilitySuffix.star))
            .node,
        same(never));
  }

  test_decorate_interfaceType_simple_question() {
    checkInt(
        decorate(InterfaceTypeImpl(typeProvider.intType.element,
            nullabilitySuffix: NullabilitySuffix.question)),
        always);
  }

  test_decorate_interfaceType_simple_star() {
    checkInt(
        decorate(InterfaceTypeImpl(typeProvider.intType.element,
            nullabilitySuffix: NullabilitySuffix.star)),
        never);
  }

  test_decorate_iterable_dynamic() {
    var decorated = decorate(typeProvider.iterableDynamicType);
    checkIterable(decorated, never, checkDynamic);
  }

  test_decorate_typeParameterType_question() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(element,
            nullabilitySuffix: NullabilitySuffix.question)),
        always,
        element);
  }

  test_decorate_typeParameterType_star() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(element,
            nullabilitySuffix: NullabilitySuffix.star)),
        never,
        element);
  }

  test_decorate_void() {
    checkVoid(decorate(typeProvider.voidType));
  }

  test_getImmediateSupertypes_future() {
    var element = typeProvider.futureElement;
    var decoratedSupertypes =
        decorator.getImmediateSupertypes(element).toList();
    var typeParam = element.typeParameters[0];
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], never);
    // Since Future<T> is a subtype of FutureOr<T>, we consider FutureOr<T> to
    // be an immediate supertype, even though the class declaration for Future
    // doesn't mention FutureOr.
    checkFutureOr(decoratedSupertypes[1], never,
        (t) => checkTypeParameter(t, never, typeParam));
  }

  test_getImmediateSupertypes_generic() {
    var t = ElementFactory.typeParameterElement('T');
    var class_ = ElementFactory.classElement3(
      name: 'C',
      typeParameters: [t],
      supertype: typeProvider.iterableType2(
        t.instantiate(nullabilitySuffix: NullabilitySuffix.star),
      ),
    );
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkIterable(decoratedSupertypes[0], never,
        (type) => checkTypeParameter(type, never, t));
  }

  test_getImmediateSupertypes_interface() {
    var class_ = ElementFactory.classElement('C', typeProvider.objectType);
    class_.interfaces = [typeProvider.numType];
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], never);
    checkNum(decoratedSupertypes[1], never);
  }

  test_getImmediateSupertypes_mixin() {
    var class_ = ElementFactory.classElement('C', typeProvider.objectType);
    class_.mixins = [typeProvider.numType];
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], never);
    checkNum(decoratedSupertypes[1], never);
  }

  test_getImmediateSupertypes_superclassConstraint() {
    var class_ = ElementFactory.mixinElement(
        name: 'C', constraints: [typeProvider.numType]);
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkNum(decoratedSupertypes[0], never);
  }

  test_getImmediateSupertypes_supertype() {
    var class_ = ElementFactory.classElement('C', typeProvider.objectType);
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkObject(decoratedSupertypes[0], never);
  }
}
