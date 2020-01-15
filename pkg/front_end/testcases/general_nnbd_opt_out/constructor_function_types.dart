// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A {
  A();
}

class B {
  B(int x, double y, String s);
}

class C<T> {
  C();
}

class D<T, S> {
  D(T x, S y);
}

void main() {
  new A();
  new B(0, 3.14, "foo");
  new C();
  new D<Object, int>(null, 3);
}
