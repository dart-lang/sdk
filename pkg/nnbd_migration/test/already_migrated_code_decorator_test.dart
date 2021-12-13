// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
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

class _AlreadyMigratedCodeDecoratorTestBase {
  final NullabilitySuffix suffix;

  final decoratedTypeParameterBounds = DecoratedTypeParameterBounds();

  _AlreadyMigratedCodeDecoratorTestBase(this.suffix);

  DecoratedType? getDecoratedBound(TypeParameterElement element) =>
      decoratedTypeParameterBounds.get(element);

  void setUp() {
    DecoratedTypeParameterBounds.current = decoratedTypeParameterBounds;
  }

  void tearDown() {
    DecoratedTypeParameterBounds.current = null;
  }

  Future<void> test_decorate_dynamic() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();
    withElement.checkDynamic(
        withElement.decorate(withElement.typeProvider.dynamicType),
        'test type');
  }

  Future<void> test_decorate_functionType_generic_bounded() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class A<T extends num> {}',
    );
    var typeFormal = withUnit.findElement.typeParameter('T');
    var withElement = withUnit.withElement(typeFormal);

    var decoratedType = withElement.decorate(
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
    withElement.checkNum(
        getDecoratedBound(typeFormal)!,
        withElement.checkExplicitlyNonNullable,
        'bound of type formal T of test type');
    withElement.checkTypeParameter(
        decoratedType.returnType!,
        withElement.checkExplicitlyNonNullable,
        typeFormal,
        'return type of test type');
  }

  Future<void> test_decorate_functionType_generic_no_explicit_bound() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class A<T> {}',
    );
    var typeFormal = withUnit.findElement.typeParameter('T');
    var withElement = withUnit.withElement(typeFormal);

    var decoratedType = withElement.decorate(
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
    withElement.checkObject(
        getDecoratedBound(typeFormal)!,
        withElement.checkExplicitlyNullable,
        'bound of type formal T of test type');
    withElement.checkTypeParameter(
        decoratedType.returnType!,
        withElement.checkExplicitlyNonNullable,
        typeFormal,
        'return type of test type');
  }

  Future<void> test_decorate_functionType_named_parameter() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkDynamic(
        withElement
            .decorate(
              FunctionTypeImpl(
                typeFormals: const [],
                parameters: [
                  ParameterElementImpl.synthetic(
                    'x',
                    withElement.typeProvider.dynamicType,
                    ParameterKind.NAMED,
                  )
                ],
                returnType: withElement.typeProvider.voidType,
                nullabilitySuffix: suffix,
              ),
            )
            .namedParameters!['x'],
        'parameter x of test type');
  }

  Future<void> test_decorate_functionType_ordinary_parameters() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    var decoratedType = withElement.decorate(
      FunctionTypeImpl(
        typeFormals: const [],
        parameters: [
          ParameterElementImpl.synthetic(
            'x',
            withElement.typeProvider.dynamicType,
            ParameterKind.REQUIRED,
          ),
          ParameterElementImpl.synthetic(
            'y',
            withElement.typeProvider.dynamicType,
            ParameterKind.REQUIRED,
          )
        ],
        returnType: withElement.typeProvider.voidType,
        nullabilitySuffix: suffix,
      ),
    );
    withElement.checkDynamic(
        decoratedType.positionalParameters![0], 'parameter 0 of test type');
    withElement.checkDynamic(
        decoratedType.positionalParameters![1], 'parameter 1 of test type');
  }

  Future<void> test_decorate_functionType_positional_parameter() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkDynamic(
        withElement
            .decorate(
              FunctionTypeImpl(
                typeFormals: const [],
                parameters: [
                  ParameterElementImpl.synthetic(
                    'x',
                    withElement.typeProvider.dynamicType,
                    ParameterKind.POSITIONAL,
                  )
                ],
                returnType: withElement.typeProvider.voidType,
                nullabilitySuffix: suffix,
              ),
            )
            .positionalParameters![0],
        'parameter 0 of test type');
  }

  Future<void> test_decorate_functionType_question() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkExplicitlyNullable(
        withElement
            .decorate(
              FunctionTypeImpl(
                typeFormals: const [],
                parameters: const [],
                returnType: withElement.typeProvider.voidType,
                nullabilitySuffix: NullabilitySuffix.question,
              ),
            )
            .node,
        'test type');
  }

  Future<void> test_decorate_functionType_returnType() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkDynamic(
        withElement
            .decorate(
              FunctionTypeImpl(
                typeFormals: const [],
                parameters: const [],
                returnType: withElement.typeProvider.dynamicType,
                nullabilitySuffix: suffix,
              ),
            )
            .returnType,
        'return type of test type');
  }

  Future<void> test_decorate_functionType_star() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkExplicitlyNonNullable(
        withElement
            .decorate(
              FunctionTypeImpl(
                typeFormals: const [],
                parameters: const [],
                returnType: withElement.typeProvider.voidType,
                nullabilitySuffix: suffix,
              ),
            )
            .node,
        'test type');
  }

  Future<void> test_decorate_interfaceType_parameters() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    var decoratedType = withElement.decorate(InterfaceTypeImpl(
        element: withElement.typeProvider.mapElement,
        typeArguments: [
          withElement.typeProvider.intType,
          withElement.typeProvider.numType
        ],
        nullabilitySuffix: suffix));
    withElement.checkInt(decoratedType.typeArguments[0]!,
        withElement.checkExplicitlyNonNullable, 'type argument 0 of test type');
    withElement.checkNum(decoratedType.typeArguments[1]!,
        withElement.checkExplicitlyNonNullable, 'type argument 1 of test type');
  }

  Future<void> test_decorate_interfaceType_simple_question() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkInt(
        withElement.decorate(
          InterfaceTypeImpl(
            element: withElement.typeProvider.intElement,
            typeArguments: const [],
            nullabilitySuffix: NullabilitySuffix.question,
          ),
        ),
        withElement.checkExplicitlyNullable,
        'test type');
  }

  Future<void> test_decorate_interfaceType_simple_star() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkInt(
        withElement.decorate(
          InterfaceTypeImpl(
            element: withElement.typeProvider.intElement,
            typeArguments: const [],
            nullabilitySuffix: suffix,
          ),
        ),
        withElement.checkExplicitlyNonNullable,
        'test type');
  }

  Future<void> test_decorate_iterable_dynamic() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    var decorated =
        withElement.decorate(withElement.typeProvider.iterableDynamicType);
    withElement.checkIterable(decorated, withElement.checkExplicitlyNonNullable,
        withElement.checkDynamic, 'test type');
  }

  Future<void> test_decorate_never() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkNever(
        withElement.decorate(withElement.typeProvider.neverType), 'test type');
  }

  Future<void> test_decorate_typeParameterType_question() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class A<T> {}',
    );
    var element = withUnit.findElement.typeParameter('T');
    var withElement = withUnit.withElement(element);

    withElement.checkTypeParameter(
        withElement.decorate(TypeParameterTypeImpl(
            element: element, nullabilitySuffix: NullabilitySuffix.question)),
        withElement.checkExplicitlyNullable,
        element,
        'test type');
  }

  Future<void> test_decorate_typeParameterType_star() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class A<T> {}',
    );
    var element = withUnit.findElement.typeParameter('T');
    var withElement = withUnit.withElement(element);

    withElement.checkTypeParameter(
        withElement.decorate(
            TypeParameterTypeImpl(element: element, nullabilitySuffix: suffix)),
        withElement.checkExplicitlyNonNullable,
        element,
        'test type');
  }

  Future<void> test_decorate_void() async {
    var withElement = await _ContextWithFiles().withEmptyUnit();

    withElement.checkVoid(
        withElement.decorate(withElement.typeProvider.voidType), 'test type');
  }

  Future<void> test_getImmediateSupertypes_future() async {
    var withUnit = await _ContextWithFiles().buildUnitElement('');
    var element = withUnit.typeProvider.futureElement;
    var withElement = withUnit.withElement(element);

    // var class_ = element = typeProvider.futureElement;
    var class_ = withElement.typeProvider.futureElement;
    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(class_).toList();
    var typeParam = class_.typeParameters[0];
    expect(decoratedSupertypes, hasLength(2));
    // TODO(scheglov) Use location matcher.
    withElement.checkObject(decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable, 'Future (async.dart:1:79)');
    // Since Future<T> is a subtype of FutureOr<T>, we consider FutureOr<T> to
    // be an immediate supertype, even though the class declaration for Future
    // doesn't mention FutureOr.
    // TODO(scheglov) Use location matcher.
    withElement.checkFutureOr(
        decoratedSupertypes[1],
        withElement.checkExplicitlyNonNullable,
        (t, displayName) => withElement.checkTypeParameter(
            t!, withElement.checkExplicitlyNonNullable, typeParam, displayName),
        'Future (async.dart:1:79)');
  }

  Future<void> test_getImmediateSupertypes_generic() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class C<T> extends Iterable<T> {}',
    );
    var unitElement = withUnit.unitElement;
    var class_ = unitElement.classes.single;
    var t = class_.typeParameters.single;

    var withElement = withUnit.withElement(class_);

    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    withElement.checkIterable(
        decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable,
        (type, displayName) => withElement.checkTypeParameter(
            type!, withElement.checkExplicitlyNonNullable, t, displayName),
        'C (test.dart:1:7)');
  }

  Future<void> test_getImmediateSupertypes_interface() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class C implements num {}',
    );
    var unitElement = withUnit.unitElement;
    var class_ = unitElement.classes.single;

    var withElement = withUnit.withElement(class_);

    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    withElement.checkObject(decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
    withElement.checkNum(decoratedSupertypes[1],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
  }

  Future<void> test_getImmediateSupertypes_mixin() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class C with num {}',
    );
    var unitElement = withUnit.unitElement;
    var class_ = unitElement.classes.single;

    var withElement = withUnit.withElement(class_);

    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(2));
    withElement.checkObject(decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
    withElement.checkNum(decoratedSupertypes[1],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
  }

  Future<void> test_getImmediateSupertypes_superclassConstraint() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'mixin C on num {}',
    );
    var unitElement = withUnit.unitElement;
    var mixin_ = unitElement.mixins.single;

    var withElement = withUnit.withElement(mixin_);

    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(mixin_).toList();
    expect(decoratedSupertypes, hasLength(1));
    withElement.checkNum(decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
  }

  Future<void> test_getImmediateSupertypes_supertype() async {
    var withUnit = await _ContextWithFiles().buildUnitElement(
      'class C {}',
    );
    var unitElement = withUnit.unitElement;
    var class_ = unitElement.classes.single;

    var withElement = withUnit.withElement(class_);

    var decoratedSupertypes =
        withElement.decorator.getImmediateSupertypes(class_).toList();
    expect(decoratedSupertypes, hasLength(1));
    // TODO(paulberry): displayName should be 'Object supertype of C'
    withElement.checkObject(decoratedSupertypes[0],
        withElement.checkExplicitlyNonNullable, 'C (test.dart:1:7)');
  }
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

class _ContextWithElement with EdgeTester {
  final _ContextWithUnitElement _withUnit;
  final Element element;

  final NullabilityGraphForTesting graph = NullabilityGraphForTesting();

  _ContextWithElement(this._withUnit, this.element);

  NullabilityNode get always => graph.always;

  AlreadyMigratedCodeDecorator get decorator {
    return AlreadyMigratedCodeDecorator(
        graph, typeProvider, (_) => LineInfo([0]));
  }

  NullabilityNode get never => graph.never;

  TypeProvider get typeProvider {
    return _withUnit.typeProvider;
  }

  void checkAlwaysNullable(NullabilityNode node, String displayName) {
    var edge = assertEdge(always, node, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge)!;
    expect(origin.kind, EdgeOriginKind.alwaysNullableType);
    expect(origin.element, same(element));
    expect(node.displayName, displayName);
  }

  void checkDynamic(DecoratedType? decoratedType, String displayName) {
    expect(decoratedType!.type, same(typeProvider.dynamicType));
    checkAlwaysNullable(decoratedType.node!, displayName);
  }

  void checkExplicitlyNonNullable(NullabilityNode? node, String displayName) {
    var edge = assertEdge(node, never, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge)!;
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
    expect(node!.displayName, displayName);
  }

  void checkExplicitlyNullable(NullabilityNode? node, String displayName) {
    var edge = assertEdge(always, node, hard: true, checkable: false);
    var origin = graph.getEdgeOrigin(edge)!;
    expect(origin.kind, EdgeOriginKind.alreadyMigratedType);
    expect(origin.element, same(element));
    expect(node!.displayName, displayName);
  }

  void checkFutureOr(
    DecoratedType decoratedType,
    void Function(NullabilityNode?, String) checkNullability,
    void Function(DecoratedType?, String) checkArgument,
    String displayName,
  ) {
    expect(decoratedType.type!.element, typeProvider.futureOrElement);
    checkNullability(decoratedType.node, displayName);
    checkArgument(
        decoratedType.typeArguments[0], 'type argument 0 of $displayName');
  }

  void checkInt(
    DecoratedType decoratedType,
    void Function(NullabilityNode?, String) checkNullability,
    String displayName,
  ) {
    expect(decoratedType.type!.element, typeProvider.intType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkIterable(
    DecoratedType decoratedType,
    void Function(NullabilityNode?, String) checkNullability,
    void Function(DecoratedType?, String) checkArgument,
    String displayName,
  ) {
    expect(
        decoratedType.type!.element, typeProvider.iterableDynamicType.element);
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
    void Function(NullabilityNode?, String) checkNullability,
    String displayName,
  ) {
    expect(decoratedType.type!.element, typeProvider.numType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkObject(
    DecoratedType decoratedType,
    void Function(NullabilityNode?, String) checkNullability,
    String displayName,
  ) {
    expect(decoratedType.type!.element, typeProvider.objectType.element);
    checkNullability(decoratedType.node, displayName);
  }

  void checkTypeParameter(
    DecoratedType decoratedType,
    void Function(NullabilityNode?, String) checkNullability,
    TypeParameterElement expectedElement,
    String displayName,
  ) {
    var type = decoratedType.type as TypeParameterTypeImpl;
    expect(type.element, same(expectedElement));
    checkNullability(decoratedType.node, displayName);
  }

  void checkVoid(DecoratedType decoratedType, String displayName) {
    expect(decoratedType.type, same(typeProvider.voidType));
    checkAlwaysNullable(decoratedType.node!, displayName);
  }

  DecoratedType decorate(DartType type) {
    var decoratedType = decorator.decorate(
        type, element, NullabilityNodeTarget.text('test type'));
    expect(decoratedType.type, same(type));
    return decoratedType;
  }
}

class _ContextWithFiles with ResourceProviderMixin {
  Future<_ContextWithUnitElement> buildUnitElement(String content) async {
    var file = newFile('/home/test/lib/test.dart', content: content);

    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    var contextCollection = AnalysisContextCollection(
      resourceProvider: resourceProvider,
      includedPaths: [file.path],
      sdkPath: sdkRoot.path,
    );
    var analysisContext = contextCollection.contextFor(file.path);
    var analysisSession = analysisContext.currentSession;
    var result = await analysisSession.getResolvedUnit(file.path);
    return _ContextWithUnitElement(result as ResolvedUnitResult);
  }

  Future<_ContextWithElement> withEmptyUnit() async {
    var withUnit = await buildUnitElement('');
    return withUnit.withElement(withUnit.unitElement);
  }
}

class _ContextWithUnitElement {
  final ResolvedUnitResult _unitResult;

  _ContextWithUnitElement(this._unitResult);

  FindElement get findElement {
    return FindElement(_unitResult.unit);
  }

  FindNode get findNode {
    return FindNode(_unitResult.content, _unitResult.unit);
  }

  TypeProvider get typeProvider {
    return unitElement.library.typeProvider;
  }

  CompilationUnitElement get unitElement {
    return _unitResult.unit.declaredElement!;
  }

  _ContextWithElement withElement(Element element) {
    return _ContextWithElement(this, element);
  }
}
