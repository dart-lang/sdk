// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool someStatic;

class A {}

class B {}

Object foo(Object a1, [Object a2]) {
  if (someStatic) {
    a1 = new A();
  }
  bar(a1, 42);
  a1 = new B();
  return (a1 != a2) ? a1 : a2;
}

int bar(Object a1, int a2) {
  Object v1 = a1;
  if (v1 is int) {
    int v2 = v1 + a2;
    return v2 * 3;
  }
  return -1;
}

Object loop1(Object a1, Object a2) {
  Object x = a1;
  x = loop1(x, a1);
  x = a2;
  return x;
}

int loop2(int x) {
  for (int i = 0; i < 5; i++) {
    x = x + 10;
  }
  return x;
}

main() {}
