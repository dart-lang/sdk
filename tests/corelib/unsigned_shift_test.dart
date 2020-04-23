// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=triple-shift

import "package:expect/expect.dart";

// The >>> operator is (again) supported by Dart, and used on `int`.

// This test assumes that the JS implementation of `>>>` uses the JS `>>>`
// operator directly (that is, convert the value to Uint32, shift right,)

main() {
  testIntegerShifts();
  testNonDoubleShifts();
  testConstantShifts();
}

void testIntegerShifts() {
  for (int i = -1; i <= 65; i++) {
    testShift(0, i);
    testShift(1, i);
    testShift(2, i);
    testShift(3, i);
    testShift(-1, i);
    testShift(-5, i);
    //         .   .   .
    testShift(0x7fffffff, i);
    testShift(0x55555555, i);
    testShift(0xaaaaaaaa, i);
    testShift(0x80000000, i);
    //         .   .   .   .   .
    testShift(0x7fffffffffffffff, i);
    testShift(0xffffffffffffffff, i);
  }

  // JavaScript numbers may consider Infinity as an integer.
  // If so, it is zero when converted to a fixed precision.
  if (double.infinity is int) {
    int number = (double.infinity as int);
    Expect.equals(0, number >> 1);
    Expect.throws(() => 1 >>> number); // infinity > 64.
  }
}

void testNonDoubleShifts() {
  double n = 0.0;
  n >>> 1; //# 01: compile-time error
  for (dynamic number in [0.0, 1.0, 2.4, -2.4, double.infinity, double.nan]) {
    if (number is! int) {
      Expect.throws(() => number >>> 1);
      Expect.throws(() => 1 >>> number);
    }
  }
}

int testConstantShifts() {
  const c = C();
  // >>> is a constant operation on integers.
  const c1 = 2 >>> 1;
  const c2 = (1 >>> 0) >>> 0;
  // >>> is a potentially constant operation independent of type.
  // The type must still type-check.
  const c3 = false ? 1 : c >>> c;

  // It's an error if it doesn't type-check.
  const c4 = true || c >>> c; //# 02: compile-time error
  const c5 = true || "string" >>> 1;  //# 03: compile-time error

  // Or if the shift isn't on integers and it is evaluated.
  const c6 = c >>> c; //# 04: compile-time error

  // Or if shifting throws
  const c7 = 1 >>> -1; //# 05: compile-time error
  const c8 = 1 >>> 65; //# 06: compile-time error

  Expect.isNotNull(c1 + c2 + c3);  // Avoid "unused variable" warnings.
}

const bool isJSBitOps = (-1 | 0) > 0;
const String jsFlag = isJSBitOps ? " (JS)" : "";

void testShift(int value, int shift) {
  var title = "0x${value.toRadixString(16)} >>> $shift$jsFlag";
  if (shift < 0) {
    // No platform allows shifting a negative.
    Expect.throws(() => value >>> shift, "$title: shift < 0");
    return;
  }
  if (!isJSBitOps && shift > 64) {
    // Native 64-bit integers do not allow shifts above 64.
    Expect.throws(() => value >>> shift, "$title: shift > 64");
    return;
  }
  var expected;
  if (isJSBitOps) {
    // TODO: Check that this is the desired behavior for JS >>>.
    expected = value.toUnsigned(32) >> shift;
  } else if (value < 0) {
    if (shift > 0) {
      expected = (value >> shift).toUnsigned(64 - shift);
    } else {
      expected = value;
    }
  } else {
    expected = value >> shift;
  }
  Expect.equals(expected, value >>> shift, title);
}

class C {
  const C();
  C operator >>>(C other) => other;
}
