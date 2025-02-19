// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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
    var element = typeProvider.boolElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get boolQuestion {
    var element = typeProvider.boolElement2;
    return interfaceTypeQuestion2(element);
  }

  InterfaceTypeImpl get doubleNone {
    var element = typeProvider.doubleElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get doubleQuestion {
    var element = typeProvider.doubleElement2;
    return interfaceTypeQuestion2(element);
  }

  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  InterfaceTypeImpl get functionNone {
    var element = typeProvider.functionElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get functionQuestion {
    var element = typeProvider.functionElement2;
    return interfaceTypeQuestion2(element);
  }

  InterfaceTypeImpl get intNone {
    var element = typeProvider.intElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get intQuestion {
    var element = typeProvider.intElement2;
    return interfaceTypeQuestion2(element);
  }

  TypeImpl get invalidType => InvalidTypeImpl.instance;

  NeverTypeImpl get neverNone => NeverTypeImpl.instance;

  NeverTypeImpl get neverQuestion => NeverTypeImpl.instanceNullable;

  InterfaceTypeImpl get nullNone {
    var element = typeProvider.nullElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numNone {
    var element = typeProvider.numElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numQuestion {
    var element = typeProvider.numElement2;
    return interfaceTypeQuestion2(element);
  }

  InterfaceTypeImpl get objectNone {
    var element = typeProvider.objectElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get objectQuestion {
    var element = typeProvider.objectElement2;
    return interfaceTypeQuestion2(element);
  }

  InterfaceTypeImpl get recordNone {
    var element = typeProvider.recordElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringNone {
    var element = typeProvider.stringElement2;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringQuestion {
    var element = typeProvider.stringElement2;
    return interfaceTypeQuestion2(element);
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
    InterfaceTypeImpl? superType,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl> interfaces = const [],
    List<InterfaceTypeImpl> mixins = const [],
    List<MethodElementImpl> methods = const [],
  }) {
    var fragment = ClassElementImpl(name, 0);
    fragment.isAbstract = isAbstract;
    fragment.isAugmentation = isAugmentation;
    fragment.isSealed = isSealed;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
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

  ClassElementImpl2 class_2({
    required String name,
    bool isAbstract = false,
    bool isAugmentation = false,
    bool isSealed = false,
    InterfaceTypeImpl? superType,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl> interfaces = const [],
    List<InterfaceTypeImpl> mixins = const [],
    List<MethodElementImpl2> methods = const [],
  }) {
    var fragment = ClassElementImpl(name, 0);
    fragment.isAbstract = isAbstract;
    fragment.isAugmentation = isAugmentation;
    fragment.isSealed = isSealed;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters =
        typeParameters.map((e) => e.firstFragment).toList();
    fragment.supertype = superType ?? typeProvider.objectType;
    fragment.interfaces = interfaces;
    fragment.mixins = mixins;
    fragment.methods = methods.map((e) => e.firstFragment).toList();

    var element = ClassElementImpl2(Reference.root(), fragment);
    element.mixins = fragment.mixins;
    element.interfaces = fragment.interfaces;
    element.methods = fragment.methods;

    return element;
  }

  InterfaceTypeImpl comparableNone(TypeImpl type) {
    var coreLibrary = typeProvider.intElement2.library2;
    var element = coreLibrary.getClass2('Comparable')!;
    return element.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl comparableQuestion(TypeImpl type) {
    var coreLibrary = typeProvider.intElement2.library2;
    var element = coreLibrary.getClass2('Comparable')!;
    return element.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  EnumElementImpl enum_({
    required String name,
    required List<ConstFieldElementImpl> constants,
  }) {
    var fragment = EnumElementImpl(name, 0);
    EnumElementImpl2(Reference.root(), fragment);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.fields = constants;
    return fragment;
  }

  EnumElementImpl2 enum_2({
    required String name,
    required List<ConstFieldElementImpl> constants,
  }) {
    var fragment = EnumElementImpl(name, 0);
    var element = EnumElementImpl2(Reference.root(), fragment);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.fields = constants;
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
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl> interfaces = const [],
  }) {
    var fragment = ExtensionTypeElementImpl(name, -1);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
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

  ExtensionTypeElementImpl2 extensionType2(
    String name, {
    String representationName = 'it',
    required TypeImpl representationType,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl> interfaces = const [],
  }) {
    var fragment = ExtensionTypeElementImpl(name, -1);
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
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

    return element;
  }

  FunctionTypeImpl functionType({
    required List<TypeParameterElementImpl2> typeParameters,
    required List<FormalParameterElementImpl> formalParameters,
    required TypeImpl returnType,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return FunctionTypeImpl.v2(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionTypeImpl functionTypeNone({
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<FormalParameterElementImpl> formalParameters = const [],
    required TypeImpl returnType,
  }) {
    return functionType(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  FunctionTypeImpl functionTypeQuestion({
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<FormalParameterElementImpl> formalParameters = const [],
    required TypeImpl returnType,
  }) {
    return functionType(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureNone(TypeImpl type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrNone(TypeImpl type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(TypeImpl type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureQuestion(TypeImpl type) {
    return typeProvider.futureElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl interfaceType(
    InterfaceElementImpl element, {
    List<TypeImpl> typeArguments = const [],
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  InterfaceTypeImpl interfaceTypeNone(
    InterfaceElementImpl2 element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl interfaceTypeQuestion(
    InterfaceElementImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl interfaceTypeQuestion2(
    InterfaceElementImpl2 element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl iterableNone(TypeImpl type) {
    return typeProvider.iterableElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl iterableQuestion(TypeImpl type) {
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

  InterfaceTypeImpl listNone(TypeImpl type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl listQuestion(TypeImpl type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl mapNone(TypeImpl key, TypeImpl value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl mapQuestion(TypeImpl key, TypeImpl value) {
    return typeProvider.mapElement.instantiate(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  MethodElementImpl method(
    String name,
    TypeImpl returnType, {
    bool isStatic = false,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<FormalParameterElementImpl> formalParameters = const [],
  }) {
    return MethodElementImpl(name, 0)
      ..isStatic = isStatic
      ..parameters = formalParameters.map((e) => e.asElement).toList()
      ..returnType = returnType
      ..typeParameters = typeParameters.map((e) => e.asElement).toList();
  }

  MixinElementImpl mixin_({
    required String name,
    bool isAugmentation = false,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl>? constraints,
    List<InterfaceTypeImpl> interfaces = const [],
  }) {
    var fragment = MixinElementImpl(name, 0);
    fragment.isAugmentation = isAugmentation;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
    fragment.superclassConstraints = constraints ?? [typeProvider.objectType];
    fragment.interfaces = interfaces;
    fragment.constructors = const <ConstructorElementImpl>[];

    var element = MixinElementImpl2(Reference.root(), fragment);
    element.superclassConstraints = fragment.superclassConstraints;
    element.interfaces = fragment.interfaces;
    element.methods = fragment.methods;

    return fragment;
  }

  MixinElementImpl2 mixin_2({
    required String name,
    bool isAugmentation = false,
    List<TypeParameterElementImpl2> typeParameters = const [],
    List<InterfaceTypeImpl>? constraints,
    List<InterfaceTypeImpl> interfaces = const [],
  }) {
    var fragment = MixinElementImpl(name, 0);
    fragment.isAugmentation = isAugmentation;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
    fragment.superclassConstraints = constraints ?? [typeProvider.objectType];
    fragment.interfaces = interfaces;
    fragment.constructors = const <ConstructorElementImpl>[];

    var element = MixinElementImpl2(Reference.root(), fragment);
    element.superclassConstraints = fragment.superclassConstraints;
    element.interfaces = fragment.interfaces;
    element.methods = fragment.methods;

    return element;
  }

  FormalParameterElementImpl namedParameter({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.NAMED,
    );
    fragment.type = type;
    fragment.isExplicitlyCovariant = isCovariant;
    return fragment.asElement2;
  }

  FormalParameterElementImpl namedRequiredParameter({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = ParameterElementImpl(
      name: name,
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.NAMED_REQUIRED,
    );
    fragment.type = type;
    fragment.isExplicitlyCovariant = isCovariant;
    return fragment.asElement2;
  }

  FormalParameterElementImpl positionalParameter({
    String? name,
    required TypeImpl type,
    bool isCovariant = false,
    String? defaultValueCode,
  }) {
    var fragment = ParameterElementImpl(
      name: name ?? '',
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.POSITIONAL,
    );
    fragment.type = type;
    fragment.isExplicitlyCovariant = isCovariant;
    fragment.defaultValueCode = defaultValueCode;
    return fragment.asElement2;
  }

  TypeParameterTypeImpl promotedTypeParameterType({
    required TypeParameterElementImpl2 element,
    required NullabilitySuffix nullabilitySuffix,
    required TypeImpl promotedBound,
  }) {
    return TypeParameterTypeImpl.v2(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeNone(
    TypeParameterElementImpl2 element,
    TypeImpl promotedBound,
  ) {
    return promotedTypeParameterType(
      element: element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeQuestion(
    TypeParameterElementImpl2 element,
    TypeImpl promotedBound,
  ) {
    return promotedTypeParameterType(
      element: element,
      nullabilitySuffix: NullabilitySuffix.question,
      promotedBound: promotedBound,
    );
  }

  RecordTypeImpl recordType({
    List<TypeImpl> positionalTypes = const [],
    Map<String, TypeImpl> namedTypes = const {},
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
    List<TypeImpl> positionalTypes = const [],
    Map<String, TypeImpl> namedTypes = const {},
  }) {
    return recordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  RecordTypeImpl recordTypeQuestion({
    List<TypeImpl> positionalTypes = const [],
    Map<String, TypeImpl> namedTypes = const {},
  }) {
    return recordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  FormalParameterElementImpl requiredParameter({
    String? name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = ParameterElementImpl(
      name: name ?? '',
      nameOffset: 0,
      name2: name,
      nameOffset2: 0,
      parameterKind: ParameterKind.REQUIRED,
    );
    fragment.type = type;
    fragment.isExplicitlyCovariant = isCovariant;
    return fragment.asElement2;
  }

  TypeAliasElementImpl2 typeAlias({
    required String name,
    required List<TypeParameterElementImpl2> typeParameters,
    required TypeImpl aliasedType,
  }) {
    var fragment = TypeAliasElementImpl(name, 0);
    fragment.name2 = name;
    fragment.enclosingElement3 = testLibrary.definingCompilationUnit;
    fragment.typeParameters = typeParameters.map((e) => e.asElement).toList();
    fragment.aliasedType = aliasedType;

    return TypeAliasElementImpl2(Reference.root(), fragment);
  }

  TypeImpl typeAliasTypeNone(
    TypeAliasElementImpl2 element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  TypeParameterElementImpl2 typeParameter(String name,
      {TypeImpl? bound, Variance? variance}) {
    var fragment = TypeParameterElementImpl(name, -1);
    fragment.bound = bound;

    var element = TypeParameterElementImpl2(
      firstFragment: fragment,
      name3: name,
    );
    element.variance = variance;
    return element;
  }

  TypeParameterTypeImpl typeParameterType(
    TypeParameterElementImpl2 element, {
    required NullabilitySuffix nullabilitySuffix,
    TypeImpl? promotedBound,
  }) {
    return TypeParameterTypeImpl.v2(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeNone(
    TypeParameterElementImpl2 element, {
    TypeImpl? promotedBound,
  }) {
    return typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeQuestion(
    TypeParameterElementImpl2 element, {
    TypeImpl? promotedBound,
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

extension ClassElementImpl2Extension on ClassElementImpl2 {
  void addAugmentations(List<ClassElementImpl> augmentations) {
    var augmentationTarget = fragments.last;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');

      interfaces = [
        ...interfaces,
        ...augmentation.interfaces,
      ];

      mixins = [
        ...mixins,
        ...augmentation.mixins,
      ];
    }
  }
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

extension MixinElementImpl2Extension on MixinElementImpl2 {
  void addAugmentations(List<MixinElementImpl> augmentations) {
    var augmentationTarget = fragments.last;
    for (var augmentation in augmentations) {
      expect(augmentation.isAugmentation, isTrue);
      augmentationTarget.augmentation = augmentation;
      augmentation.augmentationTargetAny = augmentationTarget;
      augmentationTarget = augmentation;

      expect(augmentation.typeParameters, isEmpty,
          reason: 'Not supported in tests');

      superclassConstraints = [
        ...superclassConstraints,
        ...augmentation.superclassConstraints,
      ];

      interfaces = [
        ...interfaces,
        ...augmentation.interfaces,
      ];
    }
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
