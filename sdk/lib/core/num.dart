// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An integer or floating-point number.
 *
 * It is a compile-time error for any type other than [int] or [double]
 * to attempt to extend or implement num.
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
   * `a == b*q + r` and `0 <= r < a.abs()`.
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
   * Returns the remainder of the truncating division of `this` by [other].
   *
   * The result `r` of this operation satisfies: `this == this ~/ other + r`.
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
   * Returns a decimal-point string-representation of `this`.
   *
   * Converts `this` to a [double] before computing the string representation.
   *
   * If the absolute value of `this` is greater or equal to `10^21` then this
   * methods returns an exponential representation computed by
   * `this.toStringAsExponential()`. Otherwise the result
   * is the closest string representation with exactly [fractionDigits] digits
   * after the decimal point. If [fractionDigits] equals 0 then the decimal
   * point is omitted.
   *
   * The parameter [fractionDigits] must be an integer satisfying:
   * [:0 <= fractionDigits <= 20:].
   *
   * Examples:
   *
   *     1.toStringAsFixed(3);  // 1.000
   *     (4321.12345678).toStringAsFixed(3);  // 4321.123
   *     (4321.12345678).toStringAsFixed(5);  // 4321.12346
   *     123456789012345678901.toStringAsFixed(3);  // 123456789012345683968.000
   *     1000000000000000000000.toStringAsFixed(3); // 1e+21
   *     5.25.toStringAsFixed(0); // 5
   */
  String toStringAsFixed(int fractionDigits);

  /**
   * Returns an exponential string-representation of `this`.
   *
   * Converts `this` to a [double] before computing the string representation.
   *
   * If [fractionDigits] is given then it must be an integer satisfying:
   * [:0 <= fractionDigits <= 20:]. In this case the string contains exactly
   * [fractionDigits] after the decimal point. Otherwise, without the parameter,
   * the returned string uses the shortest number of digits that accurately
   * represent [this].
   *
   * If [fractionDigits] equals 0 then the decimal point is omitted.
   * Examples:
   *
   *     1.toStringAsExponential();       // 1e+0
   *     1.toStringAsExponential(3);      // 1.000e+0
   *     123456.toStringAsExponential();  // 1.23456e+5
   *     123456.toStringAsExponential(3); // 1.235e+5
   *     123.toStringAsExponential(0);    // 1e+2
   */
  String toStringAsExponential([int fractionDigits]);

  /**
   * Converts `this` to a double and returns a string representation with
   * exactly [precision] significant digits.
   *
   * The parameter [precision] must be an integer satisfying:
   * [:1 <= precision <= 21:].
   *
   * Examples:
   *
   *     1.toStringAsPrecision(2);       // 1.0
   *     1e15.toStringAsPrecision(3);    // 1.00+15
   *     1234567.toStringAsPrecision(3); // 1.23e+6
   *     1234567.toStringAsPrecision(9); // 1234567.00
   *     12345678901234567890.toStringAsPrecision(20); // 12345678901234567168
   *     12345678901234567890.toStringAsPrecision(14); // 1.2345678901235e+19
   *     0.00000012345.toPrecision(15); // 1.23450000000000e-7
   *     0.0000012345.toPrecision(15);  // 0.00000123450000000000
   */
  String toStringAsPrecision(int precision);

  /**
   * Returns the shortest string that correctly represent the input number.
   *
   * All [double]s in the range `10^-6` (inclusive) to `10^21` (exclusive)
   * are converted to their decimal representation with at least one digit
   * after the decimal point. For all other doubles,
   * except for special values like `NaN` or `Infinity`, this method returns an
   * exponential representation (see [toStringAsExponential]).
   *
   * Returns `"NaN"` for [double.NAN], `"Infinity"` for [double.INFINITY], and
   * `"-Infinity"` for [double.MINUS_INFINITY].
   *
   * An [int] is converted to a decimal representation with no decimal point.
   *
   * Examples:
   *
   *     (0.000001).toString();  // "0.000001"
   *     (0.0000001).toString(); // "1e-7"
   *     (111111111111111111111.0).toString();  // "111111111111111110000.0"
   *     (100000000000000000000.0).toString();  // "100000000000000000000.0"
   *     (1000000000000000000000.0).toString(); // "1e+21"
   *     (1111111111111111111111.0).toString(); // "1.1111111111111111e+21"
   *     1.toString(); // "1"
   *     111111111111111111111.toString();  // "111111111111111110000"
   *     100000000000000000000.toString();  // "100000000000000000000"
   *     1000000000000000000000.toString(); // "1000000000000000000000"
   *     1111111111111111111111.toString(); // "1111111111111111111111"
   *     1.234e5.toString();   // 123400
   *     1234.5e6.toString();  // 1234500000
   *     12.345e67.toString(); // 1.2345e+68
   *
   * Note: the conversion may round the output if the returned string
   * is accurate enough to uniquely identify the input-number.
   * For example the most precise representation of the [double] `9e59` equals
   * `"899999999999999918767229449717619953810131273674690656206848"`, but
   * this method returns the shorter (but still uniquely identifying) `"9e59"`.
   *
   */
  String toString();
}
