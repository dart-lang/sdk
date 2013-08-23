// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Representation of Dart integers containing integer specific
 * operations and specialization of operations inherited from [num].
 *
 * Integers can be arbitrarily large in Dart.
 *
 * *Note however, that when compiling to JavaScript, integers are
 * implemented as JavaScript numbers. When compiling to JavaScript,
 * integers are therefore restricted to 53 significant bits because
 * all JavaScript numbers are double-precision floating point
 * values. The behavior of the operators and methods in the [int]
 * class therefore sometimes differs between the Dart VM and Dart code
 * compiled to JavaScript.*
 *
 * It is a compile-time error for a class to attempt to extend or implement int.
 */
abstract class int extends num {
  /**
   * Bit-wise and operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with only the bits set that are set in
   * both `this` and [other]
   *
   * Of both operands are negative, the result is negative, otherwise
   * the result is non-negative.
   */
  int operator &(int other);

  /**
   * Bit-wise or operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with the bits set that are set in either
   * of `this` and [other]
   *
   * If both operands are non-negative, the result is non-negative,
   * otherwise the result us negative.
   */
  int operator |(int other);

  /**
   * Bit-wise exclusive-or operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with the bits set that are set in one,
   * but not both, of `this` and [other]
   *
   * If the operands have the same sign, the result is non-negative,
   * otherwise the result is negative.
   */
  int operator ^(int other);

  /**
   * The bit-wise negate operator.
   *
   * Treating `this` as a sufficiently large two's component integer,
   * the result is a number with the opposite bits set.
   *
   * This maps any integer `x` to `-x - 1`.
   */
  int operator ~();

  /**
   * Shift the bits of this integer to the left by [shiftAmount].
   *
   * Shifting to the left makes the number larger, effectively multiplying
   * the number by `pow(2, shiftIndex)`.
   *
   * There is no limit on the size of the result. It may be relevant to
   * limit intermediate values by using the "and" operator with a suitable
   * mask.
   *
   * It is an error of [shiftAmount] is negative.
   */
  int operator <<(int shiftAmount);

  /**
   * Shift the bits of this integer to the right by [shiftAmount].
   *
   * Shifting to the right makes the number smaller and drops the least
   * significant bits, effectively doing an integer division by
   *`pow(2, shiftIndex)`.
   *
   * It is an error of [shiftAmount] is negative.
   */
  int operator >>(int shiftAmount);

  /** Returns true if and only if this integer is even. */
  bool get isEven;

  /** Returns true if and only if this integer is odd. */
  bool get isOdd;

  /**
   * Return the negative value of this integer.
   *
   * The result of negating an integer always has the opposite sign, except
   * for zero, which is its own negation.
   */
  int operator -();

  /**
   * Returns the absolute value of this integer.
   *
   * For any integer `x`, the result is the same as `x < 0 ? -x : x`.
   */
  int abs();

  /** Returns `this`. */
  int round();

  /** Returns `this`. */
  int floor();

  /** Returns `this`. */
  int ceil();

  /** Returns `this`. */
  int truncate();

  /** Returns `this.toDouble()`. */
  double roundToDouble();

  /** Returns `this.toDouble()`. */
  double floorToDouble();

  /** Returns `this.toDouble()`. */
  double ceilToDouble();

  /** Returns `this.toDouble()`. */
  double truncateToDouble();

  /**
   * Returns a String-representation of this integer.
   *
   * The returned string is parsable by [parse].
   * For any `int` [:i:], it is guaranteed that
   * [:i == int.parse(i.toString()):].
   */
  String toString();

  /**
   * Converts [this] to a string representation in the given [radix].
   *
   * In the string representation, lower-case letters are used for digits above
   * '9'.
   *
   * The [radix] argument must be an integer in the range 2 to 36.
   */
  String toRadixString(int radix);

  /**
   * Parse [source] as an integer literal and return its value.
   *
   * The [radix] must be in the range 2..36. The digits used are
   * first the decimal digits 0..9, and then the letters 'a'..'z'.
   * Accepts capital letters as well.
   *
   * If no [radix] is given then it defaults to 16 if the string starts
   * with "0x", "-0x" or "+0x" and 10 otherwise.
   *
   * The [source] must be a non-empty sequence of base-[radix] digits,
   * optionally prefixed with a minus or plus sign ('-' or '+').
   *
   * It must always be the case for an int [:n:] and radix [:r:] that
   * [:n == parseRadix(n.toRadixString(r), r):].
   *
   * If the [source] is not a valid integer literal, optionally prefixed by a
   * sign, the [onError] is called with the [source] as argument, and its return
   * value is used instead. If no [onError] is provided, a [FormatException]
   * is thrown.
   *
   * The [onError] function is only invoked if [source] is a [String]. It is
   * not invoked if the [source] is, for example, `null`.
   */
  external static int parse(String source,
                            { int radix,
                              int onError(String source) });
}
