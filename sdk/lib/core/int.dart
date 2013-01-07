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
 */
abstract class int extends num {
  /** The bit-wise and operator. */
  int operator &(int other);

  /** The bit-wise or operator. */
  int operator |(int other);

  /** The bit-wise xor operator. */
  int operator ^(int other);

  /** The bit-wise negate operator. */
  int operator ~();

  /** The left shift operator. */
  int operator <<(int shiftAmount);

  /** The right shift operator. */
  int operator >>(int shiftAmount);

  /** Returns true if and only if this integer is even. */
  bool get isEven;

  /** Returns true if and only if this integer is odd. */
  bool get isOdd;

  /** Negate operator. Negating an integer produces an integer. */
  int operator -();

  /** Returns the absolute value of this integer. */
  int abs();

  /** Returns [this]. */
  int round();

  /** Returns [this]. */
  int floor();

  /** Returns [this]. */
  int ceil();

  /** Returns [this]. */
  int truncate();

  /**
   * Returns a representation of this [int] value.
   *
   * It should always be the case that if [:i:] is an [int] value,
   * then [:i == int.parse(i.toString()):].
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
   */
  external static int parse(String source,
                            { int radix,
                              int onError(String source) });
}
