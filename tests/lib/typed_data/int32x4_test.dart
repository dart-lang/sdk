// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

library int32x4_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

// TODO(eernst): Come pure null-safety, it can only be `TypeError`.
bool isTypeError(e) => e is TypeError || e is ArgumentError;

void testBadArguments() {
  // Check that the actual argument type error is detected and a dynamic
  // error is raised. This is not trivially covered by similar dynamic type
  // checks on actual parameters of user-written functions because `Int32x4`
  // is a built-in type.

  dynamic dynamicNull = null;
  Expect.throws(() => new Int32x4(dynamicNull, 2, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, dynamicNull, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, dynamicNull, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, 3, dynamicNull), isTypeError);

  // Use a local variable typed as dynamic to avoid static warnings.
  dynamic str = "foo";
  Expect.throws(() => new Int32x4(str, 2, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, str, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, str, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, 3, str), isTypeError);
  // Use a local variable typed as dynamic to avoid static warnings.
  dynamic d = 0.5;
  Expect.throws(() => new Int32x4(d, 2, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, d, 3, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, d, 4), isTypeError);
  Expect.throws(() => new Int32x4(1, 2, 3, d), isTypeError);
}

void testBigArguments() {
  var tests = [
    [0x8901234567890, 0x34567890],
    [0x89012A4567890, -1537836912],
    [0x80000000, -2147483648],
    [-0x80000000, -2147483648],
    [0x7fffffff, 2147483647],
    [-0x7fffffff, -2147483647],
  ];
  var int32x4;

  for (var test in tests) {
    var input = test[0];
    var expected = test[1];

    int32x4 = new Int32x4(input, 2, 3, 4);
    Expect.equals(expected, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, input, 3, 4);
    Expect.equals(1, int32x4.x);
    Expect.equals(expected, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, 2, input, 4);
    Expect.equals(1, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(expected, int32x4.z);
    Expect.equals(4, int32x4.w);

    int32x4 = new Int32x4(1, 2, 3, input);
    Expect.equals(1, int32x4.x);
    Expect.equals(2, int32x4.y);
    Expect.equals(3, int32x4.z);
    Expect.equals(expected, int32x4.w);
  }
}

// TODO: Maybe move to `int32x4_arithmetic_test.dart`.
void testBitOperators() {
  var m = Int32x4(0xAAAAAAA, 0xAAAAAAA, 0xAAAAAAA, 0xAAAAAAA);
  var n = Int32x4(0x5555555, 0x5555555, 0x5555555, 0x5555555);
  Expect.equals(0xAAAAAAA, m.x);
  Expect.equals(0xAAAAAAA, m.y);
  Expect.equals(0xAAAAAAA, m.z);
  Expect.equals(0xAAAAAAA, m.w);
  Expect.equals(0x5555555, n.x);
  Expect.equals(0x5555555, n.y);
  Expect.equals(0x5555555, n.z);
  Expect.equals(0x5555555, n.w);
  Expect.equals(true, n.flagX);
  Expect.equals(true, n.flagY);
  Expect.equals(true, n.flagZ);
  Expect.equals(true, n.flagW);
  var o = m | n; // or
  Expect.equals(0xFFFFFFF, o.x);
  Expect.equals(0xFFFFFFF, o.y);
  Expect.equals(0xFFFFFFF, o.z);
  Expect.equals(0xFFFFFFF, o.w);
  Expect.equals(true, o.flagX);
  Expect.equals(true, o.flagY);
  Expect.equals(true, o.flagZ);
  Expect.equals(true, o.flagW);
  o = m & n; // and
  Expect.equals(0x0, o.x);
  Expect.equals(0x0, o.y);
  Expect.equals(0x0, o.z);
  Expect.equals(0x0, o.w);
  n = n.withX(0xAAAAAAA);
  n = n.withY(0xAAAAAAA);
  n = n.withZ(0xAAAAAAA);
  n = n.withW(0xAAAAAAA);
  Expect.equals(0xAAAAAAA, n.x);
  Expect.equals(0xAAAAAAA, n.y);
  Expect.equals(0xAAAAAAA, n.z);
  Expect.equals(0xAAAAAAA, n.w);
  o = m ^ n; // xor
  Expect.equals(0x0, o.x);
  Expect.equals(0x0, o.y);
  Expect.equals(0x0, o.z);
  Expect.equals(0x0, o.w);
  Expect.equals(false, o.flagX);
  Expect.equals(false, o.flagY);
  Expect.equals(false, o.flagZ);
  Expect.equals(false, o.flagW);
}

void testSetters() {
  var m = Int32x4.bool(false, false, false, false);
  Expect.equals(false, m.flagX);
  Expect.equals(false, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagX(true);
  Expect.equals(true, m.flagX);
  Expect.equals(false, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagY(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(false, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagZ(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(false, m.flagW);
  m = m.withFlagW(true);
  Expect.equals(true, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(true, m.flagW);
}

void testGetters() {
  var m = Int32x4.bool(false, true, true, false);
  Expect.equals(false, m.flagX);
  Expect.equals(true, m.flagY);
  Expect.equals(true, m.flagZ);
  Expect.equals(false, m.flagW);
}

main() {
  for (int i = 0; i < 20; i++) {
    testBigArguments();
    testBadArguments();
    testBitOperators();
    testSetters();
    testGetters();
  }
}
