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
  NumberImplementation compareTo(NumberImplementation other) {
    // TODO(5427706): NumberImplementation.compareTo is broken, since it
    // doesn't take NaNs and -0.0 into account.
    // And it doesn't return an int...
    return this - other;
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
