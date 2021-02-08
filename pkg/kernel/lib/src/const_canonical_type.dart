// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.9

import 'package:kernel/src/bounds_checks.dart';

import '../ast.dart' hide MapEntry;
import '../core_types.dart';
import '../type_algebra.dart';

/// Computes CONST_CANONICAL_TYPE
///
/// The algorithm is specified at
/// https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#constant-instances
DartType computeConstCanonicalType(DartType type, CoreTypes coreTypes,
    {bool isNonNullableByDefault}) {
  assert(isNonNullableByDefault != null);

  if (type is InvalidType) {
    return type;
  }

  // CONST_CANONICAL_TYPE(T) = T if T is dynamic, void, Null
  if (type is DynamicType || type is VoidType || type is NullType) {
    return type;
  }

  // CONST_CANONICAL_TYPE(T) = T* if T is Never or Object
  if (type is NeverType &&
      type.declaredNullability == Nullability.nonNullable) {
    return const NeverType.legacy();
  }
  if (type == coreTypes.objectNonNullableRawType) {
    return coreTypes.objectLegacyRawType;
  }

  // CONST_CANONICAL_TYPE(FutureOr<T>) = FutureOr<S>*
  // where S is CONST_CANONICAL_TYPE(T)
  if (type is FutureOrType &&
      isTypeWithoutNullabilityMarker(type,
          isNonNullableByDefault: isNonNullableByDefault)) {
    return new FutureOrType(
        computeConstCanonicalType(type.typeArgument, coreTypes,
            isNonNullableByDefault: isNonNullableByDefault),
        Nullability.legacy);
  }

  // CONST_CANONICAL_TYPE(T?) =
  // let S be CONST_CANONICAL_TYPE(T)
  // if S is R* then R?
  // else S?
  if (isNullableTypeConstructorApplication(type)) {
    return computeConstCanonicalType(
            computeTypeWithoutNullabilityMarker(type,
                isNonNullableByDefault: isNonNullableByDefault),
            coreTypes,
            isNonNullableByDefault: isNonNullableByDefault)
        .withDeclaredNullability(Nullability.nullable);
  }

  // CONST_CANONICAL_TYPE(T*) = CONST_CANONICAL_TYPE(T)
  if (isLegacyTypeConstructorApplication(type,
      isNonNullableByDefault: isNonNullableByDefault)) {
    return computeConstCanonicalType(
        computeTypeWithoutNullabilityMarker(type,
            isNonNullableByDefault: isNonNullableByDefault),
        coreTypes,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  // CONST_CANONICAL_TYPE(X extends T) = X*
  if (type is TypeParameterType && type.promotedBound == null) {
    return type.withDeclaredNullability(Nullability.legacy);
  }

  // CONST_CANONICAL_TYPE(X & T) =
  // This case should not occur, since intersection types are not permitted as
  // generic arguments.
  assert(!(type is TypeParameterType && type.promotedBound != null),
      "Intersection types are not permitted as generic arguments: '${type}'.");

  // CONST_CANONICAL_TYPE(C<T0, ..., Tn>) = C<R0, ..., Rn>*
  // where Ri is CONST_CANONICAL_TYPE(Ti)
  // Note this includes the case of an interface type with no generic parameters
  // (e.g int).
  if (type is InterfaceType) {
    assert(type.declaredNullability == Nullability.nonNullable);
    List<DartType> typeArguments;
    if (type.typeArguments.isEmpty) {
      typeArguments = const <DartType>[];
    } else {
      typeArguments =
          new List<DartType>.of(type.typeArguments, growable: false);
      for (int i = 0; i < typeArguments.length; ++i) {
        typeArguments[i] = computeConstCanonicalType(
            typeArguments[i], coreTypes,
            isNonNullableByDefault: isNonNullableByDefault);
      }
    }
    return new InterfaceType(type.classNode, Nullability.legacy, typeArguments);
  }

  // CONST_CANONICAL_TYPE(R Function<X extends B>(S)) = F*
  // where F = R1 Function<X extends B1>(S1)
  // and R1 = CONST_CANONICAL_TYPE(R)
  // and B1 = CONST_CANONICAL_TYPE(B)
  // and S1 = CONST_CANONICAL_TYPE(S)
  // Note, this generalizes to arbitrary number of type and term parameters.
  if (type is FunctionType) {
    assert(type.declaredNullability == Nullability.nonNullable);

    List<TypeParameter> canonicalizedTypeParameters;
    Substitution substitution;
    if (type.typeParameters.isEmpty) {
      canonicalizedTypeParameters = const <TypeParameter>[];
      substitution = null;
    } else {
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(type.typeParameters);
      substitution = freshTypeParameters.substitution;
      canonicalizedTypeParameters = freshTypeParameters.freshTypeParameters;
      for (TypeParameter parameter in canonicalizedTypeParameters) {
        parameter.bound = computeConstCanonicalType(parameter.bound, coreTypes,
            isNonNullableByDefault: isNonNullableByDefault);
      }
      List<DartType> defaultTypes = calculateBoundsInternal(
          canonicalizedTypeParameters, coreTypes.objectClass,
          isNonNullableByDefault: isNonNullableByDefault);
      for (int i = 0; i < canonicalizedTypeParameters.length; ++i) {
        canonicalizedTypeParameters[i].defaultType = defaultTypes[i];
      }
    }

    List<DartType> canonicalizedPositionalParameters;
    if (type.positionalParameters.isEmpty) {
      canonicalizedPositionalParameters = const <DartType>[];
    } else {
      canonicalizedPositionalParameters =
          new List<DartType>.of(type.positionalParameters, growable: false);
      for (int i = 0; i < canonicalizedPositionalParameters.length; ++i) {
        DartType canonicalized = computeConstCanonicalType(
            canonicalizedPositionalParameters[i], coreTypes,
            isNonNullableByDefault: isNonNullableByDefault);
        if (substitution != null) {
          canonicalized = substitution.substituteType(canonicalized);
        }
        canonicalizedPositionalParameters[i] = canonicalized;
      }
    }

    List<NamedType> canonicalizedNamedParameters;
    if (type.namedParameters.isEmpty) {
      canonicalizedNamedParameters = const <NamedType>[];
    } else {
      canonicalizedNamedParameters =
          new List<NamedType>.of(type.namedParameters, growable: false);
      for (int i = 0; i < canonicalizedNamedParameters.length; ++i) {
        DartType canonicalized = computeConstCanonicalType(
            canonicalizedNamedParameters[i].type, coreTypes,
            isNonNullableByDefault: isNonNullableByDefault);
        if (substitution != null) {
          canonicalized = substitution.substituteType(canonicalized);
        }
        canonicalizedNamedParameters[i] = new NamedType(
            canonicalizedNamedParameters[i].name, canonicalized,
            isRequired: canonicalizedNamedParameters[i].isRequired);
      }
    }

    DartType canonicalizedReturnType = computeConstCanonicalType(
        type.returnType, coreTypes,
        isNonNullableByDefault: isNonNullableByDefault);
    if (substitution != null) {
      canonicalizedReturnType =
          substitution.substituteType(canonicalizedReturnType);
    }

    // Canonicalize typedef type, just in case.
    TypedefType canonicalizedTypedefType;
    if (type.typedefType == null) {
      canonicalizedTypedefType = null;
    } else {
      List<DartType> canonicalizedTypeArguments;
      if (type.typedefType.typeArguments.isEmpty) {
        canonicalizedTypeArguments = const <DartType>[];
      } else {
        canonicalizedTypeArguments = new List<DartType>.of(
            type.typedefType.typeArguments,
            growable: false);
        for (int i = 0; i < canonicalizedTypeArguments.length; ++i) {
          canonicalizedTypeArguments[i] = computeConstCanonicalType(
              canonicalizedTypeArguments[i], coreTypes,
              isNonNullableByDefault: isNonNullableByDefault);
        }
      }
      canonicalizedTypedefType = new TypedefType(type.typedefType.typedefNode,
          Nullability.legacy, canonicalizedTypeArguments);
    }

    return new FunctionType(canonicalizedPositionalParameters,
        canonicalizedReturnType, Nullability.legacy,
        namedParameters: canonicalizedNamedParameters,
        typeParameters: canonicalizedTypeParameters,
        requiredParameterCount: type.requiredParameterCount,
        typedefType: canonicalizedTypedefType);
  }

  throw new StateError(
      "Unhandled '${type.runtimeType}' in 'computeConstCanonicalType'.");
}
