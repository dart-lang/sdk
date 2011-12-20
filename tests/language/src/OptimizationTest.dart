// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..

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

main() {
  for (int i = 0; i < 2000; i++) {
    Expect.stringEquals("HI 5", addThem("HI ", 5));
    Expect.equals(true, isItInt(5));
  }
  Expect.equals(8, addThem(3, 5));
  for (int i = 0; i < 2000; i++) {
    Expect.stringEquals("HI 5", addThem("HI ", 5));
    Expect.equals(8, addThem(3, 5));
  }
  for (int i = -500; i < 500; i++) {
    var r = doNeg(i);
    var p = doNeg(r);
    Expect.equals(i, p);
  }
  var maxSmi = (1 << 30) - 1;
  Expect.equals(maxSmi, doNeg(doNeg(maxSmi)));
  // Deoptimize because of overflow.
  var minInt = -(1 << 30);
  Expect.equals(minInt, doNeg(doNeg(minInt)));
  
  for (int i = 0; i < 1000; i++) {
    Expect.equals(false, doNot(true));
    Expect.equals(true, doNot(doNot(true)));
  }
  for (int i = 0; i < 1000; i++) {
    Expect.equals(-57, doBitNot(56));
    Expect.equals(55, doBitNot(-56));
  }

  for (int i = 0; i < 2000; i++) {
    Expect.equals(-2.2, doNeg2(2.2));
  }
  // Deoptimize.
  Expect.equals(-5, doNeg2(5));
}