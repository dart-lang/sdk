// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation
// VMOptions=--no-intrinsify

// Requirements=nnbd-strong

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

main() {
  for (int i = 0; i < 20; i++) {
    testBigArguments();
    testBadArguments();
  }
}
