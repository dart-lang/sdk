// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/already_migrated_code_decorator.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AlreadyMigratedCodeDecoratorTestNormal);
    defineReflectiveTests(_AlreadyMigratedCodeDecoratorTestProvisional);
  });
}

class _AlreadyMigratedCodeDecoratorTestBase extends Object with EdgeTester {
  final TypeProvider typeProvider;

  final AlreadyMigratedCodeDecorator decorator;

  final NullabilityGraphForTesting graph;

  final NullabilitySuffix suffix;

  Element element = _MockElement();

  final decoratedTypeParameterBounds = DecoratedTypeParameterBounds();

  _AlreadyMigratedCodeDecoratorTestBase(NullabilitySuffix nullabilitySuffix)
      : this._(
          nullabilitySuffix,
          NullabilityGraphForTesting(),
          TestTypeProvider(),
        );

  _AlreadyMigratedCodeDecoratorTestBase._(
      this.suffix, this.graph, this.typeProvider)
      : decorator =
            AlreadyMigratedCodeDecorator(graph, typeProvider, _getLineInfo);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  void checkAlwaysNullable(NullabilityNode node, String displayName) {
    var edge = assertEdge(always, node, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alwaysNullableType);
    expect(origin.element, same(element));
    expect(node.displayName, displayName);
  }

  void checkDynamic(DecoratedType decoratedType, String displayName) {
    expect(decoratedType.type, same(typeProvider.dynamicType));
    checkAlwaysNullable(decoratedType.node, displayName);
  }

  void checkExplicitlyNonNullable(NullabilityNode node, String displayName) {
    var edge = assertEdge(node, never, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
    expect(node.displayName, displayName);
  }

  void checkExplicitlyNullable(NullabilityNode node, String displayName) {
    var edge = assertEdge(always, node, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge);
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
    expect(node.displayName, displayName);
  }

  void checkFutureOr(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      void Function(DecoratedType, String) checkArgument,
      String displayName) {
    expect(decoratedType.type.element, typeProvider.futureOrElement);
    checkNullability(decoratedType.node, displayName);
    checkArgument(
        decoratedType.typeArguments[0], 'type argument 0 of $displayName');
  }

  void checkInt(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      String displayName) {
    expect(decoratedType.type.element, typeProvider.intType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkIterable(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      void Function(DecoratedType, String) checkArgument,
      String displayName) {
    expect(
        decoratedType.type.element, typeProvider.iterableDynamicType.element);
    checkNullability(decoratedType.node, displayName);
    checkArgument(
        decoratedType.typeArguments[0], 'type argument 0 of $displayName');
  }

  void checkNever(DecoratedType decoratedType, String displayName) {
    expect(decoratedType.type, same(typeProvider.neverType));
    checkExplicitlyNonNullable(decoratedType.node, displayName);
  }

  void checkNum(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      String displayName) {
    expect(decoratedType.type.element, typeProvider.numType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkObject(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      String displayName) {
    expect(decoratedType.type.element, typeProvider.objectType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkTypeParameter(
      DecoratedType decoratedType,
      void Function(NullabilityNode, String) checkNullability,
      TypeParameterElement expectedElement,
      String displayName) {
    var type = decoratedType.type as TypeParameterTypeImpl;
    expect(type.element, same(expectedElement));
    checkNullability(decoratedType.node, displayName);
  }

  void checkVoid(DecoratedType decoratedType, String displayName) {
    expect(decoratedType.type, same(typeProvider.voidType));
    checkAlwaysNullable(decoratedType.node, displayName);
  }

  DecoratedType decorate(DartType type) {
    var decoratedType = decorator.decorate(
        type, element, NullabilityNodeTarget.text('test type'));
    expect(decoratedType.type, same(type));
    return decoratedType;
  }

  DecoratedType getDecoratedBound(TypeParameterElement element) =>
      decoratedTypeParameterBounds.get(element);

  void setUp() {
    DecoratedTypeParameterBounds.current = decoratedTypeParameterBounds;
  }

  void tearDown() {
    DecoratedTypeParameterBounds.current = null;
  }

  void test_decorate_dynamic() {
    checkDynamic(decorate(typeProvider.dynamicType), 'test type');
  }

  void test_decorate_functionType_generic_bounded() {
    var typeFormal = element = TypeParameterElementImpl.synthetic('T')
      ..bound = typeProvider.numType;
    var decoratedType = decorate(
      FunctionTypeImpl(
        typeFormals: [typeFormal],
        parameters: const [],
        returnType: TypeParameterTypeImpl(
          element: typeFormal,
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        nullabilitySuffix: suffix,
      ),
    );
    checkNum(getDecoratedBound(typeFormal), checkExplicitlyNonNullable,
        'bound of type formal T of test type');
    checkTypeParameter(decoratedType.returnType, checkExplicitlyNonNullable,
        typeFormal, 'return type of test type');
  }

  void test_decorate_functionType_generic_no_explicit_bound() {
    var typeFormal = element = TypeParameterElementImpl.synthetic('T');
    var decoratedType = decorate(
      FunctionTypeImpl(
        typeFormals: [typeFormal],
        parameters: const [],
        returnType: TypeParameterTypeImpl(
          element: typeFormal,
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        nullabilitySuffix: suffix,
      ),
    );
    checkObject(getDecoratedBound(typeFormal), checkExplicitlyNullable,
        'bound of type formal T of test type');
    checkTypeParameter(decoratedType.returnType, checkExplicitlyNonNullable,
        typeFormal, 'return type of test type');
  }

  void test_decorate_functionType_named_parameter() {
    checkDynamic(
        decorate(
          FunctionTypeImpl(
            typeFormals: const [],
            parameters: [
              ParameterElementImpl.synthetic(
                'x',
                typeProvider.dynamicType,
                ParameterKind.NAMED,
              )
            ],
            returnType: typeProvider.voidType,
            nullabilitySuffix: suffix,
          ),
        ).namedParameters['x'],
        'parameter x of test type');
  }

  void test_decorate_functionType_ordinary_parameters() {
    var decoratedType = decorate(
      FunctionTypeImpl(
        typeFormals: const [],
        parameters: [
          ParameterElementImpl.synthetic(
            'x',
            typeProvider.dynamicType,
            ParameterKind.REQUIRED,
          ),
          ParameterElementImpl.synthetic(
            'y',
            typeProvider.dynamicType,
            ParameterKind.REQUIRED,
          )
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: suffix,
      ),
    );
    checkDynamic(
        decoratedType.positionalParameters[0], 'parameter 0 of test type');
    checkDynamic(
        decoratedType.positionalParameters[1], 'parameter 1 of test type');
  }

  void test_decorate_functionType_positional_parameter() {
    checkDynamic(
        decorate(
          FunctionTypeImpl(
            typeFormals: const [],
            parameters: [
              ParameterElementImpl.synthetic(
                'x',
                typeProvider.dynamicType,
                ParameterKind.POSITIONAL,
              )
            ],
            returnType: typeProvider.voidType,
            nullabilitySuffix: suffix,
          ),
        ).positionalParameters[0],
        'parameter 0 of test type');
  }

  void test_decorate_functionType_question() {
    checkExplicitlyNullable(
        decorate(
          FunctionTypeImpl(
            typeFormals: const [],
            parameters: const [],
            returnType: typeProvider.voidType,
            nullabilitySuffix: NullabilitySuffix.question,
          ),
        ).node,
        'test type');
  }

  void test_decorate_functionType_returnType() {
    checkDynamic(
        decorate(
          FunctionTypeImpl(
            typeFormals: const [],
            parameters: const [],
            returnType: typeProvider.dynamicType,
            nullabilitySuffix: suffix,
          ),
        ).returnType,
        'return type of test type');
  }

  void test_decorate_functionType_star() {
    checkExplicitlyNonNullable(
        decorate(
          FunctionTypeImpl(
            typeFormals: const [],
            parameters: const [],
            returnType: typeProvider.voidType,
            nullabilitySuffix: suffix,
          ),
        ).node,
        'test type');
  }

  void test_decorate_interfaceType_parameters() {
    var decoratedType = decorate(InterfaceTypeImpl(
        element: typeProvider.mapElement,
        typeArguments: [typeProvider.intType, typeProvider.numType],
        nullabilitySuffix: suffix));
    checkInt(decoratedType.typeArguments[0], checkExplicitlyNonNullable,
        'type argument 0 of test type');
    checkNum(decoratedType.typeArguments[1], checkExplicitlyNonNullable,
        'type argument 1 of test type');
  }

  void test_decorate_interfaceType_simple_question() {
    checkInt(
        decorate(
          InterfaceTypeImpl(
            element: typeProvider.intElement,
            typeArguments: const [],
            nullabilitySuffix: NullabilitySuffix.question,
          ),
        ),
        checkExplicitlyNullable,
        'test type');
  }

  void test_decorate_interfaceType_simple_star() {
    checkInt(
        decorate(
          InterfaceTypeImpl(
            element: typeProvider.intElement,
            typeArguments: const [],
            nullabilitySuffix: suffix,
          ),
        ),
        checkExplicitlyNonNullable,
        'test type');
  }

  void test_decorate_iterable_dynamic() {
    var decorated = decorate(typeProvider.iterableDynamicType);
    checkIterable(
        decorated, checkExplicitlyNonNullable, checkDynamic, 'test type');
  }

  void test_decorate_never() {
    checkNever(decorate(typeProvider.neverType), 'test type');
  }

  void test_decorate_typeParameterType_question() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(TypeParameterTypeImpl(
            element: element, nullabilitySuffix: NullabilitySuffix.question)),
        checkExplicitlyNullable,
        element,
        'test type');
  }

  void test_decorate_typeParameterType_star() {
    var element = TypeParameterElementImpl.synthetic('T');
    checkTypeParameter(
        decorate(
            TypeParameterTypeImpl(element: element, nullabilitySuffix: suffix)),
        checkExplicitlyNonNullable,
        element,
        'test type');
  }

  void test_decorate_void() {
    checkVoid(decorate(typeProvider.voidType), 'test type');
  }

  void test_getImmediateSupertypes_future() {
    var class_ = element = typeProvider.futureElement;
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    var typeParam = class_.typeParameters[0];
    expect(decoratedSupertypes, hasLength(2));
    // Note: the bogus location `async:1:1` is because we're using a
    // TestTypeProvider.
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable,
        'Future (async:1:1)');
    // Since Future<T> is a subtype of FutureOr<T>, we consider FutureOr<T> to
    // be an immediate supertype, even though the class declaration for Future
    // doesn't mention FutureOr.
    // Note: the bogus location `async:1:1` is because we're using a
    // TestTypeProvider.
    checkFutureOr(
        decoratedSupertypes[1],
        checkExplicitlyNonNullable,
        (t, displayName) => checkTypeParameter(
            t, checkExplicitlyNonNullable, typeParam, displayName),
        'Future (async:1:1)');
  }

  void test_getImmediateSupertypes_generic() {
    var t = ElementFactory.typeParameterElement('T');
    var class_ = element = ElementFactory.classElement3(
      name: 'C',
      typeParameters: [t],
      supertype: typeProvider.iterableType2(
        t.instantiate(nullabilitySuffix: suffix),
      ),
    );
    class_.enclosingElement = ElementFactory.compilationUnit('test.dart');
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkIterable(
        decoratedSupertypes[0],
        checkExplicitlyNonNullable,
        (type, displayName) => checkTypeParameter(
            type, checkExplicitlyNonNullable, t, displayName),
        'C (test.dart:1:1)');
  }

  void test_getImmediateSupertypes_interface() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    class_.interfaces = [typeProvider.numType];
    class_.enclosingElement = ElementFactory.compilationUnit('test.dart');
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
    checkNum(decoratedSupertypes[1], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
  }

  void test_getImmediateSupertypes_mixin() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    class_.mixins = [typeProvider.numType];
    class_.enclosingElement = ElementFactory.compilationUnit('test.dart');
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
    checkNum(decoratedSupertypes[1], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
  }

  void test_getImmediateSupertypes_superclassConstraint() {
    var class_ = element = ElementFactory.mixinElement(
        name: 'C', constraints: [typeProvider.numType]);
    class_.enclosingElement = ElementFactory.compilationUnit('test.dart');
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    checkNum(decoratedSupertypes[0], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
  }

  void test_getImmediateSupertypes_supertype() {
    var class_ =
        element = ElementFactory.classElement('C', typeProvider.objectType);
    class_.enclosingElement = ElementFactory.compilationUnit('test.dart');
    var decoratedSupertypes = decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    // TODO(paulberry): displayName should be 'Object supertype of C'
    checkObject(decoratedSupertypes[0], checkExplicitlyNonNullable,
        'C (test.dart:1:1)');
  }

  static LineInfo _getLineInfo(String path) => LineInfo([0]);
}

/// Specialization of [_AlreadyMigratedCodeDecoratorTestBase] for testing the
/// situation where the already migrated code does not contain star types.  In
/// the final product, by definition all already-migrated code will be free of
/// star types.  However, since we do not yet migrate using a fully NNBD-aware
/// SDK, we need to handle both star and non-star variants on a short term
/// basis.
@reflectiveTest
class _AlreadyMigratedCodeDecoratorTestNormal
    extends _AlreadyMigratedCodeDecoratorTestBase {
  _AlreadyMigratedCodeDecoratorTestNormal() : super(NullabilitySuffix.none);
}

/// Specialization of [_AlreadyMigratedCodeDecoratorTestBase] for testing the
/// situation where the already migrated code contains star types.  In the final
/// product, this will never happen.  However, since we do not yet migrate using
/// a fully NNBD-aware SDK, we need to handle both star and non-star variants on
/// a short term basis.
@reflectiveTest
class _AlreadyMigratedCodeDecoratorTestProvisional
    extends _AlreadyMigratedCodeDecoratorTestBase {
  _AlreadyMigratedCodeDecoratorTestProvisional()
      : super(NullabilitySuffix.star);
}

class _MockElement implements Element {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
