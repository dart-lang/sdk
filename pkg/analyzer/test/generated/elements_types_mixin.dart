// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';

mixin ElementsTypesMixin {
  InterfaceType get boolNone {
    var element = typeProvider.boolElement;
    return interfaceTypeNone(element);
  }

  InterfaceType get boolQuestion {
    var element = typeProvider.boolElement;
    return interfaceTypeQuestion(element);
  }

  InterfaceType get doubleNone {
    var element = typeProvider.doubleType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get doubleQuestion {
    var element = typeProvider.doubleType.element;
    return interfaceTypeQuestion(element);
  }

  DartType get dynamicType => DynamicTypeImpl.instance;

  InterfaceType get functionNone {
    var element = typeProvider.functionType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get functionQuestion {
    var element = typeProvider.functionType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceType get intNone {
    var element = typeProvider.intType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get intQuestion {
    var element = typeProvider.intType.element;
    return interfaceTypeQuestion(element);
  }

  DartType get invalidType => InvalidTypeImpl.instance;

  NeverTypeImpl get neverNone => NeverTypeImpl.instance;

  NeverTypeImpl get neverQuestion => NeverTypeImpl.instanceNullable;

  InterfaceTypeImpl get nullNone {
    var element = typeProvider.nullType.element;
    return interfaceTypeNone(element) as InterfaceTypeImpl;
  }

  InterfaceTypeImpl get nullQuestion {
    var element = typeProvider.nullType.element;
    return interfaceTypeQuestion(element) as InterfaceTypeImpl;
  }

  InterfaceType get numNone {
    var element = typeProvider.numType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get numQuestion {
    var element = typeProvider.numType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceType get objectNone {
    var element = typeProvider.objectType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get objectQuestion {
    var element = typeProvider.objectType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceType get recordNone {
    var element = typeProvider.recordElement;
    return interfaceTypeNone(element);
  }

  InterfaceType get stringNone {
    var element = typeProvider.stringType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get stringQuestion {
    var element = typeProvider.stringType.element;
    return interfaceTypeQuestion(element);
  }

  LibraryElementImpl get testLibrary => throw UnimplementedError();

  TypeProvider get typeProvider;

  DartType get unknownInferredType => UnknownInferredType.instance;

  VoidTypeImpl get voidNone => VoidTypeImpl.instance;

  ClassElementImpl class_({
    required String name,
    bool isAbstract = false,
    bool isAugmentation = false,
    bool isSealed = false,
    InterfaceType? superType,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.isAbstract = isAbstract;
    element.isAugmentation = isAugmentation;
    element.isSealed = isSealed;
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.typeParameters = typeParameters;
    element.supertype = superType ?? typeProvider.objectType;
    element.interfaces = interfaces;
    element.mixins = mixins;
    element.methods = methods;
    return element;
  }

  InterfaceType comparableNone(DartType type) {
    var coreLibrary = typeProvider.intElement.library;
    var element = coreLibrary.getClass('Comparable')!;
    return element.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType comparableQuestion(DartType type) {
    var coreLibrary = typeProvider.intElement.library;
    var element = coreLibrary.getClass('Comparable')!;
    return element.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  EnumElementImpl enum_({
    required String name,
    required List<ConstFieldElementImpl> constants,
  }) {
    var element = EnumElementImpl(name, 0);
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.fields = constants;
    return element;
  }

  ConstFieldElementImpl enumConstant_(
    String name,
  ) {
    return ConstFieldElementImpl(name, 0)..isEnumConstant = true;
  }

  ExtensionElementImpl extension({
    required DartType extendedType,
    String? name,
    bool isAugmentation = false,
    List<TypeParameterElement> typeParameters = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var element = ExtensionElementImpl(name, 0);
    element.augmented.extendedType = extendedType;
    element.isAugmentation = isAugmentation;
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.typeParameters = typeParameters;
    element.methods = methods;
    return element;
  }

  ExtensionTypeElementImpl extensionType(
    String name, {
    String representationName = 'it',
    required DartType representationType,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
  }) {
    var element = ExtensionTypeElementImpl(name, -1);
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.typeParameters = typeParameters;
    element.interfaces = interfaces;

    var field = FieldElementImpl(representationName, -1);
    field.type = representationType;
    element.fields = [field];

    element.augmented
      ..representation = field
      ..typeErasure = representationType;

    return element;
  }

  FunctionTypeImpl functionType({
    required List<TypeParameterElement> typeFormals,
    required List<ParameterElement> parameters,
    required DartType returnType,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionTypeImpl functionTypeNone({
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
    required DartType returnType,
  }) {
    return functionType(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  FunctionTypeImpl functionTypeQuestion({
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
    required DartType returnType,
  }) {
    return functionType(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureNone(DartType type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    ) as InterfaceTypeImpl;
  }

  InterfaceTypeImpl futureOrNone(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    ) as InterfaceTypeImpl;
  }

  InterfaceTypeImpl futureOrQuestion(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    ) as InterfaceTypeImpl;
  }

  InterfaceTypeImpl futureQuestion(DartType type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    ) as InterfaceTypeImpl;
  }

  InterfaceType interfaceType(
    InterfaceElement element, {
    List<DartType> typeArguments = const [],
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  InterfaceType interfaceTypeNone(
    InterfaceElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType interfaceTypeQuestion(
    InterfaceElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType iterableNone(DartType type) {
    return typeProvider.iterableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType iterableQuestion(DartType type) {
    return typeProvider.iterableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  LibraryElementImpl library_({
    required String uriStr,
    required TypeSystemImpl typeSystem,
    required AnalysisContext analysisContext,
    required AnalysisSessionImpl analysisSession,
  }) {
    var uri = Uri.parse(uriStr);
    var source = _MockSource(uri);

    var library = LibraryElementImpl(
      analysisContext,
      analysisSession,
      uriStr,
      -1,
      0,
      FeatureSet.latestLanguageVersion(),
    );

    var definingUnit = CompilationUnitElementImpl(
      library: library,
      source: source,
      lineInfo: LineInfo([0]),
    );

    library.definingCompilationUnit = definingUnit;
    library.typeProvider = typeSystem.typeProvider;
    library.typeSystem = typeSystem;

    return library;
  }

  InterfaceType listNone(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType listQuestion(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType mapNone(DartType key, DartType value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType mapQuestion(DartType key, DartType value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  MethodElementImpl method(
    String name,
    DartType returnType, {
    bool isStatic = false,
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
  }) {
    return MethodElementImpl(name, 0)
      ..isStatic = isStatic
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
  }

  MixinElementImpl mixin_({
    required String name,
    bool isAugmentation = false,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType>? constraints,
    List<InterfaceType> interfaces = const [],
  }) {
    var element = MixinElementImpl(name, 0);
    element.isAugmentation = isAugmentation;
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.typeParameters = typeParameters;
    element.superclassConstraints = constraints ?? [typeProvider.objectType];
    element.interfaces = interfaces;
    element.constructors = const <ConstructorElementImpl>[];
    return element;
  }

  ParameterElement namedParameter({
    required String name,
    required DartType type,
    bool isCovariant = false,
  }) {
    var parameter = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.NAMED,
    );
    parameter.type = type;
    parameter.isExplicitlyCovariant = isCovariant;
    return parameter;
  }

  ParameterElement namedRequiredParameter({
    required String name,
    required DartType type,
    bool isCovariant = false,
  }) {
    var parameter = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.NAMED_REQUIRED,
    );
    parameter.type = type;
    parameter.isExplicitlyCovariant = isCovariant;
    return parameter;
  }

  ParameterElement positionalParameter({
    String? name,
    required DartType type,
    bool isCovariant = false,
    String? defaultValueCode,
  }) {
    var parameter = ParameterElementImpl(
      name: name ?? '',
      nameOffset: 0,
      parameterKind: ParameterKind.POSITIONAL,
    );
    parameter.type = type;
    parameter.isExplicitlyCovariant = isCovariant;
    parameter.defaultValueCode = defaultValueCode;
    return parameter;
  }

  TypeParameterTypeImpl promotedTypeParameterType({
    required TypeParameterElement element,
    required NullabilitySuffix nullabilitySuffix,
    required DartType promotedBound,
  }) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeNone(
    TypeParameterElement element,
    DartType promotedBound,
  ) {
    return promotedTypeParameterType(
      element: element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeQuestion(
    TypeParameterElement element,
    DartType promotedBound,
  ) {
    return promotedTypeParameterType(
      element: element,
      nullabilitySuffix: NullabilitySuffix.question,
      promotedBound: promotedBound,
    );
  }

  RecordTypeImpl recordType({
    List<DartType> positionalTypes = const [],
    Map<String, DartType> namedTypes = const {},
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return RecordTypeImpl(
      positionalFields: positionalTypes.map((type) {
        return RecordTypePositionalFieldImpl(
          type: type,
        );
      }).toList(),
      namedFields: namedTypes.entries.map((entry) {
        return RecordTypeNamedFieldImpl(
          name: entry.key,
          type: entry.value,
        );
      }).toList(),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  RecordTypeImpl recordTypeNone({
    List<DartType> positionalTypes = const [],
    Map<String, DartType> namedTypes = const {},
  }) {
    return recordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  RecordTypeImpl recordTypeQuestion({
    List<DartType> positionalTypes = const [],
    Map<String, DartType> namedTypes = const {},
  }) {
    return recordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  ParameterElement requiredParameter({
    String? name,
    required DartType type,
    bool isCovariant = false,
  }) {
    var parameter = ParameterElementImpl(
      name: name ?? '',
      nameOffset: 0,
      parameterKind: ParameterKind.REQUIRED,
    );
    parameter.type = type;
    parameter.isExplicitlyCovariant = isCovariant;
    return parameter;
  }

  TypeAliasElementImpl typeAlias({
    required String name,
    required List<TypeParameterElement> typeParameters,
    required DartType aliasedType,
  }) {
    var element = TypeAliasElementImpl(name, 0);
    element.enclosingElement3 = testLibrary.definingCompilationUnit;
    element.typeParameters = typeParameters;
    element.aliasedType = aliasedType;
    return element;
  }

  DartType typeAliasTypeNone(
    TypeAliasElement element, {
    List<DartType> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  TypeParameterElementImpl typeParameter(String name,
      {DartType? bound, Variance? variance}) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound;
    element.variance = variance;
    return element;
  }

  TypeParameterTypeImpl typeParameterType(
    TypeParameterElement element, {
    required NullabilitySuffix nullabilitySuffix,
    DartType? promotedBound,
  }) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeNone(
    TypeParameterElement element, {
    DartType? promotedBound,
  }) {
    return typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeQuestion(
    TypeParameterElement element, {
    DartType? promotedBound,
  }) {
    return typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.question,
      promotedBound: promotedBound,
    );
  }
}

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

extension ClassElementImplExtension on ClassElementImpl {
  void addAugmentations(List<ClassElementImpl> augmentations) {
    expect(this.augmented, TypeMatcher<NotAugmentedClassElementImpl>());

    var augmented = AugmentedClassElementImpl(this);
    augmentedInternal = augmented;

    var augmentationTarget = this;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');
      augmented.interfaces.addAll(augmentation.interfaces);
      augmented.mixins.addAll(augmentation.mixins);
    }
  }
}

extension MixinElementImplExtension on MixinElementImpl {
  void addAugmentations(List<MixinElementImpl> augmentations) {
    expect(this.augmented, TypeMatcher<NotAugmentedMixinElementImpl>());

    var augmented = AugmentedMixinElementImpl(this);
    augmentedInternal = augmented;

    var augmentationTarget = this;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');
      augmented.superclassConstraints
          .addAll(augmentation.superclassConstraints);
      augmented.interfaces.addAll(augmentation.interfaces);
    }
  }
}
