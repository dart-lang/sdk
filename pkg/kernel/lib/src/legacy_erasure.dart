// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
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
DartType? rawLegacyErasure(DartType type) {
  return type.accept1(const _LegacyErasure(), Variance.covariant);
}

/// Returns legacy erasure of [supertype], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
Supertype legacyErasureSupertype(Supertype supertype) {
  if (supertype.typeArguments.isEmpty) {
    return supertype;
  }
  List<DartType>? newTypeArguments;
  for (int i = 0; i < supertype.typeArguments.length; i++) {
    DartType typeArgument = supertype.typeArguments[i];
    DartType? newTypeArgument =
        typeArgument.accept1(const _LegacyErasure(), Variance.covariant);
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

  @override
  Nullability? visitNullability(DartType node) {
    if (node.declaredNullability != Nullability.legacy) {
      return Nullability.legacy;
    }
    return null;
  }

  @override
  NamedType? createNamedType(NamedType node, DartType? newType) {
    if (node.isRequired || newType != null) {
      return new NamedType(node.name, newType ?? node.type, isRequired: false);
    }
    return null;
  }

  @override
  DartType visitNeverType(NeverType node, int variance) => const NullType();
}

/// Returns `true` if a member declared in [declaringClass] inherited or
/// mixed into [enclosingClass] needs legacy erasure to compute its inherited
/// type.
///
/// For instance:
///
///    // Opt in:
///    class Super {
///      int extendedMethod(int i, {required int j}) => i;
///    }
///    class Mixin {
///      int mixedInMethod(int i, {required int j}) => i;
///    }
///    // Opt out:
///    class Legacy extends Super with Mixin {}
///    // Opt in:
///    class Class extends Legacy {
///      test() {
///        // Ok to call `Legacy.extendedMethod` since its type is
///        // `int* Function(int*, {int* j})`.
///        super.extendedMethod(null);
///        // Ok to call `Legacy.mixedInMethod` since its type is
///        // `int* Function(int*, {int* j})`.
///        super.mixedInMethod(null);
///      }
///    }
///
bool needsLegacyErasure(Class enclosingClass, Class declaringClass) {
  Class? cls = enclosingClass;
  while (cls != null) {
    if (!cls.enclosingLibrary.isNonNullableByDefault) {
      return true;
    }
    if (cls == declaringClass) {
      return false;
    }
    if (cls.mixedInClass == declaringClass) {
      return false;
    }
    cls = cls.superclass;
  }
  return false;
}
