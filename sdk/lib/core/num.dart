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
  /**
   * Test whether this value is numerically equal to `other`.
   *
   * If both operands are doubles, they are equal if they have the same
   * representation, except that:
   *
   *   * zero and minus zero (0.0 and -0.0) are considered equal. They
   *     both have the numerical value zero.
   *   * NaN is not equal to anything, including NaN. If either operand is
   *     NaN, the result is always false.
   *
   * If one operand is a double and the other is an int, they are equal if
   * the double has an integer value (finite with no fractional part) and
   * `identical(doubleValue.toInt(), intValue)` is true.
   *
   * If both operands are integers, they are equal if they have the same value.
   *
   * Returns false if `other` is not a [num].
   *
   * Notice that the behavior for NaN is non-reflexive. This means that
   * equality of double values is not a proper equality relation, as is
   * otherwise required of `operator==`. Using NaN in, e.g., a [HashSet]
   * will fail to work. The behavior is the standard IEEE-754 equality of
   * doubles.
   *
   * If you can avoid NaN values, the remaining doubles do have a proper
   * equality relation, and can be used safely.
   *
   * Use [compareTo] for a comparison that distinguishes zero and minus zero,
   * and that considers NaN values as equal.
   */
  bool operator ==(Object other);

  /**
   * Returns a hash code for a numerical value.
   *
   * The hash code is compatible with equality. It returns the same value
   * for an [int] and a [double] with the same numerical value, and therefore
   * the same value for the doubles zero and minus zero.
   *
   * No guarantees are made about the hash code of NaN values.
   */
  int get hashCode;

  /**
   * Compares this to `other`.
   *
   * Returns a negative number if `this` is less than `other`, zero if they are
   * equal, and a positive number if `this` is greater than `other`.
   *
   * The ordering represented by this method is a total ordering of [num]
   * values. All distinct doubles are non-equal, as are all distinct integers,
   * but integers are equal to doubles if they have the same numerical
   * value.
   *
   * For doubles, the `compareTo` operation is different from the partial
   * ordering given by [operator==], [operator<] and [operator>]. For example,
   * IEEE doubles impose that `0.0 == -0.0` and all comparison operations on
   * NaN return false.
   *
   * This function imposes a complete ordering for doubles. When using
   * `compareTo` the following properties hold:
   *
   * - All NaN values are considered equal, and greater than any numeric value.
   * - -0.0 is less than 0.0 (and the integer 0), but greater than any non-zero
   *    negative value.
   * - Negative infinity is less than all other values and positive infinity is
   *   greater than all non-NaN values.
   * - All other values are compared using their numeric value.
   *
   * Examples:
   * ```
   * print(1.compareTo(2)); // => -1
   * print(2.compareTo(1)); // => 1
   * print(1.compareTo(1)); // => 0
   *
   * // The following comparisons yield different results than the
   * // corresponding comparison operators.
   * print((-0.0).compareTo(0.0));  // => -1
   * print(double.NAN.compareTo(double.NAN));  // => 0
   * print(double.INFINITY.compareTo(double.NAN)); // => -1
   *
   * // -0.0, and NaN comparison operators have rules imposed by the IEEE
   * // standard.
   * print(-0.0 == 0.0); // => true
   * print(double.NAN == double.NAN);  // => false
   * print(double.INFINITY < double.NAN);  // => false
   * print(double.NAN < double.INFINITY);  // => false
   * print(double.NAN == double.INFINITY);  // => false
   */
  int compareTo(num other);

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
   * `a == b * q + r` and `0 <= r < b.abs()`.
   *
   * The euclidean division is only defined for integers, but can be easily
   * extended to work with doubles. In that case `r` may have a non-integer
   * value, but it still verifies `0 <= r < |b|`.
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
   * `a ~/ b` is equivalent to `(a / b).truncate().toInt()`.
   *
   * If both operands are [int]s then `a ~/ b` performs the truncating
   * integer division.
   */
  int operator ~/(num other);

  /** Negate operator. */
  num operator -();

  /**
   * Returns the remainder of the truncating division of `this` by [other].
   *
   * The result `r` of this operation satisfies:
   * `this == (this ~/ other) * other + r`.
   * As a consequence the remainder `r` has the same sign as the divider `this`.
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

  /** True if the number is the double Not-a-Number value; otherwise, false. */
  bool get isNaN;

  /**
   * True if the number is negative; otherwise, false.
   *
   * Negative numbers are those less than zero, and the double `-0.0`.
   */
  bool get isNegative;

  /**
   * True if the number is positive infinity or negative infinity; otherwise,
   * false.
   */
  bool get isInfinite;

  /**
   * True if the number is finite; otherwise, false.
   *
   * The only non-finite numbers are NaN, positive infinity, and
   * negative infinity.
   */
  bool get isFinite;

  /** Returns the absolute value of this [num]. */
  num abs();

  /**
   * Returns minus one, zero or plus one depending on the sign and
   * numerical value of the number.
   *
   * Returns minus one if the number is less than zero,
   * plus one if the number is greater than zero,
   * and zero if the number is equal to zero.
   *
   * Returns NaN if the number is the double NaN value.
   *
   * Returns a number of the same type as this number.
   * For doubles, `-0.0.sign == -0.0`.

   * The result satisfies:
   *
   *     n == n.sign * n.abs()
   *
   * for all numbers `n` (except NaN, because NaN isn't `==` to itself).
   */
  num get sign;

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
   * Returns the double integer value closest to `this`.
   *
   * Rounds away from zero when there is no closest integer:
   *  `(3.5).roundToDouble() == 4` and `(-3.5).roundToDouble() == -4`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is a
   * non-finite double value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`,
   * and `-0.0` is therefore considered closer to negative numbers than `0.0`.
   * This means that for a value, `d` in the range `-0.5 < d < 0.0`,
   * the result is `-0.0`.
   *
   * The result is always a double.
   * If this is a numerically large integer, the result may be an infinite
   * double.
   */
  double roundToDouble();

  /**
   * Returns the greatest double integer value no greater than `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is a
   * non-finite double value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `0.0 < d < 1.0` will return `0.0`.
   *
   * The result is always a double.
   * If this is a numerically large integer, the result may be an infinite
   * double.
   */
  double floorToDouble();

  /**
   * Returns the least double integer value no smaller than `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is a
   * non-finite double value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`.
   *
   * The result is always a double.
   * If this is a numerically large integer, the result may be an infinite
   * double.
   */
  double ceilToDouble();

  /**
   * Returns the double integer value obtained by discarding any fractional
   * digits from the double value of `this`.
   *
   * If this is already an integer valued double, including `-0.0`, or it is a
   * non-finite double value, the value is returned unmodified.
   *
   * For the purpose of rounding, `-0.0` is considered to be below `0.0`.
   * A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`, and
   * in the range `0.0 < d < 1.0` it will return 0.0.
   *
   * The result is always a double.
   * If this is a numerically large integer, the result may be an infinite
   * double.
   */
  double truncateToDouble();

  /**
   * Returns this [num] clamped to be in the range [lowerLimit]-[upperLimit].
   *
   * The comparison is done using [compareTo] and therefore takes `-0.0` into
   * account. This also implies that [double.NAN] is treated as the maximal
   * double value.
   *
   * The arguments [lowerLimit] and [upperLimit] must form a valid range where
   * `lowerLimit.compareTo(upperLimit) <= 0`.
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
   * `0 <= fractionDigits <= 20`.
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
   * `0 <= fractionDigits <= 20`. In this case the string contains exactly
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
   * `1 <= precision <= 21`.
   *
   * Examples:
   *
   *     1.toStringAsPrecision(2);       // 1.0
   *     1e15.toStringAsPrecision(3);    // 1.00+15
   *     1234567.toStringAsPrecision(3); // 1.23e+6
   *     1234567.toStringAsPrecision(9); // 1234567.00
   *     12345678901234567890.toStringAsPrecision(20); // 12345678901234567168
   *     12345678901234567890.toStringAsPrecision(14); // 1.2345678901235e+19
   *     0.00000012345.toStringAsPrecision(15); // 1.23450000000000e-7
   *     0.0000012345.toStringAsPrecision(15);  // 0.00000123450000000000
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
   * `"-Infinity"` for [double.NEGATIVE_INFINITY].
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

  /**
   * Parses a string containing a number literal into a number.
   *
   * The method first tries to read the [input] as integer (similar to
   * [int.parse] without a radix).
   * If that fails, it tries to parse the [input] as a double (similar to
   * [double.parse]).
   * If that fails, too, it invokes [onError] with [input], and the result
   * of that invocation becomes the result of calling `parse`.
   *
   * If no [onError] is supplied, it defaults to a function that throws a
   * [FormatException].
   *
   * For any number `n`, this function satisfies
   * `identical(n, num.parse(n.toString()))` (except when `n` is a NaN `double`
   * with a payload).
   */
  static num parse(String input, [num onError(String input)]) {
    String source = input.trim();
    // TODO(lrn): Optimize to detect format and result type in one check.
    num result = int.parse(source, onError: _returnIntNull);
    if (result != null) return result;
    result = double.parse(source, _returnDoubleNull);
    if (result != null) return result;
    if (onError == null) throw new FormatException(input);
    return onError(input);
  }

  /** Helper functions for [parse]. */
  static int _returnIntNull(String _) => null;
  static double _returnDoubleNull(String _) => null;
}
