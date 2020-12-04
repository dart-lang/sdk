// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;

import 'replacement_visitor.dart';

/// Returns legacy erasure of [type], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
DartType legacyErasure(DartType type) {
  return rawLegacyErasure(type) ?? type;
}

/// Returns legacy erasure of [type], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
///
/// Returns `null` if the type wasn't changed.
DartType rawLegacyErasure(DartType type) {
  return type.accept(const _LegacyErasure());
}

/// Returns legacy erasure of [supertype], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
Supertype legacyErasureSupertype(Supertype supertype) {
  if (supertype.typeArguments.isEmpty) {
    return supertype;
  }
  List<DartType> newTypeArguments;
  for (int i = 0; i < supertype.typeArguments.length; i++) {
    DartType typeArgument = supertype.typeArguments[i];
    DartType newTypeArgument = typeArgument.accept(const _LegacyErasure());
    if (newTypeArgument != null) {
      newTypeArguments ??= supertype.typeArguments.toList(growable: false);
      newTypeArguments[i] = newTypeArgument;
    }
  }
  if (newTypeArguments != null) {
    return new Supertype(supertype.classNode, newTypeArguments);
  }
  return supertype;
}

/// Visitor that replaces all nnbd nullabilities with legacy nullabilities and
/// all required named parameters with optional named parameters.
///
/// The visitor returns `null` if the type wasn't changed.
class _LegacyErasure extends ReplacementVisitor {
  const _LegacyErasure();

  Nullability visitNullability(DartType node) {
    if (node.declaredNullability != Nullability.legacy) {
      return Nullability.legacy;
    }
    return null;
  }

  @override
  NamedType createNamedType(NamedType node, DartType newType) {
    if (node.isRequired || newType != null) {
      return new NamedType(node.name, newType ?? node.type, isRequired: false);
    }
    return null;
  }

  @override
  DartType visitNeverType(NeverType node) => const NullType();
}
