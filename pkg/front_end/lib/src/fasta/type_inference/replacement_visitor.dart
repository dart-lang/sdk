// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' hide MapEntry;

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor implements DartTypeVisitor<DartType> {
  const ReplacementVisitor();

  void changeVariance() {}

  @override
  DartType visitFunctionType(FunctionType node) {
    DartType newReturnType = node.returnType.accept(this);
    changeVariance();
    List<DartType> newPositionalParameters = null;
    for (int i = 0; i < node.positionalParameters.length; i++) {
      DartType substitution = node.positionalParameters[i].accept(this);
      if (substitution != null) {
        newPositionalParameters ??=
            node.positionalParameters.toList(growable: false);
        newPositionalParameters[i] = substitution;
      }
    }
    List<NamedType> newNamedParameters = null;
    for (int i = 0; i < node.namedParameters.length; i++) {
      DartType substitution = node.namedParameters[i].type.accept(this);
      if (substitution != null) {
        newNamedParameters ??= node.namedParameters.toList(growable: false);
        newNamedParameters[i] = new NamedType(
            node.namedParameters[i].name, substitution,
            isRequired: node.namedParameters[i].isRequired);
      }
    }
    changeVariance();
    DartType typedefType = node.typedefType?.accept(this);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null &&
        typedefType == null) {
      // No types had to be substituted.
      return null;
    } else {
      return new FunctionType(
          newPositionalParameters ?? node.positionalParameters,
          newReturnType ?? node.returnType,
          node.nullability,
          namedParameters: newNamedParameters ?? node.namedParameters,
          typeParameters: node.typeParameters,
          requiredParameterCount: node.requiredParameterCount,
          typedefType: typedefType);
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
      if (newPromotedBound != null) {
        return new TypeParameterType(node.parameter,
            node.typeParameterTypeNullability, newPromotedBound);
      }
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
