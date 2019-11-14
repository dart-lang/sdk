// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

mixin ElementsTypesMixin {
  DynamicTypeImpl get dynamicType => typeProvider.dynamicType;

  NeverTypeImpl get neverNone => NeverTypeImpl.instance;

  NeverTypeImpl get neverQuestion => NeverTypeImpl.instanceNullable;

  NeverTypeImpl get neverStar => NeverTypeImpl.instanceLegacy;

  TypeProvider get typeProvider;

  ClassElementImpl class_({
    @required String name,
    bool isAbstract = false,
    InterfaceType superType,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType> interfaces = const [],
    List<InterfaceType> mixins = const [],
    List<MethodElement> methods = const [],
  }) {
    var element = ClassElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.supertype = superType ?? typeProvider.objectType;
    element.interfaces = interfaces;
    element.mixins = mixins;
    element.methods = methods;
    return element;
  }

  FunctionTypeImpl functionType({
    @required List<TypeParameterElement> typeFormals,
    @required List<ParameterElement> parameters,
    @required DartType returnType,
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionType functionTypeAliasType(
    FunctionTypeAliasElement element, {
    List<DartType> typeArguments = const [],
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionTypeImpl functionTypeNone({
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
    @required DartType returnType,
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
    @required DartType returnType,
  }) {
    return functionType(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  FunctionTypeImpl functionTypeStar({
    List<TypeParameterElement> typeFormals = const [],
    List<ParameterElement> parameters = const [],
    @required DartType returnType,
  }) {
    return functionType(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  DartType futureType(DartType T) {
    var futureElement = typeProvider.futureElement;
    return interfaceType(futureElement, typeArguments: [T]);
  }

  GenericFunctionTypeElementImpl genericFunctionType({
    List<TypeParameterElement> typeParameters,
    List<ParameterElement> parameters,
    DartType returnType,
  }) {
    var result = GenericFunctionTypeElementImpl.forOffset(0);
    result.typeParameters = typeParameters;
    result.parameters = parameters;
    result.returnType = returnType ?? typeProvider.voidType;
    return result;
  }

  GenericTypeAliasElementImpl genericTypeAlias({
    @required String name,
    List<TypeParameterElement> typeParameters = const [],
    @required GenericFunctionTypeElement function,
  }) {
    return GenericTypeAliasElementImpl(name, 0)
      ..typeParameters = typeParameters
      ..function = function;
  }

  InterfaceType interfaceType(
    ClassElement element, {
    List<DartType> typeArguments = const [],
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return InterfaceTypeImpl.explicit(
      element,
      typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  MethodElement method(
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
    @required String name,
    List<TypeParameterElement> typeParameters = const [],
    List<InterfaceType> constraints,
    List<InterfaceType> interfaces = const [],
  }) {
    var element = MixinElementImpl(name, 0);
    element.typeParameters = typeParameters;
    element.superclassConstraints = constraints ?? [typeProvider.objectType];
    element.interfaces = interfaces;
    element.constructors = const <ConstructorElement>[];
    return element;
  }

  ParameterElement namedParameter({
    @required String name,
    @required DartType type,
  }) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    return parameter;
  }

  ParameterElement namedRequiredParameter({
    @required String name,
    @required DartType type,
  }) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED_REQUIRED;
    parameter.type = type;
    return parameter;
  }

  ParameterElement positionalParameter({String name, @required DartType type}) {
    var parameter = ParameterElementImpl(name ?? '', 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  ParameterElement requiredParameter({String name, @required DartType type}) {
    var parameter = ParameterElementImpl(name ?? '', 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  TypeParameterElementImpl typeParameter(String name,
      {DartType bound, Variance variance}) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound;
    element.variance = variance;
    return element;
  }

  TypeParameterTypeImpl typeParameterType(
    TypeParameterElement element, {
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return TypeParameterTypeImpl(
      element,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  TypeParameterTypeImpl typeParameterTypeNone(TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.none);
  }

  TypeParameterTypeImpl typeParameterTypeQuestion(
      TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.question);
  }

  TypeParameterTypeImpl typeParameterTypeStar(TypeParameterElement element) {
    return element.instantiate(nullabilitySuffix: NullabilitySuffix.star);
  }
}
