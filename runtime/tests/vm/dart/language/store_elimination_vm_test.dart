// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

class C {
  var x;
  var y;
  final z = 123;
}

class D {
  var x = 0.0;
}

var array = [0, 0];

s1(a) {
  a.x = 42;
  a.x = 43;
  return a.x;
}

void foo(a) {
  Expect.equals(42, a.x);
}

s1a(a) {
  a.x = 42;
  foo(a);
  a.x = 43;
  return a.x;
}

s2() {
  var t = new C();
  return t;
}

s3(a, b) {
  a.x = b + 1;
  if (b % 2 == 0) {
    a.x = 0;
  } else {
    a.x = 0;
  }
  return a.x;
}

s4(a, b) {
  a.x = b + 1.0;
  if (b % 2 == 0) {
    a.x = b + 2.0;
  }
  a.x = b + 1.0;
  return a.x;
}

test_with_context() {
  f(a) {
    var b = a + 1;
    return (() => b + 1)();
  }

  for (var i = 0; i < 100000; i++) f(42);
  Expect.equals(44, f(42));
}

test_with_instance() {
  for (var i = 0; i < 20; i++) Expect.equals(43, s1(new C()));
  for (var i = 0; i < 20; i++) Expect.equals(43, s1a(new C()));
  for (var i = 0; i < 20; i++) Expect.equals(123, s2().z);
  for (var i = 0; i < 20; i++) Expect.equals(0, s3(new C(), i));
  for (var i = 0; i < 20; i++) Expect.equals(i + 1.0, s4(new D(), i));
}

arr1(a) {
  a[0] = 42;
  a[0] = 43;
  Expect.equals(a[0], 43);
  return a[0];
}

arr2(a, b) {
  a[0] = 42;
  a[b % 2] = 43;
  Expect.equals(a[b % 2], 43);
  return a[0];
}

test_with_array() {
  for (var i = 0; i < 20; i++) Expect.equals(43, arr1(array));
  for (var i = 0; i < 20; i++) {
    Expect.equals(i % 2 == 0 ? 43 : 42, arr2(array, i));
  }
}

var st = 0;

static1(b) {
  st = 42;
  if (b % 2 == 0) {
    st = 2;
  }
  st = b + 1;
  Expect.equals(st, b + 1);
  return st;
}

test_with_static() {
  for (var i = 0; i < 20; i++) Expect.equals(i + 1, static1(i));
}

main() {
  test_with_instance();
  test_with_array();
  test_with_context();
  test_with_static();
}
