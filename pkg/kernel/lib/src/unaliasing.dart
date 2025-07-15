// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/type_algebra.dart';

import '../ast.dart';
import 'replacement_visitor.dart';

/// Replaces all occurrences of [TypedefType] in [type] with the corresponding
/// unaliased type.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
DartType unalias(DartType type) {
  return rawUnalias(type) ?? type;
}

/// Replaces all occurrences of [TypedefType] in [types] with the corresponding
/// unaliased types.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
List<DartType>? unaliasTypes(List<DartType>? types) {
  if (types == null) return null;
  return rawUnaliasTypes(types) ?? types;
}

/// Replaces all occurrences of [TypedefType] in [type] with the corresponding
/// unaliased type, or returns `null` if no [TypedefType]s were found.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
DartType? rawUnalias(DartType type) {
  return type.accept1(const _Unalias(), Variance.covariant);
}

/// Replaces all occurrences of [TypedefType] in [types] with the corresponding
/// unaliased types, or returns `null` if no [TypedefType]s were found.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
List<DartType>? rawUnaliasTypes(List<DartType> types) {
  List<DartType>? newTypes;
  for (int i = 0; i < types.length; i++) {
    DartType typeArgument = types[i];
    DartType? newTypeArgument = rawUnalias(typeArgument);
    if (newTypeArgument != null) {
      newTypes ??= types.toList(growable: false);
      newTypes[i] = newTypeArgument;
    }
  }
  return newTypes;
}

/// Visitor that replaces all occurrences of [TypedefType] with the
/// corresponding unaliased type, or returns `null` if no type was replaced.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
class _Unalias extends ReplacementVisitor {
  const _Unalias();

  @override
  DartType visitTypedefType(TypedefType node, Variance variance) {
    DartType result;
    if (node.typeArguments.isNotEmpty) {
      List<DartType>? newTypeArguments = null;
      for (int i = 0; i < node.typeArguments.length; i++) {
        DartType? substitution = node.typeArguments[i].accept1(this, variance);
        if (substitution != null) {
          newTypeArguments ??= node.typeArguments.toList(growable: false);
          newTypeArguments[i] = substitution;
        }
      }
      if (newTypeArguments != null) {
        result = new TypedefType(
                node.typedefNode, node.nullability, newTypeArguments)
            .unalias;
      } else {
        result = node.unalias;
      }
    } else {
      result = node.unalias;
    }
    result = result.withDeclaredNullability(uniteNullabilities(
        node.declaredNullability, result.declaredNullability));
    return result;
  }
}
