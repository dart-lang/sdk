// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * All numbers in dart are instances of [num].
 */
abstract class num implements Comparable<num> {
  /** Addition operator. */
  num operator +(num other);

  /** Subtraction operator. */
  num operator -(num other);

  /** Multiplication operator. */
  num operator *(num other);

  /**
   * Euclidean modulo operator.
   *
   * Returns the remainder of the euclidean division. The euclidean division of
   * two integers `a` and `b` yields two integers `q` and `r` such that
   * `a = b*q + r` and `0 <= r < |a|`.
   *
   * The euclidean division is only defined for integers, but can be easily
   * extended to work with doubles. In that case `r` may have a non-integer
   * value, but it still verifies `0 <= r < |a|`.
   *
   * The sign of the returned value `r` is always positive.
   *
   * See [remainder] for the remainder of the truncating division.
   */
  num operator %(num other);

  /** Division operator. */
  double operator /(num other);

  /**
   * Truncating division operator.
   *
   * If either operand is a [double] then the result of the truncating division
   * [:a ~/ b:] is equivalent to [:(a / b).truncate().toInt():].
   *
   * If both operands are [int]s then [:a ~/ b:] performs the truncating
   * integer division.
   */
  int operator ~/(num other);

  /** Negate operator. */
  num operator -();

  /**
   * Return the remainder of the truncating division of `this` by [other].
   *
   * The result `r` of this operation satisfies: `this = this ~/ other + r`.
   * As a consequence the remainder `r` has the same sign as the dividend
   * `this`.
   */
  num remainder(num other);

  /** Relational less than operator. */
  bool operator <(num other);

  /** Relational less than or equal operator. */
  bool operator <=(num other);

  /** Relational greater than operator. */
  bool operator >(num other);

  /** Relational greater than or equal operator. */
  bool operator >=(num other);

  bool get isNaN;

  bool get isNegative;

  bool get isInfinite;

  /** Returns the absolute value of this [num]. */
  num abs();

  /**
   * Returns the integer closest to `this`.
   *
   * Rounds away from zero when there is no closest integer:
   *  [:(3.5).round() == 4:] and [:(-3.5).round() == -4:].
   *
   * If `this` is not finite (`NaN` or infinity), throws an [UnsupportedError].
   */
  int round();

  /**
   * Returns the greatest integer no greater than `this`.
   *
   * If `this` is not finite (`NaN` or infinity), throws an [UnsupportedError].
   */
  int floor();

  /**
   * Returns the least integer no smaller than `this`.
   *
   * If `this` is not finite (`NaN` or infinity), throws an [UnsupportedError].
   */
  int ceil();

  /**
   * Returns the integer obtained by discarding any fractional
   * digits from `this`.
   *
   * If `this` is not finite (`NaN` or infinity), throws an [UnsupportedError].
   */
  int truncate();

  /**
   * Returns the integer value closest to `this`.
   *
   * Rounds away from zero when there is no closest integer:
   *  [:(3.5).round() == 4:] and [:(-3.5).round() == -4:].
   *
   * The result is a double.
   */
  double roundToDouble();

  /**
   * Returns the greatest integer value no greater than `this`.
   *
   * The result is a double.
   */
  double floorToDouble();

  /**
   * Returns the least integer value no smaller than `this`.
   *
   * The result is a double.
   */
  double ceilToDouble();

  /**
   * Returns the integer obtained by discarding any fractional
   * digits from `this`.
   *
   * The result is a double.
   */
  double truncateToDouble();

  /**
   * Clamps [this] to be in the range [lowerLimit]-[upperLimit]. The comparison
   * is done using [compareTo] and therefore takes [:-0.0:] into account.
   * It also implies that [double.NAN] is treated as the maximal double value.
   */
  num clamp(num lowerLimit, num upperLimit);

  /** Truncates this [num] to an integer and returns the result as an [int]. */
  int toInt();

  /**
   * Return this [num] as a [double].
   *
   * If the number is not representable as a [double], an
   * approximation is returned. For numerically large integers, the
   * approximation may be infinite.
   */
  double toDouble();

  /**
   * Converts [this] to a string representation with [fractionDigits] digits
   * after the decimal point.
   *
   * The parameter [fractionDigits] must be an integer satisfying:
   * [:0 <= fractionDigits <= 20:].
   */
  String toStringAsFixed(int fractionDigits);

  /**
   * Converts [this] to a string in decimal exponential notation with
   * [fractionDigits] digits after the decimal point.
   *
   * If [fractionDigits] is given then it must be an integer satisfying:
   * [:0 <= fractionDigits <= 20:]. Without the parameter the returned string
   * uses the shortest number of digits that accurately represent [this].
   */
  String toStringAsExponential([int fractionDigits]);

  /**
   * Converts [this] to a string representation with [precision] significant
   * digits.
   *
   * The parameter [precision] must be an integer satisfying:
   * [:1 <= precision <= 21:].
   */
  String toStringAsPrecision(int precision);


}
