// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;
import '../type_algebra.dart';

/// Helper visitor that merges two types, and return the merged type or `null`
/// if the types could not be merged.
class MergeVisitor implements DartTypeVisitor1<DartType, DartType> {
  Nullability mergeNullability(Nullability a, Nullability b) {
    return a == b ? a : null;
  }

  @override
  DartType visitFunctionType(FunctionType a, DartType b) {
    if (b is FunctionType &&
        a.typeParameters.length == b.typeParameters.length &&
        a.requiredParameterCount == b.requiredParameterCount &&
        a.positionalParameters.length == b.positionalParameters.length &&
        a.namedParameters.length == b.namedParameters.length) {
      Nullability nullability = mergeNullability(a.nullability, b.nullability);
      if (nullability != null) {
        return mergeFunctionTypes(a, b, nullability);
      }
    }
    return null;
  }

  FunctionType mergeFunctionTypes(
      FunctionType a, FunctionType b, Nullability nullability) {
    assert(a.typeParameters.length == b.typeParameters.length);
    assert(a.requiredParameterCount == b.requiredParameterCount);
    assert(a.positionalParameters.length == b.positionalParameters.length);
    assert(a.namedParameters.length == b.namedParameters.length);

    List<TypeParameter> newTypeParameters =
        new List<TypeParameter>.filled(a.typeParameters.length, null);
    for (int i = 0; i < a.typeParameters.length; i++) {
      TypeParameter aTypeParameter = a.typeParameters[i];
      TypeParameter bTypeParameter = b.typeParameters[i];
      newTypeParameters[i] =
          new TypeParameter(aTypeParameter.name ?? bTypeParameter.name);
    }

    Substitution aSubstitution;
    Substitution bSubstitution;

    DartType mergeTypes(DartType a, DartType b) {
      if (aSubstitution != null) {
        a = aSubstitution.substituteType(a);
        b = bSubstitution.substituteType(b);
      }
      return a.accept1(this, b);
    }

    if (newTypeParameters.isNotEmpty) {
      List<TypeParameterType> aTypeParameterTypes =
          new List<TypeParameterType>.filled(newTypeParameters.length, null);
      for (int i = 0; i < newTypeParameters.length; i++) {
        aTypeParameterTypes[i] = new TypeParameterType.forAlphaRenaming(
            a.typeParameters[i], newTypeParameters[i]);
      }
      aSubstitution =
          Substitution.fromPairs(a.typeParameters, aTypeParameterTypes);
      List<TypeParameterType> bTypeParameterTypes =
          new List<TypeParameterType>.filled(newTypeParameters.length, null);
      for (int i = 0; i < newTypeParameters.length; i++) {
        bTypeParameterTypes[i] = new TypeParameterType.forAlphaRenaming(
            b.typeParameters[i], newTypeParameters[i]);
      }
      bSubstitution =
          Substitution.fromPairs(b.typeParameters, bTypeParameterTypes);

      for (int i = 0; i < newTypeParameters.length; i++) {
        DartType newBound =
            mergeTypes(a.typeParameters[i].bound, b.typeParameters[i].bound);
        if (newBound == null) {
          return null;
        }
        newTypeParameters[i].bound = newBound;
        DartType newDefaultType = mergeTypes(
            a.typeParameters[i].defaultType, b.typeParameters[i].defaultType);
        if (newDefaultType == null) {
          return null;
        }
        newTypeParameters[i].defaultType = newDefaultType;
      }
    }

    DartType newReturnType = mergeTypes(a.returnType, b.returnType);
    if (newReturnType == null) return null;
    List<DartType> newPositionalParameters =
        new List<DartType>.filled(a.positionalParameters.length, null);
    for (int i = 0; i < a.positionalParameters.length; i++) {
      DartType newType =
          mergeTypes(a.positionalParameters[i], b.positionalParameters[i]);
      if (newType == null) {
        return null;
      }
      newPositionalParameters[i] = newType;
    }
    List<NamedType> newNamedParameters =
        new List<NamedType>.filled(a.namedParameters.length, null);
    for (int i = 0; i < a.namedParameters.length; i++) {
      DartType newType =
          mergeTypes(a.namedParameters[i].type, b.namedParameters[i].type);
      if (newType == null) {
        return null;
      }
      NamedType newNamedType =
          mergeNamedTypes(a.namedParameters[i], b.namedParameters[i], newType);
      if (newNamedType == null) {
        return null;
      }
      newNamedParameters[i] = newNamedType;
    }
    DartType newTypedefType;
    if (a.typedefType != null) {
      newTypedefType = mergeTypes(a.typedefType, b.typedefType);
      if (newTypedefType == null) return null;
    }

    return new FunctionType(newPositionalParameters, newReturnType, nullability,
        namedParameters: newNamedParameters,
        typeParameters: newTypeParameters,
        requiredParameterCount: a.requiredParameterCount,
        typedefType: newTypedefType);
  }

  NamedType mergeNamedTypes(NamedType a, NamedType b, DartType newType) {
    if (a.name != b.name || a.isRequired != b.isRequired) {
      return null;
    } else {
      return new NamedType(a.name, newType, isRequired: a.isRequired);
    }
  }

  @override
  DartType visitInterfaceType(InterfaceType a, DartType b) {
    if (b is InterfaceType &&
        a.classNode == b.classNode &&
        a.typeArguments.length == b.typeArguments.length) {
      Nullability nullability = mergeNullability(a.nullability, b.nullability);
      if (nullability != null) {
        return mergeInterfaceTypes(a, b, nullability);
      }
    }
    return null;
  }

  DartType mergeInterfaceTypes(
      InterfaceType a, InterfaceType b, Nullability nullability) {
    assert(a.classNode == b.classNode);
    assert(a.typeArguments.length == b.typeArguments.length);
    if (a.typeArguments.isEmpty) {
      return new InterfaceType(a.classNode, nullability);
    }
    List<DartType> newTypeArguments =
        new List<DartType>.filled(a.typeArguments.length, null);
    for (int i = 0; i < a.typeArguments.length; i++) {
      DartType newType = a.typeArguments[i].accept1(this, b.typeArguments[i]);
      if (newType == null) {
        return null;
      }
      newTypeArguments[i] = newType;
    }
    return new InterfaceType(a.classNode, nullability, newTypeArguments);
  }

  @override
  DartType visitFutureOrType(FutureOrType a, DartType b) {
    if (b is FutureOrType) {
      Nullability nullability = mergeNullability(a.nullability, b.nullability);
      if (nullability != null) {
        return mergeFutureOrTypes(a, b, nullability);
      }
    }
    return null;
  }

  DartType mergeFutureOrTypes(
      FutureOrType a, FutureOrType b, Nullability nullability) {
    DartType newTypeArgument = a.typeArgument.accept1(this, b.typeArgument);
    if (newTypeArgument == null) {
      return null;
    }
    return new FutureOrType(newTypeArgument, nullability);
  }

  @override
  DartType visitDynamicType(DynamicType a, DartType b) {
    if (b is DynamicType) {
      return a;
    }
    return null;
  }

  @override
  DartType visitNeverType(NeverType a, DartType b) {
    if (b is NeverType) {
      Nullability nullability = mergeNullability(a.nullability, b.nullability);
      if (nullability != null) {
        return new NeverType(nullability);
      }
    }
    return null;
  }

  @override
  DartType visitNullType(NullType a, DartType b) {
    if (b is NullType) {
      return a;
    }
    return null;
  }

  @override
  DartType visitInvalidType(InvalidType a, DartType b) => null;

  @override
  DartType visitBottomType(BottomType a, DartType b) => null;

  @override
  DartType visitVoidType(VoidType a, DartType b) {
    if (b is VoidType) {
      return a;
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType a, DartType b) {
    if (b is TypeParameterType && a.parameter == b.parameter) {
      Nullability nullability =
          mergeNullability(a.declaredNullability, b.declaredNullability);
      if (nullability == null) {
        return null;
      }
      if (a.promotedBound != null && b.promotedBound != null) {
        return mergePromotedTypeParameterTypes(a, b, nullability);
      } else if (a.promotedBound == null && b.promotedBound == null) {
        return mergeTypeParameterTypes(a, b, nullability);
      }
    }
    return null;
  }

  DartType mergeTypeParameterTypes(
      TypeParameterType a, TypeParameterType b, Nullability nullability) {
    assert(a.parameter == b.parameter);
    assert(a.promotedBound == null);
    assert(b.promotedBound == null);
    return new TypeParameterType(a.parameter, nullability);
  }

  DartType mergePromotedTypeParameterTypes(
      TypeParameterType a, TypeParameterType b, Nullability nullability) {
    assert(a.parameter == b.parameter);
    assert(a.promotedBound != null);
    assert(b.promotedBound != null);
    DartType newPromotedBound = a.promotedBound.accept1(this, b.promotedBound);
    if (newPromotedBound == null) {
      return null;
    }
    return new TypeParameterType(a.parameter, nullability, newPromotedBound);
  }

  @override
  DartType visitTypedefType(TypedefType a, DartType b) {
    if (b is TypedefType &&
        a.typedefNode == b.typedefNode &&
        a.typeArguments.length == b.typeArguments.length) {
      Nullability nullability = mergeNullability(a.nullability, b.nullability);
      if (nullability != null) {
        return mergeTypedefTypes(a, b, nullability);
      }
    }
    return null;
  }

  DartType mergeTypedefTypes(
      TypedefType a, TypedefType b, Nullability nullability) {
    assert(a.typedefNode == b.typedefNode);
    assert(a.typeArguments.length == b.typeArguments.length);
    if (a.typeArguments.isEmpty) {
      return new TypedefType(a.typedefNode, nullability);
    }
    List<DartType> newTypeArguments =
        new List<DartType>.filled(a.typeArguments.length, null);
    for (int i = 0; i < a.typeArguments.length; i++) {
      DartType newType = a.typeArguments[i].accept1(this, b.typeArguments[i]);
      if (newType == null) return null;
      newTypeArguments[i] = newType;
    }
    return new TypedefType(a.typedefNode, nullability, newTypeArguments);
  }

  @override
  DartType defaultDartType(DartType a, DartType b) => null;
}
