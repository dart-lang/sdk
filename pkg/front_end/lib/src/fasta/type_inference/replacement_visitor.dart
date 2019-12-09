// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/type_algebra.dart';

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor implements DartTypeVisitor<DartType> {
  const ReplacementVisitor();

  void changeVariance() {}

  @override
  DartType visitFunctionType(FunctionType node) {
    List<TypeParameter> newTypeParameters;
    for (int i = 0; i < node.typeParameters.length; i++) {
      TypeParameter typeParameter = node.typeParameters[i];
      DartType newBound = typeParameter.bound.accept(this);
      DartType newDefaultType = typeParameter.defaultType.accept(this);
      if (newBound != null || newDefaultType != null) {
        newTypeParameters ??= node.typeParameters.toList(growable: false);
        newTypeParameters[i] = new TypeParameter(
            typeParameter.name,
            newBound ?? typeParameter.bound,
            newDefaultType ?? typeParameter.defaultType);
      }
    }

    Substitution substitution;
    if (newTypeParameters != null) {
      List<TypeParameterType> typeParameterTypes =
          new List<TypeParameterType>(newTypeParameters.length);
      for (int i = 0; i < newTypeParameters.length; i++) {
        typeParameterTypes[i] = new TypeParameterType.forAlphaRenaming(
            node.typeParameters[i], newTypeParameters[i]);
      }
      substitution =
          Substitution.fromPairs(node.typeParameters, typeParameterTypes);
      for (int i = 0; i < newTypeParameters.length; i++) {
        newTypeParameters[i].bound =
            substitution.substituteType(newTypeParameters[i].bound);
      }
    }

    DartType visitType(DartType type) {
      if (type == null) return null;
      DartType result = type.accept(this);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      return result;
    }

    DartType newReturnType = visitType(node.returnType);
    changeVariance();
    List<DartType> newPositionalParameters = null;
    for (int i = 0; i < node.positionalParameters.length; i++) {
      DartType newType = visitType(node.positionalParameters[i]);
      if (newType != null) {
        newPositionalParameters ??=
            node.positionalParameters.toList(growable: false);
        newPositionalParameters[i] = newType;
      }
    }
    List<NamedType> newNamedParameters = null;
    for (int i = 0; i < node.namedParameters.length; i++) {
      DartType newType = visitType(node.namedParameters[i].type);
      NamedType newNamedType =
          createNamedType(node.namedParameters[i], newType);
      if (newNamedType != null) {
        newNamedParameters ??= node.namedParameters.toList(growable: false);
        newNamedParameters[i] = newNamedType;
      }
    }
    changeVariance();
    DartType newTypedefType = visitType(node.typedefType);

    return createFunctionType(node, newTypeParameters, newReturnType,
        newPositionalParameters, newNamedParameters, newTypedefType);
  }

  NamedType createNamedType(NamedType node, DartType newType) {
    if (newType == null) {
      return null;
    } else {
      return new NamedType(node.name, newType, isRequired: node.isRequired);
    }
  }

  DartType createFunctionType(
      FunctionType node,
      List<TypeParameter> newTypeParameters,
      DartType newReturnType,
      List<DartType> newPositionalParameters,
      List<NamedType> newNamedParameters,
      TypedefType newTypedefType) {
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null &&
        newTypedefType == null) {
      // No types had to be substituted.
      return null;
    } else {
      return new FunctionType(
          newPositionalParameters ?? node.positionalParameters,
          newReturnType ?? node.returnType,
          node.nullability,
          namedParameters: newNamedParameters ?? node.namedParameters,
          typeParameters: newTypeParameters ?? node.typeParameters,
          requiredParameterCount: node.requiredParameterCount,
          typedefType: newTypedefType ?? node.typedefType);
    }
  }

  @override
  DartType visitInterfaceType(InterfaceType node) {
    List<DartType> newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType substitution = node.typeArguments[i].accept(this);
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    return createInterfaceType(node, newTypeArguments);
  }

  DartType createInterfaceType(
      InterfaceType node, List<DartType> newTypeArguments) {
    if (newTypeArguments == null) {
      // No type arguments needed to be substituted.
      return null;
    } else {
      return new InterfaceType(
          node.classNode, node.nullability, newTypeArguments);
    }
  }

  @override
  DartType visitDynamicType(DynamicType node) => null;

  @override
  DartType visitNeverType(NeverType node) => null;

  @override
  DartType visitInvalidType(InvalidType node) => null;

  @override
  DartType visitBottomType(BottomType node) => null;

  @override
  DartType visitVoidType(VoidType node) => null;

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    if (node.promotedBound != null) {
      DartType newPromotedBound = node.promotedBound.accept(this);
      return createPromotedTypeParameterType(node, newPromotedBound);
    }
    return createTypeParameterType(node);
  }

  DartType createTypeParameterType(TypeParameterType node) {
    return null;
  }

  DartType createPromotedTypeParameterType(
      TypeParameterType node, DartType newPromotedBound) {
    if (newPromotedBound != null) {
      return new TypeParameterType(
          node.parameter, node.typeParameterTypeNullability, newPromotedBound);
    }
    return null;
  }

  @override
  DartType visitTypedefType(TypedefType node) {
    List<DartType> newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType substitution = node.typeArguments[i].accept(this);
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    if (newTypeArguments == null) {
      // No type arguments needed to be substituted.
      return null;
    } else {
      return new TypedefType(
          node.typedefNode, node.nullability, newTypeArguments);
    }
  }

  @override
  DartType defaultDartType(DartType node) => null;
}
