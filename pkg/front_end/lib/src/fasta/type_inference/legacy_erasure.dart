// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart';

import 'replacement_visitor.dart';

/// Returns legacy erasure of [type], that is, the type in which all nnbd
/// nullabilities have been replaced with legacy nullability, and all required
/// named parameters are not required.
DartType legacyErasure(CoreTypes coreTypes, DartType type) {
  return type.accept(new _LegacyErasure(coreTypes)) ?? type;
}

/// Visitor that replaces all nnbd nullabilities with legacy nullabilities and
/// all required named parameters with optional named parameters.
///
/// The visitor returns `null` if the type wasn't changed.
class _LegacyErasure extends ReplacementVisitor {
  final CoreTypes coreTypes;

  _LegacyErasure(this.coreTypes);

  @override
  NamedType createNamedType(NamedType node, DartType newType) {
    if (node.isRequired || newType != null) {
      return new NamedType(node.name, newType ?? node.type, isRequired: false);
    }
    return null;
  }

  @override
  DartType createFunctionType(
      FunctionType node,
      List<TypeParameter> newTypeParameters,
      DartType newReturnType,
      List<DartType> newPositionalParameters,
      List<NamedType> newNamedParameters,
      TypedefType newTypedefType) {
    if (node.nullability != Nullability.legacy ||
        newTypeParameters != null ||
        newReturnType != null ||
        newPositionalParameters != null ||
        newNamedParameters != null ||
        newTypedefType != null) {
      return new FunctionType(
          newPositionalParameters ?? node.positionalParameters,
          newReturnType ?? node.returnType,
          Nullability.legacy,
          namedParameters: newNamedParameters ?? node.namedParameters,
          typeParameters: newTypeParameters ?? node.typeParameters,
          requiredParameterCount: node.requiredParameterCount,
          typedefType: newTypedefType ?? node.typedefType);
    }
    return null;
  }

  @override
  DartType createInterfaceType(
      InterfaceType node, List<DartType> newTypeArguments) {
    if (node.classNode == coreTypes.nullClass) return null;

    if (node.nullability != Nullability.legacy || newTypeArguments != null) {
      return new InterfaceType(node.classNode, Nullability.legacy,
          newTypeArguments ?? node.typeArguments);
    }
    return null;
  }

  DartType createTypeParameterType(TypeParameterType node) {
    if (node.nullability != Nullability.legacy) {
      return new TypeParameterType(node.parameter, Nullability.legacy);
    }
    return null;
  }

  DartType createPromotedTypeParameterType(
      TypeParameterType node, DartType newPromotedBound) {
    if (node.nullability != Nullability.legacy || newPromotedBound != null) {
      return new TypeParameterType(
          node.parameter, Nullability.legacy, newPromotedBound);
    }
    return null;
  }

  @override
  DartType visitNeverType(NeverType node) => coreTypes.nullType;
}
