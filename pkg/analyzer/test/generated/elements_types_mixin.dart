// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

mixin ElementsTypesMixin {
  DynamicTypeImpl get dynamicType => typeProvider.dynamicType;

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

  FunctionType functionType({
    List<TypeParameterElement> typeFormals,
    List<DartType> required,
    List<DartType> optional,
    Map<String, DartType> named,
    DartType returns,
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    if (optional != null && named != null) {
      throw ArgumentError(
        'Cannot have both optional positional and named parameters.',
      );
    }

    var parameters = <ParameterElement>[];
    if (required != null) {
      for (var i = 0; i < required.length; ++i) {
        parameters.add(
          ParameterElementImpl.synthetic(
            'r$i',
            required[i],
            ParameterKind.REQUIRED,
          ),
        );
      }
    }
    if (optional != null) {
      for (var i = 0; i < optional.length; ++i) {
        parameters.add(
          ParameterElementImpl.synthetic(
            'p$i',
            optional[i],
            ParameterKind.POSITIONAL,
          ),
        );
      }
    }
    if (named != null) {
      for (var namedEntry in named.entries) {
        parameters.add(
          ParameterElementImpl.synthetic(
            namedEntry.key,
            namedEntry.value,
            ParameterKind.NAMED,
          ),
        );
      }
    }

    return FunctionTypeImpl.synthetic(
      returns ?? typeProvider.voidType,
      typeFormals ?? const <TypeParameterElement>[],
      parameters,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  FunctionType functionTypeAliasType(
    FunctionTypeAliasElement element, {
    List<DartType> typeArguments = const [],
    NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star,
  }) {
    return element.instantiate2(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
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
    var element = MethodElementImpl(name, 0)
      ..isStatic = isStatic
      ..parameters = parameters
      ..returnType = returnType
      ..typeParameters = typeFormals;
    element.type = _typeOfExecutableElement(element);
    return element;
  }

  ParameterElement namedParameter(String name, {@required DartType type}) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.NAMED;
    parameter.type = type;
    return parameter;
  }

  ParameterElement positionalParameter(String name, {@required DartType type}) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.POSITIONAL;
    parameter.type = type;
    return parameter;
  }

  ParameterElement requiredParameter(String name, {@required DartType type}) {
    var parameter = ParameterElementImpl(name, 0);
    parameter.parameterKind = ParameterKind.REQUIRED;
    parameter.type = type;
    return parameter;
  }

  TypeParameterElementImpl typeParameter(String name, {DartType bound}) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound;
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

  /// TODO(scheglov) We should do the opposite - build type in the element.
  /// But build a similar synthetic / structured type.
  FunctionType _typeOfExecutableElement(ExecutableElement element) {
    return FunctionTypeImpl.synthetic(
      element.returnType,
      element.typeParameters,
      element.parameters,
    );
  }
}
