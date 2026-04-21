// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
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
    var element = typeProvider.doubleElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get doubleQuestion {
    var element = typeProvider.doubleElement;
    return interfaceTypeQuestion(element);
  }

  TypeImpl get dynamicType => DynamicTypeImpl.instance;

  InterfaceTypeImpl get functionNone {
    var element = typeProvider.functionElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get functionQuestion {
    var element = typeProvider.functionElement;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get intNone {
    var element = typeProvider.intElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get intQuestion {
    var element = typeProvider.intElement;
    return interfaceTypeQuestion(element);
  }

  TypeImpl get invalidType => InvalidTypeImpl.instance;

  NeverTypeImpl get neverNone => NeverTypeImpl.instance;

  NeverTypeImpl get neverQuestion => NeverTypeImpl.instanceNullable;

  InterfaceTypeImpl get nullNone {
    var element = typeProvider.nullElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numNone {
    var element = typeProvider.numElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get numQuestion {
    var element = typeProvider.numElement;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get objectNone {
    var element = typeProvider.objectElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get objectQuestion {
    var element = typeProvider.objectElement;
    return interfaceTypeQuestion(element);
  }

  InterfaceTypeImpl get recordNone {
    var element = typeProvider.recordElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringNone {
    var element = typeProvider.stringElement;
    return interfaceTypeNone(element);
  }

  InterfaceTypeImpl get stringQuestion {
    var element = typeProvider.stringElement;
    return interfaceTypeQuestion(element);
  }

  LibraryElementImpl get testLibrary => throw UnimplementedError();

  TypeProviderImpl get typeProvider;

  TypeImpl get unknownInferredType => UnknownInferredType.instance;

  VoidTypeImpl get voidNone => VoidTypeImpl.instance;

  InterfaceTypeImpl comparableNone(TypeImpl type) {
    var coreLibrary = typeProvider.intElement.library;
    var element = coreLibrary.getClass('Comparable')!;
    return element.instantiateImpl(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl comparableQuestion(TypeImpl type) {
    var coreLibrary = typeProvider.intElement.library;
    var element = coreLibrary.getClass('Comparable')!;
    return element.instantiateImpl(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  FunctionTypeImpl functionType({
    required List<TypeParameterElementImpl> typeParameters,
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
    List<TypeParameterElementImpl> typeParameters = const [],
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
    List<TypeParameterElementImpl> typeParameters = const [],
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
    return typeProvider.futureElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrNone(TypeImpl type) {
    return typeProvider.futureOrElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(TypeImpl type) {
    return typeProvider.futureOrElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureQuestion(TypeImpl type) {
    return typeProvider.futureElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl interfaceTypeNone(
    InterfaceElementImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl interfaceTypeQuestion(
    InterfaceElementImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl iterableNone(TypeImpl type) {
    return typeProvider.iterableElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl iterableQuestion(TypeImpl type) {
    return typeProvider.iterableElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
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

    var definingUnit = LibraryFragmentImpl(
      library: library,
      source: source,
      lineInfo: LineInfo([0]),
    );

    library.firstFragment = definingUnit;
    library.typeProvider = typeSystem.typeProvider;
    library.typeSystem = typeSystem;

    return library;
  }

  InterfaceTypeImpl listNone(TypeImpl type) {
    return typeProvider.listElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl listQuestion(TypeImpl type) {
    return typeProvider.listElement.instantiateImpl(
      typeArguments: <TypeImpl>[type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl mapNone(TypeImpl key, TypeImpl value) {
    return typeProvider.mapElement.instantiateImpl(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl mapQuestion(TypeImpl key, TypeImpl value) {
    return typeProvider.mapElement.instantiateImpl(
      typeArguments: [key, value],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  FormalParameterElementImpl namedParameter({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = FormalParameterFragmentImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.NAMED,
    );
    fragment.isExplicitlyCovariant = isCovariant;
    return FormalParameterElementImpl(fragment)..type = type;
  }

  FormalParameterElementImpl namedRequiredParameter({
    required String name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = FormalParameterFragmentImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.NAMED_REQUIRED,
    );
    fragment.isExplicitlyCovariant = isCovariant;
    return FormalParameterElementImpl(fragment)..type = type;
  }

  FormalParameterElementImpl positionalParameter({
    String? name,
    required TypeImpl type,
    bool isCovariant = false,
  }) {
    var fragment = FormalParameterFragmentImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.POSITIONAL,
    );
    fragment.isExplicitlyCovariant = isCovariant;
    return FormalParameterElementImpl(fragment)..type = type;
  }

  TypeParameterTypeImpl promotedTypeParameterType({
    required TypeParameterElementImpl element,
    required NullabilitySuffix nullabilitySuffix,
    required TypeImpl promotedBound,
  }) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeNone(
    TypeParameterElementImpl element,
    TypeImpl promotedBound,
  ) {
    return promotedTypeParameterType(
      element: element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl promotedTypeParameterTypeQuestion(
    TypeParameterElementImpl element,
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
        return RecordTypePositionalFieldImpl(type: type);
      }).toList(),
      namedFields: namedTypes.entries.map((entry) {
        return RecordTypeNamedFieldImpl(name: entry.key, type: entry.value);
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
    var fragment = FormalParameterFragmentImpl(
      name: name,
      nameOffset: 0,
      parameterKind: ParameterKind.REQUIRED,
    );
    fragment.isExplicitlyCovariant = isCovariant;
    return FormalParameterElementImpl(fragment)..type = type;
  }

  TypeImpl typeAliasTypeNone(
    TypeAliasElementImpl element, {
    List<TypeImpl> typeArguments = const [],
  }) {
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  TypeParameterElementImpl typeParameter(
    String name, {
    TypeImpl? bound,
    Variance? variance,
  }) {
    var fragment = TypeParameterFragmentImpl(name: name);

    var element = TypeParameterElementImpl(firstFragment: fragment);
    element.bound = bound;
    element.variance = variance;
    return element;
  }

  TypeParameterTypeImpl typeParameterType(
    TypeParameterElementImpl element, {
    required NullabilitySuffix nullabilitySuffix,
    TypeImpl? promotedBound,
  }) {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeNone(
    TypeParameterElementImpl element, {
    TypeImpl? promotedBound,
  }) {
    return typeParameterType(
      element,
      nullabilitySuffix: NullabilitySuffix.none,
      promotedBound: promotedBound,
    );
  }

  TypeParameterTypeImpl typeParameterTypeQuestion(
    TypeParameterElementImpl element, {
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
