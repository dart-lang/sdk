// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType;
import 'package:kernel/src/standard_bounds.dart';

import 'type_schema.dart' show UnknownType;
import 'type_schema_elimination.dart';

mixin TypeSchemaStandardBounds on StandardBounds {
  @override
  DartType greatestClosureForLowerBound(DartType typeSchema) {
    //  - We replace all uses of `T1 <: T2` in the `DOWN` algorithm by `S1 <:
    //  S2` where `Si` is the greatest closure of `Ti` with respect to `_`.
    return greatestClosure(typeSchema,
        topType: coreTypes.objectNullableRawType);
  }

  @override
  DartType leastClosureForUpperBound(DartType typeSchema) {
    //  - We replace all uses of `T1 <: T2` in the `UP` algorithm by `S1 <: S2`
    //  where `Si` is the least closure of `Ti` with respect to `_`.
    return leastClosure(typeSchema, coreTypes: hierarchy.coreTypes);
  }

  @override
  DartType getStandardLowerBoundInternal(DartType type1, DartType type2) {
    //  - We add the axiom that `DOWN(T, _) == T` and the symmetric version.
    if (type1 is UnknownType) return type2;
    if (type2 is UnknownType) return type1;

    return super.getStandardLowerBoundInternal(type1, type2);
  }

  @override
  DartType getStandardUpperBoundInternal(DartType type1, DartType type2) {
    //  - We add the axiom that `UP(T, _) == T` and the symmetric version.
    if (type1 is UnknownType) return type2;
    if (type2 is UnknownType) return type1;

    return super.getStandardUpperBoundInternal(type1, type2);
  }
}
