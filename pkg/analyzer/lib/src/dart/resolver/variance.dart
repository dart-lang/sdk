// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Computes the variance of the [typeParameter] in the [type].
int computeVariance(TypeParameterElement typeParameter, DartType type) {
  if (type is TypeParameterType) {
    if (type.element == typeParameter) {
      return Variance.covariant;
    } else {
      return Variance.unrelated;
    }
  } else if (type is InterfaceType) {
    var result = Variance.unrelated;
    for (var argument in type.typeArguments) {
      result = Variance.meet(
        result,
        computeVariance(typeParameter, argument),
      );
    }
    return result;
  } else if (type is FunctionType) {
    var result = computeVariance(typeParameter, type.returnType);

    for (var parameter in type.typeFormals) {
      // If [parameter] is referenced in the bound at all, it makes the
      // variance of [parameter] in the entire type invariant.  The invocation
      // of [computeVariance] below is made to simply figure out if [variable]
      // occurs in the bound.
      var bound = parameter.bound;
      if (bound != null &&
          computeVariance(typeParameter, bound) != Variance.unrelated) {
        result = Variance.invariant;
      }
    }

    for (var parameter in type.parameters) {
      result = Variance.meet(
        result,
        Variance.combine(
          Variance.contravariant,
          computeVariance(typeParameter, parameter.type),
        ),
      );
    }
    return result;
  }
  return Variance.unrelated;
}

/// Value set for variance of a type parameter `X` in a type `T`.
class Variance {
  /// Used when `X` does not occur free in `T`.
  static const int unrelated = 0;

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[U/X]T <: [V/X]T`.
  static const int covariant = 1;

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[V/X]T <: [U/X]T`.
  static const int contravariant = 2;

  /// Used when there exists a pair `U` and `V` such that `U <: V`, but
  /// `[U/X]T` and `[V/X]T` are incomparable.
  static const int invariant = 3;

  /// Combines variances of `X` in `T` and `Y` in `S` into variance of `X` in
  /// `[Y/T]S`.
  ///
  /// Consider the following examples:
  ///
  /// * variance of `X` in `Function(X)` is [contravariant], variance of `Y`
  /// in `List<Y>` is [covariant], so variance of `X` in `List<Function(X)>` is
  /// [contravariant];
  ///
  /// * variance of `X` in `List<X>` is [covariant], variance of `Y` in
  /// `Function(Y)` is [contravariant], so variance of `X` in
  /// `Function(List<X>)` is [contravariant];
  ///
  /// * variance of `X` in `Function(X)` is [contravariant], variance of `Y` in
  /// `Function(Y)` is [contravariant], so variance of `X` in
  /// `Function(Function(X))` is [covariant];
  ///
  /// * let the following be declared:
  ///
  ///     typedef F<Z> = Function();
  ///
  /// then variance of `X` in `F<X>` is [unrelated], variance of `Y` in
  /// `List<Y>` is [covariant], so variance of `X` in `List<F<X>>` is
  /// [unrelated];
  ///
  /// * let the following be declared:
  ///
  ///     typedef G<Z> = Z Function(Z);
  ///
  /// then variance of `X` in `List<X>` is [covariant], variance of `Y` in
  /// `G<Y>` is [invariant], so variance of `X` in `G<List<X>>` is [invariant].
  static int combine(int a, int b) {
    if (a == unrelated || b == unrelated) return unrelated;
    if (a == invariant || b == invariant) return invariant;
    return a == b ? covariant : contravariant;
  }

  /// Variance values form a lattice where [unrelated] is the top, [invariant]
  /// is the bottom, and [covariant] and [contravariant] are incomparable.
  /// [meet] calculates the meet of two elements of such lattice.  It can be
  /// used, for example, to calculate the variance of a typedef type parameter
  /// if it's encountered on the RHS of the typedef multiple times.
  static int meet(int a, int b) => a | b;
}
