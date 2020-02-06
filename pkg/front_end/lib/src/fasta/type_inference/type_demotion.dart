// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/replacement_visitor.dart';

/// Returns `true` if type contains a promoted type variable.
bool hasPromotedTypeVariable(DartType type) {
  return type.accept(const _HasPromotedTypeVariableVisitor());
}

/// Visitor that returns `true` if a type contains a promoted type variable.
class _HasPromotedTypeVariableVisitor extends DartTypeVisitor<bool> {
  const _HasPromotedTypeVariableVisitor();

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    for (DartType parameterType in node.positionalParameters) {
      if (parameterType.accept(this)) return true;
    }
    for (NamedType namedParameterType in node.namedParameters) {
      if (namedParameterType.type.accept(this)) return true;
    }
    if (node.typedefType != null && node.typedefType.accept(this)) {
      return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return node.promotedBound != null;
  }
}

/// Returns [type] in which all promoted type variables have been replace with
/// their unpromoted equivalents, and, if [library] is non-nullable by default,
/// replaces all legacy types with their non-nullable equivalents.
DartType demoteTypeInLibrary(DartType type, Library library) {
  if (library.isNonNullableByDefault) {
    return type.accept(const _DemotionNonNullification()) ?? type;
  } else {
    return type
            .accept(const _DemotionNonNullification(nonNullifyTypes: false)) ??
        type;
  }
}

/// Returns [type] in which all legacy types have been replaced with
/// non-nullable types.
DartType nonNullifyInLibrary(DartType type, Library library) {
  if (library.isNonNullableByDefault) {
    return type.accept(
            const _DemotionNonNullification(demoteTypeVariables: false)) ??
        type;
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

  const _DemotionNonNullification(
      {this.demoteTypeVariables: true, this.nonNullifyTypes: true})
      : assert(demoteTypeVariables || nonNullifyTypes);

  @override
  Nullability visitNullability(DartType node) {
    if (nonNullifyTypes && node.nullability == Nullability.legacy) {
      return Nullability.nonNullable;
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    Nullability newNullability = visitNullability(node);
    if (demoteTypeVariables && node.promotedBound != null) {
      return new TypeParameterType(
          node.parameter, newNullability ?? node.typeParameterTypeNullability);
    }
    return createTypeParameterType(node, newNullability);
  }
}
