// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
   * Parse [source] as an integer literal and return its value.
   *
   * Accepts "0x" prefix for hexadecimal numbers, otherwise defaults
   * to base-10.
   *
   * Throws a [FormatException] if [source] is not a valid integer literal.
   */
  external static int parse(String source);
}
