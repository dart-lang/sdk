// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(dmitryas):  Delete the file when a special representation for FutureOr
// is landed.

import '../ast.dart';

Nullability uniteNullabilities(Nullability a, Nullability b) {
  if (a == Nullability.nullable || b == Nullability.nullable) {
    return Nullability.nullable;
  }
  if (a == Nullability.legacy || b == Nullability.legacy) {
    return Nullability.legacy;
  }
  if (a == Nullability.undetermined || b == Nullability.undetermined) {
    return Nullability.undetermined;
  }
  return Nullability.nonNullable;
}

Nullability intersectNullabilities(Nullability a, Nullability b) {
  if (a == Nullability.nonNullable || b == Nullability.nonNullable) {
    return Nullability.nonNullable;
  }
  if (a == Nullability.undetermined || b == Nullability.undetermined) {
    return Nullability.undetermined;
  }
  if (a == Nullability.legacy || b == Nullability.legacy) {
    return Nullability.legacy;
  }
  return Nullability.nullable;
}

Nullability computeNullabilityOfFutureOr(
    InterfaceType futureOr, Class futureOrClass) {
  assert(futureOr.classNode == futureOrClass);

  // Performance note: the algorithm is linear.
  DartType argument = futureOr.typeArguments.single;
  if (argument is InterfaceType && argument.classNode == futureOrClass) {
    return uniteNullabilities(
        computeNullabilityOfFutureOr(argument, futureOrClass),
        futureOr.nullability);
  }
  if (argument is TypeParameterType && argument.promotedBound != null) {
    DartType promotedBound = argument.promotedBound;
    if (promotedBound is InterfaceType &&
        promotedBound.className == futureOrClass) {
      return uniteNullabilities(
          intersectNullabilities(argument.typeParameterTypeNullability,
              computeNullabilityOfFutureOr(promotedBound, futureOrClass)),
          futureOr.nullability);
    }
  }
  Nullability argumentNullability =
      argument is InvalidType ? Nullability.undetermined : argument.nullability;
  return uniteNullabilities(argumentNullability, futureOr.nullability);
}

Nullability computeNullability(DartType type, Class futureOrClass) {
  if (type is InterfaceType && type.classNode == futureOrClass) {
    return computeNullabilityOfFutureOr(type, futureOrClass);
  }
  return type.nullability;
}

bool isPotentiallyNullable(DartType type, Class futureOrClass) {
  Nullability nullability = computeNullability(type, futureOrClass);
  return nullability == Nullability.nullable ||
      nullability == Nullability.undetermined;
}

bool isPotentiallyNonNullable(DartType type, Class futureOrClass) {
  Nullability nullability = computeNullability(type, futureOrClass);
  return nullability == Nullability.nonNullable ||
      nullability == Nullability.undetermined;
}
