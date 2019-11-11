// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// The variance of a type parameter `X` in a type `T`.
class Variance {
  /// Used when `X` does not occur free in `T`.
  static const Variance _unrelated = Variance._(0);

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[U/X]T <: [V/X]T`.
  static const Variance _covariant = Variance._(1);

  /// Used when `X` occurs free in `T`, and `U <: V` implies `[V/X]T <: [U/X]T`.
  static const Variance _contravariant = Variance._(2);

  /// Used when there exists a pair `U` and `V` such that `U <: V`, but
  /// `[U/X]T` and `[V/X]T` are incomparable.
  static const Variance _invariant = Variance._(3);

  /// The encoding associated with the variance.
  final int _encoding;

  /// Computes the variance of the [typeParameter] in the [type].
  factory Variance(TypeParameterElement typeParameter, DartType type) {
    if (type is TypeParameterType) {
      if (type.element == typeParameter) {
        return _covariant;
      } else {
        return _unrelated;
      }
    } else if (type is InterfaceType) {
      var result = _unrelated;
      for (var argument in type.typeArguments) {
        result = result.meet(
          Variance(typeParameter, argument),
        );
      }
      return result;
    } else if (type is FunctionType) {
      var result = Variance(typeParameter, type.returnType);

      for (var parameter in type.typeFormals) {
        // If [parameter] is referenced in the bound at all, it makes the
        // variance of [parameter] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        var bound = parameter.bound;
        if (bound != null && !Variance(typeParameter, bound).isUnrelated) {
          result = _invariant;
        }
      }

      for (var parameter in type.parameters) {
        result = result.meet(
          _contravariant.combine(
            Variance(typeParameter, parameter.type),
          ),
        );
      }
      return result;
    }
    return _unrelated;
  }

  /// Initialize a newly created variance to have the given [encoding].
  const Variance._(this._encoding);

  /// Return the variance with the given [encoding].
  factory Variance._fromEncoding(int encoding) {
    switch (encoding) {
      case 0:
        return _unrelated;
      case 1:
        return _covariant;
      case 2:
        return _contravariant;
      case 3:
        return _invariant;
    }
    throw new ArgumentError('Invalid encoding for variance: $encoding');
  }

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[V/X]T <: [U/X]T`.
  bool get isContravariant => this == _contravariant;

  /// Return `true` if this represents the case when `X` occurs free in `T`, and
  /// `U <: V` implies `[U/X]T <: [V/X]T`.
  bool get isCovariant => this == _covariant;

  /// Return `true` if this represents the case when there exists a pair `U` and
  /// `V` such that `U <: V`, but `[U/X]T` and `[V/X]T` are incomparable.
  bool get isInvariant => this == _invariant;

  /// Return `true` if this represents the case when `X` does not occur free in
  /// `T`.
  bool get isUnrelated => this == _unrelated;

  /// Combines variances of `X` in `T` and `Y` in `S` into variance of `X` in
  /// `[Y/T]S`.
  ///
  /// Consider the following examples:
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y`
  /// in `List<Y>` is covariant, so variance of `X` in `List<Function(X)>` is
  /// contravariant;
  ///
  /// * variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(List<X>)` is contravariant;
  ///
  /// * variance of `X` in `Function(X)` is contravariant, variance of `Y` in
  /// `Function(Y)` is contravariant, so variance of `X` in
  /// `Function(Function(X))` is covariant;
  ///
  /// * let the following be declared:
  ///
  ///     typedef F<Z> = Function();
  ///
  /// then variance of `X` in `F<X>` is unrelated, variance of `Y` in
  /// `List<Y>` is covariant, so variance of `X` in `List<F<X>>` is
  /// unrelated;
  ///
  /// * let the following be declared:
  ///
  ///     typedef G<Z> = Z Function(Z);
  ///
  /// then variance of `X` in `List<X>` is covariant, variance of `Y` in
  /// `G<Y>` is invariant, so variance of `X` in `G<List<X>>` is invariant.
  Variance combine(Variance other) {
    if (isUnrelated || other.isUnrelated) return _unrelated;
    if (isInvariant || other.isInvariant) return _invariant;
    return this == other ? _covariant : _contravariant;
  }

  /// Variance values form a lattice where unrelated is the top, invariant
  /// is the bottom, and covariant and contravariant are incomparable.
  /// [meet] calculates the meet of two elements of such lattice.  It can be
  /// used, for example, to calculate the variance of a typedef type parameter
  /// if it's encountered on the RHS of the typedef multiple times.
  Variance meet(Variance other) =>
      Variance._fromEncoding(_encoding | other._encoding);
}
