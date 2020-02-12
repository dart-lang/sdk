// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

/// TODO(scheglov) Rewrite using `ReplacementVisitor`, once we have it.
class NullabilityEliminator extends DartTypeVisitor<DartType> {
  final TypeProviderImpl _typeProvider;

  int _counter = 0;

  NullabilityEliminator(this._typeProvider);

  @override
  DartType defaultDartType(DartType type) {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  DartType visit(DartType type) {
    return DartTypeVisitor.visit(type, this);
  }

  @override
  DartType visitDynamicType(DynamicTypeImpl type) {
    return type;
  }

  @override
  DartType visitFunctionType(FunctionType type) {
    var before = _counter;
    _incrementCounterIfNotLegacy(type);

    type = _freshTypeParameters(type);

    var parameters = type.parameters.map(_parameterElement).toList();

    var returnType = visit(type.returnType);
    var typeArguments = type.typeArguments.map(visit).toList();

    if (_counter == before) {
      return type;
    }

    return FunctionTypeImpl(
      typeFormals: type.typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: NullabilitySuffix.star,
      element: type.element,
      typeArguments: typeArguments,
    );
  }

  @override
  DartType visitInterfaceType(InterfaceType type) {
    var before = _counter;
    _incrementCounterIfNotLegacy(type);

    var typeArguments = type.typeArguments;
    if (typeArguments.isNotEmpty) {
      typeArguments = type.typeArguments.map(visit).toList();
    }

    if (_counter == before) {
      return type;
    }

    return type.element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  @override
  DartType visitNeverType(NeverTypeImpl type) {
    _counter++;
    return _typeProvider.nullStar;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType type) {
    var before = _counter;
    _incrementCounterIfNotLegacy(type);

    if (_counter == before) {
      return type;
    }

    return type.element.instantiate(
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  @override
  DartType visitUnknownInferredType(UnknownInferredType type) {
    return type;
  }

  @override
  DartType visitVoidType(VoidType type) {
    return type;
  }

  /// If the [type] has type parameters, and any of them has bounds with
  /// nullability to eliminate, return a new [FunctionType] instance, with
  /// new type parameters with legacy types as their bounds, incrementing
  /// [_counter] as necessary. Otherwise return the original [type] instance.
  FunctionType _freshTypeParameters(FunctionType type) {
    var elements = type.typeFormals;
    if (elements.isEmpty) {
      return type;
    }

    var before = _counter;

    var freshBounds = List<DartType>(elements.length);
    for (var i = 0; i < elements.length; i++) {
      var bound = elements[i].bound;
      if (bound != null) {
        freshBounds[i] = visit(bound);
      }
    }

    if (_counter == before) {
      return type;
    }

    var freshElements = List<TypeParameterElement>(elements.length);
    var substitutionMap = <TypeParameterElement, TypeParameterType>{};
    for (var i = 0; i < elements.length; i++) {
      // TODO (kallentu) : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      var element = elements[i] as TypeParameterElementImpl;
      var freshElement = TypeParameterElementImpl(element.name, -1);
      if (!element.isLegacyCovariant) {
        freshElement.variance = element.variance;
      }
      freshElements[i] = freshElement;
      substitutionMap[element] = freshElement.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    var substitution = Substitution.fromMap(substitutionMap);
    for (var i = 0; i < elements.length; i++) {
      var bound = freshBounds[i];
      if (bound != null) {
        var freshElement = freshElements[i] as TypeParameterElementImpl;
        freshElement.bound = substitution.substituteType(bound);
      }
    }

    FunctionType newType = replaceTypeParameters(type, freshElements);
    return FunctionTypeImpl(
      typeFormals: freshElements,
      parameters: newType.parameters,
      returnType: newType.returnType,
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void _incrementCounterIfNotLegacy(DartType type) {
    if (type.nullabilitySuffix != NullabilitySuffix.star) {
      _counter++;
    }
  }

  ParameterElementImpl _parameterElement(ParameterElement parameter) {
    var type = visit(parameter.type);

    // ignore: deprecated_member_use_from_same_package
    var parameterKind = parameter.parameterKind;
    if (parameter.isRequiredNamed) {
      parameterKind = ParameterKind.NAMED;
      _counter++;
    }

    var result = ParameterElementImpl.synthetic(
      parameter.name,
      type,
      parameterKind,
    );
    result.isExplicitlyCovariant = parameter.isCovariant;
    return result;
  }

  /// If the [type] itself, or any of its components, has any nullability,
  /// return a new type with legacy nullability suffixes. Otherwise return the
  /// original instance.
  static T perform<T extends DartType>(TypeProviderImpl typeProvider, T type) {
    if (type == null) {
      return type;
    }

    return NullabilityEliminator(typeProvider).visit(type);
  }
}
