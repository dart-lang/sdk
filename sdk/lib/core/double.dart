// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

// TODO: Convert this abstract class into a concrete class double
// that uses the patch class functionality to account for the
// different platform implementations.

/**
 * Representation of Dart doubles containing double specific constants
 * and operations and specializations of operations inherited from
 * [num].
 *
 * The [double] type is contagious. Operations on [double]s return
 * [double] results.
 */
abstract class double extends num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;
  static const double MIN_POSITIVE = 5e-324;
  static const double MAX_FINITE = 1.7976931348623157e+308;

  /** Return the remainder from dividing this [double] by [other]. */
  double remainder(num other);

  /** Addition operator. */
  double operator +(num other);

  /** Subtraction operator. */
  double operator -(num other);

  /** Multiplication operator. */
  double operator *(num other);

  /** Euclidean modulo operator. */
  double operator %(num other);

  /** Division operator. */
  double operator /(num other);

  /**
   * Truncating division operator.
   *
   * The result of the truncating division [:a ~/ b:] is equivalent to
   * [:(a / b).truncate().toInt():].
   */
  int operator ~/(num other);

  /** Negate operator. */
  double operator -();

  /** Returns the absolute value of this [double]. */
  double abs();

  /**
   * Returns the integer value closest to this [double].
   *
   * Rounds away from zero when there is no closest integer:
   *  [:(3.5).round() == 4:] and [:(-3.5).round() == -4:].
   */
  double round();

  /** Returns the greatest integer value no greater than this [double]. */
  double floor();

  /** Returns the least integer value that is no smaller than this [double]. */
  double ceil();

  /**
   * Returns the integer value obtained by discarding any fractional
   * digits from this [double].
   */
  double truncate();

  /**
   * Provide a representation of this [double] value.
   *
   * The representation is a number literal such that the closest double value
   * to the representation's mathematical value is this [double].
   *
   * Returns "NaN" for the Not-a-Number value.
   * Returns "Infinity" and "-Infinity" for positive and negative Infinity.
   * Returns "-0.0" for negative zero.
   *
   * It should always be the case that if [:d:] is a [double], then
   * [:d == double.parse(d.toString()):].
   */
  String toString();

  /**
   * Parse [source] as an double literal and return its value.
   *
   * Accepts the same format as double literals:
   *   [: ['+'|'-'] [digit* '.'] digit+ [('e'|'E') ['+'|'-'] digit+] :]
   *
   * Also recognizes "NaN", "Infinity" and "-Infinity" as inputs and
   * returns the corresponding double value.
   *
   * If the [soure] is not a valid double literal, the [handleError]
   * is called with the [source] as argument, and its return value is
   * used instead. If no handleError is provided, a [FormatException]
   * is thrown.
   */
  external static double parse(String source,
                               [double handleError(String source)]);
}
