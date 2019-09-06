// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
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
    return _AlreadyMigratedCodeDecoratorTest._(NullabilityGraphForTesting());
  }

  _AlreadyMigratedCodeDecoratorTest._(this.graph)
      : typeProvider = TestTypeProvider(),
        decorator = AlreadyMigratedCodeDecorator(graph);

  void checkDynamic(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.dynamicType));
    expect(decoratedType.node, same(graph.always));
  }

  void checkInt(DecoratedType decoratedType) {
    expect(decoratedType.type, typeProvider.intType);
    expect(decoratedType.node, same(graph.never));
  }

  void checkTypeParameter(
      DecoratedType decoratedType, TypeParameterElementImpl expectedElement) {
    var type = decoratedType.type as TypeParameterTypeImpl;
    expect(type.element, same(expectedElement));
    expect(decoratedType.node, same(graph.never));
  }

  void checkVoid(DecoratedType decoratedType) {
    expect(decoratedType.type, same(typeProvider.voidType));
    expect(decoratedType.node, same(graph.always));
  }

  DecoratedType decorate(DartType type) {
    var decoratedType = decorator.decorate(type);
    expect(decoratedType.type, same(type));
    return decoratedType;
  }

  test_decorate_dynamic() {
    checkDynamic(decorate(typeProvider.dynamicType));
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
        same(graph.never));
  }

  test_decorate_interfaceType_simple_star() {
    checkInt(decorate(InterfaceTypeImpl(typeProvider.intType.element,
        nullabilitySuffix: NullabilitySuffix.star)));
  }

  test_decorate_typeParameterType_star() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(element,
            nullabilitySuffix: NullabilitySuffix.star)),
        element);
  }

  test_decorate_void() {
    checkVoid(decorate(typeProvider.voidType));
  }
}
