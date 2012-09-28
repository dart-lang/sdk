// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * All numbers in dart are instances of [num].
 */
abstract class num implements Comparable {
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
   * [:(a / b).truncate():].
   */
  num operator ~/(num other);

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

  bool isNaN();

  bool isNegative();

  bool isInfinite();

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
   * Converts a [num] to a string representation with [fractionDigits]
   * digits after the decimal point.
   */
  String toStringAsFixed(int fractionDigits);

  /**
   * Converts a [num] to a string in decimal exponential notation with
   * [fractionDigits] digits after the decimal point.
   */
  String toStringAsExponential(int fractionDigits);

  /**
   * Converts a [num] to a string representation with [precision]
   * significant digits.
   */
  String toStringAsPrecision(int precision);

  /**
   * Converts a [num] to a string representation in the given [radix].
   *
   * The [num] in converted to an [int] using [toInt]. That [int] is
   * then converted to a string representation with the given
   * [radix]. In the string representation, lower-case letters are
   * used for digits above '9'.
   *
   * The [radix] argument must be an integer between 2 and 36.
   */
  String toRadixString(int radix);
}
