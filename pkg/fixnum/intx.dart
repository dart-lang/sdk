// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A fixed-precision integer.
 */
abstract class intx implements Comparable {

  // Arithmetic operations.
  intx operator +(other);
  intx operator -(other);
  // The unary '-' operator.  Note that -MIN_VALUE will be equal
  // to MIN_VALUE due to overflow.
  intx operator -();
  intx operator *(other);
  intx operator %(other);
  // Truncating division.
  intx operator ~/(other);
  intx remainder(other);

  // Note: no / operator

  // Bit-operations.
  intx operator &(other);
  intx operator |(other);
  intx operator ^(other);
  intx operator ~();
  intx operator <<(int shiftAmount);
  intx operator >>(int shiftAmount);
  intx shiftRightUnsigned(int shiftAmount);

  // Relational operations, may be applied to intx or int.
  int compareTo(Comparable other);
  bool operator ==(other);
  bool operator <(other);
  bool operator <=(other);
  bool operator >(other);
  bool operator >=(other);

  // Testers.
  bool isEven();
  bool isMaxValue();
  bool isMinValue();
  bool isNegative();
  bool isOdd();
  bool isZero();

  int get hashCode;

  intx abs();

  /**
   * Returns the number of leading zeros in this [intx] as an [int]
   * between 0 and 64.
   */
  int numberOfLeadingZeros();

  /**
   * Returns the number of trailing zeros in this [intx] as an [int]
   * between 0 and 64.
   */
  int numberOfTrailingZeros();

  /**
   * Converts this [intx] to a [List] of [int], starting with the least
   * significant byte.
   */
  List<int> toBytes();

  /**
   * Converts this [intx] to an [int].  On some platforms, inputs with large
   * absolute values (i.e., > 2^52) may lose some of their low bits.
   */
  int toInt();

  /**
   * Converts an [intx] to 32 bits.  Narrower values are sign extended and
   * wider values have their high bits truncated.
   */
  int32 toInt32();

  /**
   * Converts an [intx] to 64 bits.
   */
  int64 toInt64();

  /**
   * Returns the value of this [intx] as a decimal [String].
   */
  String toString();

  /**
   * Returns the value of this [intx] as a hexadecimal [String].
   */
  String toHexString();

  /**
   * Returns the value of this [intx] as a [String] in the given radix.
   * [radix] must be an integer between 2 and 16, inclusive.
   */
  String toRadixString(int radix);
}
