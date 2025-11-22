// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void foo1(int a, {String b});
  int get foo2;
  set foo3(double c);
}

void instanceCalls(A obj, A? obj2, int a, String b, double c) {
  obj.foo1(a);
  obj.foo1(a, b: b);
  final v = obj.foo2;
  if (obj2 != null) {
    if (obj == obj2) {
      obj.foo3 = c + v;
    }
  }
}

int sField = 42;

void staticCalls(int a, Object b) {
  if (a > 0) {
    staticCalls(a - 1, b);
  }
  sField = sField + 1;
}

void dynamicCalls(dynamic x, dynamic y, dynamic z) {
  x.foo1(y, z);
  final v = y.bar;
  z.baz = v + 1;
}

void main() {}
