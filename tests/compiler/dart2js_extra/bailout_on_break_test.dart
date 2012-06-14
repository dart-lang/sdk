// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  operator+(arg) => 42;
}

get42() => 42;
getNonInt() => new A();
use(x) => x;

void testInWhileLoop() {
  var c = get42();
  while (true) {
    var e = getNonInt();
    Expect.equals(42, e + 2);
    if (e !== null) break;
    while (true) use(e);
  }
  // This is what matters: 'c' must have been saved in the
  // environment.
  Expect.equals(c, 42);
}

void testInNestedWhileLoop() {
  var c = get42();
  while (true) {
    while (true) {
      var e = getNonInt();
      Expect.equals(42, e + 2);
      if (e !== null) break;
    }
    // This is what matters: 'c' must have been saved in the
    // environment.
    Expect.equals(c, 42);
    if (c == 42) break;
  }
}

void testInNestedWhileLoop2() {
  var c = get42();
  L0: while (true) {
    while (true) {
      var e = getNonInt();
      Expect.equals(42, e + 2);
      if (e !== null) break L0;
      while (true) use(e);
    }
  }
  // This is what matters: 'c' must have been saved in the
  // environment.
  Expect.equals(c, 42);
}

void testInNestedWhileLoop3() {
  var c = get42();
  int index = 0;
  while (index < 2) {
    while (index < 2) {
      var e = getNonInt();
      Expect.equals(42, e + 2);
      if (e !== null && index++ == 0) break;
      // This is what matters: 'c' must have been saved in the
      // environment.
      Expect.equals(c, 42);
      while (e === null) use(e);
    }
  }
}

void testInDoWhileLoop() {
  var c = get42();
  do {
    var e = getNonInt();
    Expect.equals(42, e + 2);
    if (e !== null) break;
    while (true) use(e);
  } while (true);
  // This is what matters: 'c' must have been saved in the
  // environment.
  Expect.equals(c, 42);
}

void testInForLoop() {
  var c = get42();
  for (int i = 0; i < 10; i++) {
    var e = getNonInt();
    Expect.equals(42, e + 2);
    if (e !== null) break;
    while (true) use(e);
  }
  // This is what matters: 'c' must have been saved in the
  // environment.
  Expect.equals(c, 42);
}

void testLabeledIf() {
  var c = get42();
  L1: if (c == 42) {
    var e = getNonInt();
    Expect.equals(42, e + 2);
    if (e === null) break L1;
    // This is what matters: 'c' must have been saved in the
    // environment.
    Expect.equals(c, 42);
    while (e === null) use(e);
  }
  Expect.equals(c, 42);
}

void testLabeledIf2() {
  var c = get42();
  L1: if (c == 42) {
    var e = getNonInt();
    Expect.equals(42, e + 2);
    if (e === null) break L1;
    Expect.equals(42, e + 1);
    while (e === null) use(e);
  }
  Expect.equals(42, c);
}

main() {
  testInWhileLoop();
  testInDoWhileLoop();
  testInForLoop();
  testInNestedWhileLoop();
  testInNestedWhileLoop2();
  testInNestedWhileLoop3();
  testLabeledIf();
  testLabeledIf2();
}
