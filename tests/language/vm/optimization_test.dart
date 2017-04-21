// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

addThem(a, b) {
  return a + b;
}

isItInt(a) {
  return a is int;
}

doNeg(a) {
  return -a;
}

doNeg2(a) {
  return -a;
}

doNot(a) {
  return !a;
}

doBitNot(a) {
  return ~a;
}

doStore1(a, v) {
  a[1] = v;
}

doStore2(a, v) {
  a[2] = v;
}

class StringPlus {
  const StringPlus(String this._val);
  operator +(right) => new StringPlus("${_val}${right}");
  toString() => _val;

  final String _val;
}

main() {
  for (int i = 0; i < 20; i++) {
    Expect.stringEquals("HI 5", addThem(const StringPlus("HI "), 5).toString());
    Expect.equals(true, isItInt(5));
  }
  Expect.equals(8, addThem(3, 5));
  for (int i = 0; i < 20; i++) {
    Expect.stringEquals("HI 5", addThem(const StringPlus("HI "), 5).toString());
    Expect.equals(8, addThem(3, 5));
  }
  for (int i = -10; i < 10; i++) {
    var r = doNeg(i);
    var p = doNeg(r);
    Expect.equals(i, p);
  }
  var maxSmi = (1 << 30) - 1;
  Expect.equals(maxSmi, doNeg(doNeg(maxSmi)));
  // Deoptimize because of overflow.
  var minInt = -(1 << 30);
  Expect.equals(minInt, doNeg(doNeg(minInt)));

  for (int i = 0; i < 20; i++) {
    Expect.equals(false, doNot(true));
    Expect.equals(true, doNot(doNot(true)));
  }
  for (int i = 0; i < 20; i++) {
    Expect.equals(-57, doBitNot(56));
    Expect.equals(55, doBitNot(-56));
  }

  for (int i = 0; i < 20; i++) {
    Expect.equals(-2.2, doNeg2(2.2));
  }
  // Deoptimize.
  Expect.equals(-5, doNeg2(5));

  var fixed = new List(10);
  var growable = [1, 2, 3, 4, 5];

  for (int i = 0; i < 20; i++) {
    doStore1(fixed, 7);
    Expect.equals(7, fixed[1]);
    doStore2(growable, 12);
    Expect.equals(12, growable[2]);
  }

  // Deoptimize.
  doStore1(growable, 8);
  Expect.equals(8, growable[1]);
  doStore2(fixed, 101);
  Expect.equals(101, fixed[2]);
}
