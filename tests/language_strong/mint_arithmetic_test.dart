// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Test arithmetic on 64-bit integers.

test_and_1() {
  try {
    // Avoid optimizing this function.
    f(a, b) {
      var s = b;
      var t = a & s;
      return t == b;
    }

    var x = 0xffffffff;
    for (var i = 0; i < 20; i++) f(x, 0);
    Expect.equals(true, f(x, 0));
    Expect.equals(false, f(x, -1)); // Triggers deoptimization.
  } finally {}
}

test_and_2() {
  try {
    // Avoid optimizing this function.
    f(a, b) {
      return a & b;
    }

    var x = 0xffffffff;
    for (var i = 0; i < 20; i++) f(x, x);
    Expect.equals(x, f(x, x));
    Expect.equals(1234, f(0xffffffff, 1234));
    Expect.equals(0x100000001, f(0x100000001, -1));
    Expect.equals(-0x40000000, f(-0x40000000, -1));
    Expect.equals(0x40000000, f(0x40000000, -1));
    Expect.equals(0x3fffffff, f(0x3fffffff, -1));
  } finally {}
}

test_xor_1() {
  try {
    // Avoid optimizing this function.
    f(a, b) {
      var s = b;
      var t = a ^ s;
      return t;
    }

    var x = 0xffffffff;
    for (var i = 0; i < 20; i++) f(x, x);
    Expect.equals(0, f(x, x));
    Expect.equals(-x - 1, f(x, -1));
    var y = 0xffffffffffffffff;
    Expect.equals(-y - 1, f(y, -1)); // Triggers deoptimization.
  } finally {}
}

test_or_1() {
  try {
    // Avoid optimizing this function.
    f(a, b) {
      var s = b;
      var t = a | s;
      return t;
    }

    var x = 0xffffffff;
    for (var i = 0; i < 20; i++) f(x, x);
    Expect.equals(x, f(x, x));
    Expect.equals(-1, f(x, -1));
    var y = 0xffffffffffffffff;
    Expect.equals(-1, f(y, -1)); // Triggers deoptimization.
  } finally {}
}

test_func(x, y) => (x & y) + 1.0;

test_mint_double_op() {
  for (var i = 0; i < 20; i++) test_func(4294967295, 1);
  Expect.equals(2.0, test_func(4294967295, 1));
}

main() {
  for (var i = 0; i < 5; i++) {
    test_and_1();
    test_and_2();
    test_xor_1();
    test_or_1();
    test_mint_double_op();
  }
}
