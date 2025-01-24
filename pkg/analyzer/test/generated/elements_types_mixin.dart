// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:test/test.dart';

mixin ElementsTypesMixin {
  InterfaceTypeImpl get boolNone {
    var element = typeProvider.boolElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get boolQuestion {
    var element = typeProvider.boolElement;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get doubleNone {
    var element = typeProvider.doubleType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get doubleQuestion {
    var element = typeProvider.doubleType.element;
    return interfaceTypeQuestion(element);
  }

  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  InterfaceTypeImpl get functionNone {
    var element = typeProvider.functionType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get functionQuestion {
    var element = typeProvider.functionType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get intNone {
    var element = typeProvider.intType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get intQuestion {
    var element = typeProvider.intType.element;
    return interfaceTypeQuestion(element);
  }

  TypeImpl get invalidType => InvalidTypeImpl.instance;

  NeverTypeImpl get neverNone => NeverTypeImpl.instance;

  NeverTypeImpl get neverQuestion => NeverTypeImpl.instanceNullable;

  InterfaceTypeImpl get nullNone {
    var element = typeProvider.nullType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numNone {
    var element = typeProvider.numType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numQuestion {
    var element = typeProvider.numType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get objectNone {
    var element = typeProvider.objectType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get objectQuestion {
    var element = typeProvider.objectType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get recordNone {
    var element = typeProvider.recordElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringNone {
    var element = typeProvider.stringType.element;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringQuestion {
    var element = typeProvider.stringType.element;
    return interfaceTypeQuestion(element);
  }

  LibraryElementImpl get testLibrary => throw UnimplementedError();

  TypeProviderImpl get typeProvider;

  TypeImpl get unknownInferredType => UnknownInferredType.instance;

  VoidTypeImpl get voidNone => VoidTypeImpl.instance;
  ClassElementImpl class_({
    required String name,
    bool isAbstract = false,
    bool isAugmentation = false,
    bool isSealed = false,
    InterfaceType? superType,
    List<TypeParameterElementImpl> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var fragment = ClassElementImpl(name, 0);
    fragment.isAbstract = isAbstract;
    fragment.isAugmentation = isAugmentation;
    fragment.isSealed = isSealed;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters;
    fragment.supertype = superType ?? typeProvider.objectType;
    fragment.interfaces = interfaces;
    fragment.mixins = mixins;
    fragment.methods = methods;

    var element = ClassElementImpl2(Reference.root(), fragment);
    element.mixins = fragment.mixins;
    element.interfaces = fragment.interfaces;
    element.methods = fragment.methods;

    return fragment;
  }

  ClassElementImpl class_2({
    required String name,
    bool isAbstract = false,
    bool isAugmentation = false,
    bool isSealed = false,
    InterfaceType? superType,
    List<TypeParameterElement2> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    return class_(
        name: name,
        isAbstract: isAbstract,
        isAugmentation: isAugmentation,
        isSealed: isSealed,
        superType: superType,
        typeParameters: typeParameters
            .map((e) => e.asElement as TypeParameterElementImpl)
            .toList(),
        interfaces: interfaces,
        mixins: mixins,
        methods: methods);
  }

  InterfaceTypeImpl comparableNone(DartType type) {
    var coreLibrary = typeProvider.intElement.library;
    var element = coreLibrary.getClass('Comparable')!;
    return element.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl comparableQuestion(DartType type) {
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
    EnumElementImpl2(Reference.root(), element);
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
    required TypeImpl extendedType,
    String? name,
    bool isAugmentation = false,
    List<TypeParameterElementImpl> typeParameters = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var element = ExtensionElementImpl(name, 0);
    ExtensionElementImpl2(Reference.root(), element);
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
    required TypeImpl representationType,
    List<TypeParameterElementImpl> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
  }) {
    var fragment = ExtensionTypeElementImpl(name, -1);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters;
    fragment.interfaces = interfaces;

    var field = FieldElementImpl(representationName, -1);
    field.type = representationType;
    fragment.fields = [field];

    var element = ExtensionTypeElementImpl2(Reference.root(), fragment);
    element
      ..representation = field
      ..typeErasure = representationType
      ..interfaces = fragment.interfaces
      ..fields = fragment.fields;

    return fragment;
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

  FunctionTypeImpl functionTypeNone2({
    List<TypeParameterElement2> typeFormals = const [],
    List<FormalParameterElement> parameters = const [],
    required DartType returnType,
  }) {
    return functionTypeNone(
        parameters: parameters.map((e) => e.asElement).toList(),
        typeFormals: typeFormals.map((e) => e.asElement).toList(),
        returnType: returnType);
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
    );
  }

  InterfaceTypeImpl futureOrNone(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureQuestion(DartType type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl interfaceType(
    InterfaceElementImpl element, {
    List<DartType> typeArguments = const [],
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  InterfaceTypeImpl interfaceTypeNone(
    InterfaceElementImpl element, {
    List<DartType> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl interfaceTypeQuestion(
    InterfaceElementImpl element, {
    List<DartType> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl iterableNone(DartType type) {
    return typeProvider.iterableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl iterableQuestion(DartType type) {
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

  InterfaceTypeImpl listNone(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl listQuestion(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl mapNone(DartType key, DartType value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl mapQuestion(DartType key, DartType value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  MethodElementImpl method(
    String name,
    DartType returnType, {
    bool isStatic = false,
    List<TypeParameterElementImpl> typeFormals = const [],
    List<ParameterElementImpl> parameters = const [],
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
    List<TypeParameterElementImpl> typeParameters = const [],
    List<InterfaceType>? constraints,
    List<InterfaceType> interfaces = const [],
  }) {
    var fragment = MixinElementImpl(name, 0);
    fragment.isAugmentation = isAugmentation;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters;
    fragment.superclassConstraints = constraints ?? [typeProvider.objectType];
    fragment.interfaces = interfaces;
    fragment.constructors = const <ConstructorElementImpl>[];

    var element = MixinElementImpl2(Reference.root(), fragment);
    element.superclassConstraints = fragment.superclassConstraints;
    element.interfaces = fragment.interfaces;
    element.methods = fragment.methods;

    return fragment;
  }

  ParameterElementImpl namedParameter({
    required String name,
    required TypeImpl type,
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

  FormalParameterElement namedParameter2({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    return namedParameter(name: name, type: type, isCovariant: isCovariant)
        .asElement2;
  }

  ParameterElementImpl namedRequiredParameter({
    required String name,
    required TypeImpl type,
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

  FormalParameterElement namedRequiredParameter2({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    return namedRequiredParameter(
            name: name, type: type, isCovariant: isCovariant)
        .asElement2;
  }

  ParameterElementImpl positionalParameter({
    String? name,
    required TypeImpl type,
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

  FormalParameterElement positionalParameter2({
    String? name,
    required TypeImpl type,
    bool isCovariant = false,
    String? defaultValueCode,
  }) {
    return positionalParameter(
            type: type,
            isCovariant: isCovariant,
            defaultValueCode: defaultValueCode)
        .asElement2;
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

  TypeParameterTypeImpl promotedTypeParameterTypeNone2(
    TypeParameterElement2 element,
    DartType promotedBound,
  ) {
    return promotedTypeParameterTypeNone(
      element.asElement,
      promotedBound,
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

  TypeParameterTypeImpl promotedTypeParameterTypeQuestion2(
    TypeParameterElement2 element,
    DartType promotedBound,
  ) {
    return promotedTypeParameterTypeQuestion(element.asElement, promotedBound);
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

  ParameterElementImpl requiredParameter({
    String? name,
    required TypeImpl type,
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

  FormalParameterElement requiredParameter2({
    String? name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    return requiredParameter(name: name, type: type, isCovariant: isCovariant)
        .asElement2;
  }

  TypeAliasElementImpl typeAlias({
    required String name,
    required List<TypeParameterElementImpl> typeParameters,
    required DartType aliasedType,
  }) {
    var fragment = TypeAliasElementImpl(name, 0);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters;
    fragment.aliasedType = aliasedType;

    TypeAliasElementImpl2(Reference.root(), fragment);

    return fragment;
  }

  TypeImpl typeAliasTypeNone(
    TypeAliasElementImpl element, {
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

  TypeParameterElement2 typeParameter2(String name,
      {DartType? bound, Variance? variance}) {
    return typeParameter(name, bound: bound, variance: variance).asElement2;
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

  TypeParameterTypeImpl typeParameterTypeNone2(
    TypeParameterElement2 element, {
    DartType? promotedBound,
  }) {
    return typeParameterTypeNone(
      element.asElement,
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

  TypeParameterTypeImpl typeParameterTypeQuestion2(
    TypeParameterElement2 element, {
    DartType? promotedBound,
  }) {
    return typeParameterTypeQuestion(
      element.asElement,
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
    var augmentationTarget = this;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');

      augmentedInternal.interfaces = [
        ...augmentedInternal.interfaces,
        ...augmentation.interfaces,
      ];

      augmentedInternal.mixins = [
        ...augmentedInternal.mixins,
        ...augmentation.mixins,
      ];
    }
  }

  void updateElement() {
    element.interfaces = interfaces;
    element.mixins = mixins;
  }
}

extension MixinElementImplExtension on MixinElementImpl {
  void addAugmentations(List<MixinElementImpl> augmentations) {
    var augmentationTarget = this;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');

      augmentedInternal.superclassConstraints = [
        ...augmentedInternal.superclassConstraints,
        ...augmentation.superclassConstraints,
      ];

      augmentedInternal.interfaces = [
        ...augmentedInternal.interfaces,
        ...augmentation.interfaces,
      ];
    }
  }
}
