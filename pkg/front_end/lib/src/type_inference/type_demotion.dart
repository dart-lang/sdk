// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/find_type_visitor.dart';
import 'package:kernel/src/replacement_visitor.dart';

/// Returns `true` if type contains a promoted type parameter.
bool hasPromotedTypeParameter(DartType type) {
  return type.accept(const _HasPromotedTypeParameterVisitor());
}

/// Visitor that returns `true` if a type contains a promoted type parameter.
class _HasPromotedTypeParameterVisitor extends FindTypeVisitor {
  const _HasPromotedTypeParameterVisitor();

  @override
  // Coverage-ignore(suite): Not run.
  bool visitIntersectionType(IntersectionType node) => true;
}

/// Returns [type] in which all promoted type parameters have been replace with
/// their unpromoted equivalents, and where all nullabilities have been
/// normalized to the default nullability of [library].
///
/// If [library] is non-nullable by default all legacy types have been replaced
/// with non-nullable types. Otherwise all non-legacy types have been replaced
/// with legacy types.
DartType demoteTypeInLibrary(DartType type) {
  return type.accept1(
        const _DemotionNullabilityNormalization(),
        Variance.covariant,
      ) ??
      type;
}

/// Visitor that replaces all promoted type parameters the type parameter itself
/// and normalizes the type nullabilities.
///
/// The visitor returns `null` if the type wasn't changed.
class _DemotionNullabilityNormalization extends ReplacementVisitor {
  const _DemotionNullabilityNormalization();

  @override
  Nullability? visitNullability(DartType node) {
    return null;
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    return createTypeParameterType(node, newNullability);
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    return new TypeParameterType(
      node.left.parameter,
      newNullability ?? node.left.nullability,
    );
  }
}
