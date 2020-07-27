// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show DartType, Library, NeverType, Nullability;

import 'package:kernel/src/standard_bounds.dart';

import 'type_schema.dart' show UnknownType;

import 'type_schema_elimination.dart';

mixin TypeSchemaStandardBounds on StandardBounds {
  @override
  DartType getNullabilityAwareStandardLowerBoundInternal(
      DartType type1, DartType type2, Library clientLibrary) {
    //  - We add the axiom that `DOWN(T, _) == T` and the symmetric version.
    //  - We replace all uses of `T1 <: T2` in the `DOWN` algorithm by `S1 <:
    //  S2` where `Si` is the greatest closure of `Ti` with respect to `_`.
    if (type1 is UnknownType) return type2;
    if (type2 is UnknownType) return type1;
    type1 = greatestClosure(type1, coreTypes.objectNullableRawType,
        const NeverType(Nullability.nonNullable));
    type2 = greatestClosure(type2, coreTypes.objectNullableRawType,
        const NeverType(Nullability.nonNullable));

    return super.getNullabilityAwareStandardLowerBoundInternal(
        type1, type2, clientLibrary);
  }

  @override
  DartType getNullabilityObliviousStandardLowerBoundInternal(
      type1, type2, clientLibrary) {
    // For any type T, SLB(?, T) = SLB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }
    return super.getNullabilityObliviousStandardLowerBoundInternal(
        type1, type2, clientLibrary);
  }

  @override
  DartType getNullabilityAwareStandardUpperBoundInternal(
      DartType type1, DartType type2, Library clientLibrary) {
    //  - We add the axiom that `UP(T, _) == T` and the symmetric version.
    //  - We replace all uses of `T1 <: T2` in the `UP` algorithm by `S1 <: S2`
    //  where `Si` is the least closure of `Ti` with respect to `_`.
    if (type1 is UnknownType) return type2;
    if (type2 is UnknownType) return type1;
    type1 = leastClosure(type1, coreTypes.objectNullableRawType,
        const NeverType(Nullability.nonNullable));
    type2 = leastClosure(type2, coreTypes.objectNullableRawType,
        const NeverType(Nullability.nonNullable));
    return super.getNullabilityAwareStandardUpperBoundInternal(
        type1, type2, clientLibrary);
  }

  @override
  DartType getNullabilityObliviousStandardUpperBoundInternal(
      DartType type1, DartType type2, Library clientLibrary) {
    // For any type T, SUB(?, T) = SUB(T, ?) = T.
    if (type1 is UnknownType) {
      return type2;
    }
    if (type2 is UnknownType) {
      return type1;
    }
    return super.getNullabilityObliviousStandardUpperBoundInternal(
        type1, type2, clientLibrary);
  }
}
