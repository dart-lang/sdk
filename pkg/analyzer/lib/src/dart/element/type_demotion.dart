// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';

/// Returns [type] in which all promoted type variables have been replace with
/// their unpromoted equivalents, and, if [library] is non-nullable by default,
/// replaces all legacy types with their non-nullable equivalents.
DartType demoteType(LibraryElement library, DartType type) {
  if (library.isNonNullableByDefault) {
    var visitor = const _DemotionNonNullification();
    return visitor.visit(type) ?? type;
  } else {
    var visitor = const _DemotionNonNullification(nonNullifyTypes: false);
    return visitor.visit(type) ?? type;
  }
}

/// Returns `true` if type contains a promoted type variable.
bool hasPromotedTypeVariable(DartType type) {
  return const _HasPromotedTypeVariableVisitor()._visit(type);
}

/// Returns [type] in which all legacy types have been replaced with
/// non-nullable types.
DartType nonNullifyType(TypeSystemImpl typeSystem, DartType type) {
  if (typeSystem.isNonNullableByDefault && type != null) {
    var visitor = const _DemotionNonNullification(demoteTypeVariables: false);
    return visitor.visit(type) ?? type;
  }
  return type;
}

/// Visitor that replaces all promoted type variables the type variable itself
/// and/or replaces all legacy types with non-nullable types.
///
/// The visitor returns `null` if the type wasn't changed.
class _DemotionNonNullification extends ReplacementVisitor {
  final bool demoteTypeVariables;
  final bool nonNullifyTypes;

  const _DemotionNonNullification({
    this.demoteTypeVariables = true,
    this.nonNullifyTypes = true,
  }) : assert(demoteTypeVariables || nonNullifyTypes);

  @override
  NullabilitySuffix visitNullability(DartType type) {
    if (nonNullifyTypes && type.nullabilitySuffix == NullabilitySuffix.star) {
      return NullabilitySuffix.none;
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType type) {
    var newNullability = visitNullability(type);

    if (demoteTypeVariables) {
      var typeImpl = type as TypeParameterTypeImpl;
      if (typeImpl.promotedBound != null) {
        return TypeParameterTypeImpl(
          element: type.element,
          nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
        );
      }
    }

    return createTypeParameterType(
      type: type,
      newNullability: newNullability,
    );
  }
}

/// Visitor that returns `true` if a type contains a promoted type variable.
class _HasPromotedTypeVariableVisitor extends DartTypeVisitor<bool> {
  const _HasPromotedTypeVariableVisitor();

  @override
  bool defaultDartType(DartType type) => false;

  @override
  bool visitFunctionType(FunctionType type) {
    if (_visit(type.returnType)) {
      return true;
    }

    for (var parameter in type.parameters) {
      if (_visit(parameter.type)) {
        return true;
      }
    }

    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      if (_visit(typeArgument)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    return (type as TypeParameterTypeImpl).promotedBound != null;
  }

  bool _visit(DartType type) {
    return DartTypeVisitor.visit(type, this);
  }
}
