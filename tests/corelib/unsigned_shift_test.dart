// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import "package:expect/expect.dart";

// The >>> operator is (again) supported by Dart, and used on `int`.

// This test assumes that the JS implementation of `>>>` uses the JS `>>>`
// operator directly (that is, convert the value to Uint32, shift right,)

main() {
  testIntegerShifts();
  testNonIntegerShifts();
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
    //         .   .   .   .
    testShift(0x7fffffffffff, i);
    testShift(0xffffffffffff, i);
    //         .   .   .   .   .
    testShift(0x7ffffffffffff000, i);
    testShift(0xfffffffffffff000, i);
    // Construct the values below to get 'all ones' values on the VM without a
    // compile-time error for roundned literals on the web. The arithmetic
    // produces rounded values on the web, so they are effectively testing zero.
    testShift(0x7ffffffffffff000 + 0xfff, i);
    testShift(0xfffffffffffff000 + 0xfff, i);
  }

  // JavaScript numbers may consider Infinity as an integer.
  // If so, it is zero when converted to a fixed precision.
  if (double.infinity is int) {
    int number = (double.infinity as int);
    Expect.equals(0, number >>> 1);
    Expect.equals(0, 1 >>> number); // infinity > 64.
  }
}

void testNonIntegerShifts() {
  double n = 0.0;
  n >>> 1; //# 01: compile-time error
  for (dynamic number in [0.0, 1.0, 2.4, -2.4, double.infinity, double.nan]) {
    if (number is! int) {
      Expect.throws(() => number >>> 1); //# 07: ok
      Expect.throws(() => 1 >>> number); //# 08: ok
    }
  }
}

void testConstantShifts() {
  const c = C();
  // >>> is a constant operation on integers.
  const c1 = 2 >>> 1;
  const c2 = (1 >>> 0) >>> 0;
  const c3 = 1 >>> 65;

  // >>> is a non-constant operation on other types.
  const c4 = false ? 1 : c >>> c; //# 02: compile-time error
  const c5 = true || c >>> c; //# 03: compile-time error
  const c6 = true || "string" >>> 1;  //# 04: compile-time error
  const c7 = c >>> c; //# 05: compile-time error

  // Or if shifting throws
  const c8 = 1 >>> -1; //# 06: compile-time error

  Expect.isNotNull(c1 + c2 + c3);  // Avoid "unused variable" warnings.
}

const bool isJSBitOps = (-1 | 0) > 0;
const String jsFlag = isJSBitOps ? " (JS)" : "";

void testShift(int value, int shift) {
  var title = "0x${value.toRadixString(16)} >>> $shift$jsFlag";
  if (shift < 0) {
    // No platform allows shifting a negative.
    Expect.throwsArgumentError(() => value >>> shift, "$title: shift < 0");
    return;
  }
  var expected;
  if (isJSBitOps) {
    // TODO: Check that this is the desired behavior for JS >>>.
    expected = value.toUnsigned(32) >> shift;
  } else if (value < 0) {
    if (shift >= 64) {
      expected = 0;
    } else if (shift > 0) {
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
