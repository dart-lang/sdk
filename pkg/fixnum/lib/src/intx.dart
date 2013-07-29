// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/**
 * A fixed-precision integer.
 */
abstract class IntX implements Comparable {

  // Arithmetic operations.
  IntX operator +(other);
  IntX operator -(other);
  // The unary '-' operator.  Note that -MIN_VALUE will be equal
  // to MIN_VALUE due to overflow.
  IntX operator -();
  IntX operator *(other);
  IntX operator %(other);
  // Truncating division.
  IntX operator ~/(other);
  IntX remainder(other);

  // Note: no / operator

  // Bit-operations.
  IntX operator &(other);
  IntX operator |(other);
  IntX operator ^(other);
  IntX operator ~();
  IntX operator <<(int shiftAmount);
  IntX operator >>(int shiftAmount);
  IntX shiftRightUnsigned(int shiftAmount);

  // Relational operations, may be applied to IntX or int.
  int compareTo(Comparable other);
  bool operator ==(other);
  bool operator <(other);
  bool operator <=(other);
  bool operator >(other);
  bool operator >=(other);

  // Testers.
  bool get isEven;
  bool get isMaxValue;
  bool get isMinValue;
  bool get isNegative;
  bool get isOdd;
  bool get isZero;

  int get hashCode;

  IntX abs();

  /**
   * Returns the number of leading zeros in this [IntX] as an [int]
   * between 0 and 64.
   */
  int numberOfLeadingZeros();

  /**
   * Returns the number of trailing zeros in this [IntX] as an [int]
   * between 0 and 64.
   */
  int numberOfTrailingZeros();

  /**
   * Converts this [IntX] to a [List] of [int], starting with the least
   * significant byte.
   */
  List<int> toBytes();

  /**
   * Converts this [IntX] to an [int].  On some platforms, inputs with large
   * absolute values (i.e., > 2^52) may lose some of their low bits.
   */
  int toInt();

  /**
   * Converts an [IntX] to 32 bits.  Narrower values are sign extended and
   * wider values have their high bits truncated.
   */
  Int32 toInt32();

  /**
   * Converts an [IntX] to 64 bits.
   */
  Int64 toInt64();

  /**
   * Returns the value of this [IntX] as a decimal [String].
   */
  String toString();

  /**
   * Returns the value of this [IntX] as a hexadecimal [String].
   */
  String toHexString();

  /**
   * Returns the value of this [IntX] as a [String] in the given radix.
   * [radix] must be an integer between 2 and 16, inclusive.
   */
  String toRadixString(int radix);
}
