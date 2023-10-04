// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/type_algebra.dart';

import '../ast.dart';
import 'legacy_erasure.dart';
import 'replacement_visitor.dart';

/// Replaces all occurrences of [TypedefType] in [type] with the corresponding
/// unaliased type.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
DartType unalias(DartType type, {required bool legacyEraseAliases}) {
  return rawUnalias(type, legacyEraseAliases: legacyEraseAliases) ?? type;
}

/// Replaces all occurrences of [TypedefType] in [types] with the corresponding
/// unaliased types.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
List<DartType>? unaliasTypes(List<DartType>? types,
    {required bool legacyEraseAliases}) {
  if (types == null) return null;
  return rawUnaliasTypes(types, legacyEraseAliases: legacyEraseAliases) ??
      types;
}

/// Replaces all occurrences of [TypedefType] in [type] with the corresponding
/// unaliased type, or returns `null` if no [TypedefType]s were found.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
DartType? rawUnalias(DartType type, {required bool legacyEraseAliases}) {
  return type.accept1(
      legacyEraseAliases
          ? const _Unalias(legacyEraseAliases: true)
          : const _Unalias(legacyEraseAliases: false),
      Variance.covariant);
}

/// Replaces all occurrences of [TypedefType] in [types] with the corresponding
/// unaliased types, or returns `null` if no [TypedefType]s were found.
///
/// If [legacyEraseAliases] is `true`, the unaliased types will be legacy
/// erased. This used when the [TypedefType] was used in a legacy library.
List<DartType>? rawUnaliasTypes(List<DartType> types,
    {required bool legacyEraseAliases}) {
  List<DartType>? newTypes;
  for (int i = 0; i < types.length; i++) {
    DartType typeArgument = types[i];
    DartType? newTypeArgument =
        rawUnalias(typeArgument, legacyEraseAliases: legacyEraseAliases);
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
  final bool legacyEraseAliases;

  const _Unalias({required this.legacyEraseAliases});

  @override
  DartType visitTypedefType(TypedefType node, int variance) {
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
    if (node.nullability == Nullability.legacy ||
        node.typedefNode.type!.nullability == Nullability.legacy) {
      // The typedef is defined or used in an opt-out library so the nullability
      // is based on the use site alone.
      result = result.withDeclaredNullability(node.nullability);
    } else {
      result = result.withDeclaredNullability(
          uniteNullabilities(node.nullability, result.nullability));
    }
    if (legacyEraseAliases) {
      result = legacyErasure(result);
    }
    return result;
  }
}
