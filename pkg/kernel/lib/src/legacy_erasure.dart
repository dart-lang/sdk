// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;
import '../core_types.dart';

import 'replacement_visitor.dart';

/// Returns legacy erasure of [type], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
DartType legacyErasure(CoreTypes coreTypes, DartType type) {
  return rawLegacyErasure(coreTypes, type) ?? type;
}

/// Returns legacy erasure of [type], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
///
/// Returns `null` if the type wasn't changed.
DartType rawLegacyErasure(CoreTypes coreTypes, DartType type) {
  return type.accept(new _LegacyErasure(coreTypes));
}

/// Returns legacy erasure of [supertype], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
Supertype legacyErasureSupertype(CoreTypes coreTypes, Supertype supertype) {
  if (supertype.typeArguments.isEmpty) {
    return supertype;
  }
  List<DartType> newTypeArguments;
  for (int i = 0; i < supertype.typeArguments.length; i++) {
    DartType typeArgument = supertype.typeArguments[i];
    DartType newTypeArgument =
        typeArgument.accept(new _LegacyErasure(coreTypes));
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
  final CoreTypes coreTypes;

  _LegacyErasure(this.coreTypes);

  Nullability visitNullability(DartType node) {
    if (node.nullability != Nullability.legacy) {
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
  DartType visitInterfaceType(InterfaceType node) {
    if (node.classNode == coreTypes.nullClass) return null;
    return super.visitInterfaceType(node);
  }

  @override
  DartType visitNeverType(NeverType node) => coreTypes.nullType;
}
