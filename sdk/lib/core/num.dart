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

  /** Euclidean modulo operator. */
  num operator %(num other);

  /** Division operator. */
  double operator /(num other);

  /**
   * Truncating division operator.
   *
   * The result of the truncating division [:a ~/ b:] is equivalent to
   * [:(a / b).truncate().toInt():].
   */
  // TODO(floitsch): this is currently not true: bignum1 / bignum2 will return
  // NaN, whereas bignum1 ~/ bignum2 will give the correct result.
  int operator ~/(num other);

  /** Negate operator. */
  num operator -();

  /** Return the remainder from dividing this [num] by [other]. */
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

  /** Returns the greatest integer value no greater than this [num]. */
  num floor();

  /** Returns the least integer value that is no smaller than this [num]. */
  num ceil();

  /**
   * Returns the integer value closest to this [num].
   *
   * Rounds away from zero when there is no closest integer:
   *  [:(3.5).round() == 4:] and [:(-3.5).round() == -4:].
   */
  num round();

  /**
   * Returns the integer value obtained by discarding any fractional
   * digits from this [num].
   */
  num truncate();

  /**
   * Clamps [this] to be in the range [lowerLimit]-[upperLimit]. The comparison
   * is done using [compareTo] and therefore takes [:-0.0:] into account.
   * It also implies that [double.NaN] is treated as the maximal double value.
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
