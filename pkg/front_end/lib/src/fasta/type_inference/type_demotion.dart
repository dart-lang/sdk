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
/// their unpromoted equivalents, and where all nullabilities have been
/// normalized to the default nullability of [library].
///
/// If [library] is non-nullable by default all legacy types have been replaced
/// with non-nullable types. Otherwise all non-legacy types have been replaced
/// with legacy types.
DartType demoteTypeInLibrary(DartType type, Library library) {
  if (library.isNonNullableByDefault) {
    return type.accept(const _DemotionNullabilityNormalization(
            demoteTypeVariables: true, forNonNullableByDefault: true)) ??
        type;
  } else {
    return type.accept(const _DemotionNullabilityNormalization(
            demoteTypeVariables: true, forNonNullableByDefault: false)) ??
        type;
  }
}

/// Returns [type] normalized to the known nullabilities of [library].
///
/// If [library] is non-nullable by default [type] returned (non-nullable
/// libraries can handle all kinds of nullability). Otherwise all
/// non-legacy types have been replaced with legacy types (legacy libraries
/// can only handle legacy types).
DartType normalizeNullabilityInLibrary(DartType type, Library library) {
  if (library.isNonNullableByDefault) {
    return type;
  } else {
    return type.accept(const _DemotionNullabilityNormalization(
            demoteTypeVariables: false, forNonNullableByDefault: false)) ??
        type;
  }
}

/// Visitor that replaces all promoted type variables the type variable itself
/// and normalizes the type nullabilities.
///
/// The visitor returns `null` if the type wasn't changed.
class _DemotionNullabilityNormalization extends ReplacementVisitor {
  final bool demoteTypeVariables;
  final bool forNonNullableByDefault;

  const _DemotionNullabilityNormalization(
      {this.demoteTypeVariables, this.forNonNullableByDefault})
      : assert(demoteTypeVariables != null),
        assert(forNonNullableByDefault != null);

  @override
  Nullability visitNullability(DartType node) {
    if (forNonNullableByDefault) {
      if (node.declaredNullability == Nullability.legacy) {
        return Nullability.nonNullable;
      }
    } else {
      if (node.declaredNullability != Nullability.legacy) {
        return Nullability.legacy;
      }
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    Nullability newNullability = visitNullability(node);
    if (demoteTypeVariables && node.promotedBound != null) {
      return new TypeParameterType(
          node.parameter, newNullability ?? node.declaredNullability);
    }
    return createTypeParameterType(node, newNullability);
  }
}
