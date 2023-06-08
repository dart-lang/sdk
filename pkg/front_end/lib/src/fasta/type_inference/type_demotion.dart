// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';
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
  bool visitTypeParameterType(TypeParameterType node) => false;

  @override
  bool visitIntersectionType(IntersectionType node) => true;
}

/// Returns [type] in which all promoted type variables have been replace with
/// their unpromoted equivalents, and where all nullabilities have been
/// normalized to the default nullability of [library].
///
/// If [library] is non-nullable by default all legacy types have been replaced
/// with non-nullable types. Otherwise all non-legacy types have been replaced
/// with legacy types.
DartType demoteTypeInLibrary(DartType type,
    {required bool isNonNullableByDefault}) {
  if (isNonNullableByDefault) {
    return type.accept1(
            const _DemotionNullabilityNormalization(
                demoteTypeVariables: true, forNonNullableByDefault: true),
            Variance.covariant) ??
        type;
  } else {
    return type.accept1(
            const _DemotionNullabilityNormalization(
                demoteTypeVariables: true, forNonNullableByDefault: false),
            Variance.covariant) ??
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
    return type.accept1(
            const _DemotionNullabilityNormalization(
                demoteTypeVariables: false, forNonNullableByDefault: false),
            Variance.covariant) ??
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
      {required this.demoteTypeVariables,
      required this.forNonNullableByDefault});

  @override
  Nullability? visitNullability(DartType node) {
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
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    Nullability? newNullability = visitNullability(node);
    return createTypeParameterType(node, newNullability);
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, int variance) {
    Nullability? newNullability = visitNullability(node);
    if (demoteTypeVariables) {
      return new TypeParameterType(
          node.left.parameter, newNullability ?? node.left.nullability);
    }
    return createTypeParameterType(node.left, newNullability);
  }
}
