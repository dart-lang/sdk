// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NumberImplementation implements int, double native "Number" {

  NumberImplementation operator +(NumberImplementation other) native;
  NumberImplementation operator -(NumberImplementation other) native;
  NumberImplementation operator *(NumberImplementation other) native;
  NumberImplementation operator /(NumberImplementation other) native;
  NumberImplementation operator ~/(NumberImplementation other) native;
  NumberImplementation operator %(NumberImplementation shiftAmount) native;
  NumberImplementation operator negate() native;

  int operator |(int other) native;
  int operator &(int other) native;
  int operator ^(int other) native;
  int operator <<(int shiftAmount) native;
  int operator >>(int shiftAmount) native;
  int operator ~() native;

  bool operator ==(NumberImplementation other) native;
  bool operator <(NumberImplementation other) native;
  bool operator <=(NumberImplementation other) native;
  bool operator >(NumberImplementation other) native;
  bool operator >=(NumberImplementation other) native;

  NumberImplementation remainder(num other) native;
  NumberImplementation abs() native;
  NumberImplementation round() native;
  NumberImplementation floor() native;
  NumberImplementation ceil() native;
  NumberImplementation truncate() native;

  // CompareTo has to give a complete order, including -0/+0, NaN and
  // Infinities.
  // Order is: -Inf < .. < -0.0 < 0.0 .. < +inf < NaN.
  NumberImplementation compareTo(NumberImplementation other) {
    // Don't use the 'this' object (which is a JS Number object), but get the
    // primitive JS number by invoking toDouble().
    num thisValue = toDouble();
    // Remember that NaN return false for any comparison.
    if (thisValue < other) {
      return -1;
    } else if (thisValue > other) {
      return 1;
    } else if (thisValue == other) {
      if (thisValue == 0) {
        bool thisIsNegative = isNegative();
        bool otherIsNegative = other.isNegative();
        if (thisIsNegative == otherIsNegative) return 0;
        if (thisIsNegative) return -1;
        return 1;
      }
      return 0;
    } else if (isNaN()) {
      if (other.isNaN()) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  }

  bool isNegative() native;
  bool isEven() native;
  bool isOdd() native;
  bool isNaN() native;
  bool isInfinite() native;

  int toInt() {
    if (isNaN()) throw new BadNumberFormatException("NaN");
    if (isInfinite()) throw new BadNumberFormatException("Infinity");
    NumberImplementation truncated = truncate();
    // If truncated is -0.0 return +0. The test will also trigger for positive
    // 0s but that's not a problem.
    if (truncated == -0.0) return 0;
    return truncated;
  }

  NumberImplementation toDouble() native;
  String toString() native;
  String toStringAsFixed(int fractionDigits) native;
  String toStringAsExponential(int fractionDigits) native;
  String toStringAsPrecision(int precision) native;
  String toRadixString(int radix) native;

  int hashCode() native;
  get dynamic() { return toDouble(); }
}

class _NumberJsUtil {
  static void _throwIllegalArgumentException(var argument) native {
    throw new IllegalArgumentException([argument]);
  }
}
