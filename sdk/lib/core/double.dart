// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

// TODO: Convert this abstract class into a concrete class double
// that uses the patch class functionality to account for the
// different platform implementations.

/**
 * A double-precision floating point number.
 *
 * Representation of Dart doubles containing double specific constants
 * and operations and specializations of operations inherited from
 * [num]. Dart doubles are 64-bit floating-point numbers as specified in the
 * IEEE 754 standard.
 *
 * The [double] type is contagious. Operations on [double]s return
 * [double] results.
 *
 * It is a compile-time error for a class to attempt to extend or implement
 * double.
 */
abstract class double extends num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;
  static const double MIN_POSITIVE = 5e-324;
  static const double MAX_FINITE = 1.7976931348623157e+308;

  double remainder(num other);

  /** Addition operator. */
  double operator +(num other);

  /** Subtraction operator. */
  double operator -(num other);

  /** Multiplication operator. */
  double operator *(num other);

  double operator %(num other);

  /** Division operator. */
  double operator /(num other);

  /**
   * Truncating division operator.
   *
   * The result of the truncating division `a ~/ b` is equivalent to
   * `(a / b).truncate()`.
   */
  int operator ~/(num other);

  /** Negate operator. */
  double operator -();

  /** Returns the absolute value of this [double]. */
  double abs();

  /**
   * Returns the sign of the double's numerical value.
   *
   * Returns -1.0 if the value is less than zero,
   * +1.0 if the value is greater than zero,
   * and the value itself if it is -0.0, 0.0 or NaN.
   */
  double get sign;

  /**
   * Returns the integer closest to `this`.
   *
   * Rounds away from zero when there is no closest integer:
   *  `(3.5).round() == 4` and `(-3.5).round() == -4`.
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
   * Returns the integer double value closest to `this`.
   *
   * Rounds away from zero when there is no closest integer:
   *  `(3.5).roundToDouble() == 4` and `(-3.5).roundToDouble() == -4`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is not
   * a finite value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`,
   * and `-0.0` is therefore considered closer to negative numbers than `0.0`.
   * This means that for a value, `d` in the range `-0.5 < d < 0.0`,
   * the result is `-0.0`.
   */
  double roundToDouble();

  /**
   * Returns the greatest integer double value no greater than `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is not
   * a finite value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `0.0 < d < 1.0` will return `0.0`.
   */
  double floorToDouble();

  /**
   * Returns the least integer double value no smaller than `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is not
   * a finite value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`.
   */
  double ceilToDouble();

  /**
   * Returns the integer double value obtained by discarding any fractional
   * digits from `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is not
   * a finite value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`, and
   * in the range `0.0 < d < 1.0` it will return 0.0.
   */
  double truncateToDouble();

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
   * For all doubles, `d`, converting to a string and parsing the string back
   * gives the same value again: `d == double.parse(d.toString())` (except when
   * `d` is NaN).
   */
  String toString();

  /**
   * Parse [source] as an double literal and return its value.
   *
   * Accepts an optional sign (`+` or `-`) followed by either the characters
   * "Infinity", the characters "NaN" or a floating-point representation.
   * A floating-point representation is composed of a mantissa and an optional
   * exponent part. The mantissa is either a decimal point (`.`) followed by a
   * sequence of (decimal) digits, or a sequence of digits
   * optionally followed by a decimal point and optionally more digits. The
   * (optional) exponent part consists of the character "e" or "E", an optional
   * sign, and one or more digits.
   *
   * Leading and trailing whitespace is ignored.
   *
   * If the [source] is not a valid double literal, the [onError]
   * is called with the [source] as argument, and its return value is
   * used instead. If no `onError` is provided, a [FormatException]
   * is thrown instead.
   *
   * The [onError] function is only invoked if [source] is a [String] with an
   * invalid format. It is not invoked if the [source] is invalid for some
   * other reason, for example by being `null`.
   *
   * Examples of accepted strings:
   *
   *     "3.14"
   *     "  3.14 \xA0"
   *     "0."
   *     ".0"
   *     "-1.e3"
   *     "1234E+7"
   *     "+.12e-9"
   *     "-NaN"
   */
  external static double parse(String source, [double onError(String source)]);
}
