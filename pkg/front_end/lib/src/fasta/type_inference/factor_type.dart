// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/type_environment.dart';

/// Computes the "remainder" of [T] when [S] has been removed from consideration
/// by an instance check.  This operation is used for type promotion during flow
/// analysis.
DartType factorType(TypeEnvironment typeEnvironment, DartType T, DartType S) {
  // * If T <: S then Never
  if (typeEnvironment.isSubtypeOf(T, S, SubtypeCheckMode.withNullabilities)) {
    return const NeverType(Nullability.nonNullable);
  }

  // * Else if T is R? and Null <: S then factor(R, S)
  // * Else if T is R? then factor(R, S)?
  if (T.declaredNullability == Nullability.nullable) {
    DartType R = T.withDeclaredNullability(Nullability.nonNullable);
    if (identical(R, T)) {
      return T;
    }
    DartType factor_RS = factorType(typeEnvironment, R, S);
    if (typeEnvironment.isSubtypeOf(
        const NullType(), S, SubtypeCheckMode.withNullabilities)) {
      return factor_RS;
    } else {
      return factor_RS.withDeclaredNullability(Nullability.nullable);
    }
  }

  // * Else if T is R* and Null <: S then factor(R, S)
  // * Else if T is R* then factor(R, S)*
  if (T.declaredNullability == Nullability.legacy) {
    DartType R = T.withDeclaredNullability(Nullability.nonNullable);
    DartType factor_RS = factorType(typeEnvironment, R, S);
    if (typeEnvironment.isSubtypeOf(
        const NullType(), S, SubtypeCheckMode.withNullabilities)) {
      return factor_RS;
    } else {
      return factor_RS.withDeclaredNullability(Nullability.legacy);
    }
  }

  // * Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
  // * Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
  if (T is FutureOrType) {
    DartType R = T.typeArgument;
    DartType future_R = typeEnvironment.futureType(R, Nullability.nonNullable);
    if (typeEnvironment.isSubtypeOf(
        future_R, S, SubtypeCheckMode.withNullabilities)) {
      return factorType(typeEnvironment, R, S);
    }
    if (typeEnvironment.isSubtypeOf(R, S, SubtypeCheckMode.withNullabilities)) {
      return factorType(typeEnvironment, future_R, S);
    }
  }

  return T;
}
