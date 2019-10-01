// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DecoratedTypeTest);
  });
}

@reflectiveTest
class DecoratedTypeTest extends Object
    with DecoratedTypeTester
    implements DecoratedTypeTesterBase {
  final graph = NullabilityGraph();

  final TypeProvider typeProvider;

  factory DecoratedTypeTest() {
    var typeProvider = TestTypeProvider();
    return DecoratedTypeTest._(typeProvider);
  }

  DecoratedTypeTest._(this.typeProvider);

  NullabilityNode get always => graph.always;

  ClassElement get listElement => typeProvider.listElement;

  void assertDartType(DartType type, String expected) {
    // Note: by default DartType.toString doesn't print nullability suffixes,
    // so we have to override that behavior in order to make sure the
    // nullability suffixes are correct.
    expect((type as TypeImpl).toString(withNullability: true), expected);
  }

  void setUp() {
    NullabilityNode.clearDebugNames();
  }

  test_equal_dynamic_and_void() {
    expect(dynamic_ == dynamic_, isTrue);
    expect(dynamic_ == void_, isFalse);
    expect(void_ == dynamic_, isFalse);
    expect(void_ == void_, isTrue);
  }

  test_equal_functionType_different_nodes() {
    var returnType = int_();
    expect(
        function(returnType, node: newNode()) ==
            function(returnType, node: newNode()),
        isFalse);
  }

  test_equal_functionType_named_different_names() {
    var node = newNode();
    var argType = int_();
    expect(
        function(dynamic_, named: {'x': argType}, node: node) ==
            function(dynamic_, named: {'y': argType}, node: node),
        isFalse);
  }

  test_equal_functionType_named_different_types() {
    var node = newNode();
    expect(
        function(dynamic_, named: {'x': int_()}, node: node) ==
            function(dynamic_, named: {'x': int_()}, node: node),
        isFalse);
  }

  test_equal_functionType_named_extra() {
    var node = newNode();
    var argType = int_();
    var t1 = function(dynamic_, named: {'x': argType}, node: node);
    var t2 = function(dynamic_, node: node);
    expect(t1 == t2, isFalse);
    expect(t2 == t1, isFalse);
  }

  test_equal_functionType_named_same() {
    var node = newNode();
    var argType = int_();
    expect(
        function(dynamic_, named: {'x': argType}, node: node) ==
            function(dynamic_, named: {'x': argType}, node: node),
        isTrue);
  }

  test_equal_functionType_positional_different() {
    var node = newNode();
    expect(
        function(dynamic_, positional: [int_()], node: node) ==
            function(dynamic_, positional: [int_()], node: node),
        isFalse);
  }

  test_equal_functionType_positional_same() {
    var node = newNode();
    var argType = int_();
    expect(
        function(dynamic_, positional: [argType], node: node) ==
            function(dynamic_, positional: [argType], node: node),
        isTrue);
  }

  test_equal_functionType_required_different() {
    var node = newNode();
    expect(
        function(dynamic_, required: [int_()], node: node) ==
            function(dynamic_, required: [int_()], node: node),
        isFalse);
  }

  test_equal_functionType_required_same() {
    var node = newNode();
    var argType = int_();
    expect(
        function(dynamic_, required: [argType], node: node) ==
            function(dynamic_, required: [argType], node: node),
        isTrue);
  }

  test_equal_functionType_required_vs_positional() {
    var node = newNode();
    var argType = int_();
    expect(
        function(dynamic_, required: [argType], node: node) ==
            function(dynamic_, positional: [argType], node: node),
        isFalse);
  }

  test_equal_functionType_return_different() {
    var node = newNode();
    expect(
        function(int_(), node: node) == function(int_(), node: node), isFalse);
  }

  test_equal_functionType_return_same() {
    var node = newNode();
    var returnType = int_();
    expect(function(returnType, node: node) == function(returnType, node: node),
        isTrue);
  }

  test_equal_functionType_typeFormals_different_bounds() {
    var n1 = newNode();
    var n2 = newNode();
    var t = typeParameter('T', object());
    var u = typeParameter('U', int_());
    expect(
        function(typeParameterType(t, node: n1), typeFormals: [t], node: n2) ==
            function(typeParameterType(u, node: n1),
                typeFormals: [u], node: n2),
        isFalse);
  }

  test_equal_functionType_typeFormals_equivalent_bounds_after_substitution() {
    var n1 = newNode();
    var n2 = newNode();
    var n3 = newNode();
    var n4 = newNode();
    var bound = object();
    var t = typeParameter('T', bound);
    var u = typeParameter('U', typeParameterType(t, node: n1));
    var v = typeParameter('V', bound);
    var w = typeParameter('W', typeParameterType(v, node: n1));
    expect(
        function(void_,
                typeFormals: [t, u],
                required: [
                  typeParameterType(t, node: n2),
                  typeParameterType(u, node: n3)
                ],
                node: n4) ==
            function(void_,
                typeFormals: [v, w],
                required: [
                  typeParameterType(v, node: n2),
                  typeParameterType(w, node: n3)
                ],
                node: n4),
        isTrue);
  }

  test_equal_functionType_typeFormals_same_bounds_named() {
    var n1 = newNode();
    var n2 = newNode();
    var bound = object();
    var t = typeParameter('T', bound);
    var u = typeParameter('U', bound);
    expect(
        function(void_,
                typeFormals: [t],
                named: {'x': typeParameterType(t, node: n1)},
                node: n2) ==
            function(void_,
                typeFormals: [u],
                named: {'x': typeParameterType(u, node: n1)},
                node: n2),
        isTrue);
  }

  test_equal_functionType_typeFormals_same_bounds_positional() {
    var n1 = newNode();
    var n2 = newNode();
    var bound = object();
    var t = typeParameter('T', bound);
    var u = typeParameter('U', bound);
    expect(
        function(void_,
                typeFormals: [t],
                positional: [typeParameterType(t, node: n1)],
                node: n2) ==
            function(void_,
                typeFormals: [u],
                positional: [typeParameterType(u, node: n1)],
                node: n2),
        isTrue);
  }

  test_equal_functionType_typeFormals_same_bounds_required() {
    var n1 = newNode();
    var n2 = newNode();
    var bound = object();
    var t = typeParameter('T', bound);
    var u = typeParameter('U', bound);
    expect(
        function(void_,
                typeFormals: [t],
                required: [typeParameterType(t, node: n1)],
                node: n2) ==
            function(void_,
                typeFormals: [u],
                required: [typeParameterType(u, node: n1)],
                node: n2),
        isTrue);
  }

  test_equal_functionType_typeFormals_same_bounds_return() {
    var n1 = newNode();
    var n2 = newNode();
    var bound = object();
    var t = typeParameter('T', bound);
    var u = typeParameter('U', bound);
    expect(
        function(typeParameterType(t, node: n1), typeFormals: [t], node: n2) ==
            function(typeParameterType(u, node: n1),
                typeFormals: [u], node: n2),
        isTrue);
  }

  test_equal_functionType_typeFormals_same_parameters() {
    var n1 = newNode();
    var n2 = newNode();
    var t = typeParameter('T', object());
    expect(
        function(typeParameterType(t, node: n1), typeFormals: [t], node: n2) ==
            function(typeParameterType(t, node: n1),
                typeFormals: [t], node: n2),
        isTrue);
  }

  test_equal_interfaceType_different_args() {
    var node = newNode();
    expect(list(int_(), node: node) == list(int_(), node: node), isFalse);
  }

  test_equal_interfaceType_different_classes() {
    var node = newNode();
    expect(int_(node: node) == object(node: node), isFalse);
  }

  test_equal_interfaceType_different_nodes() {
    expect(int_() == int_(), isFalse);
  }

  test_equal_interfaceType_same() {
    var node = newNode();
    expect(int_(node: node) == int_(node: node), isTrue);
  }

  test_equal_interfaceType_same_generic() {
    var argType = int_();
    var node = newNode();
    expect(list(argType, node: node) == list(argType, node: node), isTrue);
  }

  test_toFinalType_bottom_non_nullable() {
    var type =
        DecoratedType(BottomTypeImpl.instance, never).toFinalType(typeProvider);
    assertDartType(type, 'Never');
  }

  test_toFinalType_bottom_nullable() {
    var type = DecoratedType(BottomTypeImpl.instance, always)
        .toFinalType(typeProvider);
    assertDartType(type, 'Null');
  }

  test_toFinalType_dynamic() {
    var type = dynamic_.toFinalType(typeProvider);
    assertDartType(type, 'dynamic');
  }

  test_toFinalType_function_generic_substitute_bounds() {
    var u = typeParameter('U', object(node: never));
    var t = typeParameter(
        'T', list(typeParameterType(u, node: never), node: never));
    var v = typeParameter(
        'V', list(typeParameterType(u, node: never), node: never));
    var type = function(dynamic_, typeFormals: [t, u, v], node: never)
        .toFinalType(typeProvider) as FunctionType;
    assertDartType(
        type,
        'dynamic Function<T extends List<U>,U extends Object,'
        'V extends List<U>>()');
    expect(type.typeFormals[0], isNot(same(t)));
    expect(type.typeFormals[1], isNot(same(u)));
    expect(type.typeFormals[2], isNot(same(v)));
    expect(
        ((type.typeFormals[0].bound as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[1]));
    expect(
        ((type.typeFormals[2].bound as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[1]));
  }

  test_toFinalType_function_generic_substitute_named() {
    var t = typeParameter('T', object(node: never));
    var type = function(dynamic_,
            typeFormals: [t],
            named: {'x': list(typeParameterType(t, node: never), node: never)},
            node: never)
        .toFinalType(typeProvider) as FunctionType;
    assertDartType(type, 'dynamic Function<T extends Object>({x: List<T>})');
    expect(type.typeFormals[0], isNot(same(t)));
    expect(
        ((type.parameters[0].type as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[0]));
  }

  test_toFinalType_function_generic_substitute_optional() {
    var t = typeParameter('T', object(node: never));
    var type = function(dynamic_,
            typeFormals: [t],
            positional: [list(typeParameterType(t, node: never), node: never)],
            node: never)
        .toFinalType(typeProvider) as FunctionType;
    assertDartType(type, 'dynamic Function<T extends Object>([List<T>])');
    expect(type.typeFormals[0], isNot(same(t)));
    expect(
        ((type.parameters[0].type as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[0]));
  }

  test_toFinalType_function_generic_substitute_required() {
    var t = typeParameter('T', object());
    var type = function(dynamic_,
            typeFormals: [t],
            required: [list(typeParameterType(t, node: never), node: never)],
            node: never)
        .toFinalType(typeProvider) as FunctionType;
    assertDartType(type, 'dynamic Function<T extends Object>(List<T>)');
    expect(type.typeFormals[0], isNot(same(t)));
    expect(
        ((type.parameters[0].type as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[0]));
  }

  test_toFinalType_function_generic_substitute_return_type() {
    var t = typeParameter('T', object(node: never));
    var type = function(list(typeParameterType(t, node: never), node: never),
            typeFormals: [t], node: never)
        .toFinalType(typeProvider) as FunctionType;
    assertDartType(type, 'List<T> Function<T extends Object>()');
    expect(type.typeFormals[0], isNot(same(t)));
    expect(
        ((type.returnType as InterfaceType).typeArguments[0]
                as TypeParameterType)
            .element,
        same(type.typeFormals[0]));
  }

  test_toFinalType_function_named_parameter_non_nullable() {
    var xType = int_(node: never);
    var type = function(dynamic_, named: {'x': xType}, node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function({x: int})');
  }

  test_toFinalType_function_named_parameter_nullable() {
    var xType = int_(node: always);
    var type = function(dynamic_, named: {'x': xType}, node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function({x: int?})');
  }

  test_toFinalType_function_non_nullable() {
    var type = function(dynamic_, node: never).toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function()');
  }

  test_toFinalType_function_nullable() {
    var type = function(dynamic_, node: always).toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function()?');
  }

  test_toFinalType_function_optional_parameter_non_nullable() {
    var argType = int_(node: never);
    var type = function(dynamic_, positional: [argType], node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function([int])');
  }

  test_toFinalType_function_optional_parameter_nullable() {
    var argType = int_(node: always);
    var type = function(dynamic_, positional: [argType], node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function([int?])');
  }

  test_toFinalType_function_required_parameter_non_nullable() {
    var argType = int_(node: never);
    var type = function(dynamic_, required: [argType], node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function(int)');
  }

  test_toFinalType_function_required_parameter_nullable() {
    var argType = int_(node: always);
    var type = function(dynamic_, required: [argType], node: never)
        .toFinalType(typeProvider);
    assertDartType(type, 'dynamic Function(int?)');
  }

  test_toFinalType_function_return_type_non_nullable() {
    var returnType = int_(node: never);
    var type = function(returnType, node: never).toFinalType(typeProvider);
    assertDartType(type, 'int Function()');
  }

  test_toFinalType_function_return_type_nullable() {
    var returnType = int_(node: always);
    var type = function(returnType, node: never).toFinalType(typeProvider);
    assertDartType(type, 'int? Function()');
  }

  test_toFinalType_interface_non_nullable() {
    var type = int_(node: never).toFinalType(typeProvider);
    assertDartType(type, 'int');
  }

  test_toFinalType_interface_nullable() {
    var type = int_(node: always).toFinalType(typeProvider);
    assertDartType(type, 'int?');
  }

  test_toFinalType_interface_type_argument_non_nullable() {
    var argType = int_(node: never);
    var type = list(argType, node: never).toFinalType(typeProvider);
    assertDartType(type, 'List<int>');
  }

  test_toFinalType_interface_type_argument_nullable() {
    var argType = int_(node: always);
    var type = list(argType, node: never).toFinalType(typeProvider);
    assertDartType(type, 'List<int?>');
  }

  test_toFinalType_null_non_nullable() {
    var type = DecoratedType(null_.type, never).toFinalType(typeProvider);
    assertDartType(type, 'Never');
  }

  test_toFinalType_null_nullable() {
    var type = DecoratedType(null_.type, always).toFinalType(typeProvider);
    assertDartType(type, 'Null');
  }

  test_toFinalType_typeParameter_non_nullable() {
    var t = typeParameter('T', object(node: never));
    var type = typeParameterType(t, node: never).toFinalType(typeProvider);
    expect(type, TypeMatcher<TypeParameterType>());
    assertDartType(type, 'T');
  }

  test_toFinalType_typeParameter_nullable() {
    var t = typeParameter('T', object(node: never));
    var type = typeParameterType(t, node: always).toFinalType(typeProvider);
    expect(type, TypeMatcher<TypeParameterType>());
    assertDartType(type, 'T?');
  }

  test_toFinalType_void() {
    var type = void_.toFinalType(typeProvider);
    assertDartType(type, 'void');
  }

  test_toString_bottom() {
    var node = newNode();
    var decoratedType = DecoratedType(BottomTypeImpl.instance, node);
    expect(decoratedType.toString(), 'Never?($node)');
  }

  test_toString_interface_type_argument() {
    var argType = int_();
    var decoratedType = list(argType, node: always);
    expect(decoratedType.toString(), 'List<$argType>?');
  }

  test_toString_named_parameter() {
    var xType = int_();
    var decoratedType = function(dynamic_, named: {'x': xType}, node: always);
    expect(decoratedType.toString(), 'dynamic Function({x: $xType})?');
  }

  test_toString_normal_and_named_parameter() {
    var xType = int_();
    var yType = int_();
    var decoratedType = function(dynamic_,
        required: [xType], named: {'y': yType}, node: always);
    expect(decoratedType.toString(), 'dynamic Function($xType, {y: $yType})?');
  }

  test_toString_normal_and_optional_parameter() {
    var xType = int_();
    var yType = int_();
    var decoratedType = function(dynamic_,
        required: [xType], positional: [yType], node: always);
    expect(decoratedType.toString(), 'dynamic Function($xType, [$yType])?');
  }

  test_toString_normal_parameter() {
    var xType = int_();
    var decoratedType = function(dynamic_, required: [xType], node: always);
    expect(decoratedType.toString(), 'dynamic Function($xType)?');
  }

  test_toString_optional_parameter() {
    var xType = int_();
    var decoratedType = function(dynamic_, positional: [xType], node: always);
    expect(decoratedType.toString(), 'dynamic Function([$xType])?');
  }
}
