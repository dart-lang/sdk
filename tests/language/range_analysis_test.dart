// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Check that range analysis does not enter infinite loop trying to propagate
// ranges through dependant phis.
bar() {
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    for (var j = i - 1; j >= 0; j--) {
      for (var k = j; k < i; k++) {
        sum += (i + j + k);
      }
    }
  }
  return sum;
}

test1() {
  for (var i = 0; i < 20; i++) bar();
}

// Check that range analysis does not erroneously remove overflow check.
test2() {
  var width = 1073741823;
  Expect.equals(width - 1, foo(width - 5000, width - 1));
  Expect.equals(width, foo(width - 5000, width));
}

foo(n, w) {
  var x = 0;
  for (var i = n; i <= w; i++) {
    Expect.isTrue(i > 0);
    x = i;
  }
  return x;
}

// Test detection of unsatisfiable constraints.
f(a, b) {
  if (a < b) {
    if (a > b) {
      throw "unreachable";
    }
    return 2;
  }
  return 3;
}

f1(a, b) {
  if (a < b) {
    if (a > b - 1) {
      throw "unreachable";
    }
    return 2;
  }
  return 3;
}

f2(a, b) {
  if (a < b) {
    if (a > b - 2) {
      return 2;
    }
    throw "unreachable";
  }
  return 3;
}

g() {
  var i;
  for (i = 0; i < 10; i++) {
    if (i < 0) throw "unreachable";
  }
  return i;
}

h(n) {
  var i;
  for (i = 0; i < n; i++) {
    if (i < 0) throw "unreachable";
    var j = i - 1;
    if (j >= n - 1) throw "unreachable";
  }
  return i;
}

test3() {
  test_fun(fun) {
    Expect.equals(2, fun(0, 1));
    Expect.equals(3, fun(0, 0));
    for (var i = 0; i < 20; i++) fun(0, 1);
    Expect.equals(2, fun(0, 1));
    Expect.equals(3, fun(0, 0));
  }

  test_fun(f);
  test_fun(f1);
  test_fun(f2);

  Expect.equals(10, g());
  for (var i = 0; i < 20; i++) g();
  Expect.equals(10, g());

  Expect.equals(10, h(10));
  for (var i = 0; i < 20; i++) h(10);
  Expect.equals(10, h(10));
}

main() {
  test1();
  test2();
  test3();
}
