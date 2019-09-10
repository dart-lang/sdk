// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An arbitrarily large integer.
 */
abstract class BigInt implements Comparable<BigInt> {
  external static BigInt get zero;
  external static BigInt get one;
  external static BigInt get two;

  /**
   * Parses [source] as a, possibly signed, integer literal and returns its
   * value.
   *
   * The [source] must be a non-empty sequence of base-[radix] digits,
   * optionally prefixed with a minus or plus sign ('-' or '+').
   *
   * The [radix] must be in the range 2..36. The digits used are
   * first the decimal digits 0..9, and then the letters 'a'..'z' with
   * values 10 through 35. Also accepts upper-case letters with the same
   * values as the lower-case ones.
   *
   * If no [radix] is given then it defaults to 10. In this case, the [source]
   * digits may also start with `0x`, in which case the number is interpreted
   * as a hexadecimal literal, which effectively means that the `0x` is ignored
   * and the radix is instead set to 16.
   *
   * For any int `n` and radix `r`, it is guaranteed that
   * `n == int.parse(n.toRadixString(r), radix: r)`.
   *
   * Throws a [FormatException] if the [source] is not a valid integer literal,
   * optionally prefixed by a sign.
   */
  external static BigInt parse(String source, {int radix});

  /**
   * Parses [source] as a, possibly signed, integer literal and returns its
   * value.
   *
   * As [parse] except that this method returns `null` if the input is not
   * valid
   */
  external static BigInt tryParse(String source, {int radix});

  /// Allocates a big integer from the provided [value] number.
  external factory BigInt.from(num value);

  /**
   * Returns the absolute value of this integer.
   *
   * For any integer `x`, the result is the same as `x < 0 ? -x : x`.
   */
  BigInt abs();

  /**
   * Return the negative value of this integer.
   *
   * The result of negating an integer always has the opposite sign, except
   * for zero, which is its own negation.
   */
  BigInt operator -();

  /// Addition operator.
  BigInt operator +(BigInt other);

  /// Subtraction operator.
  BigInt operator -(BigInt other);

  /// Multiplication operator.
  BigInt operator *(BigInt other);

  /// Division operator.
  double operator /(BigInt other);

  /**
   * Truncating division operator.
   *
   * Performs a truncating integer division, where the remainder is discarded.
   *
   * The remainder can be computed using the [remainder] method.
   *
   * Examples:
   * ```
   * var seven = new BigInt.from(7);
   * var three = new BigInt.from(3);
   * seven ~/ three;    // => 2
   * (-seven) ~/ three; // => -2
   * seven ~/ -three;   // => -2
   * seven.remainder(three);    // => 1
   * (-seven).remainder(three); // => -1
   * seven.remainder(-three);   // => 1
   * ```
   */
  BigInt operator ~/(BigInt other);

  /**
   * Euclidean modulo operator.
   *
   * Returns the remainder of the Euclidean division. The Euclidean division of
   * two integers `a` and `b` yields two integers `q` and `r` such that
   * `a == b * q + r` and `0 <= r < b.abs()`.
   *
   * The sign of the returned value `r` is always positive.
   *
   * See [remainder] for the remainder of the truncating division.
   */
  BigInt operator %(BigInt other);

  /**
   * Returns the remainder of the truncating division of `this` by [other].
   *
   * The result `r` of this operation satisfies:
   * `this == (this ~/ other) * other + r`.
   * As a consequence the remainder `r` has the same sign as the divider `this`.
   */
  BigInt remainder(BigInt other);

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
   * It is an error if [shiftAmount] is negative.
   */
  BigInt operator <<(int shiftAmount);

  /**
   * Shift the bits of this integer to the right by [shiftAmount].
   *
   * Shifting to the right makes the number smaller and drops the least
   * significant bits, effectively doing an integer division by
   *`pow(2, shiftIndex)`.
   *
   * It is an error if [shiftAmount] is negative.
   */
  BigInt operator >>(int shiftAmount);

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
  BigInt operator &(BigInt other);

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
  BigInt operator |(BigInt other);

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
  BigInt operator ^(BigInt other);

  /**
   * The bit-wise negate operator.
   *
   * Treating `this` as a sufficiently large two's component integer,
   * the result is a number with the opposite bits set.
   *
   * This maps any integer `x` to `-x - 1`.
   */
  BigInt operator ~();

  /** Relational less than operator. */
  bool operator <(BigInt other);

  /** Relational less than or equal operator. */
  bool operator <=(BigInt other);

  /** Relational greater than operator. */
  bool operator >(BigInt other);

  /** Relational greater than or equal operator. */
  bool operator >=(BigInt other);

  /**
   * Compares this to `other`.
   *
   * Returns a negative number if `this` is less than `other`, zero if they are
   * equal, and a positive number if `this` is greater than `other`.
   */
  int compareTo(BigInt other);

  /**
   * Returns the minimum number of bits required to store this big integer.
   *
   * The number of bits excludes the sign bit, which gives the natural length
   * for non-negative (unsigned) values.  Negative values are complemented to
   * return the bit position of the first bit that differs from the sign bit.
   *
   * To find the number of bits needed to store the value as a signed value,
   * add one, i.e. use `x.bitLength + 1`.
   *
   * ```
   * x.bitLength == (-x-1).bitLength
   *
   * new BigInt.from(3).bitLength == 2;   // 00000011
   * new BigInt.from(2).bitLength == 2;   // 00000010
   * new BigInt.from(1).bitLength == 1;   // 00000001
   * new BigInt.from(0).bitLength == 0;   // 00000000
   * new BigInt.from(-1).bitLength == 0;  // 11111111
   * new BigInt.from(-2).bitLength == 1;  // 11111110
   * new BigInt.from(-3).bitLength == 2;  // 11111101
   * new BigInt.from(-4).bitLength == 2;  // 11111100
   * ```
   */
  int get bitLength;

  /**
   * Returns the sign of this big integer.
   *
   * Returns 0 for zero, -1 for values less than zero and
   * +1 for values greater than zero.
   */
  int get sign;

  /// Whether this big integer is even.
  bool get isEven;

  /// Whether this big integer is odd.
  bool get isOdd;

  /// Whether this number is negative.
  bool get isNegative;

  /**
   * Returns `this` to the power of [exponent].
   *
   * Returns [one] if the [exponent] equals 0.
   *
   * The [exponent] must otherwise be positive.
   *
   * The result is always equal to the mathematical result of this to the power
   * [exponent], only limited by the available memory.
   */
  BigInt pow(int exponent);

  /**
   * Returns this integer to the power of [exponent] modulo [modulus].
   *
   * The [exponent] must be non-negative and [modulus] must be
   * positive.
   */
  BigInt modPow(BigInt exponent, BigInt modulus);

  /**
   * Returns the modular multiplicative inverse of this big integer
   * modulo [modulus].
   *
   * The [modulus] must be positive.
   *
   * It is an error if no modular inverse exists.
   */
  // Returns 1/this % modulus, with modulus > 0.
  BigInt modInverse(BigInt modulus);

  /**
   * Returns the greatest common divisor of this big integer and [other].
   *
   * If either number is non-zero, the result is the numerically greatest
   * integer dividing both `this` and `other`.
   *
   * The greatest common divisor is independent of the order,
   * so `x.gcd(y)` is  always the same as `y.gcd(x)`.
   *
   * For any integer `x`, `x.gcd(x)` is `x.abs()`.
   *
   * If both `this` and `other` is zero, the result is also zero.
   */
  BigInt gcd(BigInt other);

  /**
   * Returns the least significant [width] bits of this big integer as a
   * non-negative number (i.e. unsigned representation).  The returned value has
   * zeros in all bit positions higher than [width].
   *
   * ```
   * new BigInt.from(-1).toUnsigned(5) == 31   // 11111111  ->  00011111
   * ```
   *
   * This operation can be used to simulate arithmetic from low level languages.
   * For example, to increment an 8 bit quantity:
   *
   * ```
   * q = (q + 1).toUnsigned(8);
   * ```
   *
   * `q` will count from `0` up to `255` and then wrap around to `0`.
   *
   * If the input fits in [width] bits without truncation, the result is the
   * same as the input.  The minimum width needed to avoid truncation of `x` is
   * given by `x.bitLength`, i.e.
   *
   * ```
   * x == x.toUnsigned(x.bitLength);
   * ```
   */
  BigInt toUnsigned(int width);

  /**
   * Returns the least significant [width] bits of this integer, extending the
   * highest retained bit to the sign.  This is the same as truncating the value
   * to fit in [width] bits using an signed 2-s complement representation.  The
   * returned value has the same bit value in all positions higher than [width].
   *
   * ```
   * var big15 = new BigInt.from(15);
   * var big16 = new BigInt.from(16);
   * var big239 = new BigInt.from(239);
   *                                      V--sign bit-V
   * big16.toSigned(5) == -big16   //  00010000 -> 11110000
   * big239.toSigned(5) == big15   //  11101111 -> 00001111
   *                                      ^           ^
   * ```
   *
   * This operation can be used to simulate arithmetic from low level languages.
   * For example, to increment an 8 bit signed quantity:
   *
   * ```
   * q = (q + 1).toSigned(8);
   * ```
   *
   * `q` will count from `0` up to `127`, wrap to `-128` and count back up to
   * `127`.
   *
   * If the input value fits in [width] bits without truncation, the result is
   * the same as the input.  The minimum width needed to avoid truncation of `x`
   * is `x.bitLength + 1`, i.e.
   *
   * ```
   * x == x.toSigned(x.bitLength + 1);
   * ```
   */
  BigInt toSigned(int width);

  /**
   * Whether this big integer can be represented as an `int` without losing
   * precision.
   *
   * Warning: this function may give a different result on
   * dart2js, dev compiler, and the VM, due to the differences in
   * integer precision.
   */
  bool get isValidInt;

  /**
   * Returns this [BigInt] as an [int].
   *
   * If the number does not fit, clamps to the max (or min)
   * integer.
   *
   * Warning: the clamping behaves differently on dart2js, dev
   * compiler, and the VM, due to the differences in integer
   * precision.
   */
  int toInt();

  /**
   * Returns this [BigInt] as a [double].
   *
   * If the number is not representable as a [double], an
   * approximation is returned. For numerically large integers, the
   * approximation may be infinite.
   */
  double toDouble();

  /**
   * Returns a String-representation of this integer.
   *
   * The returned string is parsable by [parse].
   * For any `BigInt` `i`, it is guaranteed that
   * `i == BigInt.parse(i.toString())`.
   */
  String toString();

  /**
   * Converts [this] to a string representation in the given [radix].
   *
   * In the string representation, lower-case letters are used for digits above
   * '9', with 'a' being 10 an 'z' being 35.
   *
   * The [radix] argument must be an integer in the range 2 to 36.
   */
  String toRadixString(int radix);
}
